from django.db import models
from django.urls import reverse
from accounts.models import CustomUser
from services.models import Service


class Staff(models.Model):
    user = models.OneToOneField(
        CustomUser, on_delete=models.CASCADE, related_name='staff_profile',
        verbose_name='کاربر',
        help_text='کاربری که این پرسنل به آن متصل است',
    )
    bio = models.TextField('بیوگرافی', blank=True)
    experience_years = models.PositiveIntegerField('سابقه کار (سال)', default=0)
    specialties = models.ManyToManyField(
        'services.ServiceCategory', blank=True, verbose_name='تخصص‌ها',
        help_text='دسته‌هایی که این پرسنل در آن‌ها تخصص دارد',
    )
    is_available = models.BooleanField('در دسترس', default=True, help_text='آیا این پرسنل فعال است؟')
    order = models.PositiveIntegerField('ترتیب نمایش', default=0)

    class Meta:
        ordering = ['order']
        verbose_name = 'پرسنل'
        verbose_name_plural = 'پرسنل'

    def __str__(self):
        return self.user.get_full_name() or self.user.username


class WorkingHours(models.Model):
    WEEKDAYS = [
        (0, 'شنبه'), (1, 'یکشنبه'), (2, 'دوشنبه'), (3, 'سه‌شنبه'),
        (4, 'چهارشنبه'), (5, 'پنج‌شنبه'), (6, 'جمعه'),
    ]
    staff = models.ForeignKey(
        Staff, on_delete=models.CASCADE, related_name='working_hours',
        verbose_name='پرسنل',
    )
    weekday = models.IntegerField('روز هفته', choices=WEEKDAYS)
    start_time = models.TimeField('ساعت شروع')
    end_time = models.TimeField('ساعت پایان')
    is_active = models.BooleanField('فعال', default=True)

    class Meta:
        unique_together = ['staff', 'weekday']
        ordering = ['weekday']
        verbose_name = 'ساعت کاری'
        verbose_name_plural = 'ساعات کاری'

    def __str__(self):
        return f"{self.staff} - {self.get_weekday_display()}"


class Holiday(models.Model):
    date = models.DateField('تاریخ', unique=True)
    title = models.CharField('عنوان', max_length=200, blank=True)
    is_full_day = models.BooleanField('تمام روز', default=True)
    start_time = models.TimeField('از ساعت', null=True, blank=True)
    end_time = models.TimeField('تا ساعت', null=True, blank=True)

    class Meta:
        ordering = ['-date']
        verbose_name = 'تعطیلی'
        verbose_name_plural = 'تعطیلات'

    def __str__(self):
        return f"{self.date} - {self.title or 'تعطیل'}"


class BlockedTime(models.Model):
    staff = models.ForeignKey(
        Staff, on_delete=models.CASCADE, related_name='blocked_times',
        verbose_name='پرسنل',
    )
    start_datetime = models.DateTimeField('از تاریخ و ساعت')
    end_datetime = models.DateTimeField('تا تاریخ و ساعت')
    reason = models.CharField('دلیل', max_length=200, blank=True)
    created_at = models.DateTimeField('تاریخ ثبت', auto_now_add=True)

    class Meta:
        ordering = ['-start_datetime']
        verbose_name = 'زمان مسدود'
        verbose_name_plural = 'زمان‌های مسدود'

    def __str__(self):
        return f"{self.staff} - {self.start_datetime:%Y/%m/%d %H:%M}"


class Appointment(models.Model):
    STATUS = [
        ('pending', 'در انتظار تأیید'),
        ('confirmed', 'تأیید شده'),
        ('cancelled', 'لغو شده'),
        ('completed', 'انجام شده'),
        ('no_show', 'عدم حضور'),
    ]
    user = models.ForeignKey(
        CustomUser, on_delete=models.CASCADE, related_name='appointments',
        verbose_name='کاربر', help_text='کاربری که نوبت را رزرو کرده است',
    )
    staff = models.ForeignKey(
        Staff, on_delete=models.CASCADE, related_name='appointments',
        verbose_name='پرسنل', help_text='پرسنلی که این نوبت را انجام می‌دهد',
    )
    service = models.ForeignKey(
        Service, on_delete=models.CASCADE, related_name='appointments',
        verbose_name='خدمت', help_text='خدمتی که در این نوبت ارائه می‌شود',
    )
    date = models.DateField('تاریخ نوبت')
    start_time = models.TimeField('ساعت شروع')
    end_time = models.TimeField('ساعت پایان')
    status = models.CharField(
        'وضعیت', max_length=20, choices=STATUS, default='pending',
    )
    payment_status = models.CharField(
        'وضعیت پرداخت', max_length=20, default='unpaid',
        choices=[
            ('unpaid', 'پرداخت نشده'),
            ('paid', 'پرداخت شده'),
            ('refunded', 'بازگشت داده شده'),
        ],
    )
    notes = models.TextField('یادداشت بیمار', blank=True, help_text='توضیحات کاربر هنگام رزرو')
    staff_notes = models.TextField('یادداشت پرسنل', blank=True, help_text='یادداشت داخلی برای این نوبت')
    cancel_reason = models.TextField('دلیل لغو', blank=True)
    created_at = models.DateTimeField('تاریخ ثبت', auto_now_add=True)
    updated_at = models.DateTimeField('آخرین ویرایش', auto_now=True)

    class Meta:
        ordering = ['-date', '-start_time']
        verbose_name = 'نوبت'
        verbose_name_plural = 'نوبت‌ها'
        indexes = [
            models.Index(fields=['staff', 'date']),
            models.Index(fields=['user', '-created_at']),
        ]

    def __str__(self):
        return f"{self.user} - {self.service} - {self.date} {self.start_time}"

    def get_absolute_url(self):
        return reverse('appointments:detail', args=[self.pk])

    def get_jalali_date(self):
        import jdatetime
        return jdatetime.date.fromgregorian(date=self.date)

    @property
    def can_cancel(self):
        from datetime import datetime, timedelta
        if self.status not in ['pending', 'confirmed']:
            return False
        dt = datetime.combine(self.date, self.start_time)
        return dt - datetime.now() > timedelta(hours=6)

    @property
    def status_color(self):
        return {
            'pending': 'amber',
            'confirmed': 'emerald',
            'cancelled': 'red',
            'completed': 'blue',
            'no_show': 'slate',
        }.get(self.status, 'slate')
