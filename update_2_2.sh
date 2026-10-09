#!/bin/bash
# ============================================================
#  Phase 2.2 - Reviews & Ratings System
# ============================================================

set -e

if [ ! -f "manage.py" ]; then
    echo "ERROR: run in project root"
    exit 1
fi

echo "Running Phase 2.2 setup..."

# ------------------------------------------------------------
# 1) Model Review
# ------------------------------------------------------------
cat > services/models.py << 'PYEOF'
from django.db import models
from django.core.validators import MinValueValidator, MaxValueValidator


class ServiceCategory(models.Model):
    name = models.CharField('نام دسته', max_length=100)
    slug = models.SlugField(unique=True, allow_unicode=True)
    description = models.TextField('توضیحات', blank=True)
    icon = models.CharField('آیکون', max_length=80, blank=True)
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
    description = models.TextField('توضیحات')
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

    def average_rating(self):
        """میانگین امتیاز (فقط تأیید شده‌ها)"""
        result = self.reviews.filter(is_approved=True).aggregate(
            avg=models.Avg('rating')
        )['avg']
        return round(result or 0, 1)

    def reviews_count(self):
        return self.reviews.filter(is_approved=True).count()

    def rating_distribution(self):
        """توزیع امتیازها برای نمودار"""
        dist = {i: 0 for i in range(1, 6)}
        for r in self.reviews.filter(is_approved=True).values('rating'):
            dist[r['rating']] += 1
        return dist


class Package(models.Model):
    name = models.CharField('نام بسته', max_length=200)
    slug = models.SlugField(unique=True, allow_unicode=True)
    short_description = models.CharField('توضیح کوتاه', max_length=300, blank=True)
    description = models.TextField('توضیحات')
    features = models.TextField('امکانات', blank=True)
    price = models.DecimalField('قیمت', max_digits=12, decimal_places=0)
    old_price = models.DecimalField('قیمت قبل', max_digits=12, decimal_places=0, null=True, blank=True)
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
    category = models.ForeignKey(ServiceCategory, on_delete=models.SET_NULL, null=True, blank=True)
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
    name = models.CharField('نام', max_length=150)
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


# ============================================================
#  REVIEW MODEL
# ============================================================

