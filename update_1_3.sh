#!/bin/bash
# ============================================================
#  فاز ۱ - بخش ۱.۳
#  خدمات، بسته‌ها، مقالات، فرم تماس و خبرنامه
# ============================================================

set -e

echo "🚀 شروع آپدیت بخش ۱.۳..."

# ---------- اطمینان از قرار داشتن در ریشه پروژه ----------
if [ ! -f "manage.py" ]; then
    echo "❌ خطا: فایل manage.py پیدا نشد."
    echo "لطفاً این اسکریپت را در ریشه پروژه (کنار manage.py) اجرا کنید."
    exit 1
fi

# ============================================================
#  1. مدل‌ها - اضافه کردن ContactMessage و NewsletterSubscriber
# ============================================================

cat > services/models.py << 'EOF'
from django.db import models


class ServiceCategory(models.Model):
    name = models.CharField('نام دسته', max_length=100)
    slug = models.SlugField(unique=True, allow_unicode=True, help_text='می‌توانید فارسی وارد کنید')
    description = models.TextField('توضیحات', blank=True)
    icon = models.CharField('آیکون (کلاس Bootstrap Icons)', max_length=80, blank=True,
                            help_text='مثال: bi-heart-pulse')
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
    slug = models.SlugField(unique=True, allow_unicode=True)
    short_description = models.CharField('توضیح کوتاه', max_length=300, blank=True)
    description = models.TextField('توضیحات کامل')
    duration = models.PositiveIntegerField('مدت (دقیقه)', default=30)
    price = models.DecimalField('قیمت (تومان)', max_digits=12, decimal_places=0)
    image = models.ImageField('تصویر', upload_to='services/', null=True, blank=True)
    is_active = models.BooleanField(default=True)
    is_featured = models.BooleanField('ویژه', default=False)
    order = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True, null=True, blank=True)

    class Meta:
        ordering = ['order']
        verbose_name = 'سرویس'
        verbose_name_plural = 'سرویس‌ها'

    def __str__(self):
        return self.name


class Package(models.Model):
    name = models.CharField('نام بسته', max_length=200)
    slug = models.SlugField(unique=True, allow_unicode=True)
    short_description = models.CharField('توضیح کوتاه', max_length=300, blank=True)
    description = models.TextField('توضیحات')
    features = models.TextField('امکانات (هر خط یک مورد)', blank=True)
    price = models.DecimalField('قیمت (تومان)', max_digits=12, decimal_places=0)
    old_price = models.DecimalField('قیمت قبل از تخفیف', max_digits=12, decimal_places=0, null=True, blank=True)
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

    @property
    def discount_percent(self):
        if self.old_price and self.old_price > 0 and self.old_price > self.price:
            return int((self.old_price - self.price) * 100 / self.old_price)
        return 0

    def features_list(self):
        return [line.strip() for line in self.features.splitlines() if line.strip()]


