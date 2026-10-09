#!/bin/bash
# ============================================================
#  فاز ۱ - بخش ۱.۱ - پروژه مرجان آرام
#  راه‌اندازی کامل Django + صفحه اصلی زیبا
# ============================================================

set -e  # توقف در صورت خطا

# ---------- پوشه‌ها ----------
mkdir -p config
mkdir -p accounts/migrations
mkdir -p services/migrations
mkdir -p appointments/migrations
mkdir -p payments/migrations
mkdir -p dashboard/migrations
mkdir -p templates/partials
mkdir -p templates/accounts
mkdir -p templates/services
mkdir -p templates/appointments
mkdir -p templates/payments
mkdir -p templates/dashboard
mkdir -p static/css
mkdir -p static/js
mkdir -p static/images
mkdir -p media

echo "✅ پوشه‌ها ساخته شدند"

# ============================================================
#  فایل‌های ریشه پروژه
# ============================================================

cat > requirements.txt << 'EOF'
Django>=5.0,<5.1
Pillow>=10.0
python-decouple>=3.8
django-crispy-forms>=2.1
crispy-tailwind>=1.0.1
requests>=2.31
EOF

cat > .env.example << 'EOF'
SECRET_KEY=django-insecure-your-secret-key-change-me
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1
ZARINPAL_MERCHANT_ID=your-merchant-id
ZARINPAL_SANDBOX=True
SMS_API_KEY=your-api-key
SMS_SENDER=10008663
EOF

cat > .gitignore << 'EOF'
__pycache__/
*.py[cod]
*.sqlite3
.env
media/
staticfiles/
venv/
.idea/
.vscode/
*.log
EOF

cat > manage.py << 'EOF'
#!/usr/bin/env python
import os, sys

def main():
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
    try:
        from django.core.management import execute_from_command_line
    except ImportError as exc:
        raise ImportError("Django not installed") from exc
    execute_from_command_line(sys.argv)

if __name__ == '__main__':
    main()
EOF
chmod +x manage.py

echo "✅ فایل‌های ریشه ساخته شدند"

# ============================================================
#  config
# ============================================================
touch config/__init__.py

cat > config/settings.py << 'EOF'
from pathlib import Path
from decouple import config

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = config('SECRET_KEY', default='django-insecure-temp-key')
DEBUG = config('DEBUG', default=True, cast=bool)
ALLOWED_HOSTS = config('ALLOWED_HOSTS', default='localhost,127.0.0.1').split(',')

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'django.contrib.humanize',
    'crispy_forms',
    'crispy_tailwind',
    'accounts',
    'services',
    'appointments',
    'payments',
    'dashboard',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'config.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [BASE_DIR / 'templates'],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
                'services.context_processors.site_settings',
            ],
        },
    },
]

WSGI_APPLICATION = 'config.wsgi.application'

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}

AUTH_USER_MODEL = 'accounts.CustomUser'

AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]

LANGUAGE_CODE = 'fa-ir'
TIME_ZONE = 'Asia/Tehran'
USE_I18N = True
USE_TZ = True

STATIC_URL = '/static/'
STATICFILES_DIRS = [BASE_DIR / 'static']
STATIC_ROOT = BASE_DIR / 'staticfiles'
MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

CRISPY_ALLOWED_TEMPLATE_PACKS = "tailwind"
CRISPY_TEMPLATE_PACK = "tailwind"

LOGIN_URL = 'accounts:login'
LOGIN_REDIRECT_URL = 'home'
LOGOUT_REDIRECT_URL = 'home'

ZARINPAL_MERCHANT_ID = config('ZARINPAL_MERCHANT_ID', default='')
ZARINPAL_SANDBOX = config('ZARINPAL_SANDBOX', default=True, cast=bool)

SITE_NAME = 'مرجان آرام'
SITE_PHONE = '09016828512'
SITE_ADDRESS = 'خیابان لاهور، شیخ صفی غربی، بعد از چهارراه اول، ساختمان ثامن ۴'
EOF

cat > config/urls.py << 'EOF'
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

admin.site.site_header = 'پنل مدیریت مرجان آرام'
admin.site.site_title = 'مدیریت'
admin.site.index_title = 'به پنل مدیریت خوش آمدید'

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', include('services.urls')),
    path('accounts/', include('accounts.urls')),
    path('appointments/', include('appointments.urls')),
    path('payments/', include('payments.urls')),
    path('dashboard/', include('dashboard.urls')),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)

handler404 = 'services.views.custom_404'
handler500 = 'services.views.custom_500'
EOF

cat > config/wsgi.py << 'EOF'
import os
from django.core.wsgi import get_wsgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
application = get_wsgi_application()
EOF

cat > config/asgi.py << 'EOF'
import os
from django.core.asgi import get_asgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
application = get_asgi_application()
EOF

echo "✅ config ساخته شد"

# ============================================================
#  اپ accounts
# ============================================================
touch accounts/__init__.py accounts/migrations/__init__.py

cat > accounts/models.py << 'EOF'
from django.contrib.auth.models import AbstractUser
from django.db import models


class CustomUser(AbstractUser):
    phone_number = models.CharField('شماره موبایل', max_length=15, unique=True, null=True, blank=True)
    national_code = models.CharField('کد ملی', max_length=10, blank=True)
    birth_date = models.DateField('تاریخ تولد', null=True, blank=True)
    avatar = models.ImageField('تصویر پروفایل', upload_to='avatars/', null=True, blank=True)
    is_doctor = models.BooleanField('دکتر', default=False)
    is_secretary = models.BooleanField('منشی', default=False)

    class Meta:
        verbose_name = 'کاربر'
        verbose_name_plural = 'کاربران'

    def __str__(self):
        return self.get_full_name() or self.username
EOF

cat > accounts/admin.py << 'EOF'
from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import CustomUser


@admin.register(CustomUser)
class CustomUserAdmin(UserAdmin):
    list_display = ('username', 'phone_number', 'first_name', 'last_name', 'is_doctor', 'is_secretary', 'is_staff')
    search_fields = ('username', 'phone_number', 'first_name', 'last_name')
    list_filter = ('is_doctor', 'is_secretary', 'is_staff', 'is_active')
EOF

cat > accounts/views.py << 'EOF'
from django.shortcuts import render, redirect
from django.contrib.auth import login, logout, authenticate
from django.urls import reverse_lazy
from django.views.generic import UpdateView
from django.contrib.auth.mixins import LoginRequiredMixin
from django.contrib import messages
from django import forms
from .models import CustomUser


class RegisterForm(forms.ModelForm):
    password1 = forms.CharField(label='رمز عبور', widget=forms.PasswordInput, min_length=6)
    password2 = forms.CharField(label='تکرار رمز عبور', widget=forms.PasswordInput)

    class Meta:
        model = CustomUser
        fields = ('first_name', 'last_name', 'username', 'phone_number', 'email')

    def clean_password2(self):
        p1 = self.cleaned_data.get('password1')
        p2 = self.cleaned_data.get('password2')
        if p1 and p2 and p1 != p2:
            raise forms.ValidationError('رمزهای عبور یکسان نیستند.')
        return p2

    def save(self, commit=True):
        user = super().save(commit=False)
        user.set_password(self.cleaned_data['password1'])
        if commit:
            user.save()
        return user


class LoginForm(forms.Form):
    username = forms.CharField(label='نام کاربری یا موبایل')
    password = forms.CharField(label='رمز عبور', widget=forms.PasswordInput)


def register_view(request):
    if request.user.is_authenticated:
        return redirect('home')
    if request.method == 'POST':
        form = RegisterForm(request.POST)
        if form.is_valid():
            user = form.save()
            login(request, user)
            messages.success(request, 'ثبت‌نام با موفقیت انجام شد. خوش آمدید!')
            return redirect('home')
    else:
        form = RegisterForm()
    return render(request, 'accounts/register.html', {'form': form})


def login_view(request):
    if request.user.is_authenticated:
        return redirect('home')
    if request.method == 'POST':
        form = LoginForm(request.POST)
        if form.is_valid():
            username = form.cleaned_data['username']
            password = form.cleaned_data['password']
            user = authenticate(request, username=username, password=password)
            if not user and username.isdigit():
                try:
                    u = CustomUser.objects.get(phone_number=username)
                    user = authenticate(request, username=u.username, password=password)
                except CustomUser.DoesNotExist:
                    pass
            if user is not None:
                login(request, user)
                messages.success(request, f'خوش آمدید {user.get_full_name() or user.username}!')
                return redirect(request.GET.get('next', 'home'))
            else:
                messages.error(request, 'نام کاربری یا رمز عبور اشتباه است.')
    else:
        form = LoginForm()
    return render(request, 'accounts/login.html', {'form': form})


def logout_view(request):
    logout(request)
    messages.info(request, 'با موفقیت خارج شدید.')
    return redirect('home')


class ProfileUpdateView(LoginRequiredMixin, UpdateView):
    model = CustomUser
    fields = ['first_name', 'last_name', 'email', 'phone_number', 'national_code', 'birth_date', 'avatar']
    template_name = 'accounts/profile_edit.html'
    success_url = reverse_lazy('accounts:profile')

    def get_object(self):
        return self.request.user


def profile_view(request):
    if not request.user.is_authenticated:
        return redirect('accounts:login')
    return render(request, 'accounts/profile.html')
EOF

cat > accounts/urls.py << 'EOF'
from django.urls import path
from . import views

app_name = 'accounts'

urlpatterns = [
    path('register/', views.register_view, name='register'),
    path('login/', views.login_view, name='login'),
    path('logout/', views.logout_view, name='logout'),
    path('profile/', views.profile_view, name='profile'),
    path('profile/edit/', views.ProfileUpdateView.as_view(), name='profile_edit'),
]
EOF

