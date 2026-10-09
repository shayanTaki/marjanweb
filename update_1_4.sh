#!/bin/bash
# ============================================================
#  Fix - بخش ۱.۴ (نسخه ۲ - بدون خطای regex)
# ============================================================

set -e

if [ ! -f "manage.py" ]; then
    echo "❌ این اسکریپت باید در ریشه پروژه اجرا شود."
    exit 1
fi

echo "🔧 اعمال fix..."

# ============================================================
#  1. views.py
# ============================================================

cat > appointments/views.py << 'PYEOF'
import jdatetime
from datetime import date
from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth.decorators import login_required
from django.contrib import messages
from django.http import JsonResponse
from django.views.decorators.http import require_POST, require_GET
from django.core.exceptions import ValidationError
from django.db.models import Q

from .models import Staff, Appointment
from .forms import CancelForm
from .utils import get_available_slots, get_month_calendar, create_appointment
from services.models import Service


def _parse_int(value, field_name='پارامتر'):
    """تبدیل ایمن به int — اگر نامعتبر بود None برمی‌گرداند"""
    if value is None:
        return None
    s = str(value).strip()
    if s == '' or s.lower() in ('null', 'undefined', 'none'):
        return None
    try:
        return int(s)
    except (ValueError, TypeError):
        return None


@login_required
def book_appointment(request):
    services = Service.objects.filter(is_active=True).select_related('category')
    staffs = Staff.objects.filter(is_available=True).select_related('user')
    has_staff = staffs.exists()
    has_services = services.exists()

    default_staff = staffs.first()
    preselected_service = None
    preselected_slug = request.GET.get('service')
    if preselected_slug:
        preselected_service = services.filter(slug=preselected_slug).first()

    return render(request, 'appointments/book.html', {
        'services': services,
        'staffs': staffs,
        'has_staff': has_staff,
        'has_services': has_services,
        'default_staff': default_staff,
        'preselected_service': preselected_service,
    })


@login_required
@require_GET
def api_calendar(request):
    service_id = _parse_int(request.GET.get('service_id'))
    staff_id = _parse_int(request.GET.get('staff_id'))
    year = _parse_int(request.GET.get('year')) or jdatetime.date.today().year
    month = _parse_int(request.GET.get('month')) or jdatetime.date.today().month

    if service_id is None:
        return JsonResponse({'error': 'سرویس انتخاب نشده است.'}, status=400)
    if staff_id is None:
        return JsonResponse({'error': 'مشاور انتخاب نشده است.'}, status=400)
    if not (1 <= month <= 12):
        return JsonResponse({'error': 'ماه نامعتبر'}, status=400)

    service = Service.objects.filter(pk=service_id, is_active=True).first()
    if not service:
        return JsonResponse({'error': 'سرویس یافت نشد.'}, status=404)

    staff = Staff.objects.filter(pk=staff_id, is_available=True).first()
    if not staff:
        return JsonResponse({'error': 'مشاور یافت نشد.'}, status=404)

    data = get_month_calendar(staff, service, year, month)

    if month == 1:
        data['prev'] = {'year': year - 1, 'month': 12}
    else:
        data['prev'] = {'year': year, 'month': month - 1}

    if month == 12:
        data['next'] = {'year': year + 1, 'month': 1}
    else:
        data['next'] = {'year': year, 'month': month + 1}

    return JsonResponse(data)


@login_required
@require_GET
def api_slots(request):
    service_id = _parse_int(request.GET.get('service_id'))
    staff_id = _parse_int(request.GET.get('staff_id'))
    jdate_str = request.GET.get('date', '').strip()

    if service_id is None:
        return JsonResponse({'error': 'سرویس انتخاب نشده است.'}, status=400)
    if staff_id is None:
        return JsonResponse({'error': 'مشاور انتخاب نشده است.'}, status=400)
    if not jdate_str:
        return JsonResponse({'error': 'تاریخ را انتخاب کنید.'}, status=400)

    service = Service.objects.filter(pk=service_id, is_active=True).first()
    if not service:
        return JsonResponse({'error': 'سرویس یافت نشد.'}, status=404)

    staff = Staff.objects.filter(pk=staff_id, is_available=True).first()
    if not staff:
        return JsonResponse({'error': 'مشاور یافت نشد.'}, status=404)

    try:
        y, m, d = map(int, jdate_str.split('-'))
        jdate = jdatetime.date(y, m, d)
        gdate = jdate.togregorian()
    except (ValueError, TypeError):
        return JsonResponse({'error': 'تاریخ نامعتبر'}, status=400)

    slots = get_available_slots(staff, service, gdate)

    weekday_names = ['شنبه', 'یکشنبه', 'دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنج‌شنبه', 'جمعه']
    month_names = ['فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور',
                   'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند']

    return JsonResponse({
        'date': jdate_str,
        'jalali_display': f"{weekday_names[jdate.weekday()]} {jdate.day} {month_names[jdate.month - 1]} {jdate.year}",
        'slots': slots,
        'service_duration': service.duration,
    })