class Article(models.Model):
    title = models.CharField('عنوان', max_length=200)
    slug = models.SlugField(unique=True, allow_unicode=True)
    summary = models.CharField('خلاصه', max_length=300, blank=True)
    content = models.TextField('محتوا')
    image = models.ImageField('تصویر', upload_to='articles/', null=True, blank=True)
    category = models.ForeignKey(ServiceCategory, on_delete=models.SET_NULL, null=True, blank=True,
                                  verbose_name='دسته‌بندی')
    views = models.PositiveIntegerField('بازدید', default=0)
    is_published = models.BooleanField('منتشر شده', default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

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
    message = models.TextField('پیام')
    is_read = models.BooleanField('خوانده شده', default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']
        verbose_name = 'پیام تماس'
        verbose_name_plural = 'پیام‌های تماس'

    def __str__(self):
        return f"{self.name} - {self.phone}"


class NewsletterSubscriber(models.Model):
    email = models.EmailField('ایمیل', unique=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']
        verbose_name = 'مشترک خبرنامه'
        verbose_name_plural = 'مشترکین خبرنامه'

    def __str__(self):
        return self.email
EOF

# ============================================================
#  2. forms.py برای services
# ============================================================

cat > services/forms.py << 'EOF'
from django import forms
from .models import ContactMessage, NewsletterSubscriber


class ContactForm(forms.ModelForm):
    class Meta:
        model = ContactMessage
        fields = ['name', 'phone', 'email', 'subject', 'message']
        widgets = {
            'name': forms.TextInput(attrs={'class': 'form-input', 'placeholder': 'نام و نام خانوادگی شما'}),
            'phone': forms.TextInput(attrs={'class': 'form-input', 'placeholder': '۰۹۱۲۳۴۵۶۷۸۹', 'dir': 'ltr'}),
            'email': forms.EmailInput(attrs={'class': 'form-input', 'placeholder': 'example@mail.com', 'dir': 'ltr'}),
            'subject': forms.TextInput(attrs={'class': 'form-input', 'placeholder': 'موضوع پیام'}),
            'message': forms.Textarea(attrs={'class': 'form-input', 'rows': 5, 'placeholder': 'متن پیام شما...'}),
        }


class NewsletterForm(forms.ModelForm):
    class Meta:
        model = NewsletterSubscriber
        fields = ['email']
        widgets = {
            'email': forms.EmailInput(attrs={
                'class': 'newsletter-input',
                'placeholder': 'ایمیل خود را وارد کنید',
                'dir': 'ltr',
            }),
        }
EOF

# ============================================================
#  3. views.py کامل
# ============================================================

cat > services/views.py << 'EOF'
from django.shortcuts import render, get_object_or_404, redirect
from django.contrib import messages
from django.db.models import F, Q
from django.core.paginator import Paginator
from .models import (
    ServiceCategory, Service, Package, Article,
    ContactMessage, NewsletterSubscriber,
)
from .forms import ContactForm, NewsletterForm


def home(request):
    categories = ServiceCategory.objects.all()[:6]
    featured_services = Service.objects.filter(is_active=True, is_featured=True)[:6]
    if not featured_services:
        featured_services = Service.objects.filter(is_active=True)[:6]
    articles = Article.objects.filter(is_published=True)[:3]
    packages = Package.objects.filter(is_active=True, is_featured=True)[:3]
    if not packages:
        packages = Package.objects.filter(is_active=True)[:3]

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
    if request.method == 'POST':
        form = ContactForm(request.POST)
        if form.is_valid():
            form.save()
            messages.success(request, 'پیام شما با موفقیت ارسال شد. به‌زودی با شما تماس می‌گیریم.')
            return redirect('contact')
        else:
            messages.error(request, 'لطفاً خطاهای فرم را برطرف کنید.')
    else:
        form = ContactForm()
    return render(request, 'contact.html', {'form': form})


def service_list(request):
    categories = ServiceCategory.objects.prefetch_related('services').all()
    selected_category = request.GET.get('category')
    search = request.GET.get('q', '').strip()

    services = Service.objects.filter(is_active=True).select_related('category')

    if selected_category:
        services = services.filter(category__slug=selected_category)

    if search:
        services = services.filter(
            Q(name__icontains=search) |
            Q(short_description__icontains=search) |
            Q(description__icontains=search)
        )

    context = {
        'categories': categories,
        'services': services,
        'selected_category': selected_category,
        'search': search,
    }
    return render(request, 'services/service_list.html', context)


def service_detail(request, slug):
    service = get_object_or_404(Service, slug=slug, is_active=True)
    related = Service.objects.filter(
        category=service.category, is_active=True
    ).exclude(pk=service.pk)[:3]
    return render(request, 'services/service_detail.html', {
        'service': service,
        'related': related,
    })


def package_list(request):
    packages = Package.objects.filter(is_active=True)
    return render(request, 'services/package_list.html', {'packages': packages})


def package_detail(request, slug):
    package = get_object_or_404(Package, slug=slug, is_active=True)
    return render(request, 'services/package_detail.html', {'package': package})


def article_list(request):
    articles = Article.objects.filter(is_published=True)
    search = request.GET.get('q', '').strip()
    if search:
        articles = articles.filter(
            Q(title__icontains=search) | Q(summary__icontains=search) | Q(content__icontains=search)
        )
    paginator = Paginator(articles, 9)
    page_number = request.GET.get('page', 1)
    page_obj = paginator.get_page(page_number)
    return render(request, 'services/article_list.html', {
        'articles': page_obj,
        'page_obj': page_obj,
        'search': search,
    })


def article_detail(request, slug):
    article = get_object_or_404(Article, slug=slug, is_published=True)
    # افزایش بازدید
    Article.objects.filter(pk=article.pk).update(views=F('views') + 1)
    related = Article.objects.filter(
        is_published=True
    ).exclude(pk=article.pk)[:3]
    return render(request, 'services/article_detail.html', {
        'article': article,
        'related': related,
    })


def newsletter_subscribe(request):
    if request.method == 'POST':
        form = NewsletterForm(request.POST)
        if form.is_valid():
            email = form.cleaned_data['email']
            obj, created = NewsletterSubscriber.objects.get_or_create(email=email)
            if created:
                messages.success(request, 'عضویت شما در خبرنامه با موفقیت ثبت شد.')
            else:
                messages.info(request, 'این ایمیل قبلاً عضو خبرنامه شده است.')
        else:
            messages.error(request, 'ایمیل وارد شده معتبر نیست.')
    return redirect(request.META.get('HTTP_REFERER', 'home'))


def custom_404(request, exception):
    return render(request, '404.html', status=404)


def custom_500(request):
    return render(request, '500.html', status=500)
EOF

# ============================================================
#  4. urls.py
# ============================================================

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
    path('packages/<slug:slug>/', views.package_detail, name='package_detail'),
    path('articles/', views.article_list, name='article_list'),
    path('articles/<slug:slug>/', views.article_detail, name='article_detail'),
    path('newsletter/subscribe/', views.newsletter_subscribe, name='newsletter_subscribe'),
]
EOF

# ============================================================
#  5. context_processors - اضافه کردن دسته‌بندی‌ها برای مگامنو
# ============================================================

cat > services/context_processors.py << 'EOF'
from django.conf import settings
from .models import ServiceCategory


def site_settings(request):
    return {
        'SITE_NAME': getattr(settings, 'SITE_NAME', 'مرجان آرام'),
        'SITE_PHONE': getattr(settings, 'SITE_PHONE', ''),
        'SITE_ADDRESS': getattr(settings, 'SITE_ADDRESS', ''),
        'nav_categories': ServiceCategory.objects.prefetch_related('services').all()[:8],
    }
EOF

# ============================================================
#  6. admin.py
# ============================================================

cat > services/admin.py << 'EOF'
from django.contrib import admin
from .models import (
    ServiceCategory, Service, Package, Article,
    ContactMessage, NewsletterSubscriber,
)


@admin.register(ServiceCategory)
class ServiceCategoryAdmin(admin.ModelAdmin):
    list_display = ('name', 'slug', 'order')
    prepopulated_fields = {'slug': ('name',)}
    list_editable = ('order',)


@admin.register(Service)
class ServiceAdmin(admin.ModelAdmin):
    list_display = ('name', 'category', 'price', 'duration', 'is_active', 'is_featured', 'order')
    list_filter = ('category', 'is_active', 'is_featured')
    list_editable = ('is_active', 'is_featured', 'order')
    prepopulated_fields = {'slug': ('name',)}
    search_fields = ('name', 'description')


@admin.register(Package)
class PackageAdmin(admin.ModelAdmin):
    list_display = ('name', 'price', 'old_price', 'duration_days', 'is_active', 'is_featured')
    list_filter = ('is_active', 'is_featured')
    prepopulated_fields = {'slug': ('name',)}


@admin.register(Article)
class ArticleAdmin(admin.ModelAdmin):
    list_display = ('title', 'category', 'views', 'is_published', 'created_at')
    list_filter = ('is_published', 'category')
    prepopulated_fields = {'slug': ('title',)}
    search_fields = ('title', 'content')
    readonly_fields = ('views',)


@admin.register(ContactMessage)
class ContactMessageAdmin(admin.ModelAdmin):
    list_display = ('name', 'phone', 'subject', 'is_read', 'created_at')
    list_filter = ('is_read', 'created_at')
    search_fields = ('name', 'phone', 'email', 'message')
    list_editable = ('is_read',)
    readonly_fields = ('name', 'phone', 'email', 'subject', 'message', 'created_at')


@admin.register(NewsletterSubscriber)
class NewsletterSubscriberAdmin(admin.ModelAdmin):
    list_display = ('email', 'is_active', 'created_at')
    list_filter = ('is_active',)
    search_fields = ('email',)
EOF

# ============================================================
#  7. Template: services/service_list.html
# ============================================================

cat > templates/services/service_list.html << 'EOF'
{% extends 'base.html' %}
{% load humanize %}

{% block title %}خدمات ما{% endblock %}

{% block content %}

<!-- Hero -->
<section class="relative overflow-hidden bg-gradient-to-bl from-primary-50 via-white to-accent/5 py-20">
    <div class="absolute top-10 right-10 w-72 h-72 bg-primary/10 rounded-full blur-3xl animate-float"></div>
    <div class="absolute bottom-10 left-10 w-72 h-72 bg-accent/10 rounded-full blur-3xl animate-float" style="animation-delay:1s"></div>

    <div class="relative max-w-7xl mx-auto px-4 lg:px-8 text-center" data-aos="fade-up">
        <nav class="flex items-center justify-center gap-2 text-sm text-slate-500 mb-6">
            <a href="{% url 'home' %}" class="hover:text-primary">خانه</a>
            <i class="bi bi-chevron-left text-xs"></i>
            <span class="text-primary font-semibold">خدمات</span>
        </nav>
        <h1 class="text-4xl md:text-5xl font-black text-dark mb-4">خدمات تخصصی ما</h1>
        <p class="text-slate-600 max-w-2xl mx-auto leading-8">
            مجموعه‌ای کامل از خدمات مشاوره و روانشناسی برای کمک به شما در مسیر بهبودی و رشد.
        </p>
    </div>
</section>

<!-- Filters -->
<section class="py-8 sticky top-20 z-30 bg-white/80 backdrop-blur-xl border-y border-slate-100">
    <div class="max-w-7xl mx-auto px-4 lg:px-8">
        <div class="flex flex-col md:flex-row gap-4 items-center justify-between">
            <!-- Category chips -->
            <div class="flex flex-wrap gap-2 overflow-x-auto w-full md:w-auto">
                <a href="{% url 'service_list' %}"
                   class="px-5 py-2 rounded-full text-sm font-semibold transition whitespace-nowrap
                          {% if not selected_category %}bg-primary text-white{% else %}bg-slate-100 text-slate-700 hover:bg-slate-200{% endif %}">
                    همه ({{ services|length }})
                </a>
                {% for cat in categories %}
                    <a href="?category={{ cat.slug }}{% if search %}&q={{ search }}{% endif %}"
                       class="px-5 py-2 rounded-full text-sm font-semibold transition whitespace-nowrap
                              {% if selected_category == cat.slug %}bg-primary text-white{% else %}bg-slate-100 text-slate-700 hover:bg-slate-200{% endif %}">
                        {{ cat.name }} ({{ cat.services.count }})
                    </a>
                {% endfor %}
            </div>

            <!-- Search -->
            <form method="get" class="relative w-full md:w-72">
                {% if selected_category %}<input type="hidden" name="category" value="{{ selected_category }}">{% endif %}
                <input type="text" name="q" value="{{ search }}" placeholder="جستجو در خدمات..."
                       class="w-full pr-10 pl-4 py-2.5 rounded-full bg-slate-100 focus:bg-white border-2 border-transparent focus:border-primary/30 outline-none transition text-sm">
                <i class="bi bi-search absolute right-4 top-1/2 -translate-y-1/2 text-slate-400"></i>
            </form>
        </div>
    </div>
</section>

<!-- Services Grid -->
<section class="py-16">
    <div class="max-w-7xl mx-auto px-4 lg:px-8">
        {% if services %}
        <div class="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
            {% for service in services %}
            <a href="{% url 'service_detail' service.slug %}"
               class="group relative bg-white rounded-3xl overflow-hidden border border-slate-100 hover:border-primary/30 hover:shadow-2xl hover:shadow-primary/10 transition-all duration-300 hover:-translate-y-2"
               data-aos="fade-up" data-aos-delay="{{ forloop.counter0|add:0 }}00">

                <!-- Image or icon -->
                <div class="relative h-48 bg-gradient-to-br from-primary-50 to-accent/10 overflow-hidden">
                    {% if service.image %}
                        <img src="{{ service.image.url }}" alt="{{ service.name }}" class="w-full h-full object-cover group-hover:scale-110 transition-transform duration-500">
                    {% else %}
                        <div class="w-full h-full flex items-center justify-center">
                            <i class="bi {{ service.category.icon|default:'bi-heart-pulse' }} text-7xl text-primary/30 group-hover:scale-110 transition-transform duration-500"></i>
                        </div>
                    {% endif %}
                    {% if service.is_featured %}
                    <span class="absolute top-4 right-4 bg-gradient-to-l from-amber-400 to-orange-500 text-white text-xs font-bold px-3 py-1.5 rounded-full shadow-lg">
                        <i class="bi bi-star-fill text-xs"></i> ویژه
                    </span>
                    {% endif %}
                    <span class="absolute bottom-4 right-4 bg-white/90 backdrop-blur text-primary text-xs font-bold px-3 py-1.5 rounded-full">
                        {{ service.category.name }}
                    </span>
                </div>

                <div class="p-6">
                    <h3 class="text-xl font-bold text-dark mb-3 group-hover:text-primary transition">{{ service.name }}</h3>
                    <p class="text-slate-500 text-sm leading-7 mb-5 line-clamp-2">
                        {{ service.short_description|default:service.description|truncatewords:15 }}
                    </p>

                    <div class="flex items-center gap-4 mb-5 text-xs text-slate-500">
                        <div class="flex items-center gap-1.5">
                            <i class="bi bi-clock text-primary"></i>
                            <span>{{ service.duration }} دقیقه</span>
                        </div>
                        <div class="flex items-center gap-1.5">
                            <i class="bi bi-tag text-primary"></i>
                            <span>{{ service.category.name }}</span>
                        </div>
                    </div>

                    <div class="flex items-center justify-between pt-5 border-t border-slate-100">
                        <div>
                            <div class="text-xs text-slate-400 mb-1">شروع از</div>
                            <div class="font-black text-primary text-lg">{{ service.price|intcomma }} <span class="text-xs font-normal text-slate-500">تومان</span></div>
                        </div>
                        <div class="w-10 h-10 rounded-full bg-primary/5 group-hover:bg-primary group-hover:text-white flex items-center justify-center transition">
                            <i class="bi bi-arrow-left"></i>
                        </div>
                    </div>
                </div>
            </a>
            {% endfor %}
        </div>
        {% else %}
        <div class="text-center py-20 bg-white rounded-3xl border border-dashed border-slate-200" data-aos="fade-up">
            <i class="bi bi-search text-6xl text-slate-300 mb-4"></i>
            <h3 class="text-xl font-bold text-slate-600 mb-2">خدمتی یافت نشد</h3>
            <p class="text-slate-400 mb-6">فیلترها را تغییر دهید یا عبارت دیگری جستجو کنید.</p>
            <a href="{% url 'service_list' %}" class="inline-flex items-center gap-2 bg-primary text-white font-bold px-6 py-3 rounded-2xl">
                <i class="bi bi-arrow-clockwise"></i> نمایش همه خدمات
            </a>
        </div>
        {% endif %}
    </div>
</section>

<!-- CTA -->
<section class="py-16">
    <div class="max-w-7xl mx-auto px-4 lg:px-8">
        <div class="relative overflow-hidden rounded-[2rem] bg-gradient-to-bl from-primary via-primary-600 to-primary-700 p-10 md:p-16 text-center" data-aos="zoom-in">
            <div class="absolute top-0 right-0 w-72 h-72 bg-white/10 rounded-full blur-3xl"></div>
            <div class="relative">
                <h2 class="text-3xl md:text-4xl font-black text-white mb-4">نمی‌دانید کدام خدمت مناسب شماست؟</h2>
                <p class="text-white/80 mb-8 max-w-2xl mx-auto">با ما تماس بگیرید تا مشاوران ما بهترین گزینه را به شما پیشنهاد دهند.</p>
                <a href="{% url 'contact' %}" class="inline-flex items-center gap-2 bg-white text-primary font-bold px-8 py-4 rounded-2xl hover:bg-slate-100 transition">
                    <i class="bi bi-telephone-fill"></i> مشاوره رایگان
                </a>
            </div>
        </div>
    </div>
</section>

{% endblock %}
EOF

# ============================================================
#  8. Template: services/service_detail.html
# ============================================================

cat > templates/services/service_detail.html << 'EOF'
{% extends 'base.html' %}
{% load humanize %}

{% block title %}{{ service.name }}{% endblock %}

{% block content %}

<!-- Hero / Breadcrumb -->
<section class="bg-gradient-to-bl from-primary-50 via-white to-accent/5 py-12">
    <div class="max-w-7xl mx-auto px-4 lg:px-8">
        <nav class="flex items-center gap-2 text-sm text-slate-500 mb-6" data-aos="fade-up">
            <a href="{% url 'home' %}" class="hover:text-primary">خانه</a>
            <i class="bi bi-chevron-left text-xs"></i>
            <a href="{% url 'service_list' %}" class="hover:text-primary">خدمات</a>
            <i class="bi bi-chevron-left text-xs"></i>
            <a href="{% url 'service_list' %}?category={{ service.category.slug }}" class="hover:text-primary">{{ service.category.name }}</a>
            <i class="bi bi-chevron-left text-xs"></i>
            <span class="text-primary font-semibold">{{ service.name }}</span>
        </nav>
    </div>
</section>

<!-- Main Content -->
<section class="py-12">
    <div class="max-w-7xl mx-auto px-4 lg:px-8">
        <div class="grid lg:grid-cols-3 gap-8">

            <!-- Content -->
            <div class="lg:col-span-2 space-y-8" data-aos="fade-up">
                <!-- Image header -->
                <div class="relative rounded-3xl overflow-hidden h-72 md:h-96 bg-gradient-to-br from-primary-50 to-accent/10">
                    {% if service.image %}
                        <img src="{{ service.image.url }}" alt="{{ service.name }}" class="w-full h-full object-cover">
                    {% else %}
                        <div class="w-full h-full flex items-center justify-center">
                            <i class="bi {{ service.category.icon|default:'bi-heart-pulse' }} text-[10rem] text-primary/30"></i>
                        </div>
                    {% endif %}
                    {% if service.is_featured %}
                    <span class="absolute top-6 right-6 bg-gradient-to-l from-amber-400 to-orange-500 text-white text-sm font-bold px-4 py-2 rounded-full shadow-xl">
                        <i class="bi bi-star-fill"></i> خدمت ویژه
                    </span>
                    {% endif %}
                </div>

                <!-- Description -->
                <div class="bg-white rounded-3xl p-8 border border-slate-100">
                    <h2 class="text-2xl font-black text-dark mb-6 flex items-center gap-3">
                        <span class="w-1.5 h-8 bg-primary rounded-full"></span>
                        توضیحات
                    </h2>
                    <div class="prose prose-slate max-w-none text-slate-600 leading-8 whitespace-pre-line">
                        {{ service.description }}
                    </div>
                </div>

                <!-- Info cards -->
                <div class="grid sm:grid-cols-3 gap-4">
                    <div class="bg-white rounded-3xl p-6 border border-slate-100 text-center">
                        <div class="w-14 h-14 mx-auto rounded-2xl bg-primary-50 flex items-center justify-center mb-4">
                            <i class="bi bi-clock-history text-2xl text-primary"></i>
                        </div>
                        <div class="text-xs text-slate-500 mb-1">مدت زمان</div>
                        <div class="font-black text-dark text-lg">{{ service.duration }} دقیقه</div>
                    </div>
                    <div class="bg-white rounded-3xl p-6 border border-slate-100 text-center">
                        <div class="w-14 h-14 mx-auto rounded-2xl bg-emerald-50 flex items-center justify-center mb-4">
                            <i class="bi bi-tag-fill text-2xl text-emerald-500"></i>
                        </div>
                        <div class="text-xs text-slate-500 mb-1">دسته‌بندی</div>
                        <div class="font-black text-dark text-lg">{{ service.category.name }}</div>
                    </div>
                    <div class="bg-white rounded-3xl p-6 border border-slate-100 text-center">
                        <div class="w-14 h-14 mx-auto rounded-2xl bg-accent/10 flex items-center justify-center mb-4">
                            <i class="bi bi-shield-check text-2xl text-accent"></i>
                        </div>
                        <div class="text-xs text-slate-500 mb-1">کیفیت</div>
                        <div class="font-black text-dark text-lg">تضمینی</div>
                    </div>
                </div>
            </div>

            <!-- Sidebar -->
            <div class="lg:col-span-1 space-y-6" data-aos="fade-left">
                <!-- Price card (sticky) -->
                <div class="lg:sticky lg:top-24 bg-white rounded-3xl border border-slate-100 shadow-lg overflow-hidden">
                    <div class="bg-gradient-to-bl from-primary to-primary-700 p-6 text-white">
                        <div class="text-sm opacity-90 mb-1">قیمت این خدمت</div>
                        <div class="text-3xl font-black">{{ service.price|intcomma }} <span class="text-sm font-normal opacity-80">تومان</span></div>
                    </div>
                    <div class="p-6 space-y-4">
                        <a href="{% url 'appointments:book' %}?service={{ service.slug }}"
                           class="flex items-center justify-center gap-2 bg-gradient-to-l from-primary to-primary-700 text-white font-bold py-4 rounded-2xl hover:shadow-xl hover:shadow-primary/30 transition-all">
                            <i class="bi bi-calendar2-plus text-xl"></i>
                            رزرو نوبت
                        </a>

                        <a href="tel:{{ SITE_PHONE }}"
                           class="flex items-center justify-center gap-2 bg-slate-100 text-slate-700 font-bold py-4 rounded-2xl hover:bg-slate-200 transition">
                            <i class="bi bi-telephone-fill"></i>
                            تماس برای مشاوره
                        </a>

                        <div class="pt-4 border-t border-slate-100 space-y-3 text-sm">
                            <div class="flex items-center gap-3 text-slate-600">
                                <i class="bi bi-check-circle-fill text-emerald-500"></i>
                                <span>مشاوره تخصصی و حرفه‌ای</span>
                            </div>
                            <div class="flex items-center gap-3 text-slate-600">
                                <i class="bi bi-check-circle-fill text-emerald-500"></i>
                                <span>محرمانگی کامل اطلاعات</span>
                            </div>
                            <div class="flex items-center gap-3 text-slate-600">
                                <i class="bi bi-check-circle-fill text-emerald-500"></i>
                                <span>پیگیری پس از جلسه</span>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Share -->
                <div class="bg-white rounded-3xl p-6 border border-slate-100">
                    <div class="text-sm font-bold text-dark mb-3">اشتراک‌گذاری</div>
                    <div class="flex gap-2">
                        <a href="#" class="w-10 h-10 rounded-xl bg-slate-100 hover:bg-primary hover:text-white flex items-center justify-center transition">
                            <i class="bi bi-telegram"></i>
                        </a>
                        <a href="#" class="w-10 h-10 rounded-xl bg-slate-100 hover:bg-primary hover:text-white flex items-center justify-center transition">
                            <i class="bi bi-whatsapp"></i>
                        </a>
                        <a href="#" class="w-10 h-10 rounded-xl bg-slate-100 hover:bg-primary hover:text-white flex items-center justify-center transition">
                            <i class="bi bi-instagram"></i>
                        </a>
                    </div>
                </div>
            </div>
        </div>

        <!-- Related Services -->
        {% if related %}
        <div class="mt-20" data-aos="fade-up">
            <div class="flex items-center justify-between mb-8">
                <h2 class="text-2xl font-black text-dark flex items-center gap-3">
                    <span class="w-1.5 h-8 bg-accent rounded-full"></span>
                    خدمات مرتبط
                </h2>
                <a href="{% url 'service_list' %}?category={{ service.category.slug }}" class="text-sm font-semibold text-primary hover:underline">
                    مشاهده همه <i class="bi bi-arrow-left"></i>
                </a>
            </div>

            <div class="grid md:grid-cols-3 gap-6">
                {% for item in related %}
                <a href="{% url 'service_detail' item.slug %}"
                   class="group bg-white rounded-3xl overflow-hidden border border-slate-100 hover:border-primary/30 hover:shadow-xl transition-all hover:-translate-y-1">
                    <div class="h-40 bg-gradient-to-br from-primary-50 to-accent/10 overflow-hidden">
                        {% if item.image %}
                            <img src="{{ item.image.url }}" class="w-full h-full object-cover group-hover:scale-110 transition-transform duration-500">
                        {% else %}
                            <div class="w-full h-full flex items-center justify-center">
                                <i class="bi {{ item.category.icon|default:'bi-heart-pulse' }} text-6xl text-primary/30"></i>
                            </div>
                        {% endif %}
                    </div>
                    <div class="p-5">
                        <h3 class="font-bold text-dark mb-2 group-hover:text-primary transition">{{ item.name }}</h3>
                        <div class="flex items-center justify-between text-sm">
                            <span class="text-slate-500">{{ item.duration }} دقیقه</span>
                            <span class="font-bold text-primary">{{ item.price|intcomma }} تومان</span>
                        </div>
                    </div>
                </a>
                {% endfor %}
            </div>
        </div>
        {% endif %}
    </div>
</section>

{% endblock %}
EOF

# ============================================================
#  9. Template: services/package_list.html
# ============================================================

cat > templates/services/package_list.html << 'EOF'
{% extends 'base.html' %}
{% load humanize %}

{% block title %}بسته‌های خدماتی{% endblock %}

{% block content %}

<section class="relative overflow-hidden bg-gradient-to-bl from-accent/5 via-white to-primary-50 py-20">
    <div class="absolute top-10 right-10 w-72 h-72 bg-accent/10 rounded-full blur-3xl animate-float"></div>
    <div class="relative max-w-7xl mx-auto px-4 lg:px-8 text-center" data-aos="fade-up">
        <nav class="flex items-center justify-center gap-2 text-sm text-slate-500 mb-6">
            <a href="{% url 'home' %}" class="hover:text-primary">خانه</a>
            <i class="bi bi-chevron-left text-xs"></i>
            <span class="text-primary font-semibold">بسته‌ها</span>
        </nav>
        <div class="inline-flex items-center gap-2 bg-accent/10 text-accent px-4 py-2 rounded-full text-sm font-semibold mb-4">
            <i class="bi bi-gift-fill"></i>
            <span>با تخفیف ویژه</span>
        </div>
        <h1 class="text-4xl md:text-5xl font-black text-dark mb-4">بسته‌های خدماتی</h1>
        <p class="text-slate-600 max-w-2xl mx-auto leading-8">
            بسته‌های ویژه با قیمت مناسب و تخفیف‌های فوق‌العاده برای شما عزیزان.
        </p>
    </div>
</section>

<section class="py-16 -mt-8">
    <div class="max-w-7xl mx-auto px-4 lg:px-8">
        {% if packages %}
        <div class="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
            {% for package in packages %}
            <div class="relative bg-white rounded-3xl overflow-hidden border-2 {% if package.is_featured %}border-primary shadow-2xl shadow-primary/20 lg:scale-105{% else %}border-slate-100{% endif %} hover:shadow-xl transition-all"
                 data-aos="fade-up" data-aos-delay="{{ forloop.counter0 }}00">

                {% if package.is_featured %}
                <div class="absolute top-0 left-0 right-0 bg-gradient-to-l from-primary to-primary-700 text-white text-center py-2 text-sm font-bold z-10">
                    <i class="bi bi-star-fill"></i> پیشنهاد ویژه
                </div>
                {% endif %}

                {% if package.discount_percent > 0 %}
                <div class="absolute top-4 right-4 z-10 w-16 h-16 rounded-full bg-gradient-to-br from-red-500 to-red-600 text-white flex flex-col items-center justify-center shadow-lg">
                    <span class="text-lg font-black leading-none">{{ package.discount_percent }}٪</span>
                    <span class="text-[10px]">تخفیف</span>
                </div>
                {% endif %}

                <div class="{% if package.is_featured %}pt-12{% endif %} p-8">
                    <!-- Icon -->
                    <div class="w-16 h-16 rounded-2xl bg-gradient-to-br from-primary-50 to-accent/10 flex items-center justify-center mb-5">
                        <i class="bi bi-box-seam-fill text-3xl text-primary"></i>
                    </div>

                    <h3 class="text-2xl font-black text-dark mb-3">{{ package.name }}</h3>
                    <p class="text-slate-500 text-sm leading-7 mb-6">
                        {{ package.short_description|default:package.description|truncatewords:15 }}
                    </p>

                    <!-- Price -->
                    <div class="flex items-end gap-3 mb-6">
                        <div class="text-3xl font-black text-primary">{{ package.price|intcomma }}</div>
                        {% if package.old_price and package.old_price > package.price %}
                        <div class="text-slate-400 line-through text-sm mb-1">{{ package.old_price|intcomma }}</div>
                        {% endif %}
                        <span class="text-xs text-slate-500 mb-1.5">تومان</span>
                    </div>

                    <!-- Features -->
                    {% if package.features_list %}
                    <ul class="space-y-2 mb-6">
                        {% for feature in package.features_list %}
                        <li class="flex items-start gap-2 text-sm text-slate-600">
                            <i class="bi bi-check-circle-fill text-emerald-500 mt-0.5"></i>
                            <span>{{ feature }}</span>
                        </li>
                        {% endfor %}
                    </ul>
                    {% endif %}

                    <!-- Duration -->
                    <div class="flex items-center gap-2 text-sm text-slate-500 mb-6 pb-6 border-b border-slate-100">
                        <i class="bi bi-clock-history text-primary"></i>
                        <span>مدت اعتبار: {{ package.duration_days }} روز</span>
                    </div>

                    <!-- CTA -->
                    <div class="flex gap-3">
                        <a href="{% url 'package_detail' package.slug %}"
                           class="flex-1 text-center bg-slate-100 hover:bg-slate-200 text-slate-700 font-bold py-3 rounded-2xl transition text-sm">
                            جزئیات
                        </a>
                        <a href="{% url 'appointments:book' %}?package={{ package.slug }}"
                           class="flex-1 text-center bg-gradient-to-l from-primary to-primary-700 hover:shadow-lg hover:shadow-primary/30 text-white font-bold py-3 rounded-2xl transition text-sm">
                            <i class="bi bi-cart-plus"></i> خرید
                        </a>
                    </div>
                </div>
            </div>
            {% endfor %}
        </div>
        {% else %}
        <div class="text-center py-20 bg-white rounded-3xl border border-dashed border-slate-200">
            <i class="bi bi-box text-6xl text-slate-300 mb-4"></i>
            <h3 class="text-xl font-bold text-slate-600 mb-2">هنوز بسته‌ای ثبت نشده است</h3>
        </div>
        {% endif %}
    </div>
</section>

{% endblock %}
EOF

# ============================================================
#  10. Template: services/package_detail.html
# ============================================================

cat > templates/services/package_detail.html << 'EOF'
{% extends 'base.html' %}
{% load humanize %}

{% block title %}{{ package.name }}{% endblock %}

{% block content %}

<section class="bg-gradient-to-bl from-primary-50 via-white to-accent/5 py-12">
    <div class="max-w-7xl mx-auto px-4 lg:px-8">
        <nav class="flex items-center gap-2 text-sm text-slate-500 mb-6">
            <a href="{% url 'home' %}" class="hover:text-primary">خانه</a>
            <i class="bi bi-chevron-left text-xs"></i>
            <a href="{% url 'package_list' %}" class="hover:text-primary">بسته‌ها</a>
            <i class="bi bi-chevron-left text-xs"></i>
            <span class="text-primary font-semibold">{{ package.name }}</span>
        </nav>
    </div>
</section>

<section class="py-12">
    <div class="max-w-7xl mx-auto px-4 lg:px-8">
        <div class="grid lg:grid-cols-3 gap-8">
            <div class="lg:col-span-2 space-y-6" data-aos="fade-up">
                <div class="bg-white rounded-3xl p-8 border border-slate-100">
                    <div class="flex items-start gap-4 mb-6">
                        <div class="w-20 h-20 rounded-3xl bg-gradient-to-br from-primary to-primary-700 flex items-center justify-center shrink-0">
                            <i class="bi bi-box-seam-fill text-white text-3xl"></i>
                        </div>
                        <div>
                            <h1 class="text-3xl font-black text-dark mb-2">{{ package.name }}</h1>
                            <p class="text-slate-500">{{ package.short_description }}</p>
                        </div>
                    </div>

                    <div class="prose max-w-none text-slate-600 leading-8 whitespace-pre-line">
                        {{ package.description }}
                    </div>
                </div>

                {% if package.features_list %}
                <div class="bg-white rounded-3xl p-8 border border-slate-100">
                    <h2 class="text-xl font-black text-dark mb-6 flex items-center gap-3">
                        <span class="w-1.5 h-8 bg-emerald-500 rounded-full"></span>
                        امکانات این بسته
                    </h2>
                    <ul class="grid md:grid-cols-2 gap-3">
                        {% for feature in package.features_list %}
                        <li class="flex items-start gap-3 p-4 bg-emerald-50/50 rounded-2xl">
                            <i class="bi bi-check-circle-fill text-emerald-500 text-xl mt-0.5"></i>
                            <span class="text-slate-700">{{ feature }}</span>
                        </li>
                        {% endfor %}
                    </ul>
                </div>
                {% endif %}
            </div>

            <div class="lg:col-span-1" data-aos="fade-left">
                <div class="lg:sticky lg:top-24 bg-white rounded-3xl border border-slate-100 shadow-lg overflow-hidden">
                    <div class="bg-gradient-to-bl from-accent to-accent-600 p-6 text-white">
                        {% if package.discount_percent > 0 %}
                        <div class="inline-flex items-center gap-1 bg-white/20 backdrop-blur px-3 py-1 rounded-full text-xs font-bold mb-3">
                            <i class="bi bi-fire"></i>
                            {{ package.discount_percent }}٪ تخفیف
                        </div>
                        {% endif %}
                        <div class="text-sm opacity-90 mb-1">قیمت بسته</div>
                        <div class="flex items-end gap-2">
                            <div class="text-4xl font-black">{{ package.price|intcomma }}</div>
                            <span class="text-sm opacity-80 mb-2">تومان</span>
                        </div>
                        {% if package.old_price and package.old_price > package.price %}
                        <div class="text-white/70 line-through text-sm mt-1">{{ package.old_price|intcomma }} تومان</div>
                        {% endif %}
                    </div>
                    <div class="p-6 space-y-4">
                        <a href="{% url 'appointments:book' %}?package={{ package.slug }}"
                           class="flex items-center justify-center gap-2 bg-gradient-to-l from-primary to-primary-700 text-white font-bold py-4 rounded-2xl hover:shadow-xl hover:shadow-primary/30 transition-all">
                            <i class="bi bi-cart-plus text-xl"></i>
                            خرید و رزرو
                        </a>

                        <div class="pt-4 border-t border-slate-100 space-y-3 text-sm">
                            <div class="flex justify-between">
                                <span class="text-slate-500">مدت اعتبار:</span>
                                <span class="font-bold">{{ package.duration_days }} روز</span>
                            </div>
                            <div class="flex justify-between">
                                <span class="text-slate-500">پرداخت:</span>
                                <span class="font-bold">آنلاین / اقساطی</span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</section>

{% endblock %}
EOF

# ============================================================
#  11. Template: services/article_list.html
# ============================================================

cat > templates/services/article_list.html << 'EOF'
{% extends 'base.html' %}
{% load humanize %}

{% block title %}مقالات و مطالب{% endblock %}

{% block content %}

<section class="relative overflow-hidden bg-gradient-to-bl from-primary-50 via-white to-accent/5 py-20">
    <div class="relative max-w-7xl mx-auto px-4 lg:px-8 text-center" data-aos="fade-up">
        <nav class="flex items-center justify-center gap-2 text-sm text-slate-500 mb-6">
            <a href="{% url 'home' %}" class="hover:text-primary">خانه</a>
            <i class="bi bi-chevron-left text-xs"></i>
            <span class="text-primary font-semibold">مقالات</span>
        </nav>
        <h1 class="text-4xl md:text-5xl font-black text-dark mb-4">مقالات و مطالب</h1>
        <p class="text-slate-600 max-w-2xl mx-auto leading-8 mb-8">
            جدیدترین مقالات روانشناسی، مشاوره خانواده و سلامت روان
        </p>

        <form method="get" class="max-w-xl mx-auto relative">
            <input type="text" name="q" value="{{ search }}" placeholder="جستجو در مقالات..."
                   class="w-full pr-12 pl-4 py-4 rounded-full bg-white shadow-lg focus:shadow-xl border-2 border-transparent focus:border-primary/30 outline-none transition text-sm">
            <i class="bi bi-search absolute right-5 top-1/2 -translate-y-1/2 text-slate-400"></i>
        </form>
    </div>
</section>

<section class="py-16">
    <div class="max-w-7xl mx-auto px-4 lg:px-8">
        {% if articles %}
        <div class="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
            {% for article in articles %}
            <a href="{% url 'article_detail' article.slug %}"
               class="group bg-white rounded-3xl overflow-hidden border border-slate-100 hover:border-primary/30 hover:shadow-xl hover:shadow-primary/10 transition-all hover:-translate-y-2"
               data-aos="fade-up" data-aos-delay="{{ forloop.counter0 }}00">

                <div class="relative h-52 bg-gradient-to-br from-primary-50 to-accent/10 overflow-hidden">
                    {% if article.image %}
                        <img src="{{ article.image.url }}" alt="{{ article.title }}" class="w-full h-full object-cover group-hover:scale-110 transition-transform duration-500">
                    {% else %}
                        <div class="w-full h-full flex items-center justify-center">
                            <i class="bi bi-newspaper text-6xl text-primary/30"></i>
                        </div>
                    {% endif %}
                    {% if article.category %}
                    <span class="absolute top-4 right-4 bg-white/90 backdrop-blur text-primary text-xs font-bold px-3 py-1.5 rounded-full">
                        {{ article.category.name }}
                    </span>
                    {% endif %}
                </div>

                <div class="p-6">
                    <div class="flex items-center gap-3 text-xs text-slate-500 mb-3">
                        <span class="flex items-center gap-1"><i class="bi bi-calendar3"></i> {{ article.created_at|date:"Y/m/d" }}</span>
                        <span class="flex items-center gap-1"><i class="bi bi-eye"></i> {{ article.views }} بازدید</span>
                    </div>
                    <h3 class="font-bold text-dark text-lg leading-7 mb-3 group-hover:text-primary transition line-clamp-2">
                        {{ article.title }}
                    </h3>
                    <p class="text-slate-500 text-sm leading-7 line-clamp-3">
                        {{ article.summary|default:article.content|truncatewords:20 }}
                    </p>
                    <div class="mt-5 pt-4 border-t border-slate-100 flex items-center justify-between">
                        <span class="text-primary font-bold text-sm">ادامه مطلب</span>
                        <div class="w-8 h-8 rounded-full bg-primary/5 group-hover:bg-primary group-hover:text-white flex items-center justify-center transition">
                            <i class="bi bi-arrow-left text-sm"></i>
                        </div>
                    </div>
                </div>
            </a>
            {% endfor %}
        </div>

        <!-- Pagination -->
        {% if page_obj.has_other_pages %}
        <div class="flex justify-center items-center gap-2 mt-12">
            {% if page_obj.has_previous %}
                <a href="?page={{ page_obj.previous_page_number }}{% if search %}&q={{ search }}{% endif %}"
                   class="w-11 h-11 rounded-xl bg-white border border-slate-200 hover:bg-primary hover:text-white hover:border-primary transition flex items-center justify-center">
                    <i class="bi bi-chevron-right"></i>
                </a>
            {% endif %}

            {% for num in page_obj.paginator.page_range %}
                {% if page_obj.number == num %}
                    <span class="w-11 h-11 rounded-xl bg-primary text-white font-bold flex items-center justify-center">{{ num }}</span>
                {% elif num > page_obj.number|add:'-3' and num < page_obj.number|add:'3' %}
                    <a href="?page={{ num }}{% if search %}&q={{ search }}{% endif %}"
                       class="w-11 h-11 rounded-xl bg-white border border-slate-200 hover:bg-slate-100 transition flex items-center justify-center">{{ num }}</a>
                {% endif %}
            {% endfor %}

            {% if page_obj.has_next %}
                <a href="?page={{ page_obj.next_page_number }}{% if search %}&q={{ search }}{% endif %}"
                   class="w-11 h-11 rounded-xl bg-white border border-slate-200 hover:bg-primary hover:text-white hover:border-primary transition flex items-center justify-center">
                    <i class="bi bi-chevron-left"></i>
                </a>
            {% endif %}
        </div>
        {% endif %}

        {% else %}
        <div class="text-center py-20 bg-white rounded-3xl border border-dashed border-slate-200">
            <i class="bi bi-journal-x text-6xl text-slate-300 mb-4"></i>
            <h3 class="text-xl font-bold text-slate-600 mb-2">مقاله‌ای یافت نشد</h3>
            {% if search %}<p class="text-slate-400">عبارت «{{ search }}» نتیجه‌ای نداشت.</p>{% endif %}
        </div>
        {% endif %}
    </div>
</section>

{% endblock %}
EOF

# ============================================================
#  12. Template: services/article_detail.html
# ============================================================

cat > templates/services/article_detail.html << 'EOF'
{% extends 'base.html' %}

{% block title %}{{ article.title }}{% endblock %}

{% block content %}

<section class="bg-gradient-to-bl from-primary-50 via-white to-accent/5 py-12">
    <div class="max-w-4xl mx-auto px-4 lg:px-8">
        <nav class="flex items-center gap-2 text-sm text-slate-500 mb-6">
            <a href="{% url 'home' %}" class="hover:text-primary">خانه</a>
            <i class="bi bi-chevron-left text-xs"></i>
            <a href="{% url 'article_list' %}" class="hover:text-primary">مقالات</a>
            <i class="bi bi-chevron-left text-xs"></i>
            <span class="text-primary font-semibold line-clamp-1">{{ article.title|truncatewords:5 }}</span>
        </nav>

        {% if article.category %}
        <div class="inline-flex items-center gap-2 bg-primary/10 text-primary px-4 py-2 rounded-full text-sm font-semibold mb-4">
            <i class="bi bi-tag-fill"></i>
            {{ article.category.name }}
        </div>
        {% endif %}

        <h1 class="text-3xl md:text-4xl lg:text-5xl font-black text-dark leading-tight mb-6" data-aos="fade-up">
            {{ article.title }}
        </h1>

        <div class="flex items-center gap-4 text-sm text-slate-500" data-aos="fade-up">
            <span class="flex items-center gap-1.5"><i class="bi bi-calendar3"></i> {{ article.created_at|date:"Y/m/d" }}</span>
            <span class="flex items-center gap-1.5"><i class="bi bi-eye"></i> {{ article.views }} بازدید</span>
            <span class="flex items-center gap-1.5"><i class="bi bi-clock"></i> {{ article.content|wordcount|div:200|add:1 }} دقیقه مطالعه</span>
        </div>
    </div>
</section>

<section class="py-12">
    <div class="max-w-4xl mx-auto px-4 lg:px-8">
        {% if article.image %}
        <div class="rounded-3xl overflow-hidden mb-8" data-aos="fade-up">
            <img src="{{ article.image.url }}" alt="{{ article.title }}" class="w-full h-auto">
        </div>
        {% endif %}

        {% if article.summary %}
        <div class="bg-primary-50 rounded-3xl p-6 mb-8 border-r-4 border-primary" data-aos="fade-up">
            <p class="text-slate-700 leading-8 font-medium">{{ article.summary }}</p>
        </div>
        {% endif %}

        <div class="bg-white rounded-3xl p-8 md:p-12 border border-slate-100 prose prose-lg max-w-none
                    prose-headings:text-dark prose-headings:font-black
                    prose-p:text-slate-600 prose-p:leading-8
                    prose-a:text-primary prose-a:font-bold
                    prose-strong:text-dark
                    prose-ul:text-slate-600 prose-li:my-2
                    prose-blockquote:border-r-4 prose-blockquote:border-primary prose-blockquote:bg-primary-50 prose-blockquote:rounded-2xl prose-blockquote:py-4 prose-blockquote:pr-6 prose-blockquote:not-italic
                    whitespace-pre-line" data-aos="fade-up">
            {{ article.content }}
        </div>

        <!-- Share -->
        <div class="mt-8 p-6 bg-white rounded-3xl border border-slate-100 flex items-center justify-between flex-wrap gap-4">
            <div class="font-bold text-dark">این مقاله را به اشتراک بگذارید:</div>
            <div class="flex gap-2">
                <a href="#" class="w-10 h-10 rounded-xl bg-slate-100 hover:bg-primary hover:text-white flex items-center justify-center transition">
                    <i class="bi bi-telegram"></i>
                </a>
                <a href="#" class="w-10 h-10 rounded-xl bg-slate-100 hover:bg-primary hover:text-white flex items-center justify-center transition">
                    <i class="bi bi-whatsapp"></i>
                </a>
                <a href="#" class="w-10 h-10 rounded-xl bg-slate-100 hover:bg-primary hover:text-white flex items-center justify-center transition">
                    <i class="bi bi-twitter-x"></i>
                </a>
                <a href="#" class="w-10 h-10 rounded-xl bg-slate-100 hover:bg-primary hover:text-white flex items-center justify-center transition">
                    <i class="bi bi-link-45deg"></i>
                </a>
            </div>
        </div>

        <!-- Related -->
        {% if related %}
        <div class="mt-16" data-aos="fade-up">
            <h2 class="text-2xl font-black text-dark mb-8 flex items-center gap-3">
                <span class="w-1.5 h-8 bg-accent rounded-full"></span>
                مقالات مرتبط
            </h2>
            <div class="grid md:grid-cols-3 gap-6">
                {% for item in related %}
                <a href="{% url 'article_detail' item.slug %}"
                   class="group bg-white rounded-3xl overflow-hidden border border-slate-100 hover:shadow-xl transition-all hover:-translate-y-1">
                    <div class="h-40 bg-gradient-to-br from-primary-50 to-accent/10 overflow-hidden">
                        {% if item.image %}
                            <img src="{{ item.image.url }}" class="w-full h-full object-cover group-hover:scale-110 transition-transform duration-500">
                        {% else %}
                            <div class="w-full h-full flex items-center justify-center">
                                <i class="bi bi-newspaper text-5xl text-primary/30"></i>
                            </div>
                        {% endif %}
                    </div>
                    <div class="p-5">
                        <h3 class="font-bold text-dark text-sm leading-6 mb-2 group-hover:text-primary transition line-clamp-2">
                            {{ item.title }}
                        </h3>
                        <div class="flex items-center gap-2 text-xs text-slate-400">
                            <i class="bi bi-calendar3"></i>
                            <span>{{ item.created_at|date:"Y/m/d" }}</span>
                        </div>
                    </div>
                </a>
                {% endfor %}
            </div>
        </div>
        {% endif %}
    </div>
</section>

{% endblock %}
EOF

# ============================================================
#  13. Template: contact.html (کامل با فرم)
# ============================================================

cat > templates/contact.html << 'EOF'
{% extends 'base.html' %}

{% block title %}تماس با ما{% endblock %}

{% block content %}

<section class="relative overflow-hidden bg-gradient-to-bl from-primary-50 via-white to-accent/5 py-20">
    <div class="absolute top-10 right-10 w-72 h-72 bg-primary/10 rounded-full blur-3xl animate-float"></div>
    <div class="relative max-w-7xl mx-auto px-4 lg:px-8 text-center" data-aos="fade-up">
        <h1 class="text-4xl md:text-5xl font-black text-dark mb-4">تماس با ما</h1>
        <p class="text-slate-600 max-w-2xl mx-auto leading-8">
            هر سؤالی دارید بپرسید، در کوتاه‌ترین زمان پاسخگو خواهیم بود.
        </p>
    </div>
</section>

<!-- Contact cards -->
<section class="py-12 -mt-8">
    <div class="max-w-7xl mx-auto px-4 lg:px-8">
        <div class="grid md:grid-cols-3 gap-6">
            <div class="bg-white rounded-3xl p-8 border border-slate-100 text-center hover:shadow-xl transition" data-aos="fade-up">
                <div class="w-16 h-16 mx-auto rounded-2xl bg-primary-50 flex items-center justify-center mb-4">
                    <i class="bi bi-telephone-fill text-2xl text-primary"></i>
                </div>
                <h3 class="font-bold text-dark mb-2">تلفن</h3>
                <a href="tel:{{ SITE_PHONE }}" dir="ltr" class="text-slate-500 hover:text-primary font-semibold">{{ SITE_PHONE }}</a>
            </div>

            <div class="bg-white rounded-3xl p-8 border border-slate-100 text-center hover:shadow-xl transition" data-aos="fade-up" data-aos-delay="100">
                <div class="w-16 h-16 mx-auto rounded-2xl bg-accent/10 flex items-center justify-center mb-4">
                    <i class="bi bi-geo-alt-fill text-2xl text-accent"></i>
                </div>
                <h3 class="font-bold text-dark mb-2">آدرس</h3>
                <p class="text-slate-500 text-sm leading-7">{{ SITE_ADDRESS }}</p>
            </div>

            <div class="bg-white rounded-3xl p-8 border border-slate-100 text-center hover:shadow-xl transition" data-aos="fade-up" data-aos-delay="200">
                <div class="w-16 h-16 mx-auto rounded-2xl bg-emerald-50 flex items-center justify-center mb-4">
                    <i class="bi bi-clock-fill text-2xl text-emerald-500"></i>
                </div>
                <h3 class="font-bold text-dark mb-2">ساعات کاری</h3>
                <p class="text-slate-500 text-sm leading-7">هر روز از ۱۰ صبح تا ۷ عصر</p>
            </div>
        </div>
    </div>
</section>

<!-- Contact form -->
<section class="py-16">
    <div class="max-w-6xl mx-auto px-4 lg:px-8">
        <div class="bg-white rounded-3xl border border-slate-100 shadow-xl overflow-hidden">
            <div class="grid lg:grid-cols-5">

                <!-- Info side -->
                <div class="lg:col-span-2 bg-gradient-to-bl from-primary to-primary-700 p-10 text-white relative overflow-hidden">
                    <div class="absolute -bottom-20 -right-20 w-80 h-80 bg-white/10 rounded-full blur-3xl"></div>
                    <div class="relative">
                        <h2 class="text-2xl font-black mb-4">بیایید صحبت کنیم</h2>
                        <p class="text-white/80 leading-7 mb-8">ما مشتاقانه منتظر شنیدن نظرات، سؤالات و پیشنهادات شما هستیم.</p>

                        <div class="space-y-5">
                            <div class="flex items-start gap-4">
                                <div class="w-11 h-11 rounded-xl bg-white/10 backdrop-blur flex items-center justify-center shrink-0">
                                    <i class="bi bi-telephone-fill"></i>
                                </div>
                                <div>
                                    <div class="text-xs text-white/60 mb-1">شماره تماس</div>
                                    <div class="font-bold" dir="ltr">{{ SITE_PHONE }}</div>
                                </div>
                            </div>
                            <div class="flex items-start gap-4">
                                <div class="w-11 h-11 rounded-xl bg-white/10 backdrop-blur flex items-center justify-center shrink-0">
                                    <i class="bi bi-geo-alt-fill"></i>
                                </div>
                                <div>
                                    <div class="text-xs text-white/60 mb-1">آدرس مطب</div>
                                    <div class="font-bold leading-6 text-sm">{{ SITE_ADDRESS }}</div>
                                </div>
                            </div>
                        </div>

                        <div class="mt-10 pt-8 border-t border-white/20">
                            <div class="text-sm mb-3">ما را در شبکه‌های اجتماعی دنبال کنید</div>
                            <div class="flex gap-2">
                                <a href="#" class="w-10 h-10 rounded-xl bg-white/10 backdrop-blur hover:bg-white/20 flex items-center justify-center transition">
                                    <i class="bi bi-instagram"></i>
                                </a>
                                <a href="#" class="w-10 h-10 rounded-xl bg-white/10 backdrop-blur hover:bg-white/20 flex items-center justify-center transition">
                                    <i class="bi bi-telegram"></i>
                                </a>
                                <a href="#" class="w-10 h-10 rounded-xl bg-white/10 backdrop-blur hover:bg-white/20 flex items-center justify-center transition">
                                    <i class="bi bi-whatsapp"></i>
                                </a>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Form side -->
                <div class="lg:col-span-3 p-10">
                    <h2 class="text-2xl font-black text-dark mb-6" data-aos="fade-up">ارسال پیام</h2>

                    <form method="post" class="space-y-5" data-aos="fade-up">
                        {% csrf_token %}
                        <div class="grid md:grid-cols-2 gap-5">
                            <div>
                                <label class="block text-sm font-semibold mb-2">نام و نام خانوادگی <span class="text-red-500">*</span></label>
                                {{ form.name }}
                            </div>
                            <div>
                                <label class="block text-sm font-semibold mb-2">شماره تماس <span class="text-red-500">*</span></label>
                                {{ form.phone }}
                            </div>
                        </div>
                        <div class="grid md:grid-cols-2 gap-5">
                            <div>
                                <label class="block text-sm font-semibold mb-2">ایمیل</label>
                                {{ form.email }}
                            </div>
                            <div>
                                <label class="block text-sm font-semibold mb-2">موضوع</label>
                                {{ form.subject }}
                            </div>
                        </div>
                        <div>
                            <label class="block text-sm font-semibold mb-2">پیام <span class="text-red-500">*</span></label>
                            {{ form.message }}
                        </div>

                        {% if form.errors %}
                        <div class="bg-red-50 border border-red-200 rounded-2xl p-4 text-sm text-red-700">
                            {% for field, errors in form.errors.items %}
                                {% for error in errors %}<p>• {{ error }}</p>{% endfor %}
                            {% endfor %}
                        </div>
                        {% endif %}

                        <button type="submit"
                                class="w-full bg-gradient-to-l from-primary to-primary-700 text-white font-bold py-4 rounded-2xl hover:shadow-xl hover:shadow-primary/30 transition-all flex items-center justify-center gap-2">
                            <i class="bi bi-send-fill"></i>
                            ارسال پیام
                        </button>
                    </form>
                </div>
            </div>
        </div>
    </div>
</section>

<style>
    .form-input {
        width: 100%;
        padding: 0.85rem 1rem;
        border-radius: 1rem;
        border: 1px solid #e2e8f0;
        background: #f8fafc;
        font-family: inherit;
        transition: all 0.2s;
        font-size: 0.875rem;
    }
    .form-input:focus {
        outline: none;
        border-color: #2B6CF5;
        background: white;
        box-shadow: 0 0 0 4px rgba(43,108,245,0.1);
    }
</style>

{% endblock %}
EOF

# ============================================================
#  14. Template: about.html (کامل)
# ============================================================

cat > templates/about.html << 'EOF'
{% extends 'base.html' %}

{% block title %}درباره ما{% endblock %}

{% block content %}

<!-- Hero -->
<section class="relative overflow-hidden bg-gradient-to-bl from-primary-50 via-white to-accent/5 py-20">
    <div class="absolute top-10 right-10 w-72 h-72 bg-primary/10 rounded-full blur-3xl animate-float"></div>
    <div class="absolute bottom-10 left-10 w-72 h-72 bg-accent/10 rounded-full blur-3xl animate-float" style="animation-delay:1s"></div>

    <div class="relative max-w-7xl mx-auto px-4 lg:px-8">
        <div class="grid lg:grid-cols-2 gap-12 items-center">
            <div data-aos="fade-left">
                <nav class="flex items-center gap-2 text-sm text-slate-500 mb-6">
                    <a href="{% url 'home' %}" class="hover:text-primary">خانه</a>
                    <i class="bi bi-chevron-left text-xs"></i>
                    <span class="text-primary font-semibold">درباره ما</span>
                </nav>
                <div class="inline-flex items-center gap-2 bg-primary/10 text-primary px-4 py-2 rounded-full text-sm font-semibold mb-6">
                    <i class="bi bi-person-heart"></i>
                    <span>درباره دکتر مرجان آرام</span>
                </div>
                <h1 class="text-4xl md:text-5xl font-black text-dark leading-tight mb-6">
                    مسیری به سوی <span class="text-primary">آرامش و رشد</span>
                </h1>
                <p class="text-lg text-slate-600 leading-8 mb-6">
                    با بیش از ۱۵ سال تجربه در حوزه مشاوره و روانشناسی، همراه شما هستیم تا با آرامش و اطمینان، مسیر بهبودی و رشد شخصی را طی کنید.
                </p>

                <div class="grid grid-cols-3 gap-4 mt-8">
                    <div class="bg-white rounded-2xl p-4 text-center shadow-sm border border-slate-100">
                        <div class="text-2xl font-black text-primary">۱۵+</div>
                        <div class="text-xs text-slate-500 mt-1">سال تجربه</div>
                    </div>
                    <div class="bg-white rounded-2xl p-4 text-center shadow-sm border border-slate-100">
                        <div class="text-2xl font-black text-accent">۵۰۰۰+</div>
                        <div class="text-xs text-slate-500 mt-1">مشاوره موفق</div>
                    </div>
                    <div class="bg-white rounded-2xl p-4 text-center shadow-sm border border-slate-100">
                        <div class="text-2xl font-black text-emerald-500">۹۸٪</div>
                        <div class="text-xs text-slate-500 mt-1">رضایت</div>
                    </div>
                </div>
            </div>

            <div data-aos="fade-right" class="relative">
                <div class="relative w-full aspect-square max-w-lg mx-auto">
                    <div class="absolute inset-0 rounded-[3rem] bg-gradient-to-br from-primary to-accent rotate-6"></div>
                    <div class="absolute inset-0 rounded-[3rem] bg-gradient-to-br from-primary-50 to-accent/20 flex items-center justify-center overflow-hidden">
                        <i class="bi bi-person-heart text-[12rem] text-primary/30"></i>
                    </div>
                </div>
            </div>
        </div>
    </div>
</section>

<!-- Bio -->
<section class="py-20">
    <div class="max-w-4xl mx-auto px-4 lg:px-8">
        <div class="bg-white rounded-3xl p-10 md:p-14 border border-slate-100 shadow-sm" data-aos="fade-up">
            <h2 class="text-3xl font-black text-dark mb-8 flex items-center gap-3">
                <span class="w-1.5 h-9 bg-primary rounded-full"></span>
                بیوگرافی دکتر مرجان آرام
            </h2>

            <div class="space-y-5 text-slate-600 leading-8">
                <p>
                    دکتر مرجان آرام، متخصص مشاوره خانواده و روانشناسی بالینی، دارای مدرک دکترای روانشناسی از دانشگاه تهران و عضو رسمی انجمن روانشناسان ایران با شماره نظام ۷۶۴۲۷ هستند.
                </p>
                <p>
                    ایشان با بیش از ۱۵ سال سابقه درخشان، خدمات تخصصی در حوزه‌های مشاوره فردی، مشاوره خانواده، مشاوره قبل از ازدواج، درمان افسردگی و اضطراب، و همچنین مشاوره طلاق را به مراجعین گرامی ارائه می‌دهند.
                </p>
                <p>
                    رویکرد درمانی دکتر آرام بر پایه اصول علمی روانشناسی، احترام به حریم خصوصی و همدلی با مراجع بنا شده است. تاکنون بیش از ۵۰۰۰ مشاوره موفق در کارنامه ایشان به ثبت رسیده است.
                </p>
            </div>

            <div class="grid md:grid-cols-3 gap-4 mt-10">
                <div class="bg-gradient-to-br from-primary-50 to-primary-100 rounded-2xl p-6 text-center">
                    <i class="bi bi-mortarboard-fill text-3xl text-primary mb-3"></i>
                    <div class="font-bold text-dark">دکترای روانشناسی</div>
                    <div class="text-xs text-slate-500 mt-1">دانشگاه تهران</div>
                </div>
                <div class="bg-gradient-to-br from-accent/10 to-accent/20 rounded-2xl p-6 text-center">
                    <i class="bi bi-award-fill text-3xl text-accent mb-3"></i>
                    <div class="font-bold text-dark">عضو انجمن روانشناسان</div>
                    <div class="text-xs text-slate-500 mt-1">کد نظام ۷۶۴۲۷</div>
                </div>
                <div class="bg-gradient-to-br from-emerald-50 to-emerald-100 rounded-2xl p-6 text-center">
                    <i class="bi bi-patch-check-fill text-3xl text-emerald-500 mb-3"></i>
                    <div class="font-bold text-dark">مجوز رسمی</div>
                    <div class="text-xs text-slate-500 mt-1">سازمان نظام روانشناسی</div>
                </div>
            </div>
        </div>
    </div>
</section>

<!-- Values -->
<section class="py-20 bg-gradient-to-b from-white to-slate-50">
    <div class="max-w-7xl mx-auto px-4 lg:px-8">
        <div class="text-center mb-14" data-aos="fade-up">
            <h2 class="text-3xl md:text-4xl font-black text-dark mb-4">ارزش‌های ما</h2>
            <p class="text-slate-500">اصولی که همیشه به آن پایبند هستیم</p>
        </div>

        <div class="grid md:grid-cols-3 gap-6">
            <div class="bg-white rounded-3xl p-8 border border-slate-100 hover:shadow-xl transition" data-aos="fade-up">
                <div class="w-16 h-16 rounded-2xl bg-primary-50 flex items-center justify-center mb-5">
                    <i class="bi bi-shield-lock-fill text-3xl text-primary"></i>
                </div>
                <h3 class="font-black text-dark text-lg mb-3">محرمانگی کامل</h3>
                <p class="text-slate-500 text-sm leading-7">
                    تمام اطلاعات و گفتگوهای شما با بالاترین استانداردهای امنیتی و به‌صورت کاملاً محرمانه محافظت می‌شود.
                </p>
            </div>

            <div class="bg-white rounded-3xl p-8 border border-slate-100 hover:shadow-xl transition" data-aos="fade-up" data-aos-delay="100">
                <div class="w-16 h-16 rounded-2xl bg-accent/10 flex items-center justify-center mb-5">
                    <i class="bi bi-heart-fill text-3xl text-accent"></i>
                </div>
                <h3 class="font-black text-dark text-lg mb-3">همدلی و احترام</h3>
                <p class="text-slate-500 text-sm leading-7">
                    ما بدون قضاوت، با احترام و همدلی به صحبت‌های شما گوش می‌دهیم و در کنار شما هستیم.
                </p>
            </div>

            <div class="bg-white rounded-3xl p-8 border border-slate-100 hover:shadow-xl transition" data-aos="fade-up" data-aos-delay="200">
                <div class="w-16 h-16 rounded-2xl bg-emerald-50 flex items-center justify-center mb-5">
                    <i class="bi bi-graph-up-arrow text-3xl text-emerald-500"></i>
                </div>
                <h3 class="font-black text-dark text-lg mb-3">رویکرد علمی</h3>
                <p class="text-slate-500 text-sm leading-7">
                    استفاده از جدیدترین متدها و روش‌های علمی روانشناسی برای رسیدن به بهترین نتیجه.
                </p>
            </div>
        </div>
    </div>
</section>

<!-- CTA -->
<section class="py-16">
    <div class="max-w-7xl mx-auto px-4 lg:px-8">
        <div class="relative overflow-hidden rounded-[2rem] bg-gradient-to-bl from-primary via-primary-600 to-primary-700 p-10 md:p-16 text-center" data-aos="zoom-in">
            <div class="absolute top-0 right-0 w-72 h-72 bg-white/10 rounded-full blur-3xl"></div>
            <div class="relative">
                <h2 class="text-3xl md:text-4xl font-black text-white mb-4">آماده‌اید اولین قدم را بردارید؟</h2>
                <p class="text-white/80 mb-8 max-w-2xl mx-auto">همین حالا نوبت خود را رزرو کنید و با آرامش، مسیر بهبودی را شروع کنید.</p>
                <a href="{% url 'appointments:book' %}" class="inline-flex items-center gap-2 bg-white text-primary font-bold px-8 py-4 rounded-2xl hover:bg-slate-100 transition">
                    <i class="bi bi-calendar2-check"></i> رزرو نوبت
                </a>
            </div>
        </div>
    </div>
</section>

{% endblock %}
EOF

# ============================================================
#  15. Template: partials/footer.html (اضافه کردن خبرنامه)
# ============================================================

cat > templates/partials/footer.html << 'EOF'
<footer class="bg-dark text-slate-300 mt-24 relative overflow-hidden">
    <div class="absolute -top-32 -right-32 w-96 h-96 bg-primary/20 rounded-full blur-3xl"></div>
    <div class="absolute -bottom-32 -left-32 w-96 h-96 bg-accent/20 rounded-full blur-3xl"></div>

    <!-- Newsletter -->
    <div class="relative border-b border-white/10">
        <div class="max-w-7xl mx-auto px-4 lg:px-8 py-12">
            <div class="grid md:grid-cols-2 gap-8 items-center">
                <div>
                    <h3 class="text-2xl font-black text-white mb-2">عضویت در خبرنامه</h3>
                    <p class="text-slate-400 text-sm">جدیدترین مقالات و تخفیف‌های ویژه را در ایمیل خود دریافت کنید.</p>
                </div>
                <form method="post" action="{% url 'newsletter_subscribe' %}" class="flex gap-3">
                    {% csrf_token %}
                    <input type="email" name="email" required placeholder="ایمیل خود را وارد کنید"
                           class="flex-1 px-5 py-3.5 rounded-2xl bg-white/5 border border-white/10 text-white placeholder-slate-500 focus:outline-none focus:border-primary focus:bg-white/10 transition"
                           dir="ltr">
                    <button type="submit" class="bg-gradient-to-l from-primary to-primary-700 text-white font-bold px-6 py-3.5 rounded-2xl hover:shadow-lg hover:shadow-primary/30 transition">
                        <i class="bi bi-send"></i>
                        <span class="hidden sm:inline mr-2">عضویت</span>
                    </button>
                </form>
            </div>
        </div>
    </div>

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

# ============================================================
#  16. Template: partials/header.html (به‌روزرسانی مگامنو با دسته‌بندی‌های داینامیک)
# ============================================================

cat > templates/partials/header.html << 'EOF'
{% load static %}
<header x-data="{scrolled:false, mobileMenu:false, servicesOpen:false}"
        @scroll.window="scrolled = window.scrollY > 30"
        :class="scrolled ? 'bg-white/90 backdrop-blur-xl shadow-lg' : 'bg-white/70 backdrop-blur-md'"
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

                <!-- Mega Menu Services -->
                {% if nav_categories %}
                <div class="relative" @mouseenter="servicesOpen=true" @mouseleave="servicesOpen=false">
                    <button class="px-5 py-2 rounded-full text-sm font-semibold text-slate-700 hover:bg-primary hover:text-white transition-all flex items-center gap-1.5">
                        خدمات
                        <i class="bi bi-chevron-down text-xs" :class="servicesOpen ? 'rotate-180' : ''" style="transition: transform 0.2s"></i>
                    </button>
                    <div x-show="servicesOpen" x-cloak
                         x-transition:enter="transition ease-out duration-200"
                         x-transition:enter-start="opacity-0 translate-y-2"
                         class="absolute top-full right-0 mt-2 w-[640px] bg-white rounded-3xl shadow-2xl border border-slate-100 p-6 z-50">
                        <div class="grid grid-cols-2 gap-3">
                            {% for cat in nav_categories %}
                            <a href="{% url 'service_list' %}?category={{ cat.slug }}"
                               class="group flex items-start gap-3 p-3 rounded-2xl hover:bg-primary/5 transition">
                                <div class="w-11 h-11 rounded-xl bg-primary-50 group-hover:bg-primary flex items-center justify-center transition shrink-0">
                                    <i class="bi {{ cat.icon|default:'bi-heart-pulse' }} text-primary group-hover:text-white transition"></i>
                                </div>
                                <div>
                                    <div class="font-bold text-sm text-dark group-hover:text-primary transition">{{ cat.name }}</div>
                                    <div class="text-xs text-slate-500 line-clamp-1 mt-0.5">{{ cat.description|default:"مشاهده خدمات" }}</div>
                                </div>
                            </a>
                            {% endfor %}
                        </div>
                        <div class="mt-4 pt-4 border-t border-slate-100">
                            <a href="{% url 'service_list' %}" class="flex items-center justify-center gap-2 text-primary font-bold text-sm hover:underline">
                                مشاهده همه خدمات <i class="bi bi-arrow-left"></i>
                            </a>
                        </div>
                    </div>
                </div>
                {% else %}
                <a href="{% url 'service_list' %}" class="px-5 py-2 rounded-full text-sm font-semibold text-slate-700 hover:bg-primary hover:text-white transition-all">خدمات</a>
                {% endif %}

                <a href="{% url 'package_list' %}" class="px-5 py-2 rounded-full text-sm font-semibold text-slate-700 hover:bg-primary hover:text-white transition-all">بسته‌ها</a>
                <a href="{% url 'article_list' %}" class="px-5 py-2 rounded-full text-sm font-semibold text-slate-700 hover:bg-primary hover:text-white transition-all">مقالات</a>
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
#  17. اجرای مایگریشن
# ============================================================

echo ""
echo "🔧 در حال اجرای مایگریشن‌ها..."

python manage.py makemigrations services --noinput
python manage.py migrate --noinput

echo ""
echo "======================================================"
echo "  ✅ فاز ۱ - بخش ۱.۳ با موفقیت اضافه شد!"
echo "======================================================"
echo ""
echo "🚀 سرور را ری‌استارت کنید:"
echo "   python manage.py runserver"
echo ""
echo "📌 برای دیدن نتایج، از پنل ادمین داده اضافه کنید:"
echo "   http://127.0.0.1:8000/admin"
echo ""
echo "   - یک دسته‌بندی (ServiceCategory) بسازید"
echo "   - چند سرویس (Service) اضافه کنید"
echo "   - یک بسته (Package) اضافه کنید"
echo "   - یک مقاله (Article) اضافه کنید"
echo ""
echo "🌐 سپس این صفحات را ببینید:"
echo "   http://127.0.0.1:8000/services/"
echo "   http://127.0.0.1:8000/packages/"
echo "   http://127.0.0.1:8000/articles/"
echo "   http://127.0.0.1:8000/contact/"
echo "   http://127.0.0.1:8000/about/"
echo ""
echo "======================================================"