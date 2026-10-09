from django.db import models
from django.core.validators import MinValueValidator, MaxValueValidator


class ServiceCategory(models.Model):
    name = models.CharField('نام دسته', max_length=100)
    slug = models.SlugField('شناسه URL', unique=True, allow_unicode=True,
                            help_text='برای آدرس صفحه، فقط حروف کوچک و خط تیره')
    description = models.TextField('توضیحات', blank=True)
    icon = models.CharField('آیکون', max_length=80, blank=True,
                            help_text='مثال: bi-heart-pulse (از Bootstrap Icons)')
    image = models.ImageField('تصویر', upload_to='categories/', null=True, blank=True)
    order = models.PositiveIntegerField('ترتیب نمایش', default=0)

    class Meta:
        ordering = ['order']
        verbose_name = 'دسته‌بندی'
        verbose_name_plural = 'دسته‌بندی‌ها'

    def __str__(self):
        return self.name


class Service(models.Model):
    category = models.ForeignKey(
        ServiceCategory, on_delete=models.CASCADE, related_name='services',
        verbose_name='دسته‌بندی',
    )
    name = models.CharField('نام خدمت', max_length=200)
    slug = models.SlugField('شناسه URL', unique=True, allow_unicode=True)
    short_description = models.CharField('توضیح کوتاه', max_length=300, blank=True,
                                        help_text='در کارت‌های لیست نمایش داده می‌شود')
    description = models.TextField('توضیحات کامل')
    duration = models.PositiveIntegerField('مدت زمان (دقیقه)', default=30)
    price = models.DecimalField('قیمت (تومان)', max_digits=12, decimal_places=0)
    image = models.ImageField('تصویر', upload_to='services/', null=True, blank=True)
    is_active = models.BooleanField('فعال', default=True)
    is_featured = models.BooleanField('ویژه', default=False, help_text='نمایش در بخش ویژه صفحه اصلی')
    order = models.PositiveIntegerField('ترتیب نمایش', default=0)
    created_at = models.DateTimeField('تاریخ ایجاد', auto_now_add=True, null=True, blank=True)

    class Meta:
        ordering = ['order']
        verbose_name = 'خدمت'
        verbose_name_plural = 'خدمات'

    def __str__(self):
        return self.name

    def average_rating(self):
        result = self.reviews.filter(is_approved=True).aggregate(
            avg=models.Avg('rating')
        )['avg']
        return round(result or 0, 1)

    def reviews_count(self):
        return self.reviews.filter(is_approved=True).count()


class Package(models.Model):
    name = models.CharField('نام بسته', max_length=200)
    slug = models.SlugField('شناسه URL', unique=True, allow_unicode=True)
    short_description = models.CharField('توضیح کوتاه', max_length=300, blank=True)
    description = models.TextField('توضیحات')
    features = models.TextField('امکانات', blank=True,
                                help_text='هر خط یک امکان')
    price = models.DecimalField('قیمت (تومان)', max_digits=12, decimal_places=0)
    old_price = models.DecimalField('قیمت قبل از تخفیف', max_digits=12, decimal_places=0, null=True, blank=True)
    duration_days = models.PositiveIntegerField('مدت اعتبار (روز)')
    image = models.ImageField('تصویر', upload_to='packages/', null=True, blank=True)
    is_active = models.BooleanField('فعال', default=True)
    is_featured = models.BooleanField('ویژه', default=False)
    order = models.PositiveIntegerField('ترتیب نمایش', default=0)

    class Meta:
        ordering = ['order']
        verbose_name = 'بسته'
        verbose_name_plural = 'بسته‌ها'

    def __str__(self):
        return self.name

    @property
    def discount_percent(self):
        if self.old_price and self.old_price > 0 and self.old_price > self.price:
            return int((self.old_price - self.price) * 100 / self.old_price)
        return 0

    def features_list(self):
        return [line.strip() for line in self.features.splitlines() if line.strip()]