@login_required
@require_POST
def confirm_booking(request):
    service_id = request.POST.get('service_id')
    staff_id = request.POST.get('staff_id')
    jdate_str = request.POST.get('date')
    start_time = request.POST.get('start_time')
    end_time = request.POST.get('end_time')
    notes = request.POST.get('notes', '').strip()

    if not all([service_id, staff_id, jdate_str, start_time, end_time]):
        messages.error(request, 'اطلاعات ناقص است.')
        return redirect('appointments:book')

    service = Service.objects.filter(pk=service_id, is_active=True).first()
    staff = Staff.objects.filter(pk=staff_id, is_available=True).first()
    if not service or not staff:
        messages.error(request, 'سرویس یا مشاور معتبر نیست.')
        return redirect('appointments:book')

    try:
        appointment = create_appointment(
            user=request.user,
            service=service,
            staff=staff,
            jdate_str=jdate_str,
            start_time_str=start_time,
            end_time_str=end_time,
            notes=notes,
        )
        messages.success(request, 'نوبت شما با موفقیت ثبت شد و در انتظار تأیید است.')
        return redirect('appointments:detail', pk=appointment.pk)
    except ValidationError as e:
        messages.error(request, str(e.message))
        return redirect('appointments:book')
    except Exception as e:
        messages.error(request, 'خطا در ثبت نوبت: ' + str(e))
        return redirect('appointments:book')


@login_required
def my_appointments(request):
    upcoming = Appointment.objects.filter(
        user=request.user,
        date__gte=date.today(),
        status__in=['pending', 'confirmed'],
    ).select_related('service', 'staff__user').order_by('date', 'start_time')

    past = Appointment.objects.filter(user=request.user).filter(
        Q(date__lt=date.today()) | Q(status__in=['completed', 'cancelled', 'no_show'])
    ).select_related('service', 'staff__user').order_by('-date', '-start_time')

    return render(request, 'appointments/my_appointments.html', {
        'upcoming': upcoming,
        'past': past,
    })


@login_required
def appointment_detail(request, pk):
    appointment = get_object_or_404(
        Appointment.objects.select_related('service', 'staff__user', 'user'),
        pk=pk,
    )
    is_owner = appointment.user == request.user
    is_staff_user = request.user.is_staff or request.user.is_doctor or request.user.is_secretary

    if not (is_owner or is_staff_user):
        messages.error(request, 'شما به این نوبت دسترسی ندارید.')
        return redirect('appointments:my_appointments')

    return render(request, 'appointments/detail.html', {'appointment': appointment})


@login_required
def cancel_appointment(request, pk):
    appointment = get_object_or_404(Appointment, pk=pk, user=request.user)

    if not appointment.can_cancel:
        messages.error(request, 'امکان لغو این نوبت وجود ندارد.')
        return redirect('appointments:detail', pk=pk)

    if request.method == 'POST':
        form = CancelForm(request.POST)
        if form.is_valid():
            appointment.status = 'cancelled'
            appointment.cancel_reason = form.cleaned_data.get('reason', '')
            appointment.save()
            messages.success(request, 'نوبت شما با موفقیت لغو شد.')
            return redirect('appointments:my_appointments')
    else:
        form = CancelForm()

    return render(request, 'appointments/cancel.html', {
        'appointment': appointment,
        'form': form,
    })
PYEOF

echo "✅ views.py به‌روزرسانی شد"

# ============================================================
#  2. بازنویسی کامل book.html (بدون regex)
# ============================================================

cat > templates/appointments/book.html << 'HTMLEOF'
{% extends 'base.html' %}
{% load humanize %}

{% block title %}رزرو نوبت{% endblock %}