echo "✅ accounts ساخته شد"

# ============================================================
#  اپ services
# ============================================================
touch services/__init__.py services/migrations/__init__.py

cat > services/models.py << 'EOF'
from django.db import models


class ServiceCategory(models.Model):
    name = models.CharField('نام دسته', max_length=100)
    slug = models.SlugField(unique=True)
    description = models.TextField('توضیحات', blank=True)
    icon = models.CharField('آیکون (کلاس)', max_length=50, blank=True)
    image = models.ImageField('تصویر', upload_to='categories/', null=True, blank=True)
    order = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ['order']
        verbose_name = 'دسته‌بندی'
        verbose_name_plural = 'دسته‌بندی‌ها'

    def __str__(self):
        return self.name


class Service(models.Model):
    category = models.ForeignKey(ServiceCategory, on_delete=models.CASCADE, related_name='services')
    name = models.CharField('نام سرویس', max_length=200)
    slug = models.SlugField(unique=True)
    short_description = models.CharField('توضیح کوتاه', max_length=300, blank=True)
    description = models.TextField('توضیحات کامل')
    duration = models.PositiveIntegerField('مدت (دقیقه)', default=30)
    price = models.DecimalField('قیمت (تومان)', max_digits=12, decimal_places=0)
    image = models.ImageField('تصویر', upload_to='services/', null=True, blank=True)
    is_active = models.BooleanField(default=True)
    is_featured = models.BooleanField('ویژه', default=False)
    order = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ['order']
        verbose_name = 'سرویس'
        verbose_name_plural = 'سرویس‌ها'

    def __str__(self):
        return self.name


class Article(models.Model):
    title = models.CharField('عنوان', max_length=200)
    slug = models.SlugField(unique=True)
    summary = models.CharField('خلاصه', max_length=300, blank=True)
    content = models.TextField('محتوا')
    image = models.ImageField('تصویر', upload_to='articles/', null=True, blank=True)
    is_published = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']
        verbose_name = 'مقاله'
        verbose_name_plural = 'مقالات'

    def __str__(self):
        return self.title


class Package(models.Model):
    name = models.CharField('نام بسته', max_length=200)
    slug = models.SlugField(unique=True)
    description = models.TextField('توضیحات')
    price = models.DecimalField('قیمت', max_digits=12, decimal_places=0)
    duration_days = models.PositiveIntegerField('مدت (روز)')
    image = models.ImageField('تصویر', upload_to='packages/', null=True, blank=True)
    is_active = models.BooleanField(default=True)
    is_featured = models.BooleanField('ویژه', default=False)
    order = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ['order']
        verbose_name = 'بسته'
        verbose_name_plural = 'بسته‌ها'

    def __str__(self):
        return self.name
EOF

cat > services/admin.py << 'EOF'
from django.contrib import admin
from .models import ServiceCategory, Service, Article, Package


@admin.register(ServiceCategory)
class ServiceCategoryAdmin(admin.ModelAdmin):
    list_display = ('name', 'order')
    prepopulated_fields = {'slug': ('name',)}
    list_editable = ('order',)


@admin.register(Service)
class ServiceAdmin(admin.ModelAdmin):
    list_display = ('name', 'category', 'price', 'duration', 'is_active', 'is_featured', 'order')
    list_filter = ('category', 'is_active', 'is_featured')
    list_editable = ('is_active', 'is_featured', 'order')
    prepopulated_fields = {'slug': ('name',)}
    search_fields = ('name',)


@admin.register(Article)
class ArticleAdmin(admin.ModelAdmin):
    list_display = ('title', 'is_published', 'created_at')
    list_filter = ('is_published',)
    prepopulated_fields = {'slug': ('title',)}


@admin.register(Package)
class PackageAdmin(admin.ModelAdmin):
    list_display = ('name', 'price', 'duration_days', 'is_active', 'is_featured')
    list_filter = ('is_active', 'is_featured')
    prepopulated_fields = {'slug': ('name',)}
EOF

cat > services/context_processors.py << 'EOF'
from django.conf import settings


def site_settings(request):
    return {
        'SITE_NAME': getattr(settings, 'SITE_NAME', 'مرجان آرام'),
        'SITE_PHONE': getattr(settings, 'SITE_PHONE', ''),
        'SITE_ADDRESS': getattr(settings, 'SITE_ADDRESS', ''),
    }
EOF

cat > services/views.py << 'EOF'
from django.shortcuts import render, get_object_or_404
from .models import ServiceCategory, Service, Article, Package


def home(request):
    categories = ServiceCategory.objects.all()[:6]
    featured_services = Service.objects.filter(is_active=True, is_featured=True)[:6]
    if not featured_services:
        featured_services = Service.objects.filter(is_active=True)[:6]
    articles = Article.objects.filter(is_published=True)[:3]
    packages = Package.objects.filter(is_active=True, is_featured=True)[:3]

    context = {
        'categories': categories,
        'services': featured_services,
        'articles': articles,
        'packages': packages,
    }
    return render(request, 'home.html', context)


def about(request):
    return render(request, 'about.html')


def contact(request):
    return render(request, 'contact.html')


def service_list(request):
    categories = ServiceCategory.objects.prefetch_related('services').all()
    return render(request, 'services/service_list.html', {'categories': categories})


def service_detail(request, slug):
    service = get_object_or_404(Service, slug=slug, is_active=True)
    return render(request, 'services/service_detail.html', {'service': service})


def package_list(request):
    packages = Package.objects.filter(is_active=True)
    return render(request, 'services/package_list.html', {'packages': packages})


def article_list(request):
    articles = Article.objects.filter(is_published=True)
    return render(request, 'services/article_list.html', {'articles': articles})


def article_detail(request, slug):
    article = get_object_or_404(Article, slug=slug, is_published=True)
    return render(request, 'services/article_detail.html', {'article': article})


def custom_404(request, exception):
    return render(request, '404.html', status=404)


def custom_500(request):
    return render(request, '500.html', status=500)
EOF

cat > services/urls.py << 'EOF'
from django.urls import path
from . import views

urlpatterns = [
    path('', views.home, name='home'),
    path('about/', views.about, name='about'),
    path('contact/', views.contact, name='contact'),
    path('services/', views.service_list, name='service_list'),
    path('services/<slug:slug>/', views.service_detail, name='service_detail'),
    path('packages/', views.package_list, name='package_list'),
    path('articles/', views.article_list, name='article_list'),
    path('articles/<slug:slug>/', views.article_detail, name='article_detail'),
]
EOF

echo "✅ services ساخته شد"

# ============================================================
#  اپ appointments
# ============================================================
touch appointments/__init__.py appointments/migrations/__init__.py

cat > appointments/models.py << 'EOF'
from django.db import models
from accounts.models import CustomUser
from services.models import Service


class Staff(models.Model):
    user = models.OneToOneField(CustomUser, on_delete=models.CASCADE, related_name='staff_profile')
    bio = models.TextField('بیوگرافی', blank=True)
    experience_years = models.PositiveIntegerField('سابقه (سال)', default=0)
    specialties = models.ManyToManyField('services.ServiceCategory', blank=True, verbose_name='تخصص‌ها')
    is_available = models.BooleanField(default=True)
    order = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ['order']
        verbose_name = 'پرسنل'
        verbose_name_plural = 'پرسنل'

    def __str__(self):
        return self.user.get_full_name() or self.user.username


class WorkingHours(models.Model):
    WEEKDAYS = [
        (5, 'شنبه'), (6, 'یکشنبه'), (0, 'دوشنبه'), (1, 'سه‌شنبه'),
        (2, 'چهارشنبه'), (3, 'پنج‌شنبه'), (4, 'جمعه'),
    ]
    staff = models.ForeignKey(Staff, on_delete=models.CASCADE, related_name='working_hours')
    weekday = models.IntegerField(choices=WEEKDAYS)
    start_time = models.TimeField()
    end_time = models.TimeField()
    is_active = models.BooleanField(default=True)

    class Meta:
        unique_together = ['staff', 'weekday']
        verbose_name = 'ساعت کاری'
        verbose_name_plural = 'ساعات کاری'

    def __str__(self):
        return f"{self.staff} - {self.get_weekday_display()}"


