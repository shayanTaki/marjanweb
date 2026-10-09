import json
import jdatetime
from datetime import date, datetime, time, timedelta
from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth.decorators import login_required, user_passes_test
from django.contrib import messages
from django.http import JsonResponse
from django.views.decorators.http import require_POST, require_GET
from django.db.models import Sum, Count, Q
from django.utils import timezone
from django.core.paginator import Paginator

from accounts.models import CustomUser
from appointments.models import Appointment, Staff, WorkingHours, BlockedTime, Holiday
from services.models import Service
from payments.models import Payment


def is_staff_user(user):
    return user.is_staff or user.is_doctor or user.is_secretary


# ============================================================
#  MAIN DASHBOARD
# ============================================================
@login_required
@user_passes_test(is_staff_user)
def home(request):
    today = date.today()
    month_start = today.replace(day=1)

    # KPIs
    total_appointments = Appointment.objects.count()
    today_appointments = Appointment.objects.filter(date=today).exclude(status='cancelled').count()
    pending_appointments = Appointment.objects.filter(status='pending').count()
    confirmed_appointments = Appointment.objects.filter(status='confirmed').count()
    total_users = CustomUser.objects.count()
    total_revenue = Payment.objects.filter(status='success').aggregate(s=Sum('amount'))['s'] or 0
    month_revenue = Payment.objects.filter(
        status='success', paid_at__gte=month_start
    ).aggregate(s=Sum('amount'))['s'] or 0

    # Today's appointments with details
    today_apps = Appointment.objects.filter(date=today).select_related(
        'user', 'service', 'staff__user'
    ).order_by('start_time')

    # Upcoming appointments (next 7 days)
    week_later = today + timedelta(days=7)
    upcoming = Appointment.objects.filter(
        date__gt=today, date__lte=week_later
    ).exclude(status='cancelled').select_related('user', 'service').order_by('date', 'start_time')[:10]

    # Recent payments
    recent_payments = Payment.objects.filter(status='success').select_related('user').order_by('-paid_at')[:5]

    # Chart data
    chart_data = []
    for i in range(6, -1, -1):
        d = today - timedelta(days=i)
        jd = jdatetime.date.fromgregorian(date=d)
        count = Appointment.objects.filter(date=d).exclude(status='cancelled').count()
        chart_data.append({
            'date': d.isoformat(),
            'jalali_label': f'{jd.month}/{jd.day}',
            'count': count,
        })

    # Status counts
    status_counts = {
        'pending': Appointment.objects.filter(status='pending').count(),
        'confirmed': Appointment.objects.filter(status='confirmed').count(),
        'completed': Appointment.objects.filter(status='completed').count(),
        'cancelled': Appointment.objects.filter(status='cancelled').count(),
        'no_show': Appointment.objects.filter(status='no_show').count(),
    }

    context = {
        'total_appointments': total_appointments,
        'today_appointments': today_appointments,
        'pending_appointments': pending_appointments,
        'confirmed_appointments': confirmed_appointments,
        'total_users': total_users,
        'total_revenue': total_revenue,
        'month_revenue': month_revenue,
        'today_apps': today_apps,
        'upcoming': upcoming,
        'recent_payments': recent_payments,
        'chart_data': chart_data,
        'status_counts': status_counts,
        'today': today,
        'today_jalali': jdatetime.date.fromgregorian(date=today),
    }
    return render(request, 'dashboard/home.html', context)


