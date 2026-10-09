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

    # Current Jalali date
    today_j = jdatetime.date.today()

    return render(request, 'appointments/book.html', {
        'services': services,
        'staffs': staffs,
        'has_staff': has_staff,
        'has_services': has_services,
        'default_staff': default_staff,
        'preselected_service': preselected_service,
        'today_jalali_year': today_j.year,
        'today_jalali_month': today_j.month,
        'today_jalali_day': today_j.day,
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