class Appointment(models.Model):
    STATUS = [
        ('pending', 'در انتظار تأیید'),
        ('confirmed', 'تأیید شده'),
        ('cancelled', 'لغو شده'),
        ('completed', 'انجام شده'),
        ('no_show', 'عدم حضور'),
    ]
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='appointments')
    staff = models.ForeignKey(Staff, on_delete=models.CASCADE, related_name='appointments')
    service = models.ForeignKey(Service, on_delete=models.CASCADE)
    date = models.DateField('تاریخ')
    start_time = models.TimeField('ساعت شروع')
    end_time = models.TimeField('ساعت پایان')
    status = models.CharField(max_length=20, choices=STATUS, default='pending')
    notes = models.TextField('یادداشت', blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-date', '-start_time']
        verbose_name = 'نوبت'
        verbose_name_plural = 'نوبت‌ها'

    def __str__(self):
        return f"{self.user} - {self.service} - {self.date}"
EOF

cat > appointments/admin.py << 'EOF'
from django.contrib import admin
from .models import Staff, WorkingHours, Appointment


@admin.register(Staff)
class StaffAdmin(admin.ModelAdmin):
    list_display = ('user', 'experience_years', 'is_available', 'order')
    filter_horizontal = ('specialties',)


@admin.register(WorkingHours)
class WorkingHoursAdmin(admin.ModelAdmin):
    list_display = ('staff', 'weekday', 'start_time', 'end_time', 'is_active')
    list_filter = ('staff', 'weekday')


@admin.register(Appointment)
class AppointmentAdmin(admin.ModelAdmin):
    list_display = ('user', 'staff', 'service', 'date', 'start_time', 'status')
    list_filter = ('status', 'date', 'staff')
    search_fields = ('user__username', 'user__phone_number')
    date_hierarchy = 'date'
EOF

cat > appointments/views.py << 'EOF'
from django.shortcuts import render
from django.contrib.auth.decorators import login_required


@login_required
def book_appointment(request):
    return render(request, 'appointments/book.html')


@login_required
def my_appointments(request):
    return render(request, 'appointments/my_appointments.html')
EOF

cat > appointments/urls.py << 'EOF'
from django.urls import path
from . import views

app_name = 'appointments'

urlpatterns = [
    path('book/', views.book_appointment, name='book'),
    path('my/', views.my_appointments, name='my_appointments'),
]
EOF

echo "✅ appointments ساخته شد"

# ============================================================
#  اپ payments
# ============================================================
touch payments/__init__.py payments/migrations/__init__.py

cat > payments/models.py << 'EOF'
from django.db import models
from accounts.models import CustomUser
from appointments.models import Appointment


class Payment(models.Model):
    STATUS = [
        ('pending', 'در انتظار'),
        ('success', 'موفق'),
        ('failed', 'ناموفق'),
    ]
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='payments')
    appointment = models.ForeignKey(Appointment, on_delete=models.SET_NULL, null=True, blank=True)
    amount = models.DecimalField(max_digits=12, decimal_places=0)
    status = models.CharField(max_length=20, choices=STATUS, default='pending')
    transaction_id = models.CharField(max_length=100, blank=True)
    gateway = models.CharField(max_length=50, default='zarinpal')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'پرداخت'
        verbose_name_plural = 'پرداخت‌ها'

    def __str__(self):
        return f"{self.user} - {self.amount}"
EOF

cat > payments/admin.py << 'EOF'
from django.contrib import admin
from .models import Payment


@admin.register(Payment)
class PaymentAdmin(admin.ModelAdmin):
    list_display = ('user', 'amount', 'status', 'gateway', 'created_at')
    list_filter = ('status', 'gateway')
EOF

cat > payments/views.py << 'EOF'
from django.shortcuts import render


def payment_result(request):
    return render(request, 'payments/result.html')
EOF

cat > payments/urls.py << 'EOF'
from django.urls import path
from . import views

app_name = 'payments'

urlpatterns = [
    path('result/', views.payment_result, name='result'),
]
EOF

# ============================================================
#  اپ dashboard
# ============================================================
touch dashboard/__init__.py dashboard/migrations/__init__.py

cat > dashboard/views.py << 'EOF'
from django.shortcuts import render
from django.contrib.auth.decorators import login_required, user_passes_test


def is_staff_user(user):
    return user.is_staff or user.is_doctor or user.is_secretary


@login_required
@user_passes_test(is_staff_user)
def home(request):
    return render(request, 'dashboard/home.html')
EOF

cat > dashboard/urls.py << 'EOF'
from django.urls import path
from . import views

app_name = 'dashboard'

urlpatterns = [
    path('', views.home, name='home'),
]
EOF

echo "✅ dashboard ساخته شد"

# ============================================================
#  TEMPLATES - base.html
# ============================================================

cat > templates/base.html << 'EOF'
{% load static %}
<!DOCTYPE html>
<html lang="fa" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{% block title %}{{ SITE_NAME }}{% endblock %}</title>
    <meta name="description" content="{% block meta_desc %}مشاوره تخصصی خانواده، روانشناسی و مشاوره فردی با دکتر مرجان آرام{% endblock %}">
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
        tailwind.config = {
            theme: {
                extend: {
                    fontFamily: { sans: ['Vazirmatn', 'sans-serif'] },
                    colors: {
                        primary: { DEFAULT: '#2B6CF5', 50: '#EEF3FF', 100: '#DCE6FF', 500: '#2B6CF5', 600: '#1D5BE0', 700: '#1548B8' },
                        accent: { DEFAULT: '#F4662F', 500: '#F4662F', 600: '#E0521B' },
                        dark: '#13162F',
                    },
                    animation: {
                        'float': 'float 6s ease-in-out infinite',
                        'pulse-slow': 'pulse 4s cubic-bezier(0.4, 0, 0.6, 1) infinite',
                    },
                    keyframes: {
                        float: {
                            '0%, 100%': { transform: 'translateY(0)' },
                            '50%': { transform: 'translateY(-20px)' },
                        },
                    },
                }
            }
        }
    </script>
    <link href="https://cdn.jsdelivr.net/gh/rastikerdar/vazirmatn@v33.003/Vazirmatn-font-face.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
    <link href="https://unpkg.com/aos@2.3.1/dist/aos.css" rel="stylesheet">
    <link rel="stylesheet" href="{% static 'css/style.css' %}">
    {% block extra_css %}{% endblock %}
</head>
<body class="font-sans bg-slate-50 text-slate-700 antialiased">

    {% include 'partials/header.html' %}

    {% if messages %}
        <div class="fixed top-24 left-1/2 -translate-x-1/2 z-[100] w-full max-w-md px-4 space-y-2">
            {% for message in messages %}
                <div x-data="{show:true}" x-show="show" x-init="setTimeout(()=>show=false, 5000)"
                     x-transition:enter="transition ease-out duration-300"
                     x-transition:enter-start="opacity-0 -translate-y-4"
                     class="rounded-2xl shadow-lg backdrop-blur-lg bg-white/90 border border-slate-200 p-4 flex items-start gap-3">
                    <div class="shrink-0">
                        {% if message.tags == 'success' %}
                            <i class="bi bi-check-circle-fill text-2xl text-emerald-500"></i>
                        {% elif message.tags == 'error' %}
                            <i class="bi bi-x-circle-fill text-2xl text-red-500"></i>
                        {% elif message.tags == 'warning' %}
                            <i class="bi bi-exclamation-triangle-fill text-2xl text-amber-500"></i>
                        {% else %}
                            <i class="bi bi-info-circle-fill text-2xl text-blue-500"></i>
                        {% endif %}
                    </div>
                    <p class="flex-1 text-sm font-medium">{{ message }}</p>
                    <button @click="show=false" class="text-slate-400 hover:text-slate-700">
                        <i class="bi bi-x-lg"></i>
                    </button>
                </div>
            {% endfor %}
        </div>
    {% endif %}

    <main class="min-h-screen">
        {% block content %}{% endblock %}
    </main>

    {% include 'partials/footer.html' %}

    <button id="scrollToTop" class="fixed bottom-6 left-6 w-12 h-12 rounded-full bg-primary text-white shadow-lg shadow-primary/30 hover:bg-primary-600 transition-all opacity-0 invisible z-40">
        <i class="bi bi-arrow-up text-xl"></i>
    </button>

    <a href="tel:{{ SITE_PHONE }}" class="fixed bottom-6 right-6 w-14 h-14 rounded-full bg-emerald-500 text-white shadow-lg shadow-emerald-500/40 hover:bg-emerald-600 transition-all flex items-center justify-center animate-pulse-slow z-40">
        <i class="bi bi-telephone-fill text-2xl"></i>
    </a>

    <script src="https://unpkg.com/aos@2.3.1/dist/aos.js"></script>
    <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js"></script>

    <script>
        AOS.init({ duration: 800, once: true, offset: 50 });
        const scrollBtn = document.getElementById('scrollToTop');
        window.addEventListener('scroll', () => {
            if (window.scrollY > 400) scrollBtn.classList.remove('opacity-0', 'invisible');
            else scrollBtn.classList.add('opacity-0', 'invisible');
        });
        scrollBtn.addEventListener('click', () => window.scrollTo({top:0, behavior:'smooth'}));
    </script>

    {% block extra_js %}{% endblock %}
</body>
</html>
EOF

# ============================================================
#  partials/header.html
# ============================================================