# ============================================================
#  CALENDAR VIEW - Day/Week/Month
# ============================================================
@login_required
@user_passes_test(is_staff_user)
def calendar_view(request):
    """View for day/week/month appointment calendar"""
    view_type = request.GET.get('view', 'day')
    date_str = request.GET.get('date', '')

    # Parse date (accept Jalali or Gregorian)
    try:
        if date_str:
            # Try Jalali first (YYYY-MM-DD format)
            parts = date_str.split('-')
            if len(parts) == 3 and int(parts[0]) > 1300:
                jy, jm, jd = map(int, parts)
                target_date = jdatetime.date(jy, jm, jd).togregorian()
            else:
                target_date = datetime.strptime(date_str, '%Y-%m-%d').date()
        else:
            target_date = date.today()
    except (ValueError, TypeError):
        target_date = date.today()

    # Get staff (filter by user's own if doctor, else all)
    if request.user.is_doctor:
        staff_list = Staff.objects.filter(user=request.user, is_available=True)
    else:
        staff_list = Staff.objects.filter(is_available=True)

    selected_staff_id = request.GET.get('staff')
    if selected_staff_id:
        staff_list = staff_list.filter(pk=selected_staff_id)

    # Get appointments based on view
    appointments = Appointment.objects.select_related(
        'user', 'service', 'staff__user'
    )

    if selected_staff_id:
        appointments = appointments.filter(staff_id=selected_staff_id)

    if view_type == 'day':
        appointments = appointments.filter(date=target_date)
        date_range_title = self_jalali_display(target_date)
    elif view_type == 'week':
        # Persian week starts Saturday
        weekday = target_date.weekday()  # 0=Mon, ..., 5=Sat, 6=Sun
        # Convert to Persian week index (0=Sat)
        persian_weekday = (weekday + 2) % 7
        week_start = target_date - timedelta(days=persian_weekday)
        week_end = week_start + timedelta(days=6)
        appointments = appointments.filter(date__range=[week_start, week_end])
        date_range_title = f"{self_jalali_display(week_start)} تا {self_jalali_display(week_end)}"
    else:  # month
        jd = jdatetime.date.fromgregorian(date=target_date)
        jmonth_start = jdatetime.date(jd.year, jd.month, 1).togregorian()
        if jd.month < 12:
            next_month = jdatetime.date(jd.year, jd.month + 1, 1).togregorian()
        else:
            next_month = jdatetime.date(jd.year + 1, 1, 1).togregorian()
        month_end = next_month - timedelta(days=1)
        appointments = appointments.filter(date__range=[jmonth_start, month_end])
        date_range_title = f"{get_jalali_month_name(jd.month)} {jd.year}"

    appointments = appointments.order_by('date', 'start_time')

    # Group by date for week/month view
    grouped = {}
    for app in appointments:
        key = app.date.isoformat()
        if key not in grouped:
            grouped[key] = []
        grouped[key].append(app)

    # Stats for this range
    stats = {
        'total': appointments.count(),
        'pending': appointments.filter(status='pending').count(),
        'confirmed': appointments.filter(status='confirmed').count(),
        'completed': appointments.filter(status='completed').count(),
        'cancelled': appointments.filter(status='cancelled').count(),
    }

    context = {
        'view_type': view_type,
        'target_date': target_date,
        'target_date_jalali': jdatetime.date.fromgregorian(date=target_date),
        'date_range_title': date_range_title,
        'appointments': appointments,
        'grouped': grouped,
        'staff_list': staff_list,
        'selected_staff_id': int(selected_staff_id) if selected_staff_id else None,
        'stats': stats,
        'services': Service.objects.filter(is_active=True),
        'status_choices': Appointment.STATUS,
    }
    return render(request, 'dashboard/calendar.html', context)


def self_jalali_display(gdate):
    jd = jdatetime.date.fromgregorian(date=gdate)
    months = ['فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور',
              'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند']
    weekdays = ['دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنج‌شنبه', 'جمعه', 'شنبه', 'یکشنبه']
    weekday = weekdays[gdate.weekday()]
    return f"{weekday} {jd.day} {months[jd.month - 1]} {jd.year}"


def get_jalali_month_name(m):
    months = ['فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور',
              'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند']
    return months[m - 1] if 1 <= m <= 12 else ''


# ============================================================
#  APPOINTMENTS LIST - Full management
# ============================================================
@login_required
@user_passes_test(is_staff_user)
def appointments_list(request):
    """Full list with filters and search"""
    qs = Appointment.objects.select_related('user', 'service', 'staff__user').order_by('-date', '-start_time')

    # Filters
    status = request.GET.get('status', '')
    if status:
        qs = qs.filter(status=status)

    staff_id = request.GET.get('staff', '')
    if staff_id:
        qs = qs.filter(staff_id=staff_id)

    date_from = request.GET.get('date_from', '')
    if date_from:
        try:
            qs = qs.filter(date__gte=datetime.strptime(date_from, '%Y-%m-%d').date())
        except: pass

    date_to = request.GET.get('date_to', '')
    if date_to:
        try:
            qs = qs.filter(date__lte=datetime.strptime(date_to, '%Y-%m-%d').date())
        except: pass

    search = request.GET.get('q', '').strip()
    if search:
        qs = qs.filter(
            Q(user__first_name__icontains=search) |
            Q(user__last_name__icontains=search) |
            Q(user__phone_number__icontains=search) |
            Q(service__name__icontains=search)
        )

    paginator = Paginator(qs, 20)
    page_obj = paginator.get_page(request.GET.get('page', 1))

    context = {
        'appointments': page_obj,
        'page_obj': page_obj,
        'staff_list': Staff.objects.filter(is_available=True),
        'current_status': status,
        'current_staff': staff_id,
        'search': search,
        'status_choices': Appointment.STATUS,
    }
    return render(request, 'dashboard/appointments.html', context)


