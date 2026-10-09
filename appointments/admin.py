from django.contrib import admin
from django.utils.html import format_html
from .models import Staff, WorkingHours, Holiday, BlockedTime, Appointment


@admin.register(Staff)
class StaffAdmin(admin.ModelAdmin):
    list_display = ('user', 'experience_years', 'is_available', 'order')
    list_filter = ('is_available',)
    filter_horizontal = ('specialties',)
    list_editable = ('is_available', 'order')


@admin.register(WorkingHours)
class WorkingHoursAdmin(admin.ModelAdmin):
    list_display = ('staff', 'weekday', 'start_time', 'end_time', 'is_active')
    list_filter = ('staff', 'weekday', 'is_active')
    list_editable = ('is_active',)


@admin.register(Holiday)
class HolidayAdmin(admin.ModelAdmin):
    list_display = ('date', 'title', 'is_full_day', 'start_time', 'end_time')
    list_filter = ('is_full_day',)
    search_fields = ('title',)


@admin.register(BlockedTime)
class BlockedTimeAdmin(admin.ModelAdmin):
    list_display = ('staff', 'start_datetime', 'end_datetime', 'reason')
    list_filter = ('staff',)
    date_hierarchy = 'start_datetime'


@admin.register(Appointment)
class AppointmentAdmin(admin.ModelAdmin):
    list_display = ('id', 'user_link', 'staff', 'service', 'jalali_date', 'time_range', 'status_badge', 'created_at')
    list_filter = ('status', 'date', 'staff', 'service')
    search_fields = ('user__username', 'user__phone_number', 'user__first_name', 'user__last_name', 'service__name')
    date_hierarchy = 'date'
    readonly_fields = ('created_at', 'updated_at')
    list_editable = ('staff',)
    actions = ['mark_confirmed', 'mark_completed', 'mark_cancelled']

    fieldsets = (
        ('اطلاعات اصلی', {
            'fields': ('user', 'staff', 'service', 'status')
        }),
        ('زمان', {
            'fields': ('date', 'start_time', 'end_time')
        }),
        ('یادداشت‌ها', {
            'fields': ('notes', 'staff_notes', 'cancel_reason')
        }),
        ('تاریخ ثبت', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )

    @admin.display(description='کاربر')
    def user_link(self, obj):
        return f"{obj.user.get_full_name() or obj.user.username}"

    @admin.display(description='تاریخ')
    def jalali_date(self, obj):
        j = obj.get_jalali_date()
        return f"{j.year}/{j.month:02d}/{j.day:02d}"

    @admin.display(description='ساعت')
    def time_range(self, obj):
        return f"{obj.start_time.strftime('%H:%M')} - {obj.end_time.strftime('%H:%M')}"

    @admin.display(description='وضعیت')
    def status_badge(self, obj):
        colors = {
            'pending': '#f59e0b',
            'confirmed': '#10b981',
            'cancelled': '#ef4444',
            'completed': '#3b82f6',
            'no_show': '#64748b',
        }
        return format_html(
            '<span style="background:{};color:white;padding:4px 10px;border-radius:20px;font-size:12px">{}</span>',
            colors.get(obj.status, '#999'),
            obj.get_status_display(),
        )

    @admin.action(description='تأیید نوبت‌های انتخاب شده')
    def mark_confirmed(self, request, queryset):
        n = queryset.update(status='confirmed')
        self.message_user(request, f'{n} نوبت تأیید شد.')

    @admin.action(description='علامت‌گذاری به‌عنوان انجام شده')
    def mark_completed(self, request, queryset):
        n = queryset.update(status='completed')
        self.message_user(request, f'{n} نوبت انجام شده شد.')

    @admin.action(description='لغو نوبت‌های انتخاب شده')
    def mark_cancelled(self, request, queryset):
        n = queryset.update(status='cancelled')
        self.message_user(request, f'{n} نوبت لغو شد.')