cat > templates/partials/header.html << 'EOF'
{% load static %}
<header x-data="{scrolled:false, mobileMenu:false}" @scroll.window="scrolled = window.scrollY > 30"
        :class="scrolled ? 'bg-white/90 backdrop-blur-xl shadow-lg' : 'bg-transparent'"
        class="fixed top-0 inset-x-0 z-50 transition-all duration-300">
    <div class="max-w-7xl mx-auto px-4 lg:px-8">
        <div class="flex items-center justify-between h-20">

            <a href="{% url 'home' %}" class="flex items-center gap-3 shrink-0">
                <div class="w-12 h-12 rounded-2xl bg-gradient-to-br from-primary to-primary-700 flex items-center justify-center shadow-lg shadow-primary/30">
                    <i class="bi bi-heart-pulse-fill text-white text-2xl"></i>
                </div>
                <div class="hidden sm:block">
                    <div class="font-bold text-lg text-dark leading-tight">{{ SITE_NAME }}</div>
                    <div class="text-xs text-slate-500">مشاوره و روانشناسی</div>
                </div>
            </a>

            <nav class="hidden lg:flex items-center gap-1 bg-white/70 backdrop-blur-md rounded-full px-2 py-2 border border-slate-200/60 shadow-sm">
                <a href="{% url 'home' %}" class="px-5 py-2 rounded-full text-sm font-semibold text-slate-700 hover:bg-primary hover:text-white transition-all">خانه</a>
                <a href="{% url 'service_list' %}" class="px-5 py-2 rounded-full text-sm font-semibold text-slate-700 hover:bg-primary hover:text-white transition-all">خدمات</a>
                <a href="{% url 'package_list' %}" class="px-5 py-2 rounded-full text-sm font-semibold text-slate-700 hover:bg-primary hover:text-white transition-all">بسته‌ها</a>
                <a href="{% url 'about' %}" class="px-5 py-2 rounded-full text-sm font-semibold text-slate-700 hover:bg-primary hover:text-white transition-all">درباره</a>
                <a href="{% url 'contact' %}" class="px-5 py-2 rounded-full text-sm font-semibold text-slate-700 hover:bg-primary hover:text-white transition-all">تماس</a>
            </nav>

            <div class="flex items-center gap-3">
                <a href="tel:{{ SITE_PHONE }}" class="hidden md:flex items-center gap-2 text-sm font-semibold text-slate-700 hover:text-primary transition">
                    <i class="bi bi-telephone-fill"></i>
                    <span dir="ltr">{{ SITE_PHONE }}</span>
                </a>

                <a href="{% url 'appointments:book' %}"
                   class="hidden sm:inline-flex items-center gap-2 bg-gradient-to-l from-primary to-primary-700 hover:shadow-lg hover:shadow-primary/40 text-white font-bold text-sm px-5 py-2.5 rounded-full transition-all">
                    <i class="bi bi-calendar2-check"></i>
                    <span>رزرو نوبت</span>
                </a>

                {% if user.is_authenticated %}
                <div x-data="{open:false}" class="relative">
                    <button @click="open = !open" @click.outside="open = false" class="flex items-center gap-2">
                        {% if user.avatar %}
                            <img src="{{ user.avatar.url }}" class="w-10 h-10 rounded-full object-cover border-2 border-primary/30">
                        {% else %}
                            <div class="w-10 h-10 rounded-full bg-primary/10 text-primary flex items-center justify-center font-bold">
                                {{ user.first_name|first|default:user.username|first }}
                            </div>
                        {% endif %}
                    </button>
                    <div x-show="open" x-transition x-cloak
                         class="absolute left-0 mt-3 w-56 bg-white rounded-2xl shadow-xl border border-slate-200 py-2 z-50">
                        <div class="px-4 py-3 border-b border-slate-100">
                            <div class="font-bold text-sm">{{ user.get_full_name|default:user.username }}</div>
                            <div class="text-xs text-slate-500" dir="ltr">{{ user.phone_number|default:user.email }}</div>
                        </div>
                        <a href="{% url 'accounts:profile' %}" class="flex items-center gap-3 px-4 py-2.5 text-sm hover:bg-slate-50">
                            <i class="bi bi-person-circle text-slate-400"></i> پروفایل من
                        </a>
                        <a href="{% url 'appointments:my_appointments' %}" class="flex items-center gap-3 px-4 py-2.5 text-sm hover:bg-slate-50">
                            <i class="bi bi-calendar-check text-slate-400"></i> نوبت‌های من
                        </a>
                        {% if user.is_staff or user.is_doctor or user.is_secretary %}
                        <a href="{% url 'dashboard:home' %}" class="flex items-center gap-3 px-4 py-2.5 text-sm hover:bg-slate-50">
                            <i class="bi bi-speedometer2 text-slate-400"></i> پنل مدیریت
                        </a>
                        {% endif %}
                        <hr class="my-1 border-slate-100">
                        <a href="{% url 'accounts:logout' %}" class="flex items-center gap-3 px-4 py-2.5 text-sm text-red-500 hover:bg-red-50">
                            <i class="bi bi-box-arrow-right"></i> خروج
                        </a>
                    </div>
                </div>
                {% else %}
                <a href="{% url 'accounts:login' %}" class="hidden sm:inline-flex items-center gap-2 text-sm font-semibold text-slate-700 hover:text-primary transition">
                    <i class="bi bi-person"></i> ورود
                </a>
                {% endif %}

                <button @click="mobileMenu = true" class="lg:hidden w-10 h-10 rounded-xl bg-slate-100 flex items-center justify-center">
                    <i class="bi bi-list text-2xl text-slate-700"></i>
                </button>
            </div>
        </div>
    </div>

    <div x-show="mobileMenu" x-cloak class="fixed inset-0 z-[60] lg:hidden">
        <div @click="mobileMenu = false" class="absolute inset-0 bg-black/50 backdrop-blur-sm"></div>
        <aside x-show="mobileMenu"
               x-transition:enter="transition ease-out duration-300"
               x-transition:enter-start="translate-x-full"
               x-transition:enter-end="translate-x-0"
               class="absolute top-0 right-0 h-full w-80 max-w-full bg-white shadow-2xl p-6 overflow-y-auto">
            <div class="flex items-center justify-between mb-8">
                <div class="font-bold text-lg">{{ SITE_NAME }}</div>
                <button @click="mobileMenu = false" class="w-10 h-10 rounded-xl bg-slate-100 flex items-center justify-center">
                    <i class="bi bi-x-lg"></i>
                </button>
            </div>

            <nav class="flex flex-col gap-2">
                <a href="{% url 'home' %}" class="flex items-center gap-3 px-4 py-3 rounded-xl hover:bg-primary/5 hover:text-primary font-semibold">
                    <i class="bi bi-house"></i> خانه
                </a>
                <a href="{% url 'service_list' %}" class="flex items-center gap-3 px-4 py-3 rounded-xl hover:bg-primary/5 hover:text-primary font-semibold">
                    <i class="bi bi-grid"></i> خدمات
                </a>
                <a href="{% url 'package_list' %}" class="flex items-center gap-3 px-4 py-3 rounded-xl hover:bg-primary/5 hover:text-primary font-semibold">
                    <i class="bi bi-box-seam"></i> بسته‌ها
                </a>
                <a href="{% url 'article_list' %}" class="flex items-center gap-3 px-4 py-3 rounded-xl hover:bg-primary/5 hover:text-primary font-semibold">
                    <i class="bi bi-newspaper"></i> مقالات
                </a>
                <a href="{% url 'about' %}" class="flex items-center gap-3 px-4 py-3 rounded-xl hover:bg-primary/5 hover:text-primary font-semibold">
                    <i class="bi bi-info-circle"></i> درباره
                </a>
                <a href="{% url 'contact' %}" class="flex items-center gap-3 px-4 py-3 rounded-xl hover:bg-primary/5 hover:text-primary font-semibold">
                    <i class="bi bi-telephone"></i> تماس
                </a>
            </nav>

            <div class="mt-8 pt-6 border-t border-slate-100">
                <a href="{% url 'appointments:book' %}" class="flex items-center justify-center gap-2 bg-primary text-white font-bold py-3 rounded-2xl w-full">
                    <i class="bi bi-calendar2-check"></i> رزرو نوبت
                </a>
                {% if not user.is_authenticated %}
                    <a href="{% url 'accounts:login' %}" class="flex items-center justify-center gap-2 mt-3 border-2 border-primary text-primary font-bold py-3 rounded-2xl w-full">
                        ورود / ثبت‌نام
                    </a>
                {% endif %}
            </div>
        </aside>
    </div>
</header>

<div class="h-20"></div>
EOF

# ============================================================
#  partials/footer.html
# ============================================================

cat > templates/partials/footer.html << 'EOF'
<footer class="bg-dark text-slate-300 mt-24 relative overflow-hidden">
    <div class="absolute -top-32 -right-32 w-96 h-96 bg-primary/20 rounded-full blur-3xl"></div>
    <div class="absolute -bottom-32 -left-32 w-96 h-96 bg-accent/20 rounded-full blur-3xl"></div>

    <div class="relative max-w-7xl mx-auto px-4 lg:px-8 py-16">
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-10">

            <div class="lg:col-span-1">
                <div class="flex items-center gap-3 mb-4">
                    <div class="w-12 h-12 rounded-2xl bg-gradient-to-br from-primary to-accent flex items-center justify-center">
                        <i class="bi bi-heart-pulse-fill text-white text-2xl"></i>
                    </div>
                    <div>
                        <div class="font-bold text-xl text-white">{{ SITE_NAME }}</div>
                        <div class="text-xs text-slate-400">مشاوره و روانشناسی</div>
                    </div>
                </div>
                <p class="text-sm leading-7 text-slate-400">
                    ارائه‌دهنده خدمات مشاوره تخصصی خانواده، فردی، طلاق و روانشناسی با بهترین کیفیت و محیطی آرام.
                </p>
            </div>

            <div>
                <h4 class="text-white font-bold mb-5">دسترسی سریع</h4>
                <ul class="space-y-3 text-sm">
                    <li><a href="{% url 'home' %}" class="hover:text-primary transition flex items-center gap-2"><i class="bi bi-chevron-left text-xs"></i> خانه</a></li>
                    <li><a href="{% url 'service_list' %}" class="hover:text-primary transition flex items-center gap-2"><i class="bi bi-chevron-left text-xs"></i> خدمات</a></li>
                    <li><a href="{% url 'package_list' %}" class="hover:text-primary transition flex items-center gap-2"><i class="bi bi-chevron-left text-xs"></i> بسته‌ها</a></li>
                    <li><a href="{% url 'article_list' %}" class="hover:text-primary transition flex items-center gap-2"><i class="bi bi-chevron-left text-xs"></i> مقالات</a></li>
                </ul>
            </div>

            <div>
                <h4 class="text-white font-bold mb-5">اطلاعات تماس</h4>
                <ul class="space-y-4 text-sm">
                    <li class="flex items-start gap-3">
                        <i class="bi bi-geo-alt-fill text-primary mt-1"></i>
                        <span class="leading-7">{{ SITE_ADDRESS }}</span>
                    </li>
                    <li class="flex items-center gap-3">
                        <i class="bi bi-telephone-fill text-primary"></i>
                        <a href="tel:{{ SITE_PHONE }}" dir="ltr" class="hover:text-primary transition">{{ SITE_PHONE }}</a>
                    </li>
                    <li class="flex items-center gap-3">
                        <i class="bi bi-clock-fill text-primary"></i>
                        <span>هر روز ۱۰ صبح تا ۷ عصر</span>
                    </li>
                </ul>
            </div>

            <div>
                <h4 class="text-white font-bold mb-5">شبکه‌های اجتماعی</h4>
                <div class="flex gap-3">
                    <a href="#" class="w-11 h-11 rounded-xl bg-white/5 hover:bg-primary flex items-center justify-center transition-all">
                        <i class="bi bi-instagram text-xl"></i>
                    </a>
                    <a href="#" class="w-11 h-11 rounded-xl bg-white/5 hover:bg-primary flex items-center justify-center transition-all">
                        <i class="bi bi-telegram text-xl"></i>
                    </a>
                    <a href="#" class="w-11 h-11 rounded-xl bg-white/5 hover:bg-primary flex items-center justify-center transition-all">
                        <i class="bi bi-whatsapp text-xl"></i>
                    </a>
                </div>
                <div class="mt-6 p-4 rounded-2xl bg-white/5 border border-white/10">
                    <div class="text-xs text-slate-400 mb-2">کد نظام روانشناسی</div>
                    <div class="text-white font-bold">۷۶۴۲۷</div>
                </div>
            </div>
        </div>

        <div class="mt-12 pt-8 border-t border-white/10 flex flex-col md:flex-row justify-between items-center gap-4 text-sm text-slate-400">
            <p>تمامی حقوق برای <span class="text-white font-semibold">{{ SITE_NAME }}</span> محفوظ است © ۱۴۰۴</p>
            <p>طراحی و توسعه با <i class="bi bi-heart-fill text-red-500"></i></p>
        </div>
    </div>