{% block content %}
<section class="min-h-screen bg-gradient-to-bl from-slate-50 via-white to-primary-50 py-10">
    <div class="max-w-6xl mx-auto px-4 lg:px-8">

        <div class="text-center mb-10" data-aos="fade-up">
            <div class="inline-flex items-center gap-2 bg-primary/10 text-primary px-4 py-2 rounded-full text-sm font-semibold mb-4">
                <i class="bi bi-calendar2-check"></i>
                <span>سیستم رزرو آنلاین</span>
            </div>
            <h1 class="text-3xl md:text-4xl font-black text-dark mb-3">رزرو نوبت مشاوره</h1>
            <p class="text-slate-500">در ۳ مرحله ساده نوبت خود را رزرو کنید</p>
        </div>

        {% if not has_staff %}
        <div class="bg-amber-50 border-2 border-amber-200 rounded-3xl p-6 mb-6">
            <div class="flex items-start gap-4">
                <div class="w-14 h-14 rounded-2xl bg-amber-100 flex items-center justify-center shrink-0">
                    <i class="bi bi-exclamation-triangle-fill text-2xl text-amber-500"></i>
                </div>
                <div>
                    <h3 class="font-black text-amber-800 mb-1">هنوز مشاوری ثبت نشده است!</h3>
                    <p class="text-sm text-amber-700 leading-7">
                        برای اینکه کاربران بتوانند نوبت رزرو کنند، ابتدا باید از پنل ادمین
                        <strong>یک کاربر با نقش دکتر</strong>، سپس
                        <strong>پرسنل (Staff)</strong> و
                        <strong>ساعات کاری</strong> تعریف کنید.
                    </p>
                    <div class="flex flex-wrap gap-2 mt-3">
                        <a href="/admin/accounts/customuser/add/" target="_blank"
                           class="inline-flex items-center gap-2 bg-amber-500 text-white font-bold px-4 py-2 rounded-xl hover:bg-amber-600 transition text-sm">
                            ۱. ساخت کاربر دکتر
                        </a>
                        <a href="/admin/appointments/staff/add/" target="_blank"
                           class="inline-flex items-center gap-2 bg-amber-500 text-white font-bold px-4 py-2 rounded-xl hover:bg-amber-600 transition text-sm">
                            ۲. ساخت پرسنل
                        </a>
                        <a href="/admin/appointments/workinghours/add/" target="_blank"
                           class="inline-flex items-center gap-2 bg-amber-500 text-white font-bold px-4 py-2 rounded-xl hover:bg-amber-600 transition text-sm">
                            ۳. ساعات کاری
                        </a>
                    </div>
                </div>
            </div>
        </div>
        {% endif %}

        {% if not has_services %}
        <div class="bg-blue-50 border-2 border-blue-200 rounded-3xl p-6 mb-6">
            <div class="flex items-start gap-4">
                <div class="w-14 h-14 rounded-2xl bg-blue-100 flex items-center justify-center shrink-0">
                    <i class="bi bi-info-circle-fill text-2xl text-blue-500"></i>
                </div>
                <div>
                    <h3 class="font-black text-blue-800 mb-1">هنوز سرویسی ثبت نشده است!</h3>
                    <p class="text-sm text-blue-700 leading-7">
                        ابتدا از پنل ادمین یک سرویس بسازید.
                    </p>
                    <a href="/admin/services/service/add/" target="_blank"
                       class="inline-flex items-center gap-2 mt-3 bg-blue-500 text-white font-bold px-4 py-2 rounded-xl hover:bg-blue-600 transition text-sm">
                        ساخت سرویس
                    </a>
                </div>
            </div>
        </div>
        {% endif %}

        {% if has_staff and has_services %}
        <div x-data="bookingWizard({
                serviceId: {{ preselected_service.id|default:0 }},
                serviceName: '{% if preselected_service %}{{ preselected_service.name|escapejs }}{% endif %}',
                serviceDuration: {{ preselected_service.duration|default:0 }},
                servicePrice: {{ preselected_service.price|default:0 }},
                staffId: {{ default_staff.id|default:0 }}
             })"
             x-init="init()"
             x-cloak
             class="space-y-6">

            <div class="bg-white rounded-3xl border border-slate-100 shadow-sm p-6">
                <div class="flex items-center justify-between max-w-3xl mx-auto">
                    <template x-for="(label, idx) in ['انتخاب سرویس', 'تاریخ و ساعت', 'تأیید نهایی']" :key="idx">
                        <div class="flex items-center flex-1">
                            <div class="flex flex-col items-center">
                                <div class="w-12 h-12 rounded-full flex items-center justify-center font-bold text-lg transition-all"
                                     :class="step >= (idx + 1) ? 'bg-gradient-to-br from-primary to-primary-700 text-white shadow-lg shadow-primary/30' : 'bg-slate-100 text-slate-400'">
                                    <template x-if="step > (idx + 1)">
                                        <i class="bi bi-check-lg text-xl"></i>
                                    </template>
                                    <template x-if="step <= (idx + 1)">
                                        <span x-text="idx + 1"></span>
                                    </template>
                                </div>
                                <span class="mt-2 text-xs font-semibold hidden sm:block"
                                      :class="step >= (idx + 1) ? 'text-primary' : 'text-slate-400'"
                                      x-text="label"></span>
                            </div>
                            <div x-show="idx < 2" class="flex-1 h-1 mx-2 rounded-full transition-all"
                                 :class="step > (idx + 1) ? 'bg-primary' : 'bg-slate-100'"></div>
                        </div>
                    </template>
                </div>
            </div>

            <!-- STEP 1 -->
            <div x-show="step === 1">
                <div class="bg-white rounded-3xl border border-slate-100 shadow-sm p-6 md:p-8">
                    <h2 class="text-xl font-black text-dark mb-6 flex items-center gap-3">
                        <span class="w-1.5 h-7 bg-primary rounded-full"></span>
                        یک سرویس انتخاب کنید
                    </h2>

                    <div class="grid md:grid-cols-2 gap-4">
                        {% for service in services %}
                        <button type="button"
                                @click="selectService({{ service.id }}, '{{ service.name|escapejs }}', {{ service.duration }}, {{ service.price }})"
                                class="group text-right p-5 rounded-2xl border-2 transition-all hover:shadow-lg"
                                :class="serviceId === {{ service.id }} ? 'border-primary bg-primary/5 shadow-lg shadow-primary/10' : 'border-slate-100 hover:border-primary/30'">
                            <div class="flex items-start gap-4">
                                <div class="w-14 h-14 rounded-2xl flex items-center justify-center shrink-0 transition"
                                     :class="serviceId === {{ service.id }} ? 'bg-gradient-to-br from-primary to-primary-700 text-white' : 'bg-primary-50 text-primary'">
                                    <i class="bi {{ service.category.icon|default:'bi-heart-pulse' }} text-2xl"></i>
                                </div>
                                <div class="flex-1">
                                    <div class="font-bold text-dark mb-1">{{ service.name }}</div>
                                    <div class="text-xs text-slate-500 mb-3 line-clamp-2">{{ service.short_description|default:service.description|truncatewords:12 }}</div>
                                    <div class="flex items-center gap-3 text-xs">
                                        <span class="text-slate-500"><i class="bi bi-clock"></i> {{ service.duration }} دقیقه</span>
                                        <span class="font-bold text-primary">{{ service.price|intcomma }} تومان</span>
                                    </div>
                                </div>
                                <div class="w-6 h-6 rounded-full border-2 flex items-center justify-center shrink-0"
                                     :class="serviceId === {{ service.id }} ? 'border-primary bg-primary' : 'border-slate-300'">
                                    <template x-if="serviceId === {{ service.id }}">
                                        <i class="bi bi-check text-white text-xs"></i>
                                    </template>
                                </div>
                            </div>
                        </button>
                        {% endfor %}
                    </div>

                    <div class="mt-8 pt-8 border-t border-slate-100">
                        <h3 class="font-bold text-dark mb-4">انتخاب مشاور</h3>
                        <div class="grid sm:grid-cols-2 md:grid-cols-3 gap-3">
                            {% for s in staffs %}
                            <button type="button"
                                    @click="staffId = {{ s.id }}; staffName = '{{ s.user.get_full_name|default:s.user.username|escapejs }}'"
                                    class="p-4 rounded-2xl border-2 text-right transition-all"
                                    :class="staffId === {{ s.id }} ? 'border-primary bg-primary/5' : 'border-slate-100 hover:border-primary/30'">
                                <div class="flex items-center gap-3">
                                    {% if s.user.avatar %}
                                        <img src="{{ s.user.avatar.url }}" class="w-12 h-12 rounded-xl object-cover">
                                    {% else %}
                                        <div class="w-12 h-12 rounded-xl bg-primary-50 text-primary flex items-center justify-center font-bold">
                                            {{ s.user.first_name|first|default:s.user.username|first }}
                                        </div>
                                    {% endif %}
                                    <div>
                                        <div class="font-bold text-sm text-dark">{{ s.user.get_full_name|default:s.user.username }}</div>
                                        <div class="text-xs text-slate-500">{{ s.experience_years }} سال تجربه</div>
                                    </div>
                                </div>
                            </button>
                            {% endfor %}
                        </div>
                    </div>

                    <div class="mt-8 flex justify-end">
                        <button type="button"
                                @click="goToStep(2)"
                                :disabled="!serviceId || !staffId"
                                :class="(!serviceId || !staffId) ? 'opacity-50 cursor-not-allowed' : 'hover:shadow-xl hover:shadow-primary/30'"
                                class="inline-flex items-center gap-2 bg-gradient-to-l from-primary to-primary-700 text-white font-bold px-8 py-3.5 rounded-2xl transition-all">
                            مرحله بعد
                            <i class="bi bi-arrow-left"></i>
                        </button>
                    </div>
                </div>
            </div>

            <!-- STEP 2 -->
            <div x-show="step === 2">
                <div class="grid lg:grid-cols-5 gap-6">
                    <div class="lg:col-span-3 bg-white rounded-3xl border border-slate-100 shadow-sm p-6">
                        <div class="flex items-center justify-between mb-6">
                            <h2 class="text-xl font-black text-dark">انتخاب تاریخ</h2>
                            <div class="flex items-center gap-2">
                                <button type="button" @click="changeMonth(-1)" class="w-10 h-10 rounded-xl bg-slate-100 hover:bg-slate-200 flex items-center justify-center transition">
                                    <i class="bi bi-chevron-right"></i>
                                </button>
                                <div class="font-bold text-sm px-3 min-w-[120px] text-center" x-text="monthLabel"></div>
                                <button type="button" @click="changeMonth(1)" class="w-10 h-10 rounded-xl bg-slate-100 hover:bg-slate-200 flex items-center justify-center transition">
                                    <i class="bi bi-chevron-left"></i>
                                </button>
                            </div>
                        </div>

                        <div x-show="loadingCalendar" class="text-center py-12">
                            <div class="inline-block w-8 h-8 border-4 border-primary/20 border-t-primary rounded-full animate-spin"></div>
                        </div>

                        <div x-show="!loadingCalendar">
                            <div class="grid grid-cols-7 gap-1 mb-2">
                                <template x-for="d in ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج']" :key="d">
                                    <div class="text-center text-xs font-bold text-slate-400 py-2" x-text="d"></div>
                                </template>
                            </div>

                            <div class="grid grid-cols-7 gap-1">
                                <template x-for="i in firstWeekdayOffset" :key="'e' + i">
                                    <div></div>
                                </template>

                                <template x-for="day in calendarDays" :key="day.day">
                                    <button type="button"
                                            @click="day.available && selectDate(day.jdate_str, day.day)"
                                            :disabled="!day.available"
                                            :class="{
                                                'bg-gradient-to-br from-primary to-primary-700 text-white shadow-lg shadow-primary/30': selectedDate === day.jdate_str,
                                                'bg-emerald-50 text-emerald-700 hover:bg-emerald-100 cursor-pointer': day.available && selectedDate !== day.jdate_str,
                                                'text-slate-300 cursor-not-allowed': !day.available,
                                                'ring-2 ring-accent': day.is_today && selectedDate !== day.jdate_str
                                            }"
                                            class="aspect-square rounded-xl text-sm font-bold transition-all flex items-center justify-center">
                                        <span x-text="toFa(day.day)"></span>
                                    </button>
                                </template>
                            </div>

                            <div class="mt-6 pt-6 border-t border-slate-100 flex items-center justify-center gap-6 text-xs">
                                <div class="flex items-center gap-2">
                                    <div class="w-4 h-4 rounded bg-emerald-100"></div>
                                    <span class="text-slate-600">قابل رزرو</span>
                                </div>
                                <div class="flex items-center gap-2">
                                    <div class="w-4 h-4 rounded bg-primary"></div>
                                    <span class="text-slate-600">انتخاب شده</span>
                                </div>
                                <div class="flex items-center gap-2">
                                    <div class="w-4 h-4 rounded bg-slate-100"></div>
                                    <span class="text-slate-600">غیرقابل رزرو</span>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="lg:col-span-2 bg-white rounded-3xl border border-slate-100 shadow-sm p-6">
                        <h2 class="text-xl font-black text-dark mb-2">انتخاب ساعت</h2>
                        <p class="text-sm text-slate-500 mb-6" x-text="selectedDateDisplay || 'ابتدا تاریخ را انتخاب کنید'"></p>

                        <div x-show="!selectedDate" class="text-center py-12">
                            <i class="bi bi-clock-history text-5xl text-slate-200 mb-3"></i>
                            <p class="text-slate-400 text-sm">تاریخی انتخاب نشده است</p>
                        </div>

                        <div x-show="selectedDate && loadingSlots" class="text-center py-8">
                            <div class="inline-block w-8 h-8 border-4 border-primary/20 border-t-primary rounded-full animate-spin"></div>
                        </div>

                        <div x-show="selectedDate && !loadingSlots">
                            <template x-if="slots.length === 0">
                                <div class="text-center py-12">
                                    <i class="bi bi-x-circle text-5xl text-slate-200 mb-3"></i>
                                    <p class="text-slate-400 text-sm">زمانی در این روز موجود نیست</p>
                                </div>
                            </template>

                            <div class="grid grid-cols-3 gap-2 max-h-96 overflow-y-auto">
                                <template x-for="slot in slots" :key="slot.start">
                                    <button type="button"
                                            @click="selectTime(slot)"
                                            :class="selectedTime && selectedTime.start === slot.start ? 'bg-gradient-to-br from-primary to-primary-700 text-white shadow-lg' : 'bg-slate-50 hover:bg-primary/10 text-slate-700'"
                                            class="py-2.5 px-2 rounded-xl text-sm font-bold transition-all">
                                        <span x-text="toFa(slot.start)"></span>
                                    </button>
                                </template>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="mt-6 flex justify-between gap-3">
                    <button type="button" @click="step = 1"
                            class="inline-flex items-center gap-2 bg-slate-100 hover:bg-slate-200 text-slate-700 font-bold px-8 py-3.5 rounded-2xl transition">
                        <i class="bi bi-arrow-right"></i>
                        مرحله قبل
                    </button>
                    <button type="button"
                            @click="goToStep(3)"
                            :disabled="!selectedDate || !selectedTime"
                            :class="(!selectedDate || !selectedTime) ? 'opacity-50 cursor-not-allowed' : 'hover:shadow-xl hover:shadow-primary/30'"
                            class="inline-flex items-center gap-2 bg-gradient-to-l from-primary to-primary-700 text-white font-bold px-8 py-3.5 rounded-2xl transition-all">
                        مرحله بعد
                        <i class="bi bi-arrow-left"></i>
                    </button>
                </div>
            </div>

            <!-- STEP 3 -->
            <div x-show="step === 3">
                <div class="grid lg:grid-cols-5 gap-6">
                    <div class="lg:col-span-2 bg-white rounded-3xl border border-slate-100 shadow-sm p-6">
                        <h2 class="text-xl font-black text-dark mb-6">خلاصه نوبت</h2>

                        <div class="space-y-4">
                            <div class="flex items-start gap-3 p-4 bg-primary-50 rounded-2xl">
                                <div class="w-10 h-10 rounded-xl bg-white flex items-center justify-center text-primary shrink-0">
                                    <i class="bi bi-heart-pulse"></i>
                                </div>
                                <div>
                                    <div class="text-xs text-slate-500">سرویس</div>
                                    <div class="font-bold text-dark text-sm" x-text="serviceName"></div>
                                </div>
                            </div>

                            <div class="flex items-start gap-3 p-4 bg-slate-50 rounded-2xl">
                                <div class="w-10 h-10 rounded-xl bg-white flex items-center justify-center text-slate-500 shrink-0">
                                    <i class="bi bi-person-badge"></i>
                                </div>
                                <div>
                                    <div class="text-xs text-slate-500">مشاور</div>
                                    <div class="font-bold text-dark text-sm" x-text="staffName || 'هر کدام در دسترس'"></div>
                                </div>
                            </div>

                            <div class="flex items-start gap-3 p-4 bg-slate-50 rounded-2xl">
                                <div class="w-10 h-10 rounded-xl bg-white flex items-center justify-center text-slate-500 shrink-0">
                                    <i class="bi bi-calendar3"></i>
                                </div>
                                <div>
                                    <div class="text-xs text-slate-500">تاریخ</div>
                                    <div class="font-bold text-dark text-sm" x-text="selectedDateDisplay"></div>
                                </div>
                            </div>

                            <div class="flex items-start gap-3 p-4 bg-slate-50 rounded-2xl">
                                <div class="w-10 h-10 rounded-xl bg-white flex items-center justify-center text-slate-500 shrink-0">
                                    <i class="bi bi-clock"></i>
                                </div>
                                <div>
                                    <div class="text-xs text-slate-500">ساعت</div>
                                    <div class="font-bold text-dark text-sm" x-text="selectedTime ? toFa(selectedTime.start) + ' - ' + toFa(selectedTime.end) : ''"></div>
                                </div>
                            </div>

                            <div class="pt-4 border-t border-slate-100">
                                <div class="flex justify-between items-center">
                                    <span class="text-slate-500">مدت زمان:</span>
                                    <span class="font-bold" x-text="toFa(serviceDuration) + ' دقیقه'"></span>
                                </div>
                                <div class="flex justify-between items-center mt-3">
                                    <span class="text-slate-500">مبلغ قابل پرداخت:</span>
                                    <span class="font-black text-primary text-lg" x-text="formatPrice(servicePrice) + ' تومان'"></span>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="lg:col-span-3 bg-white rounded-3xl border border-slate-100 shadow-sm p-6 md:p-8">
                        <h2 class="text-xl font-black text-dark mb-6">تأیید نهایی</h2>

                        <form method="post" action="{% url 'appointments:confirm' %}" class="space-y-6">
                            {% csrf_token %}
                            <input type="hidden" name="service_id" :value="serviceId">
                            <input type="hidden" name="staff_id" :value="staffId">
                            <input type="hidden" name="date" :value="selectedDate">
                            <input type="hidden" name="start_time" :value="selectedTime?.start">
                            <input type="hidden" name="end_time" :value="selectedTime?.end">

                            <div>
                                <label class="block text-sm font-semibold text-dark mb-3">
                                    توضیحات اضافی <span class="text-slate-400 font-normal">(اختیاری)</span>
                                </label>
                                <textarea name="notes" rows="4" placeholder="اگر نکته یا توضیح خاصی دارید اینجا بنویسید..."
                                          class="w-full px-4 py-3 rounded-2xl border border-slate-200 focus:border-primary focus:ring-4 focus:ring-primary/10 outline-none transition resize-none"></textarea>
                            </div>

                            <div class="bg-amber-50 border border-amber-200 rounded-2xl p-4 flex gap-3">
                                <i class="bi bi-info-circle-fill text-amber-500 text-xl shrink-0 mt-0.5"></i>
                                <div class="text-sm text-amber-800 leading-6">
                                    پس از ثبت، نوبت شما در وضعیت «در انتظار تأیید» قرار می‌گیرد.
                                </div>
                            </div>

                            <div class="flex flex-col sm:flex-row gap-3">
                                <button type="button" @click="step = 2"
                                        class="flex-1 inline-flex items-center justify-center gap-2 bg-slate-100 hover:bg-slate-200 text-slate-700 font-bold py-4 rounded-2xl transition">
                                    <i class="bi bi-arrow-right"></i>
                                    ویرایش
                                </button>
                                <button type="submit"
                                        class="flex-[2] inline-flex items-center justify-center gap-2 bg-gradient-to-l from-primary to-primary-700 hover:shadow-xl hover:shadow-primary/30 text-white font-bold py-4 rounded-2xl transition-all">
                                    <i class="bi bi-check2-circle text-xl"></i>
                                    ثبت نهایی نوبت
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>
        {% endif %}

    </div>