class Review(models.Model):
    STATUS_CHOICES = [
        ('pending', 'در انتظار تأیید'),
        ('approved', 'تأیید شده'),
        ('rejected', 'رد شده'),
    ]
    service = models.ForeignKey(
        Service,
        on_delete=models.CASCADE,
        related_name='reviews',
        verbose_name='سرویس'
    )
    user = models.ForeignKey(
        'accounts.CustomUser',
        on_delete=models.CASCADE,
        related_name='reviews',
        verbose_name='کاربر'
    )
    appointment = models.OneToOneField(
        'appointments.Appointment',
        on_delete=models.SET_NULL,
        null=True, blank=True,
        related_name='review',
        verbose_name='نوبت مربوطه'
    )
    rating = models.PositiveSmallIntegerField(
        'امتیاز',
        validators=[MinValueValidator(1), MaxValueValidator(5)],
    )
    comment = models.TextField('نظر', blank=True)
    status = models.CharField('وضعیت', max_length=20, choices=STATUS_CHOICES, default='pending')
    is_approved = models.BooleanField('تأیید شده', default=False)
    admin_reply = models.TextField('پاسخ ادمین', blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']
        verbose_name = 'نظر'
        verbose_name_plural = 'نظرات'
        # هر کاربر فقط یک نظر برای هر سرویس
        unique_together = ('user', 'service')

    def __str__(self):
        return f"{self.user.get_full_name() or self.user.username} - {self.service.name} - {self.rating}/5"

    def save(self, *args, **kwargs):
        # هماهنگ‌سازی is_approved با status
        self.is_approved = (self.status == 'approved')
        super().save(*args, **kwargs)

    @property
    def stars(self):
        return range(1, 6)

    def user_initial(self):
        u = self.user
        return (u.first_name or u.username or '?')[0].upper()
PYEOF

echo "[OK] models.py (with Review)"

# ------------------------------------------------------------
# 2) Admin
# ------------------------------------------------------------
cat > services/admin.py << 'PYEOF'
from django.contrib import admin
from django.utils.html import format_html
from .models import (
    ServiceCategory, Service, Package, Article,
    ContactMessage, NewsletterSubscriber, Review,
)


@admin.register(ServiceCategory)
class ServiceCategoryAdmin(admin.ModelAdmin):
    list_display = ('name', 'slug', 'order')
    prepopulated_fields = {'slug': ('name',)}
    list_editable = ('order',)


@admin.register(Service)
class ServiceAdmin(admin.ModelAdmin):
    list_display = ('name', 'category', 'price', 'duration', 'rating_display', 'is_active', 'is_featured', 'order')
    list_filter = ('category', 'is_active', 'is_featured')
    list_editable = ('is_active', 'is_featured', 'order')
    prepopulated_fields = {'slug': ('name',)}
    search_fields = ('name', 'description')

    @admin.display(description='امتیاز')
    def rating_display(self, obj):
        avg = obj.average_rating()
        cnt = obj.reviews_count()
        if cnt == 0:
            return '—'
        return format_html(
            '<span style="color:#f59e0b;font-weight:bold">★</span> {} <span style="color:#999">({})</span>',
            avg, cnt
        )


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


@admin.register(Review)
class ReviewAdmin(admin.ModelAdmin):
    list_display = (
        'id', 'service', 'user_link', 'rating_badge',
        'status_badge', 'created_at', 'is_approved',
    )
    list_filter = ('status', 'is_approved', 'rating', 'created_at', 'service')
    search_fields = ('user__username', 'user__phone_number', 'user__first_name', 'comment')
    readonly_fields = ('created_at', 'updated_at')
    date_hierarchy = 'created_at'
    actions = ['approve_reviews', 'reject_reviews']
    list_editable = ('is_approved',)

    fieldsets = (
        ('اطلاعات اصلی', {
            'fields': ('service', 'user', 'appointment', 'rating')
        }),
        ('نظر', {
            'fields': ('comment', 'admin_reply')
        }),
        ('وضعیت', {
            'fields': ('status', 'is_approved')
        }),
        ('زمان', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )

    @admin.display(description='کاربر')
    def user_link(self, obj):
        return obj.user.get_full_name() or obj.user.username

    @admin.display(description='امتیاز')
    def rating_badge(self, obj):
        stars = '★' * obj.rating + '☆' * (5 - obj.rating)
        return format_html(
            '<span style="color:#f59e0b;font-size:16px">{}</span>',
            stars
        )

    @admin.display(description='وضعیت')
    def status_badge(self, obj):
        colors = {
            'pending': '#f59e0b',
            'approved': '#10b981',
            'rejected': '#ef4444',
        }
        return format_html(
            '<span style="background:{};color:white;padding:4px 10px;border-radius:20px;font-size:12px">{}</span>',
            colors.get(obj.status, '#999'),
            obj.get_status_display()
        )

    @admin.action(description='تأیید نظرات انتخاب شده')
    def approve_reviews(self, request, queryset):
        n = queryset.update(status='approved', is_approved=True)
        self.message_user(request, f'{n} نظر تأیید شد.')

    @admin.action(description='رد نظرات انتخاب شده')
    def reject_reviews(self, request, queryset):
        n = queryset.update(status='rejected', is_approved=False)
        self.message_user(request, f'{n} نظر رد شد.')
PYEOF

echo "[OK] admin.py"

# ------------------------------------------------------------
# 3) Forms
# ------------------------------------------------------------
cat > services/forms.py << 'PYEOF'
from django import forms
from .models import ContactMessage, NewsletterSubscriber, Review


class ContactForm(forms.ModelForm):
    class Meta:
        model = ContactMessage
        fields = ['name', 'phone', 'email', 'subject', 'message']
        widgets = {
            'name': forms.TextInput(attrs={'class': 'form-input', 'placeholder': 'نام و نام خانوادگی'}),
            'phone': forms.TextInput(attrs={'class': 'form-input', 'placeholder': '۰۹۱۲۳۴۵۶۷۸۹', 'dir': 'ltr'}),
            'email': forms.EmailInput(attrs={'class': 'form-input', 'placeholder': 'example@mail.com', 'dir': 'ltr'}),
            'subject': forms.TextInput(attrs={'class': 'form-input', 'placeholder': 'موضوع'}),
            'message': forms.Textarea(attrs={'class': 'form-input', 'rows': 5, 'placeholder': 'متن پیام...'}),
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


class ReviewForm(forms.ModelForm):
    rating = forms.ChoiceField(
        choices=[(i, f'{i} ستاره') for i in range(1, 6)],
        widget=forms.RadioSelect(attrs={'class': 'star-rating-input'}),
        label='امتیاز شما',
    )

    class Meta:
        model = Review
        fields = ['rating', 'comment']
        widgets = {
            'comment': forms.Textarea(attrs={
                'class': 'form-input',
                'rows': 4,
                'placeholder': 'تجربه خود را با دیگران به اشتراک بگذارید... (اختیاری)',
            }),
        }
        labels = {
            'comment': 'نظر شما',
        }
PYEOF

echo "[OK] forms.py"

# ------------------------------------------------------------
# 4) Views — add review handling
# ------------------------------------------------------------
cat > services/views.py << 'PYEOF'
from django.shortcuts import render, get_object_or_404, redirect
from django.contrib import messages
from django.contrib.auth.decorators import login_required
from django.db.models import F, Q, Avg
from django.core.paginator import Paginator
from django.http import JsonResponse
from django.views.decorators.http import require_POST

from .models import (
    ServiceCategory, Service, Package, Article,
    ContactMessage, NewsletterSubscriber, Review,
)
from .forms import ContactForm, NewsletterForm, ReviewForm
from appointments.models import Appointment


def home(request):
    categories = ServiceCategory.objects.all()[:6]
    featured_services = Service.objects.filter(is_active=True, is_featured=True)[:6]
    if not featured_services:
        featured_services = Service.objects.filter(is_active=True)[:6]
    articles = Article.objects.filter(is_published=True)[:3]
    packages = Package.objects.filter(is_active=True, is_featured=True)[:3]
    if not packages:
        packages = Package.objects.filter(is_active=True)[:3]

    return render(request, 'home.html', {
        'categories': categories,
        'services': featured_services,
        'articles': articles,
        'packages': packages,
    })


def about(request):
    return render(request, 'about.html')


def contact(request):
    if request.method == 'POST':
        form = ContactForm(request.POST)
        if form.is_valid():
            form.save()
            messages.success(request, 'پیام شما با موفقیت ارسال شد.')
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

    return render(request, 'services/service_list.html', {
        'categories': categories,
        'services': services,
        'selected_category': selected_category,
        'search': search,
    })


def service_detail(request, slug):
    service = get_object_or_404(Service, slug=slug, is_active=True)
    related = Service.objects.filter(
        category=service.category, is_active=True
    ).exclude(pk=service.pk)[:3]

    # reviews
    reviews_qs = service.reviews.filter(is_approved=True).select_related('user').order_by('-created_at')
    reviews = reviews_qs[:10]
    total_reviews = reviews_qs.count()

    # avg
    avg = reviews_qs.aggregate(avg=Avg('rating'))['avg'] or 0

    # distribution
    dist = {i: 0 for i in range(1, 6)}
    for r in reviews_qs.values('rating'):
        dist[r['rating']] += 1

    # آیا کاربر فعلی می‌تواند نظر بدهد؟
    can_review = False
    user_review = None
    review_form = None
    if request.user.is_authenticated:
        # بررسی نوبت انجام‌شده
        has_completed = Appointment.objects.filter(
            user=request.user,
            service=service,
            status='completed',
        ).exists()
        user_review = Review.objects.filter(user=request.user, service=service).first()
        can_review = has_completed and not user_review
        if can_review:
            review_form = ReviewForm()

    return render(request, 'services/service_detail.html', {
        'service': service,
        'related': related,
        'reviews': reviews,
        'total_reviews': total_reviews,
        'avg_rating': round(avg, 1),
        'rating_distribution': dist,
        'can_review': can_review,
        'user_review': user_review,
        'review_form': review_form,
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
    page_obj = paginator.get_page(request.GET.get('page', 1))
    return render(request, 'services/article_list.html', {
        'articles': page_obj,
        'page_obj': page_obj,
        'search': search,
    })


def article_detail(request, slug):
    article = get_object_or_404(Article, slug=slug, is_published=True)
    Article.objects.filter(pk=article.pk).update(views=F('views') + 1)
    related = Article.objects.filter(is_published=True).exclude(pk=article.pk)[:3]
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
                messages.success(request, 'عضویت شما در خبرنامه ثبت شد.')
            else:
                messages.info(request, 'این ایمیل قبلاً عضو شده است.')
        else:
            messages.error(request, 'ایمیل معتبر نیست.')
    return redirect(request.META.get('HTTP_REFERER', 'home'))


# ============================================================
#  REVIEW VIEWS
# ============================================================

@login_required
@require_POST
def submit_review(request, slug):
    """ثبت نظر جدید — فقط برای کاربران با نوبت completed"""
    service = get_object_or_404(Service, slug=slug, is_active=True)

    # بررسی: آیا این کاربر می‌تواند نظر بدهد؟
    appointment = Appointment.objects.filter(
        user=request.user,
        service=service,
        status='completed',
    ).order_by('-date').first()

    if not appointment:
        messages.error(request, 'فقط کاربرانی که این سرویس را دریافت کرده‌اند می‌توانند نظر بدهند.')
        return redirect('service_detail', slug=slug)

    if Review.objects.filter(user=request.user, service=service).exists():
        messages.warning(request, 'شما قبلاً برای این سرویس نظر داده‌اید.')
        return redirect('service_detail', slug=slug)

    form = ReviewForm(request.POST)
    if form.is_valid():
        review = form.save(commit=False)
        review.user = request.user
        review.service = service
        review.appointment = appointment
        review.status = 'pending'
        review.is_approved = False
        review.save()
        messages.success(request, 'نظر شما ثبت شد و پس از تأیید نمایش داده می‌شود. سپاسگزاریم! 🌟')
    else:
        messages.error(request, 'لطفاً امتیاز و نظر خود را به‌درستی وارد کنید.')

    return redirect('service_detail', slug=slug)


def reviews_list_api(request, slug):
    """API برای دریافت نظرات با فیلتر"""
    service = get_object_or_404(Service, slug=slug, is_active=True)
    rating_filter = request.GET.get('rating')
    page = int(request.GET.get('page', 1))

    qs = service.reviews.filter(is_approved=True).select_related('user').order_by('-created_at')
    if rating_filter and rating_filter.isdigit():
        qs = qs.filter(rating=int(rating_filter))

    paginator = Paginator(qs, 10)
    page_obj = paginator.get_page(page)

    data = {
        'reviews': [
            {
                'id': r.id,
                'user': r.user.get_full_name() or r.user.username,
                'initial': r.user_initial(),
                'rating': r.rating,
                'comment': r.comment,
                'admin_reply': r.admin_reply,
                'created_at': r.created_at.strftime('%Y/%m/%d'),
                'is_verified': bool(r.appointment),
            }
            for r in page_obj
        ],
        'has_next': page_obj.has_next(),
        'total': paginator.count,
    }
    return JsonResponse(data)


def custom_404(request, exception):
    return render(request, '404.html', status=404)


def custom_500(request):
    return render(request, '500.html', status=500)
PYEOF

echo "[OK] views.py"

# ------------------------------------------------------------
# 5) URLs
# ------------------------------------------------------------
cat > services/urls.py << 'PYEOF'
from django.urls import path
from . import views

urlpatterns = [
    path('', views.home, name='home'),
    path('about/', views.about, name='about'),
    path('contact/', views.contact, name='contact'),
    path('services/', views.service_list, name='service_list'),
    path('services/<slug:slug>/', views.service_detail, name='service_detail'),
    path('services/<slug:slug>/review/', views.submit_review, name='submit_review'),
    path('services/<slug:slug>/reviews/', views.reviews_list_api, name='reviews_api'),
    path('packages/', views.package_list, name='package_list'),
    path('packages/<slug:slug>/', views.package_detail, name='package_detail'),
    path('articles/', views.article_list, name='article_list'),
    path('articles/<slug:slug>/', views.article_detail, name='article_detail'),
    path('newsletter/subscribe/', views.newsletter_subscribe, name='newsletter_subscribe'),
]
PYEOF

echo "[OK] urls.py"

# ------------------------------------------------------------
# 6) Template - Service Detail (completely redesigned with reviews)
# ------------------------------------------------------------
cat > templates/services/service_detail.html << 'HTMLEOF'
{% extends 'base.html' %}
{% load fa_numbers %}

{% block title %}{{ service.name }}{% endblock %}

{% block content %}

<!-- Breadcrumb -->
<section class="py-8 border-b border-night-800">
    <div class="max-w-7xl mx-auto px-4 lg:px-8">
        <nav class="flex items-center gap-2 text-sm text-night-400 flex-wrap">
            <a href="{% url 'home' %}" class="hover:text-primary">خانه</a>
            <i class="bi bi-chevron-left text-xs"></i>
            <a href="{% url 'service_list' %}" class="hover:text-primary">خدمات</a>
            <i class="bi bi-chevron-left text-xs"></i>
            <a href="{% url 'service_list' %}?category={{ service.category.slug }}" class="hover:text-primary">{{ service.category.name }}</a>
            <i class="bi bi-chevron-left text-xs"></i>
            <span class="text-primary font-bold">{{ service.name }}</span>
        </nav>
    </div>
</section>

<!-- Main -->
<section class="py-12">
    <div class="max-w-7xl mx-auto px-4 lg:px-8">
        <div class="grid lg:grid-cols-3 gap-8">

            <!-- Content -->
            <div class="lg:col-span-2 space-y-6" data-aos="fade-up">
                <!-- Header card -->
                <div class="bg-gradient-to-b from-night-800 to-night-900 border border-night-700 rounded-3xl p-8">
                    <div class="flex flex-wrap items-center gap-3 mb-5">
                        <span class="inline-flex items-center gap-2 bg-primary/15 border border-primary/30 text-primary px-3 py-1.5 rounded-full text-xs font-bold">
                            <i class="bi {{ service.category.icon|default:'bi-heart-pulse' }}"></i>
                            {{ service.category.name }}
                        </span>
                        {% if service.is_featured %}
                        <span class="inline-flex items-center gap-2 bg-amber-500/15 border border-amber-500/30 text-amber-400 px-3 py-1.5 rounded-full text-xs font-bold">
                            <i class="bi bi-star-fill"></i> ویژه
                        </span>
                        {% endif %}
                    </div>

                    <h1 class="text-3xl md:text-4xl font-black text-white mb-4">{{ service.name }}</h1>

                    <!-- Rating summary inline -->
                    {% if total_reviews > 0 %}
                    <div class="flex items-center gap-3 mb-6">
                        <div class="flex items-center gap-1">
                            {% for i in "12345" %}
                                {% if forloop.counter <= avg_rating %}
                                    <i class="bi bi-star-fill text-amber-400 text-lg"></i>
                                {% else %}
                                    <i class="bi bi-star text-night-600 text-lg"></i>
                                {% endif %}
                            {% endfor %}
                        </div>
                        <span class="text-white font-bold">{{ avg_rating }}</span>
                        <span class="text-night-400 text-sm">({{ total_reviews }} نظر)</span>
                    </div>
                    {% endif %}

                    <p class="text-night-300 leading-8 text-lg">{{ service.short_description }}</p>
                </div>

                <!-- Description -->
                <div class="bg-night-800 border border-night-700 rounded-3xl p-8">
                    <h2 class="text-xl font-black text-white mb-5 flex items-center gap-3">
                        <span class="w-1.5 h-7 bg-primary rounded-full"></span>
                        توضیحات کامل
                    </h2>
                    <div class="text-night-300 leading-8 whitespace-pre-line">{{ service.description }}</div>
                </div>

                <!-- Stats cards -->
                <div class="grid sm:grid-cols-3 gap-4">
                    <div class="bg-night-800 border border-night-700 rounded-3xl p-6 text-center">
                        <div class="w-14 h-14 mx-auto rounded-2xl bg-primary/15 border border-primary/30 flex items-center justify-center mb-3">
                            <i class="bi bi-clock-history text-2xl text-primary"></i>
                        </div>
                        <div class="text-xs text-night-400 mb-1">مدت زمان</div>
                        <div class="font-black text-white">{{ service.duration|duration_fa }}</div>
                    </div>
                    <div class="bg-night-800 border border-night-700 rounded-3xl p-6 text-center">
                        <div class="w-14 h-14 mx-auto rounded-2xl bg-emerald-500/15 border border-emerald-500/30 flex items-center justify-center mb-3">
                            <i class="bi bi-shield-check text-2xl text-emerald-400"></i>
                        </div>
                        <div class="text-xs text-night-400 mb-1">کیفیت</div>
                        <div class="font-black text-white">تضمینی</div>
                    </div>
                    <div class="bg-night-800 border border-night-700 rounded-3xl p-6 text-center">
                        <div class="w-14 h-14 mx-auto rounded-2xl bg-amber-500/15 border border-amber-500/30 flex items-center justify-center mb-3">
                            <i class="bi bi-star-fill text-2xl text-amber-400"></i>
                        </div>
                        <div class="text-xs text-night-400 mb-1">امتیاز</div>
                        <div class="font-black text-white">{{ avg_rating|default:0 }} از ۵</div>
                    </div>
                </div>

                <!-- =========================================== -->
                <!--  REVIEWS SECTION                            -->
                <!-- =========================================== -->
                <div id="reviews" class="bg-night-800 border border-night-700 rounded-3xl p-8">
                    <div class="flex flex-wrap items-center justify-between gap-4 mb-6">
                        <h2 class="text-xl font-black text-white flex items-center gap-3">
                            <span class="w-1.5 h-7 bg-amber-500 rounded-full"></span>
                            نظرات کاربران
                            {% if total_reviews > 0 %}
                            <span class="text-sm font-normal text-night-400">({{ total_reviews }})</span>
                            {% endif %}
                        </h2>
                    </div>

                    {% if total_reviews == 0 %}
                    <div class="text-center py-12">
                        <i class="bi bi-chat-quote text-5xl text-night-600 mb-4"></i>
                        <p class="text-night-400 mb-2">هنوز نظری برای این سرویس ثبت نشده است.</p>
                        {% if user.is_authenticated %}
                            <p class="text-night-500 text-sm">اگر این سرویس را دریافت کرده‌اید، اولین نظر را ثبت کنید!</p>
                        {% endif %}
                    </div>
                    {% else %}

                    <!-- Rating summary -->
                    <div class="grid md:grid-cols-3 gap-6 p-6 bg-night-900 rounded-2xl mb-8">
                        <!-- Big average -->
                        <div class="text-center md:border-l border-night-700 md:pl-6">
                            <div class="text-6xl font-black text-amber-400 mb-2">{{ avg_rating }}</div>
                            <div class="flex justify-center gap-1 mb-2">
                                {% for i in "12345" %}
                                    {% if forloop.counter <= avg_rating %}
                                        <i class="bi bi-star-fill text-amber-400 text-xl"></i>
                                    {% else %}
                                        <i class="bi bi-star text-night-600 text-xl"></i>
                                    {% endif %}
                                {% endfor %}
                            </div>
                            <div class="text-sm text-night-400">از {{ total_reviews }} نظر</div>
                        </div>

                        <!-- Distribution bars -->
                        <div class="md:col-span-2 space-y-2">
                            {% for star in "54321" %}
                            {% with s=star|add:0 %}
                            <div class="flex items-center gap-3 text-sm">
                                <span class="text-night-300 w-12 flex items-center gap-1">
                                    {{ star }} <i class="bi bi-star-fill text-amber-400 text-xs"></i>
                                </span>
                                <div class="flex-1 h-2 bg-night-800 rounded-full overflow-hidden">
                                    {% with count=rating_distribution|default_if_none:0 %}
                                    {% with total=total_reviews|default:1 %}
                                    {% with star_key=star|add:0 %}{% endwith %}
                                    {% endwith %}
                                    {% endwith %}
                                </div>
                                <span class="text-night-400 w-8 text-left" dir="ltr"></span>
                            </div>
                            {% endwith %}
                            {% endfor %}
                        </div>
                    </div>

                    <script>
                        // Distribution - use server data
                        document.addEventListener('DOMContentLoaded', () => {
                            const dist = {{ rating_distribution|safe }};
                            const total = {{ total_reviews }};
                            // This is replaced by the server template logic below
                        });
                    </script>

                    <!-- JS-rendered bars (dynamic) -->
                    <div class="hidden">
                        <!-- Hidden placeholder to avoid double render -->
                    </div>

                    <!-- Better static bars -->
                    <div class="md:col-span-2 space-y-2 hidden"></div>

                    <!-- Reviews list -->
                    <div class="space-y-4">
                        {% for review in reviews %}
                        <div class="p-5 bg-night-900 rounded-2xl border border-night-700">
                            <div class="flex items-start gap-4">
                                <div class="w-12 h-12 rounded-2xl bg-gradient-to-br from-primary to-primary-700 flex items-center justify-center text-white font-black shrink-0">
                                    {{ review.user_initial }}
                                </div>
                                <div class="flex-1 min-w-0">
                                    <div class="flex flex-wrap items-center gap-3 mb-2">
                                        <span class="font-bold text-white">{{ review.user.get_full_name|default:review.user.username }}</span>
                                        {% if review.appointment %}
                                        <span class="inline-flex items-center gap-1 text-xs text-emerald-400 bg-emerald-500/10 px-2 py-0.5 rounded-full">
                                            <i class="bi bi-patch-check-fill"></i>
                                            خرید تأیید شده
                                        </span>
                                        {% endif %}
                                        <span class="text-xs text-night-500 mr-auto">
                                            {{ review.created_at|date:"Y/m/d" }}
                                        </span>
                                    </div>

                                    <div class="flex items-center gap-1 mb-3">
                                        {% for i in "12345" %}
                                            {% if forloop.counter <= review.rating %}
                                                <i class="bi bi-star-fill text-amber-400"></i>
                                            {% else %}
                                                <i class="bi bi-star text-night-600"></i>
                                            {% endif %}
                                        {% endfor %}
                                    </div>

                                    {% if review.comment %}
                                    <p class="text-night-300 leading-7">{{ review.comment }}</p>
                                    {% endif %}

                                    {% if review.admin_reply %}
                                    <div class="mt-4 p-4 bg-primary/5 border-r-4 border-primary rounded-lg">
                                        <div class="text-xs font-bold text-primary mb-2 flex items-center gap-2">
                                            <i class="bi bi-reply-fill"></i>
                                            پاسخ مرکز مشاوره:
                                        </div>
                                        <p class="text-sm text-night-200 leading-6">{{ review.admin_reply }}</p>
                                    </div>
                                    {% endif %}
                                </div>
                            </div>
                        </div>
                        {% endfor %}
                    </div>

                    {% endif %}

                    <!-- ================= REVIEW FORM ================= -->
                    {% if user.is_authenticated %}
                        {% if can_review %}
                        <div class="mt-8 p-6 bg-gradient-to-br from-primary/10 to-accent/5 border border-primary/30 rounded-2xl">
                            <h3 class="font-black text-white text-lg mb-2 flex items-center gap-2">
                                <i class="bi bi-pencil-square text-primary"></i>
                                ثبت نظر شما
                            </h3>
                            <p class="text-sm text-night-400 mb-5">تجربه خود را با دیگران به اشتراک بگذارید</p>

                            <form method="post" action="{% url 'submit_review' service.slug %}" class="space-y-5">
                                {% csrf_token %}

                                <!-- Star rating -->
                                <div>
                                    <label class="block text-sm font-bold text-white mb-3">امتیاز شما</label>
                                    <div class="flex items-center gap-2" x-data="{ rating: 5, hover: 0 }">
                                        <template x-for="i in 5" :key="i">
                                            <button type="button"
                                                    @click="rating = i"
                                                    @mouseenter="hover = i"
                                                    @mouseleave="hover = 0"
                                                    class="text-4xl transition-transform hover:scale-110"
                                                    :class="(hover || rating) >= i ? 'text-amber-400' : 'text-night-600'">
                                                <i :class="(hover || rating) >= i ? 'bi bi-star-fill' : 'bi bi-star'"></i>
                                            </button>
                                        </template>
                                        <span class="mr-3 text-night-400 text-sm">
                                            (<span x-text="rating"></span> از 5)
                                        </span>
                                        <input type="hidden" name="rating" :value="rating">
                                    </div>
                                </div>

                                <!-- Comment -->
                                <div>
                                    <label class="block text-sm font-bold text-white mb-2">نظر شما (اختیاری)</label>
                                    <textarea name="comment" rows="4"
                                              placeholder="تجربه خود را با دیگران به اشتراک بگذارید..."
                                              class="w-full px-4 py-3 rounded-2xl bg-night-900 border border-night-700 text-white placeholder-night-500 focus:border-primary focus:ring-4 focus:ring-primary/10 outline-none transition resize-none"></textarea>
                                </div>

                                <button type="submit"
                                        class="inline-flex items-center gap-2 bg-gradient-to-l from-primary to-primary-700 hover:shadow-lg hover:shadow-primary/40 text-white font-bold px-6 py-3 rounded-2xl transition-all">
                                    <i class="bi bi-send-fill"></i>
                                    ارسال نظر
                                </button>
                            </form>
                        </div>
                        {% elif user_review %}
                        <div class="mt-6 p-5 bg-emerald-500/10 border border-emerald-500/30 rounded-2xl">
                            <div class="flex items-start gap-3">
                                <i class="bi bi-check-circle-fill text-emerald-400 text-xl"></i>
                                <div>
                                    <div class="font-bold text-emerald-300 mb-1">شما قبلاً نظر داده‌اید</div>
                                    <div class="text-sm text-night-300">
                                        {% if user_review.status == 'pending' %}
                                            نظر شما در حال بررسی است و پس از تأیید نمایش داده می‌شود.
                                        {% elif user_review.status == 'approved' %}
                                            نظر شما تأیید و منتشر شده است.
                                        {% elif user_review.status == 'rejected' %}
                                            متأسفانه نظر شما تأیید نشد.
                                        {% endif %}
                                    </div>
                                </div>
                            </div>
                        </div>
                        {% else %}
                        <div class="mt-6 p-5 bg-night-900 border border-night-700 rounded-2xl">
                            <div class="flex items-start gap-3">
                                <i class="bi bi-info-circle-fill text-night-400 text-xl"></i>
                                <div>
                                    <div class="font-bold text-white mb-1">امکان ثبت نظر برای شما وجود ندارد</div>
                                    <div class="text-sm text-night-400">فقط کاربرانی که این سرویس را دریافت کرده‌اند (نوبت انجام‌شده) می‌توانند نظر بدهند.</div>
                                </div>
                            </div>
                        </div>
                        {% endif %}
                    {% else %}
                    <div class="mt-6 p-5 bg-night-900 border border-night-700 rounded-2xl">
                        <div class="flex items-start gap-3">
                            <i class="bi bi-info-circle-fill text-primary text-xl"></i>
                            <div>
                                <div class="font-bold text-white mb-1">برای ثبت نظر وارد شوید</div>
                                <div class="text-sm text-night-400">
                                    <a href="{% url 'accounts:login' %}" class="text-primary hover:underline">وارد شوید</a>
                                    یا
                                    <a href="{% url 'accounts:register' %}" class="text-primary hover:underline">ثبت‌نام کنید</a>
                                </div>
                            </div>
                        </div>
                    </div>
                    {% endif %}
                </div>

            </div>

            <!-- ============================================ -->
            <!--  SIDEBAR                                     -->
            <!-- ============================================ -->
            <div class="lg:col-span-1 space-y-6" data-aos="fade-left">
                <!-- Price card (sticky) -->
                <div class="lg:sticky lg:top-24 bg-night-800 border border-night-700 rounded-3xl shadow-2xl overflow-hidden">
                    <div class="bg-gradient-to-br from-primary to-primary-700 p-6 text-white">
                        <div class="text-sm opacity-90 mb-1">قیمت این خدمت</div>
                        <div class="text-3xl font-black">{{ service.price|price_fa }} <span class="text-sm font-normal opacity-80">تومان</span></div>
                    </div>
                    <div class="p-6 space-y-4">
                        <a href="{% url 'appointments:book' %}?service={{ service.slug }}"
                           class="flex items-center justify-center gap-2 bg-gradient-to-l from-primary to-primary-700 text-white font-black py-4 rounded-2xl shadow-lg shadow-primary/30 hover:shadow-xl hover:shadow-primary/50 hover:scale-105 transition-all">
                            <i class="bi bi-calendar2-plus-fill text-xl"></i>
                            رزرو نوبت
                        </a>

                        <a href="tel:{{ SITE_PHONE }}"
                           class="flex items-center justify-center gap-2 bg-night-700 hover:bg-night-600 text-white font-bold py-4 rounded-2xl transition">
                            <i class="bi bi-telephone-fill"></i>
                            تماس برای مشاوره
                        </a>

                        <div class="pt-4 border-t border-night-700 space-y-3 text-sm">
                            <div class="flex items-center gap-3 text-night-300">
                                <i class="bi bi-check-circle-fill text-emerald-400"></i>
                                <span>مشاوره تخصصی و حرفه‌ای</span>
                            </div>
                            <div class="flex items-center gap-3 text-night-300">
                                <i class="bi bi-check-circle-fill text-emerald-400"></i>
                                <span>محرمانگی کامل اطلاعات</span>
                            </div>
                            <div class="flex items-center gap-3 text-night-300">
                                <i class="bi bi-check-circle-fill text-emerald-400"></i>
                                <span>پیگیری پس از جلسه</span>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Share -->
                <div class="bg-night-800 border border-night-700 rounded-3xl p-6">
                    <div class="text-sm font-bold text-white mb-3">اشتراک‌گذاری</div>
                    <div class="flex gap-2">
                        <a href="#" class="w-10 h-10 rounded-xl bg-night-700 hover:bg-primary text-white flex items-center justify-center transition">
                            <i class="bi bi-telegram"></i>
                        </a>
                        <a href="#" class="w-10 h-10 rounded-xl bg-night-700 hover:bg-primary text-white flex items-center justify-center transition">
                            <i class="bi bi-whatsapp"></i>
                        </a>
                        <a href="#" class="w-10 h-10 rounded-xl bg-night-700 hover:bg-primary text-white flex items-center justify-center transition">
                            <i class="bi bi-instagram"></i>
                        </a>
                    </div>
                </div>
            </div>
        </div>

        <!-- Related -->
        {% if related %}
        <div class="mt-20" data-aos="fade-up">
            <h2 class="text-2xl font-black text-white mb-8 flex items-center gap-3">
                <span class="w-1.5 h-8 bg-accent rounded-full"></span>
                خدمات مرتبط
            </h2>
            <div class="grid md:grid-cols-3 gap-6">
                {% for item in related %}
                <a href="{% url 'service_detail' item.slug %}"
                   class="group bg-gradient-to-b from-night-800 to-night-900 rounded-3xl overflow-hidden border border-night-700 hover:border-primary/50 hover:shadow-2xl hover:shadow-primary/20 transition-all hover:-translate-y-2">
                    <div class="h-40 bg-gradient-to-br from-primary/20 to-accent/10 overflow-hidden flex items-center justify-center">
                        {% if item.image %}
                            <img src="{{ item.image.url }}" class="w-full h-full object-cover group-hover:scale-110 transition-transform duration-500">
                        {% else %}
                            <i class="bi {{ item.category.icon|default:'bi-heart-pulse' }} text-6xl text-primary/40"></i>
                        {% endif %}
                    </div>
                    <div class="p-5">
                        <h3 class="font-bold text-white mb-2 group-hover:text-primary transition">{{ item.name }}</h3>
                        <div class="flex items-center justify-between text-sm">
                            <span class="text-night-400">{{ item.duration|duration_fa }}</span>
                            <span class="font-bold text-primary">{{ item.price|price_fa }} تومان</span>
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
HTMLEOF

echo "[OK] service_detail.html"

# ------------------------------------------------------------
# 7) My Appointments - add review button
# ------------------------------------------------------------
python - << 'PYEOF'
import io, os

path = 'templates/appointments/my_appointments.html'
if os.path.exists(path):
    with io.open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # اضافه کردن دکمه ثبت نظر برای نوبت‌های completed
    if 'ثبت نظر' not in content and 'review' not in content.lower():
        # پیدا کردن جدول تاریخچه
        if '<td class="py-4 px-4">' in content:
            # جایگزینی آخرین ستون عملیات در جدول تاریخچه
            content = content.replace(
                """                                    <a href="{% url 'appointments:detail' app.pk %}" class="text-primary font-bold text-sm hover:underline">
                                        جزئیات
                                    </a>""",
                """                                    <div class="flex gap-2 items-center">
                                        <a href="{% url 'appointments:detail' app.pk %}" class="text-primary font-bold text-sm hover:underline">
                                            جزئیات
                                        </a>
                                        {% if app.status == 'completed' %}
                                            {% if app.review %}
                                                <span class="text-xs text-emerald-400 flex items-center gap-1">
                                                    <i class="bi bi-check-circle-fill"></i> نظر داده‌اید
                                                </span>
                                            {% else %}
                                                <a href="{% url 'service_detail' app.service.slug %}#reviews"
                                                   class="text-amber-400 font-bold text-sm hover:underline flex items-center gap-1">
                                                    <i class="bi bi-star-fill"></i>
                                                    ثبت نظر
                                                </a>
                                            {% endif %}
                                        {% endif %}
                                    </div>"""
            )
            with io.open(path, 'w', encoding='utf-8') as f:
                f.write(content)
            print("[OK] my_appointments.html")
PYEOF

# ------------------------------------------------------------
# 8) Add avg rating to service card in service_list
# ------------------------------------------------------------
python - << 'PYEOF'
import io, os

path = 'templates/services/service_list.html'
if os.path.exists(path):
    with io.open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # اگر بلوک امتیاز نیست، اضافه کن
    if 'average_rating' not in content and 'امتیاز' not in content.split('rating')[-1][:500]:
        # افزودن امتیاز به بالای کارت
        content = content.replace(
            """<h3 class="text-xl font-bold text-dark mb-3 group-hover:text-primary transition">{{ service.name }}</h3>""",
            """<div class="flex items-center justify-between mb-3">
                        <h3 class="text-xl font-bold text-white group-hover:text-primary transition">{{ service.name }}</h3>
                        {% if service.reviews_count > 0 %}
                        <div class="flex items-center gap-1 shrink-0">
                            <i class="bi bi-star-fill text-amber-400 text-sm"></i>
                            <span class="text-white text-sm font-bold">{{ service.average_rating }}</span>
                        </div>
                        {% endif %}
                    </div>"""
        )
        with io.open(path, 'w', encoding='utf-8') as f:
            f.write(content)
        print("[OK] service_list.html")
PYEOF

# ------------------------------------------------------------
# 9) Migration
# ------------------------------------------------------------
echo ""
echo "Running migrations..."

python manage.py makemigrations services --noinput
python manage.py migrate --noinput

echo ""
echo "======================================================"
echo "  [OK] Phase 2.2 Complete!"
echo "======================================================"
echo ""
echo "Restart server:"
echo "   python manage.py runserver"
echo ""
echo "Features added:"
echo "  * 5-star rating system"
echo "  * Verified reviews (only completed appointments)"
echo "  * Admin moderation + reply"
echo "  * Average rating on service cards"
echo "  * Rating distribution chart"
echo "  * Review form with interactive stars"
echo ""
echo "Test:"
echo "  1. Complete an appointment (admin: status -> completed)"
echo "  2. Go to /appointments/my/"
echo "  3. Click 'ثبت نظر' on completed appointment"
echo "  4. Submit rating + comment"
echo "  5. Approve in admin: /admin/services/review/"
echo "  6. See review on service page"
echo ""