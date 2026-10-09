import uuid
from django.db import models
from django.utils import timezone
from accounts.models import CustomUser
from appointments.models import Appointment


def generate_tracking_code():
    return 'PAY-' + uuid.uuid4().hex[:12].upper()


class Payment(models.Model):
    STATUS_CHOICES = [
        ('pending', 'در انتظار پرداخت'),
        ('success', 'موفق'),
        ('failed', 'ناموفق'),
        ('cancelled', 'لغو شده'),
        ('refunded', 'بازگشت داده شده'),
    ]
    GATEWAY_CHOICES = [
        ('zarinpal', 'زرین‌پال'),
        ('manual', 'پرداخت دستی'),
        ('wallet', 'کیف پول'),
    ]

    tracking_code = models.CharField(
        'کد رهگیری', max_length=40, unique=True,
        editable=False, default=generate_tracking_code,
    )
    authority = models.CharField('Authority درگاه', max_length=100, blank=True, db_index=True)
    ref_id = models.CharField('شماره تراکنش', max_length=50, blank=True)

    user = models.ForeignKey(
        CustomUser, on_delete=models.CASCADE, related_name='payments',
        verbose_name='کاربر',
    )
    appointment = models.ForeignKey(
        Appointment, on_delete=models.SET_NULL, null=True, blank=True,
        related_name='payments', verbose_name='نوبت',
    )

    amount = models.DecimalField('مبلغ (تومان)', max_digits=12, decimal_places=0)
    status = models.CharField('وضعیت', max_length=20, choices=STATUS_CHOICES, default='pending')
    gateway = models.CharField('درگاه پرداخت', max_length=20, choices=GATEWAY_CHOICES, default='zarinpal')

    gateway_response = models.TextField('پاسخ درگاه', blank=True)
    error_message = models.TextField('پیام خطا', blank=True)

    created_at = models.DateTimeField('تاریخ ایجاد', auto_now_add=True)
    paid_at = models.DateTimeField('تاریخ پرداخت', null=True, blank=True)
    updated_at = models.DateTimeField('آخرین ویرایش', auto_now=True)

    class Meta:
        ordering = ['-created_at']
        verbose_name = 'پرداخت'
        verbose_name_plural = 'پرداخت‌ها'
        indexes = [
            models.Index(fields=['user', '-created_at']),
            models.Index(fields=['status']),
        ]

    def __str__(self):
        return f"{self.tracking_code} - {self.user} - {self.amount}"

    @property
    def status_color(self):
        return {
            'pending': 'amber',
            'success': 'emerald',
            'failed': 'red',
            'cancelled': 'slate',
            'refunded': 'purple',
        }.get(self.status, 'slate')

    def mark_success(self, ref_id='', gateway_response=''):
        self.status = 'success'
        self.ref_id = ref_id
        self.gateway_response = gateway_response
        self.paid_at = timezone.now()
        self.save()
        if self.appointment:
            Appointment.objects.filter(pk=self.appointment.pk).update(
                status='confirmed', payment_status='paid',
            )

    def mark_failed(self, error_message='', gateway_response=''):
        self.status = 'failed'
        self.error_message = error_message
        self.gateway_response = gateway_response
        self.save()