</section>

<script>
function bookingWizard(initial) {
    return {
        step: 1,
        serviceId: initial.serviceId || 0,
        serviceName: initial.serviceName || '',
        serviceDuration: initial.serviceDuration || 0,
        servicePrice: initial.servicePrice || 0,
        staffId: initial.staffId || 0,
        staffName: '',
        selectedDate: null,
        selectedDateDisplay: '',
        selectedTime: null,
        calendarYear: 1404,
        calendarMonth: 6,
        monthLabel: '',
        calendarDays: [],
        firstWeekdayOffset: 0,
        slots: [],
        loadingCalendar: false,
        loadingSlots: false,

        init() {
            if (this.serviceId && this.staffId) {
                this.$nextTick(() => this.loadCalendar());
            }
        },

        toFa(n) {
            if (n === null || n === undefined || n === '') return '';
            return String(n).replace(/[0-9]/g, function(d) {
                return '۰۱۲۳۴۵۶۷۸۹'[d];
            });
        },

        formatPrice(p) {
            return this.toFa(Number(p || 0).toLocaleString('en-US'));
        },

        selectService(id, name, duration, price) {
            this.serviceId = id;
            this.serviceName = name;
            this.serviceDuration = duration;
            this.servicePrice = price;
        },

        goToStep(n) {
            if (n === 2) {
                if (!this.serviceId) { alert('لطفاً یک سرویس انتخاب کنید.'); return; }
                if (!this.staffId) { alert('لطفاً یک مشاور انتخاب کنید.'); return; }
                this.step = 2;
                this.$nextTick(() => this.loadCalendar());
            } else if (n === 3) {
                if (!this.selectedDate || !this.selectedTime) {
                    alert('لطفاً تاریخ و ساعت را انتخاب کنید.');
                    return;
                }
                this.step = 3;
            }
        },

        async loadCalendar() {
            if (!this.serviceId || !this.staffId) return;
            this.loadingCalendar = true;
            try {
                const url = '/appointments/api/calendar/?service_id=' + this.serviceId
                    + '&staff_id=' + this.staffId
                    + '&year=' + this.calendarYear
                    + '&month=' + this.calendarMonth;
                const res = await fetch(url);
                const data = await res.json();
                if (!res.ok || data.error) throw new Error(data.error || 'خطا در بارگذاری تقویم');

                this.calendarYear = data.year;
                this.calendarMonth = data.month;
                this.monthLabel = data.month_name + ' ' + this.toFa(data.year);
                this.firstWeekdayOffset = data.first_weekday;
                this.calendarDays = data.days;
                this.slots = [];
                this.selectedDate = null;
                this.selectedTime = null;
                this.selectedDateDisplay = '';
            } catch (e) {
                console.error(e);
                this.monthLabel = 'خطا در بارگذاری';
                alert(e.message || 'خطا در بارگذاری تقویم');
            } finally {
                this.loadingCalendar = false;
            }
        },

        changeMonth(delta) {
            let m = this.calendarMonth + delta;
            let y = this.calendarYear;
            if (m > 12) { m = 1; y++; }
            if (m < 1) { m = 12; y--; }
            this.calendarYear = y;
            this.calendarMonth = m;
            this.loadCalendar();
        },

        async selectDate(jdateStr, dayNum) {
            this.selectedDate = jdateStr;
            this.selectedTime = null;
            this.loadingSlots = true;
            this.slots = [];

            try {
                const url = '/appointments/api/slots/?service_id=' + this.serviceId
                    + '&staff_id=' + this.staffId
                    + '&date=' + jdateStr;
                const res = await fetch(url);
                const data = await res.json();
                if (!res.ok || data.error) throw new Error(data.error || 'خطا در بارگذاری زمان‌ها');

                this.selectedDateDisplay = data.jalali_display;
                this.slots = data.slots;
            } catch (e) {
                console.error(e);
                this.selectedDateDisplay = 'خطا';
                alert(e.message || 'خطا در بارگذاری زمان‌ها');
            } finally {
                this.loadingSlots = false;
            }
        },

        selectTime(slot) {
            this.selectedTime = slot;
        },
    }
}
</script>
{% endblock %}
HTMLEOF

