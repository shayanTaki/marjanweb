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