</footer>
EOF

echo "✅ partials ساخته شدند"

# ============================================================
#  home.html
# ============================================================

cat > templates/home.html << 'EOF'
{% extends 'base.html' %}
{% load static %}
{% load humanize %}

{% block title %}{{ SITE_NAME }} - مشاوره تخصصی خانواده و روانشناسی{% endblock %}

{% block content %}

<section class="relative overflow-hidden bg-gradient-to-bl from-slate-50 via-white to-primary-50 pt-8 pb-24">
    <div class="absolute top-20 right-10 w-72 h-72 bg-primary/10 rounded-full blur-3xl animate-float"></div>
    <div class="absolute bottom-20 left-10 w-96 h-96 bg-accent/10 rounded-full blur-3xl animate-float" style="animation-delay:1s"></div>

    <div class="relative max-w-7xl mx-auto px-4 lg:px-8">
        <div class="grid lg:grid-cols-2 gap-12 items-center">
            <div data-aos="fade-left">
                <div class="inline-flex items-center gap-2 bg-primary/10 text-primary px-4 py-2 rounded-full text-sm font-semibold mb-6">
                    <i class="bi bi-stars"></i>
                    <span>مرکز تخصصی مشاوره و روانشناسی</span>
                </div>

                <h1 class="text-4xl md:text-5xl lg:text-6xl font-black text-dark leading-tight mb-6">
                    آرامش را با <span class="text-primary relative">
                        مرجان آرام
                        <svg class="absolute -bottom-2 right-0 w-full" viewBox="0 0 200 12" fill="none">
                            <path d="M2 9C50 3 150 3 198 9" stroke="#F4662F" stroke-width="3" stroke-linecap="round"/>
                        </svg>
                    </span>
                    <br>تجربه کنید
                </h1>

                <p class="text-lg text-slate-600 leading-8 mb-8 max-w-xl">
                    با بیش از ۱۵ سال سابقه درخشان در زمینه مشاوره خانواده، فردی، قبل از ازدواج و درمان افسردگی و اضطراب، در کنار شما هستیم تا مسیر زندگی‌تان را روشن‌تر کنیم.
                </p>

                <div class="flex flex-wrap gap-4 mb-10">
                    <a href="{% url 'appointments:book' %}" class="inline-flex items-center gap-2 bg-gradient-to-l from-primary to-primary-700 hover:shadow-xl hover:shadow-primary/40 text-white font-bold px-8 py-4 rounded-2xl transition-all">
                        <i class="bi bi-calendar2-check text-xl"></i>
                        <span>رزرو نوبت آنلاین</span>
                    </a>
                    <a href="{% url 'service_list' %}" class="inline-flex items-center gap-2 bg-white hover:bg-slate-50 text-slate-700 font-bold px-8 py-4 rounded-2xl border-2 border-slate-200 transition-all">
                        <i class="bi bi-grid"></i>
                        <span>مشاهده خدمات</span>
                    </a>
                </div>

                <div class="flex items-center gap-6 flex-wrap">
                    <div class="flex items-center gap-2">
                        <i class="bi bi-shield-check text-emerald-500 text-xl"></i>
                        <span class="text-sm font-semibold text-slate-600">مجوز رسمی</span>
                    </div>
                    <div class="flex items-center gap-2">
                        <i class="bi bi-star-fill text-amber-400 text-xl"></i>
                        <span class="text-sm font-semibold text-slate-600">رضایت ۹۸٪ بیماران</span>
                    </div>
                    <div class="flex items-center gap-2">
                        <i class="bi bi-people-fill text-primary text-xl"></i>
                        <span class="text-sm font-semibold text-slate-600">+۵۰۰۰ مشاوره موفق</span>
                    </div>
                </div>
            </div>

            <div data-aos="fade-right" class="relative">
                <div class="relative w-full aspect-square max-w-lg mx-auto">
                    <div class="absolute inset-0 rounded-[3rem] bg-gradient-to-br from-primary to-accent rotate-6"></div>
                    <div class="absolute inset-0 rounded-[3rem] bg-gradient-to-br from-primary-50 to-accent/20 flex items-center justify-center overflow-hidden">
                        <i class="bi bi-person-heart text-[12rem] text-primary/30"></i>
                    </div>

                    <div class="absolute -top-4 -right-4 bg-white rounded-2xl shadow-xl p-4 flex items-center gap-3 animate-float">
                        <div class="w-12 h-12 rounded-xl bg-emerald-100 flex items-center justify-center">
                            <i class="bi bi-check-circle-fill text-emerald-500 text-xl"></i>
                        </div>
                        <div>
                            <div class="text-xs text-slate-500">رضایت بیماران</div>
                            <div class="font-bold text-dark">۹۸٪</div>
                        </div>
                    </div>

                    <div class="absolute -bottom-4 -left-4 bg-white rounded-2xl shadow-xl p-4 flex items-center gap-3 animate-float" style="animation-delay:1s">
                        <div class="w-12 h-12 rounded-xl bg-primary-100 flex items-center justify-center">
                            <i class="bi bi-award-fill text-primary text-xl"></i>
                        </div>
                        <div>
                            <div class="text-xs text-slate-500">سابقه کار</div>
                            <div class="font-bold text-dark">۱۵+ سال</div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</section>

<section class="relative -mt-12 z-10">
    <div class="max-w-6xl mx-auto px-4 lg:px-8">
        <div class="bg-white rounded-3xl shadow-xl border border-slate-100 p-8 grid grid-cols-2 md:grid-cols-4 gap-6" data-aos="fade-up">
            <div class="text-center">
                <div class="text-4xl md:text-5xl font-black text-primary mb-2">۵۰۰۰+</div>
                <div class="text-sm text-slate-500 font-semibold">مشاوره موفق</div>
            </div>
            <div class="text-center">
                <div class="text-4xl md:text-5xl font-black text-accent mb-2">۱۵+</div>
                <div class="text-sm text-slate-500 font-semibold">سال تجربه</div>
            </div>
            <div class="text-center">
                <div class="text-4xl md:text-5xl font-black text-emerald-500 mb-2">۹۸٪</div>
                <div class="text-sm text-slate-500 font-semibold">رضایت بیماران</div>
            </div>
            <div class="text-center">
                <div class="text-4xl md:text-5xl font-black text-primary mb-2">۲۴/۷</div>
                <div class="text-sm text-slate-500 font-semibold">پشتیبانی</div>
            </div>
        </div>
    </div>
</section>

<section class="py-20 lg:py-28">
    <div class="max-w-7xl mx-auto px-4 lg:px-8">
        <div class="text-center max-w-2xl mx-auto mb-14" data-aos="fade-up">
            <div class="inline-flex items-center gap-2 bg-accent/10 text-accent px-4 py-2 rounded-full text-sm font-semibold mb-4">
                <i class="bi bi-grid-3x3-gap-fill"></i>
                <span>خدمات ما</span>
            </div>
            <h2 class="text-3xl md:text-4xl font-black text-dark mb-4">خدمات تخصصی مشاوره</h2>
            <p class="text-slate-600 leading-8">ما با تیمی از متخصصان مجرب، خدمات متنوع مشاوره را در محیطی امن و آرام به شما ارائه می‌دهیم.</p>
        </div>

        <div class="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
            {% for service in services %}
            <a href="{% url 'service_detail' service.slug %}" data-aos="fade-up" data-aos-delay="{{ forloop.counter0 }}00"
               class="group relative bg-white rounded-3xl p-6 border border-slate-100 hover:border-primary/30 hover:shadow-2xl hover:shadow-primary/10 transition-all duration-300 hover:-translate-y-2">
                <div class="w-16 h-16 rounded-2xl bg-gradient-to-br from-primary-50 to-primary-100 flex items-center justify-center mb-5 group-hover:from-primary group-hover:to-primary-700 transition-all duration-300">
                    <i class="bi bi-heart-pulse text-2xl text-primary group-hover:text-white transition"></i>
                </div>
                <h3 class="text-xl font-bold text-dark mb-3">{{ service.name }}</h3>
                <p class="text-slate-500 text-sm leading-7 mb-5 line-clamp-2">{{ service.short_description|default:service.description|truncatewords:15 }}</p>
                <div class="flex items-center justify-between pt-4 border-t border-slate-100">
                    <div>
                        <div class="text-xs text-slate-400">شروع از</div>
                        <div class="font-bold text-primary">{{ service.price|intcomma }} <span class="text-xs font-normal">تومان</span></div>
                    </div>
                    <div class="w-10 h-10 rounded-full bg-primary/5 group-hover:bg-primary group-hover:text-white flex items-center justify-center transition">
                        <i class="bi bi-arrow-left"></i>
                    </div>
                </div>
            </a>
            {% empty %}
            <div class="col-span-full text-center py-16 bg-white rounded-3xl border border-dashed border-slate-200">
                <i class="bi bi-inbox text-5xl text-slate-300 mb-4"></i>
                <p class="text-slate-500">هنوز خدمتی ثبت نشده است.</p>
                <p class="text-xs text-slate-400 mt-2">از پنل مدیریت می‌توانید خدمات اضافه کنید.</p>
            </div>
            {% endfor %}
        </div>

        {% if services %}
        <div class="text-center mt-12">
            <a href="{% url 'service_list' %}" class="inline-flex items-center gap-2 bg-slate-100 hover:bg-primary hover:text-white text-slate-700 font-bold px-8 py-3 rounded-2xl transition-all">
                مشاهده همه خدمات
                <i class="bi bi-arrow-left"></i>
            </a>
        </div>
        {% endif %}
    </div>