echo "✅ book.html بازنویسی شد"

# ============================================================
#  3. اطمینان از نصب jdatetime
# ============================================================

python -c "import jdatetime" 2>/dev/null || {
    echo "📦 نصب jdatetime..."
    pip install jdatetime
}

echo ""
echo "======================================================"
echo "  ✅ Fix با موفقیت اعمال شد!"
echo "======================================================"
echo ""
echo "🚀 حالا این کارها را انجام دهید:"
echo ""
echo "1️⃣  سرور را ری‌استارت کنید:"
echo "    python manage.py runserver"
echo ""
echo "2️⃣  از پنل ادمین این ۳ کار را انجام دهید:"
echo ""
echo "    الف) یک کاربر دکتر بسازید:"
echo "        http://127.0.0.1:8000/admin/accounts/customuser/add/"
echo "        → is_doctor را تیک بزنید"
echo ""
echo "    ب) یک Staff برای آن بسازید:"
echo "        http://127.0.0.1:8000/admin/appointments/staff/add/"
echo ""
echo "    ج) ساعات کاری روزها را تعریف کنید:"
echo "        http://127.0.0.1:8000/admin/appointments/workinghours/add/"
echo "        (مثلاً شنبه تا چهارشنبه، 09:00 تا 18:00)"
echo ""
echo "3️⃣  سپس تست کنید:"
echo "    http://127.0.0.1:8000/appointments/book/"
echo ""
echo "======================================================"