class Article(models.Model):
    title = models.CharField('عنوان', max_length=200)
    slug = models.SlugField('شناسه URL', unique=True, allow_unicode=True)
    summary = models.CharField('خلاصه', max_length=300, blank=True)
    content = models.TextField('محتوا')
    image = models.ImageField('تصویر', upload_to='articles/', null=True, blank=True)
    category = models.ForeignKey(
        ServiceCategory, on_delete=models.SET_NULL, null=True, blank=True,
        verbose_name='دسته‌بندی',
    )
    views = models.PositiveIntegerField('تعداد بازدید', default=0)
    is_published = models.BooleanField('منتشر شده', default=True)
    created_at = models.DateTimeField('تاریخ ایجاد', auto_now_add=True)
    updated_at = models.DateTimeField('آخرین ویرایش', auto_now=True)

    class Meta:
        ordering = ['-created_at']
        verbose_name = 'مقاله'
        verbose_name_plural = 'مقالات'

    def __str__(self):
        return self.title


class ContactMessage(models.Model):
    name = models.CharField('نام و نام خانوادگی', max_length=150)
    phone = models.CharField('شماره تماس', max_length=15)
    email = models.EmailField('ایمیل', blank=True)
    subject = models.CharField('موضوع', max_length=200, blank=True)
    message = models.TextField('متن پیام')
    is_read = models.BooleanField('خوانده شده', default=False)
    created_at = models.DateTimeField('تاریخ ارسال', auto_now_add=True)

    class Meta:
        ordering = ['-created_at']
        verbose_name = 'پیام تماس'
        verbose_name_plural = 'پیام‌های تماس'

    def __str__(self):
        return f"{self.name} - {self.phone}"


class NewsletterSubscriber(models.Model):
    email = models.EmailField('ایمیل', unique=True)
    is_active = models.BooleanField('فعال', default=True)
    created_at = models.DateTimeField('تاریخ عضویت', auto_now_add=True)

    class Meta:
        ordering = ['-created_at']
        verbose_name = 'مشترک خبرنامه'
        verbose_name_plural = 'مشترکین خبرنامه'

    def __str__(self):
        return self.email


class Review(models.Model):
    STATUS_CHOICES = [
        ('pending', 'در انتظار تأیید'),
        ('approved', 'تأیید شده'),
        ('rejected', 'رد شده'),
    ]
    service = models.ForeignKey(
        Service, on_delete=models.CASCADE, related_name='reviews',
        verbose_name='خدمت',
    )
    user = models.ForeignKey(
        'accounts.CustomUser', on_delete=models.CASCADE, related_name='reviews',
        verbose_name='کاربر',
    )
    appointment = models.OneToOneField(
        'appointments.Appointment', on_delete=models.SET_NULL,
        null=True, blank=True, related_name='review',
        verbose_name='نوبت مربوطه',
    )
    rating = models.PositiveSmallIntegerField(
        'امتیاز', validators=[MinValueValidator(1), MaxValueValidator(5)],
        help_text='از ۱ تا ۵',
    )
    comment = models.TextField('نظر', blank=True)
    status = models.CharField('وضعیت', max_length=20, choices=STATUS_CHOICES, default='pending')
    is_approved = models.BooleanField('تأیید شده', default=False)
    admin_reply = models.TextField('پاسخ ادمین', blank=True)
    created_at = models.DateTimeField('تاریخ ثبت', auto_now_add=True)
    updated_at = models.DateTimeField('آخرین ویرایش', auto_now=True)

    class Meta:
        ordering = ['-created_at']
        verbose_name = 'نظر'
        verbose_name_plural = 'نظرات'
        unique_together = ('user', 'service')

    def __str__(self):
        return f"{self.user} - {self.service.name} - {self.rating}/5"

    def save(self, *args, **kwargs):
        self.is_approved = (self.status == 'approved')
        super().save(*args, **kwargs)

    def user_initial(self):
        u = self.user
        return (u.first_name or u.username or '?')[0].upper()