</section>

<section class="py-20 bg-gradient-to-b from-white to-slate-50">
    <div class="max-w-7xl mx-auto px-4 lg:px-8">
        <div class="grid lg:grid-cols-2 gap-16 items-center">
            <div data-aos="fade-left">
                <div class="inline-flex items-center gap-2 bg-primary/10 text-primary px-4 py-2 rounded-full text-sm font-semibold mb-4">
                    <i class="bi bi-patch-check-fill"></i>
                    <span>چرا ما؟</span>
                </div>
                <h2 class="text-3xl md:text-4xl font-black text-dark mb-6">تجربه‌ای متفاوت از مشاوره تخصصی</h2>
                <p class="text-slate-600 leading-8 mb-8">
                    ما با رویکردی انسانی، علمی و به‌روز، در کنار شما هستیم تا مسیر رشد و بهبودی را با اطمینان طی کنید.
                </p>

                <div class="space-y-5">
                    <div class="flex gap-4 p-5 bg-white rounded-2xl border border-slate-100 hover:border-primary/20 transition">
                        <div class="shrink-0 w-12 h-12 rounded-xl bg-emerald-100 flex items-center justify-center">
                            <i class="bi bi-shield-lock-fill text-emerald-600 text-xl"></i>
                        </div>
                        <div>
                            <h4 class="font-bold text-dark mb-1">محرمانگی کامل</h4>
                            <p class="text-sm text-slate-500 leading-6">تمام اطلاعات شما با بالاترین استانداردهای امنیتی محافظت می‌شود.</p>
                        </div>
                    </div>

                    <div class="flex gap-4 p-5 bg-white rounded-2xl border border-slate-100 hover:border-primary/20 transition">
                        <div class="shrink-0 w-12 h-12 rounded-xl bg-primary-100 flex items-center justify-center">
                            <i class="bi bi-person-badge-fill text-primary text-xl"></i>
                        </div>
                        <div>
                            <h4 class="font-bold text-dark mb-1">متخصصان مجرب</h4>
                            <p class="text-sm text-slate-500 leading-6">تمام مشاوران دارای مجوز رسمی و سابقه درخشان هستند.</p>
                        </div>
                    </div>

                    <div class="flex gap-4 p-5 bg-white rounded-2xl border border-slate-100 hover:border-primary/20 transition">
                        <div class="shrink-0 w-12 h-12 rounded-xl bg-amber-100 flex items-center justify-center">
                            <i class="bi bi-clock-history text-amber-600 text-xl"></i>
                        </div>
                        <div>
                            <h4 class="font-bold text-dark mb-1">رزرو آنلاین سریع</h4>
                            <p class="text-sm text-slate-500 leading-6">در کمترین زمان ممکن نوبت خود را رزرو کنید.</p>
                        </div>
                    </div>
                </div>
            </div>

            <div data-aos="fade-right" class="grid grid-cols-2 gap-4">
                <div class="space-y-4">
                    <div class="bg-gradient-to-br from-primary to-primary-700 rounded-3xl p-6 text-white">
                        <i class="bi bi-emoji-smile text-4xl mb-4 opacity-80"></i>
                        <div class="text-3xl font-black mb-1">۹۸٪</div>
                        <div class="text-sm opacity-90">رضایت بیماران</div>
                    </div>
                    <div class="bg-white rounded-3xl p-6 border border-slate-100">
                        <i class="bi bi-chat-heart text-4xl mb-4 text-accent"></i>
                        <div class="text-3xl font-black text-dark mb-1">+۲۰۰</div>
                        <div class="text-sm text-slate-500">مشاوره روزانه</div>
                    </div>
                </div>
                <div class="space-y-4 pt-8">
                    <div class="bg-white rounded-3xl p-6 border border-slate-100">
                        <i class="bi bi-award text-4xl mb-4 text-amber-500"></i>
                        <div class="text-3xl font-black text-dark mb-1">۱۵+</div>
                        <div class="text-sm text-slate-500">سال تجربه</div>
                    </div>
                    <div class="bg-gradient-to-br from-accent to-accent-600 rounded-3xl p-6 text-white">
                        <i class="bi bi-people-fill text-4xl mb-4 opacity-80"></i>
                        <div class="text-3xl font-black mb-1">+۱۰</div>
                        <div class="text-sm opacity-90">متخصص مجرب</div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</section>

<section class="py-20">
    <div class="max-w-7xl mx-auto px-4 lg:px-8">
        <div class="relative overflow-hidden rounded-[2rem] bg-gradient-to-bl from-primary via-primary-600 to-primary-700 p-10 md:p-16" data-aos="zoom-in">
            <div class="absolute top-0 right-0 w-72 h-72 bg-white/10 rounded-full blur-3xl"></div>
            <div class="absolute bottom-0 left-0 w-96 h-96 bg-accent/20 rounded-full blur-3xl"></div>

            <div class="relative grid lg:grid-cols-2 gap-8 items-center">
                <div class="text-white">
                    <h2 class="text-3xl md:text-4xl font-black mb-4 leading-tight">همین حالا نوبت خود را رزرو کنید</h2>
                    <p class="text-white/80 leading-8 mb-6">فقط با چند کلیک ساده، نوبت مشاوره خود را رزرو کنید و اولین قدم را به سوی آرامش بردارید.</p>
                    <div class="flex flex-wrap gap-4">
                        <a href="{% url 'appointments:book' %}" class="inline-flex items-center gap-2 bg-white text-primary font-bold px-8 py-4 rounded-2xl hover:bg-slate-100 transition">
                            <i class="bi bi-calendar2-plus"></i>
                            <span>رزرو نوبت</span>
                        </a>
                        <a href="tel:{{ SITE_PHONE }}" class="inline-flex items-center gap-2 bg-white/10 backdrop-blur border-2 border-white/30 text-white font-bold px-8 py-4 rounded-2xl hover:bg-white/20 transition">
                            <i class="bi bi-telephone-fill"></i>
                            <span>تماس تلفنی</span>
                        </a>
                    </div>
                </div>
                <div class="hidden lg:flex justify-center">
                    <div class="w-64 h-64 rounded-full bg-white/10 backdrop-blur border border-white/20 flex items-center justify-center animate-float">
                        <i class="bi bi-calendar2-heart text-[8rem] text-white/60"></i>
                    </div>
                </div>
            </div>
        </div>
    </div>
</section>

{% endblock %}
EOF

# ============================================================
#  صفحات دیگر
# ============================================================

cat > templates/about.html << 'EOF'
{% extends 'base.html' %}
{% block title %}درباره ما{% endblock %}
{% block content %}
<section class="py-16 lg:py-24">
    <div class="max-w-4xl mx-auto px-4 lg:px-8">
        <div class="text-center mb-12" data-aos="fade-up">
            <h1 class="text-4xl md:text-5xl font-black text-dark mb-4">درباره {{ SITE_NAME }}</h1>
            <p class="text-slate-500">آشنایی با ما و تیم متخصصین</p>
        </div>

        <div class="prose prose-lg max-w-none bg-white rounded-3xl p-8 md:p-12 border border-slate-100" data-aos="fade-up">
            <p class="text-slate-600 leading-8 mb-6">
                دکتر مرجان آرام، متخصص مشاوره خانواده و روان‌شناسی با بیش از ۱۵ سال سابقه درخشان در زمینه مشاوره فردی، خانواده، طلاق و... می‌باشند.
            </p>
            <p class="text-slate-600 leading-8 mb-6">
                ایشان دارای مدرک دکترای روان‌شناسی از دانشگاه تهران و عضو انجمن روان‌شناسان ایران هستند و تاکنون بیش از ۵۰۰۰ مشاوره موفق انجام داده‌اند.
            </p>
            <div class="grid md:grid-cols-3 gap-4 mt-8">
                <div class="bg-primary-50 rounded-2xl p-6 text-center">
                    <i class="bi bi-mortarboard-fill text-3xl text-primary mb-3"></i>
                    <div class="font-bold">دکترای روان‌شناسی</div>
                </div>
                <div class="bg-accent/10 rounded-2xl p-6 text-center">
                    <i class="bi bi-award-fill text-3xl text-accent mb-3"></i>
                    <div class="font-bold">عضو انجمن روان‌شناسان</div>
                </div>
                <div class="bg-emerald-50 rounded-2xl p-6 text-center">
                    <i class="bi bi-patch-check-fill text-3xl text-emerald-500 mb-3"></i>
                    <div class="font-bold">کد نظام ۷۶۴۲۷</div>
                </div>
            </div>
        </div>
    </div>
