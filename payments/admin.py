from django.contrib import admin
from django.utils.html import format_html
from .models import Payment


@admin.register(Payment)
class PaymentAdmin(admin.ModelAdmin):
    list_display = (
        'tracking_code', 'user_link', 'amount_display',
        'status_badge', 'gateway', 'created_at', 'paid_at',
    )
    list_filter = ('status', 'gateway', 'created_at')
    search_fields = ('tracking_code', 'ref_id', 'authority', 'user__username', 'user__phone_number')
    date_hierarchy = 'created_at'
    readonly_fields = ('tracking_code', 'authority', 'ref_id', 'gateway_response', 'created_at', 'updated_at', 'paid_at')

    fieldsets = (
        ('شناسه‌ها', {
            'fields': ('tracking_code', 'authority', 'ref_id')
        }),
        ('اطلاعات اصلی', {
            'fields': ('user', 'appointment', 'amount', 'status', 'gateway')
        }),
        ('پاسخ درگاه', {
            'fields': ('gateway_response', 'error_message'),
            'classes': ('collapse',)
        }),
        ('زمان‌ها', {
            'fields': ('created_at', 'paid_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )

    @admin.display(description='کاربر')
    def user_link(self, obj):
        return obj.user.get_full_name() or obj.user.username

    @admin.display(description='مبلغ')
    def amount_display(self, obj):
        return f'{obj.amount:,.0f} تومان'

    @admin.display(description='وضعیت')
    def status_badge(self, obj):
        colors = {
            'pending': '#f59e0b',
            'success': '#10b981',
            'failed': '#ef4444',
            'cancelled': '#64748b',
            'refunded': '#8b5cf6',
        }
        return format_html(
            '<span style="background:{};color:white;padding:4px 10px;border-radius:20px;font-size:12px">{}</span>',
            colors.get(obj.status, '#999'),
            obj.get_status_display(),
        )
