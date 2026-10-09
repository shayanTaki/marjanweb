from django.contrib.auth.models import AbstractUser
from django.db import models


class CustomUser(AbstractUser):
    # Override some AbstractUser fields for Persian labels
    username = models.CharField(
        'نام کاربری', max_length=150, unique=True,
        help_text='اجباری. فقط حروف، اعداد و @/./+/-/_',
        error_messages={'unique': 'این نام کاربری قبلاً گرفته شده است.'},
    )
    first_name = models.CharField('نام', max_length=150, blank=True)
    last_name = models.CharField('نام خانوادگی', max_length=150, blank=True)
    email = models.EmailField('ایمیل', blank=True)

    phone_number = models.CharField('شماره موبایل', max_length=15, unique=True, null=True, blank=True)
    national_code = models.CharField('کد ملی', max_length=10, blank=True)
    birth_date = models.DateField('تاریخ تولد', null=True, blank=True)
    avatar = models.ImageField('تصویر پروفایل', upload_to='avatars/', null=True, blank=True)
    is_doctor = models.BooleanField('دکتر', default=False, help_text='آیا این کاربر دکتر است؟')
    is_secretary = models.BooleanField('منشی', default=False, help_text='آیا این کاربر منشی است؟')

    class Meta:
        verbose_name = 'کاربر'
        verbose_name_plural = 'کاربران'

    def __str__(self):
        return self.get_full_name() or self.username