</section>
{% endblock %}
EOF

cat > templates/contact.html << 'EOF'
{% extends 'base.html' %}
{% block title %}تماس با ما{% endblock %}
{% block content %}
<section class="py-16 lg:py-24">
    <div class="max-w-6xl mx-auto px-4 lg:px-8">
        <div class="text-center mb-12" data-aos="fade-up">
            <h1 class="text-4xl md:text-5xl font-black text-dark mb-4">تماس با ما</h1>
            <p class="text-slate-500">در هر ساعت از شبانه‌روز در خدمت شما هستیم</p>
        </div>

        <div class="grid md:grid-cols-3 gap-6 mb-12">
            <div class="bg-white rounded-3xl p-8 border border-slate-100 text-center" data-aos="fade-up">
                <div class="w-16 h-16 mx-auto rounded-2xl bg-primary-50 flex items-center justify-center mb-4">
                    <i class="bi bi-telephone-fill text-2xl text-primary"></i>
                </div>
                <h3 class="font-bold text-dark mb-2">تلفن</h3>
                <a href="tel:{{ SITE_PHONE }}" dir="ltr" class="text-slate-500 hover:text-primary">{{ SITE_PHONE }}</a>
            </div>

            <div class="bg-white rounded-3xl p-8 border border-slate-100 text-center" data-aos="fade-up" data-aos-delay="100">
                <div class="w-16 h-16 mx-auto rounded-2xl bg-accent/10 flex items-center justify-center mb-4">
                    <i class="bi bi-geo-alt-fill text-2xl text-accent"></i>
                </div>
                <h3 class="font-bold text-dark mb-2">آدرس</h3>
                <p class="text-slate-500 text-sm leading-7">{{ SITE_ADDRESS }}</p>
            </div>

            <div class="bg-white rounded-3xl p-8 border border-slate-100 text-center" data-aos="fade-up" data-aos-delay="200">
                <div class="w-16 h-16 mx-auto rounded-2xl bg-emerald-50 flex items-center justify-center mb-4">
                    <i class="bi bi-clock-fill text-2xl text-emerald-500"></i>
                </div>
                <h3 class="font-bold text-dark mb-2">ساعات کاری</h3>
                <p class="text-slate-500 text-sm leading-7">هر روز از ۱۰ صبح تا ۷ عصر</p>
            </div>
        </div>
    </div>
</section>
{% endblock %}
EOF

cat > templates/404.html << 'EOF'
{% extends 'base.html' %}
{% block title %}صفحه یافت نشد{% endblock %}
{% block content %}
<section class="min-h-[70vh] flex items-center justify-center py-16">
    <div class="text-center max-w-lg mx-auto px-4">
        <div class="text-[10rem] font-black text-primary/20 leading-none mb-4">۴۰۴</div>
        <h1 class="text-3xl font-black text-dark mb-4">صفحه مورد نظر یافت نشد</h1>
        <p class="text-slate-500 leading-8 mb-8">متأسفانه صفحه‌ای که به دنبال آن هستید وجود ندارد یا حذف شده است.</p>
        <a href="{% url 'home' %}" class="inline-flex items-center gap-2 bg-primary text-white font-bold px-8 py-4 rounded-2xl hover:bg-primary-600 transition">
            <i class="bi bi-house"></i>
            <span>بازگشت به صفحه اصلی</span>
        </a>
    </div>
</section>
{% endblock %}
EOF

cat > templates/500.html << 'EOF'
{% extends 'base.html' %}
{% block title %}خطای سرور{% endblock %}
{% block content %}
<section class="min-h-[70vh] flex items-center justify-center py-16">
    <div class="text-center max-w-lg mx-auto px-4">
        <div class="text-[10rem] font-black text-red-500/20 leading-none mb-4">۵۰۰</div>
        <h1 class="text-3xl font-black text-dark mb-4">خطای داخلی سرور</h1>
        <p class="text-slate-500 leading-8 mb-8">متأسفانه مشکلی پیش آمده است. لطفاً بعداً دوباره تلاش کنید.</p>
        <a href="{% url 'home' %}" class="inline-flex items-center gap-2 bg-primary text-white font-bold px-8 py-4 rounded-2xl hover:bg-primary-600 transition">
            <i class="bi bi-house"></i>
            <span>بازگشت به صفحه اصلی</span>
        </a>
    </div>
</section>
{% endblock %}
EOF

echo "✅ صفحات اصلی ساخته شدند"

# ============================================================
#  accounts templates
# ============================================================

cat > templates/accounts/login.html << 'EOF'
{% extends 'base.html' %}
{% block title %}ورود{% endblock %}
{% block content %}
<section class="min-h-[80vh] flex items-center py-12">
    <div class="max-w-md w-full mx-auto px-4">
        <div class="bg-white rounded-3xl shadow-xl border border-slate-100 p-8 md:p-10" data-aos="zoom-in">
            <div class="text-center mb-8">
                <div class="w-16 h-16 mx-auto rounded-2xl bg-gradient-to-br from-primary to-primary-700 flex items-center justify-center mb-4 shadow-lg shadow-primary/30">
                    <i class="bi bi-person-fill text-white text-3xl"></i>
                </div>
                <h1 class="text-2xl font-black text-dark mb-2">ورود به حساب</h1>
                <p class="text-slate-500 text-sm">خوش آمدید! لطفاً وارد شوید</p>
            </div>

            <form method="post" class="space-y-5">
                {% csrf_token %}
                <div>
                    <label class="block text-sm font-semibold mb-2">نام کاربری یا موبایل</label>
                    {{ form.username }}
                </div>
                <div>
                    <label class="block text-sm font-semibold mb-2">رمز عبور</label>
                    {{ form.password }}
                </div>
                <button type="submit" class="w-full bg-gradient-to-l from-primary to-primary-700 text-white font-bold py-3.5 rounded-2xl hover:shadow-lg hover:shadow-primary/30 transition-all">
                    ورود به حساب
                </button>
            </form>

            <div class="mt-6 text-center text-sm text-slate-500">
                حساب کاربری ندارید؟
                <a href="{% url 'accounts:register' %}" class="text-primary font-bold hover:underline">ثبت‌نام کنید</a>
            </div>
        </div>
    </div>