# ============================================================
#  AJAX: Change appointment status
# ============================================================
@login_required
@user_passes_test(is_staff_user)
@require_POST
def change_appointment_status(request, pk):
    try:
        data = json.loads(request.body)
        new_status = data.get('status', '')
        reason = data.get('reason', '')
    except (json.JSONDecodeError, AttributeError):
        return JsonResponse({'ok': False, 'error': 'Invalid request'}, status=400)

    valid_statuses = [s[0] for s in Appointment.STATUS]
    if new_status not in valid_statuses:
        return JsonResponse({'ok': False, 'error': 'Invalid status'}, status=400)

    try:
        app = Appointment.objects.get(pk=pk)
    except Appointment.DoesNotExist:
        return JsonResponse({'ok': False, 'error': 'Appointment not found'}, status=404)

    app.status = new_status
    if reason:
        app.cancel_reason = reason
    app.save()

    return JsonResponse({
        'ok': True,
        'status': app.status,
        'status_display': app.get_status_display(),
        'status_color': app.status_color,
    })


# ============================================================
#  AJAX: Update appointment time
# ============================================================
@login_required
@user_passes_test(is_staff_user)
@require_POST
def update_appointment_time(request, pk):
    try:
        data = json.loads(request.body)
    except json.JSONDecodeError:
        return JsonResponse({'ok': False, 'error': 'Invalid JSON'}, status=400)

    try:
        app = Appointment.objects.get(pk=pk)
    except Appointment.DoesNotExist:
        return JsonResponse({'ok': False, 'error': 'Appointment not found'}, status=404)

    try:
        jdate_str = data.get('date')  # YYYY-MM-DD Jalali
        start_time = data.get('start_time')  # HH:MM
        end_time = data.get('end_time')

        if jdate_str:
            jy, jm, jd = map(int, jdate_str.split('-'))
            app.date = jdatetime.date(jy, jm, jd).togregorian()
        if start_time:
            h, m = map(int, start_time.split(':'))
            app.start_time = time(h, m)
        if end_time:
            h, m = map(int, end_time.split(':'))
            app.end_time = time(h, m)

        app.save()
        return JsonResponse({
            'ok': True,
            'date_jalali': app.get_jalali_date().strftime('%Y/%m/%d'),
            'start_time': app.start_time.strftime('%H:%M'),
            'end_time': app.end_time.strftime('%H:%M'),
        })
    except (ValueError, TypeError) as e:
        return JsonResponse({'ok': False, 'error': str(e)}, status=400)


# ============================================================
#  Manual Add Appointment
# ============================================================
@login_required
@user_passes_test(is_staff_user)
def add_appointment_manual(request):
    """Add appointment manually (by doctor/secretary)"""
    if request.method == 'POST':
        try:
            user_id = request.POST.get('user_id')
            service_id = request.POST.get('service_id')
            staff_id = request.POST.get('staff_id')
            jdate_str = request.POST.get('date')
            start_time = request.POST.get('start_time')
            end_time = request.POST.get('end_time')
            status = request.POST.get('status', 'confirmed')
            notes = request.POST.get('notes', '')

            # Parse
            user_obj = CustomUser.objects.get(pk=user_id)
            service = Service.objects.get(pk=service_id)
            staff = Staff.objects.get(pk=staff_id)

            jy, jm, jd = map(int, jdate_str.split('-'))
            gdate = jdatetime.date(jy, jm, jd).togregorian()

            sh, sm = map(int, start_time.split(':'))
            eh, em = map(int, end_time.split(':'))

            # Create
            app = Appointment.objects.create(
                user=user_obj,
                service=service,
                staff=staff,
                date=gdate,
                start_time=time(sh, sm),
                end_time=time(eh, em),
                status=status,
                notes=notes,
            )

            messages.success(request, f'نوبت جدید ثبت شد - {app.user.get_full_name()}')
            return redirect('dashboard:calendar')
        except Exception as e:
            messages.error(request, f'خطا در ثبت: {str(e)}')

    # GET - show form
    context = {
        'users': CustomUser.objects.filter(is_active=True).order_by('-date_joined')[:100],
        'services': Service.objects.filter(is_active=True),
        'staff_list': Staff.objects.filter(is_available=True),
        'status_choices': Appointment.STATUS,
        'today_jalali': jdatetime.date.today(),
    }
    return render(request, 'dashboard/add_appointment.html', context)


# ============================================================
#  Block Time
# ============================================================
@login_required
@user_passes_test(is_staff_user)
def block_time(request):
    """Block time slots for staff"""
    if request.method == 'POST':
        try:
            staff_id = request.POST.get('staff_id')
            jdate_str = request.POST.get('date')
            start_time = request.POST.get('start_time')
            end_time = request.POST.get('end_time')
            reason = request.POST.get('reason', '')

            staff = Staff.objects.get(pk=staff_id)
            jy, jm, jd = map(int, jdate_str.split('-'))
            gdate = jdatetime.date(jy, jm, jd).togregorian()

            sh, sm = map(int, start_time.split(':'))
            eh, em = map(int, end_time.split(':'))

            start_dt = timezone.make_aware(datetime.combine(gdate, time(sh, sm)))
            end_dt = timezone.make_aware(datetime.combine(gdate, time(eh, em)))

            BlockedTime.objects.create(
                staff=staff,
                start_datetime=start_dt,
                end_datetime=end_dt,
                reason=reason,
            )
            messages.success(request, 'زمان مسدود شد')
            return redirect('dashboard:calendar')
        except Exception as e:
            messages.error(request, f'خطا: {str(e)}')

    context = {
        'staff_list': Staff.objects.filter(is_available=True),
        'blocked_times': BlockedTime.objects.select_related('staff__user').order_by('-start_datetime')[:20],
        'today_jalali': jdatetime.date.today(),
    }
    return render(request, 'dashboard/block_time.html', context)


# ============================================================
#  API: Get appointments for a specific date (AJAX)
# ============================================================
@login_required
@user_passes_test(is_staff_user)
@require_GET
def api_day_appointments(request):
    """Get appointments for a date - for calendar view"""
    jdate_str = request.GET.get('date', '')
    staff_id = request.GET.get('staff', '')

    if not jdate_str:
        return JsonResponse({'ok': False, 'error': 'Date required'}, status=400)

    try:
        jy, jm, jd = map(int, jdate_str.split('-'))
        gdate = jdatetime.date(jy, jm, jd).togregorian()
    except (ValueError, TypeError):
        return JsonResponse({'ok': False, 'error': 'Invalid date'}, status=400)

    qs = Appointment.objects.filter(date=gdate).select_related(
        'user', 'service', 'staff__user'
    ).order_by('start_time')

    if staff_id:
        qs = qs.filter(staff_id=staff_id)

    apps = []
    for a in qs:
        apps.append({
            'id': a.id,
            'user_name': a.user.get_full_name() or a.user.username,
            'user_phone': a.user.phone_number or '',
            'service': a.service.name,
            'staff': a.staff.user.get_full_name(),
            'start_time': a.start_time.strftime('%H:%M'),
            'end_time': a.end_time.strftime('%H:%M'),
            'status': a.status,
            'status_display': a.get_status_display(),
            'status_color': a.status_color,
            'notes': a.notes,
        })

    return JsonResponse({'ok': True, 'appointments': apps})


# ============================================================
#  PAYMENTS LIST
# ============================================================
@login_required
@user_passes_test(is_staff_user)
def payments_list(request):
    qs = Payment.objects.select_related('user', 'appointment').order_by('-created_at')

    status = request.GET.get('status', '')
    if status:
        qs = qs.filter(status=status)

    search = request.GET.get('q', '').strip()
    if search:
        qs = qs.filter(
            Q(user__first_name__icontains=search) |
            Q(user__phone_number__icontains=search) |
            Q(tracking_code__icontains=search) |
            Q(ref_id__icontains=search)
        )

    paginator = Paginator(qs, 20)
    page_obj = paginator.get_page(request.GET.get('page', 1))

    total = qs.filter(status='success').aggregate(s=Sum('amount'))['s'] or 0

    return render(request, 'dashboard/payments.html', {
        'payments': page_obj,
        'page_obj': page_obj,
        'total_amount': total,
        'current_status': status,
        'search': search,
    })
