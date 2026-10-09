"""ابزارهای محاسبه زمان‌های قابل رزرو"""
import jdatetime
from datetime import date, datetime, timedelta, time as dtime
from django.db.models import Q
from .models import WorkingHours, Appointment, Holiday, BlockedTime


def to_jalali(gdate):
    """تبدیل تاریخ میلادی به شمسی"""
    if isinstance(gdate, datetime):
        gdate = gdate.date()
    return jdatetime.date.fromgregorian(date=gdate)


def to_gregorian(jdate):
    """تبدیل تاریخ شمسی به میلادی"""
    return jdate.togregorian()


def jalali_weekday(gdate):
    """0=شنبه, 6=جمعه"""
    return to_jalali(gdate).weekday()


def day_has_availability(staff, service, target_date, working_days_cache=None, holidays_cache=None):
    """آیا این روز قابل رزرو است؟ (بررسی سریع)"""
    # گذشته
    if target_date < date.today():
        return False

    # تعطیلات
    if holidays_cache is not None:
        if target_date in holidays_cache:
            return False
    else:
        if Holiday.objects.filter(date=target_date, is_full_day=True).exists():
            return False

    # روز کاری
    weekday = jalali_weekday(target_date)
    if working_days_cache is not None:
        if weekday not in working_days_cache:
            return False
    else:
        if not WorkingHours.objects.filter(staff=staff, weekday=weekday, is_active=True).exists():
            return False

    return True


def get_available_slots(staff, service, target_date):
    """لیست زمان‌های خالی برای یک روز مشخص"""
    if not day_has_availability(staff, service, target_date):
        return []

    weekday = jalali_weekday(target_date)

    try:
        wh = WorkingHours.objects.get(staff=staff, weekday=weekday, is_active=True)
    except WorkingHours.DoesNotExist:
        return []

    # شیفت کاری
    shift_start = datetime.combine(target_date, wh.start_time)
    shift_end = datetime.combine(target_date, wh.end_time)
    duration = timedelta(minutes=service.duration)

    # زمان‌های مسدود
    blocked = list(BlockedTime.objects.filter(staff=staff).filter(
        start_datetime__lt=shift_end,
        end_datetime__gt=shift_start,
    ).values_list('start_datetime', 'end_datetime'))

    # نوبت‌های موجود
    existing = list(Appointment.objects.filter(
        staff=staff, date=target_date,
        status__in=['pending', 'confirmed'],
    ).values_list('start_time', 'end_time'))

    slots = []
    current = shift_start

    while current + duration <= shift_end:
        slot_start = current
        slot_end = current + duration

        # بررسی مسدودی
        is_blocked = any(
            b_start < slot_end and b_end > slot_start
            for b_start, b_end in blocked
        )

        # بررسی تداخل با نوبت‌ها
        is_booked = any(
            ex_start < slot_end.time() and ex_end > slot_start.time()
            for ex_start, ex_end in existing
        )

        # بررسی گذشته (امروز)
        now = datetime.now()
        is_past = target_date == date.today() and slot_start < now

        if not is_blocked and not is_booked and not is_past:
            slots.append({
                'start': slot_start.strftime('%H:%M'),
                'end': slot_end.strftime('%H:%M'),
                'available': True,
            })

        current += duration

    return slots


def get_month_calendar(staff, service, jyear, jmonth):
    """تولید تقویم یک ماه شمسی با روزهای در دسترس"""
    try:
        first_day = jdatetime.date(jyear, jmonth, 1)
    except ValueError:
        return {'days': [], 'year': jyear, 'month': jmonth}

    # تعداد روزهای ماه
    if jmonth <= 6:
        days_in_month = 31
    elif jmonth <= 11:
        days_in_month = 30
    else:
        days_in_month = 30 if first_day.isleap() else 29

    # کش: روزهای کاری
    working_days_cache = set(
        WorkingHours.objects.filter(staff=staff, is_active=True).values_list('weekday', flat=True)
    )

    # کش: تعطیلات ۶۰ روز آینده
    start_g = first_day.togregorian()
    end_g = (first_day + timedelta(days=days_in_month + 5)).togregorian()
    holidays_cache = set(
        Holiday.objects.filter(date__range=[start_g, end_g], is_full_day=True).values_list('date', flat=True)
    )

    days = []
    for day in range(1, days_in_month + 1):
        jdate = jdatetime.date(jyear, jmonth, day)
        gdate = jdate.togregorian()
        weekday = jdate.weekday()

        is_past = gdate < date.today()
        available = False

        if not is_past:
            available = day_has_availability(
                staff, service, gdate,
                working_days_cache=working_days_cache,
                holidays_cache=holidays_cache,
            )

        days.append({
            'day': day,
            'weekday': weekday,
            'gdate': gdate.isoformat(),
            'jdate_str': f"{jyear:04d}-{jmonth:02d}-{day:02d}",
            'available': available,
            'is_today': gdate == date.today(),
            'is_past': is_past,
        })

    # نام ماه‌های شمسی
    month_names = ['فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور',
                   'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند']

    return {
        'days': days,
        'year': jyear,
        'month': jmonth,
        'month_name': month_names[jmonth - 1],
        'days_in_month': days_in_month,
        'first_weekday': first_day.weekday(),  # 0=شنبه
    }


def create_appointment(user, service, staff, jdate_str, start_time_str, end_time_str, notes=''):
    """
    ایجاد نوبت با قفل تراکنشی برای جلوگیری از رزرو همزمان.
    jdate_str فرمت: YYYY-MM-DD (شمسی)
    """
    from django.db import transaction
    from django.core.exceptions import ValidationError

    # تبدیل تاریخ
    y, m, d = map(int, jdate_str.split('-'))
    jdate = jdatetime.date(y, m, d)
    gdate = jdate.togregorian()

    # تبدیل ساعت
    sh, sm = map(int, start_time_str.split(':'))
    eh, em = map(int, end_time_str.split(':'))
    start_t = dtime(sh, sm)
    end_t = dtime(eh, em)

    with transaction.atomic():
        # قفل کردن نوبت‌های این پرسنل در این تاریخ
        list(Appointment.objects.select_for_update().filter(
            staff=staff, date=gdate, status__in=['pending', 'confirmed']
        ))

        # بررسی مجدد تداخل
        conflict = Appointment.objects.filter(
            staff=staff, date=gdate, status__in=['pending', 'confirmed'],
        ).filter(
            Q(start_time__lt=end_t) & Q(end_time__gt=start_t)
        ).exists()

        if conflict:
            raise ValidationError('این زمان متأسفانه هم‌اکنون رزرو شد. لطفاً زمان دیگری انتخاب کنید.')

        appointment = Appointment.objects.create(
            user=user, service=service, staff=staff,
            date=gdate, start_time=start_t, end_time=end_t,
            notes=notes, status='pending',
        )

    return appointment