</section>
<style>
    input { width: 100%; padding: 0.75rem 1rem; border-radius: 1rem; border: 1px solid #e2e8f0; transition: all 0.2s; font-family: inherit; }
    input:focus { outline: none; border-color: #2B6CF5; box-shadow: 0 0 0 4px rgba(43,108,245,0.1); }
</style>
{% endblock %}
EOF

cat > templates/accounts/register.html << 'EOF'
{% extends 'base.html' %}
{% block title %}ثبت‌نام{% endblock %}
{% block content %}
<section class="min-h-[80vh] flex items-center py-12">
    <div class="max-w-lg w-full mx-auto px-4">
        <div class="bg-white rounded-3xl shadow-xl border border-slate-100 p-8 md:p-10" data-aos="zoom-in">
            <div class="text-center mb-8">
                <div class="w-16 h-16 mx-auto rounded-2xl bg-gradient-to-br from-accent to-accent-600 flex items-center justify-center mb-4 shadow-lg shadow-accent/30">
                    <i class="bi bi-person-plus-fill text-white text-3xl"></i>
                </div>
                <h1 class="text-2xl font-black text-dark mb-2">ایجاد حساب کاربری</h1>
                <p class="text-slate-500 text-sm">برای رزرو نوبت نیاز به ثبت‌نام دارید</p>
            </div>

            <form method="post" class="space-y-5">
                {% csrf_token %}
                <div class="grid grid-cols-2 gap-4">
                    <div>
                        <label class="block text-sm font-semibold mb-2">نام</label>
                        {{ form.first_name }}
                    </div>
                    <div>
                        <label class="block text-sm font-semibold mb-2">نام خانوادگی</label>
                        {{ form.last_name }}
                    </div>
                </div>
                <div>
                    <label class="block text-sm font-semibold mb-2">نام کاربری</label>
                    {{ form.username }}
                </div>
                <div>
                    <label class="block text-sm font-semibold mb-2">شماره موبایل</label>
                    {{ form.phone_number }}
                </div>
                <div>
                    <label class="block text-sm font-semibold mb-2">ایمیل (اختیاری)</label>
                    {{ form.email }}
                </div>
                <div>
                    <label class="block text-sm font-semibold mb-2">رمز عبور</label>
                    {{ form.password1 }}
                </div>
                <div>
                    <label class="block text-sm font-semibold mb-2">تکرار رمز عبور</label>
                    {{ form.password2 }}
                </div>

                {% if form.errors %}
                <div class="bg-red-50 border border-red-200 rounded-2xl p-4 text-sm text-red-700">
                    {% for field, errors in form.errors.items %}
                        {% for error in errors %}<p>• {{ error }}</p>{% endfor %}
                    {% endfor %}
                </div>
                {% endif %}

                <button type="submit" class="w-full bg-gradient-to-l from-accent to-accent-600 text-white font-bold py-3.5 rounded-2xl hover:shadow-lg hover:shadow-accent/30 transition-all">
                    ثبت‌نام
                </button>
            </form>

            <div class="mt-6 text-center text-sm text-slate-500">
                قبلاً ثبت‌نام کرده‌اید؟
                <a href="{% url 'accounts:login' %}" class="text-primary font-bold hover:underline">ورود کنید</a>
            </div>
        </div>
    </div>
</section>
<style>
    input { width: 100%; padding: 0.75rem 1rem; border-radius: 1rem; border: 1px solid #e2e8f0; transition: all 0.2s; font-family: inherit; }
    input:focus { outline: none; border-color: #2B6CF5; box-shadow: 0 0 0 4px rgba(43,108,245,0.1); }
</style>
{% endblock %}
EOF

cat > templates/accounts/profile.html << 'EOF'
{% extends 'base.html' %}
{% block title %}پروفایل من{% endblock %}
{% block content %}
<section class="py-16">
    <div class="max-w-3xl mx-auto px-4">
        <div class="bg-white rounded-3xl shadow-lg border border-slate-100 p-8">
            <div class="flex items-center gap-4 mb-8">
                {% if user.avatar %}
                    <img src="{{ user.avatar.url }}" class="w-20 h-20 rounded-2xl object-cover">
                {% else %}
                    <div class="w-20 h-20 rounded-2xl bg-primary/10 text-primary flex items-center justify-center text-3xl font-black">
                        {{ user.first_name|first|default:user.username|first }}
                    </div>
                {% endif %}
                <div>
                    <h1 class="text-2xl font-black text-dark">{{ user.get_full_name|default:user.username }}</h1>
                    <p class="text-slate-500 text-sm" dir="ltr">{{ user.phone_number|default:user.email }}</p>
                </div>
            </div>

            <div class="grid grid-cols-2 gap-4 mb-8">
                <div class="bg-slate-50 rounded-2xl p-4">
                    <div class="text-xs text-slate-500 mb-1">نام کاربری</div>
                    <div class="font-bold">{{ user.username }}</div>
                </div>
                <div class="bg-slate-50 rounded-2xl p-4">
                    <div class="text-xs text-slate-500 mb-1">کد ملی</div>
                    <div class="font-bold">{{ user.national_code|default:"-" }}</div>
                </div>
                <div class="bg-slate-50 rounded-2xl p-4">
                    <div class="text-xs text-slate-500 mb-1">تاریخ تولد</div>
                    <div class="font-bold">{{ user.birth_date|default:"-" }}</div>
                </div>
                <div class="bg-slate-50 rounded-2xl p-4">
                    <div class="text-xs text-slate-500 mb-1">ایمیل</div>
                    <div class="font-bold" dir="ltr">{{ user.email|default:"-" }}</div>
                </div>
            </div>

            <div class="flex gap-3">
                <a href="{% url 'accounts:profile_edit' %}" class="bg-primary text-white font-bold px-6 py-3 rounded-2xl hover:bg-primary-600 transition">ویرایش پروفایل</a>
                <a href="{% url 'appointments:my_appointments' %}" class="bg-slate-100 text-slate-700 font-bold px-6 py-3 rounded-2xl hover:bg-slate-200 transition">نوبت‌های من</a>
            </div>
        </div>
    </div>
</section>
{% endblock %}
EOF

cat > templates/accounts/profile_edit.html << 'EOF'
{% extends 'base.html' %}
{% block title %}ویرایش پروفایل{% endblock %}
{% block content %}
<section class="py-16">
    <div class="max-w-2xl mx-auto px-4">
        <div class="bg-white rounded-3xl shadow-lg border border-slate-100 p-8">
            <h1 class="text-2xl font-black text-dark mb-6">ویرایش پروفایل</h1>
            <form method="post" enctype="multipart/form-data" class="space-y-5">
                {% csrf_token %}
                {% for field in form %}
                <div>
                    <label class="block text-sm font-semibold mb-2">{{ field.label }}</label>
                    {{ field }}
                </div>
                {% endfor %}
                <button type="submit" class="bg-primary text-white font-bold px-8 py-3 rounded-2xl hover:bg-primary-600 transition">ذخیره تغییرات</button>
            </form>
        </div>
    </div>
</section>
<style>
    input { width: 100%; padding: 0.75rem 1rem; border-radius: 1rem; border: 1px solid #e2e8f0; font-family: inherit; }
    input:focus { outline: none; border-color: #2B6CF5; box-shadow: 0 0 0 4px rgba(43,108,245,0.1); }
</style>
{% endblock %}
EOF

echo "✅ accounts templates ساخته شدند"

# ============================================================
#  Placeholder templates
# ============================================================

cat > templates/services/service_list.html << 'EOF'
{% extends 'base.html' %}
{% block title %}خدمات{% endblock %}
{% block content %}
<section class="py-16"><div class="max-w-7xl mx-auto px-4 text-center">
    <h1 class="text-4xl font-black text-dark mb-4">خدمات ما</h1>
    <p class="text-slate-500">به‌زودی در بخش بعدی تکمیل می‌شود</p>
</div></section>
{% endblock %}
EOF

cat > templates/services/service_detail.html << 'EOF'
{% extends 'base.html' %}
{% block title %}{{ service.name }}{% endblock %}
{% block content %}
<section class="py-16"><div class="max-w-4xl mx-auto px-4">
    <h1 class="text-4xl font-black text-dark mb-4">{{ service.name }}</h1>
    <p class="text-slate-600 leading-8">{{ service.description }}</p>
</div></section>
{% endblock %}
EOF

cat > templates/services/package_list.html << 'EOF'
{% extends 'base.html' %}{% block title %}بسته‌ها{% endblock %}
{% block content %}<section class="py-16"><div class="max-w-7xl mx-auto px-4 text-center"><h1 class="text-4xl font-black">بسته‌ها</h1></div></section>{% endblock %}
EOF

cat > templates/services/article_list.html << 'EOF'
{% extends 'base.html' %}{% block title %}مقالات{% endblock %}
{% block content %}<section class="py-16"><div class="max-w-7xl mx-auto px-4 text-center"><h1 class="text-4xl font-black">مقالات</h1></div></section>{% endblock %}
EOF

cat > templates/services/article_detail.html << 'EOF'
{% extends 'base.html' %}{% block title %}{{ article.title }}{% endblock %}
{% block content %}<section class="py-16"><div class="max-w-4xl mx-auto px-4"><h1 class="text-4xl font-black mb-4">{{ article.title }}</h1><div class="prose">{{ article.content|linebreaks }}</div></div></section>{% endblock %}
EOF

cat > templates/appointments/book.html << 'EOF'
{% extends 'base.html' %}{% block title %}رزرو نوبت{% endblock %}
{% block content %}<section class="py-16"><div class="max-w-4xl mx-auto px-4 text-center">
<h1 class="text-4xl font-black text-dark mb-4">رزرو نوبت</h1>
<p class="text-slate-500">در بخش ۱.۴ این صفحه با تقویم شمسی پیاده‌سازی می‌شود</p>
</div></section>{% endblock %}
EOF

cat > templates/appointments/my_appointments.html << 'EOF'
{% extends 'base.html' %}{% block title %}نوبت‌های من{% endblock %}
{% block content %}<section class="py-16"><div class="max-w-7xl mx-auto px-4 text-center"><h1 class="text-4xl font-black">نوبت‌های من</h1></div></section>{% endblock %}
EOF

cat > templates/payments/result.html << 'EOF'
{% extends 'base.html' %}{% block title %}نتیجه پرداخت{% endblock %}
{% block content %}<section class="py-16"><div class="max-w-2xl mx-auto px-4 text-center"><h1 class="text-4xl font-black">نتیجه پرداخت</h1></div></section>{% endblock %}
EOF

cat > templates/dashboard/home.html << 'EOF'
{% extends 'base.html' %}{% block title %}داشبورد{% endblock %}
{% block content %}<section class="py-16"><div class="max-w-7xl mx-auto px-4">
<h1 class="text-4xl font-black mb-8">داشبورد مدیریت</h1>
<p class="text-slate-500">در بخش ۱.۵ این پنل با نمودارها و آمار کامل پیاده‌سازی می‌شود</p>
</div></section>{% endblock %}
EOF

# ============================================================
#  Static files
# ============================================================

cat > static/css/style.css << 'EOF'
* { -webkit-tap-highlight-color: transparent; }
html { scroll-behavior: smooth; }
body { font-family: 'Vazirmatn', system-ui, sans-serif; }
[x-cloak] { display: none !important; }

::-webkit-scrollbar { width: 10px; height: 10px; }
::-webkit-scrollbar-track { background: #f1f5f9; }
::-webkit-scrollbar-thumb { background: #2B6CF5; border-radius: 10px; border: 2px solid #f1f5f9; }
::-webkit-scrollbar-thumb:hover { background: #1D5BE0; }

::selection { background: #2B6CF5; color: white; }

.line-clamp-1 { display: -webkit-box; -webkit-line-clamp: 1; -webkit-box-orient: vertical; overflow: hidden; }
.line-clamp-2 { display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }
.line-clamp-3 { display: -webkit-box; -webkit-line-clamp: 3; -webkit-box-orient: vertical; overflow: hidden; }

@keyframes float { 0%, 100% { transform: translateY(0); } 50% { transform: translateY(-20px); } }
EOF

cat > static/js/main.js << 'EOF'
console.log('%cمرجان آرام', 'color: #2B6CF5; font-size: 20px; font-weight: bold;');
console.log('%cسایت با موفقیت بارگذاری شد ✓', 'color: #10b981;');
EOF

# ============================================================
#  README
# ============================================================
cat > README.md << 'EOF'
# پروژه مرجان آرام - فاز ۱ بخش ۱.۱

## نصب و اجرا

```bash
python -m venv venv
source venv/bin/activate    # در ویندوز Git Bash همین دستور کار می‌کند
pip install -r requirements.txt
cp .env.example .env
python manage.py makemigrations accounts services appointments payments dashboard
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver