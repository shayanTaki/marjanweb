from django.contrib.admin import AdminSite
from django.utils import timezone
from datetime import timedelta


class CustomAdminSite(AdminSite):
    site_header = 'مرجان آرام'
    site_title = 'پنل مدیریت مرجان آرام'
    index_title = 'داشبورد مدیریت'

    def each_context(self, request):
        context = super().each_context(request)

        if request.path.rstrip('/').endswith('/admin') or request.path.rstrip('/').endswith('/admin/index'):
            try:
                from accounts.models import CustomUser
                from appointments.models import Appointment, Staff
                from services.models import Service, Review, Article
                from payments.models import Payment
                from django.db.models import Sum

                today = timezone.now().date()
                week_ago = today - timedelta(days=7)
                month_start = today.replace(day=1)

                context['admin_stats'] = {
                    'users': CustomUser.objects.count(),
                    'users_week': CustomUser.objects.filter(date_joined__gte=week_ago).count(),
                    'appointments': Appointment.objects.count(),
                    'appointments_today': Appointment.objects.filter(date=today).count(),
                    'appointments_pending': Appointment.objects.filter(status='pending').count(),
                    'appointments_week': Appointment.objects.filter(created_at__gte=week_ago).count(),
                    'revenue': Payment.objects.filter(status='success').aggregate(s=Sum('amount'))['s'] or 0,
                    'revenue_month': Payment.objects.filter(
                        status='success', paid_at__gte=month_start
                    ).aggregate(s=Sum('amount'))['s'] or 0,
                    'reviews': Review.objects.count(),
                    'reviews_pending': Review.objects.filter(status='pending').count(),
                    'services': Service.objects.count(),
                    'articles': Article.objects.count(),
                    'staff': Staff.objects.count(),
                }

                # نمودار نوبت‌ها ۷ روز اخیر
                chart_data = []
                for i in range(6, -1, -1):
                    d = today - timedelta(days=i)
                    count = Appointment.objects.filter(created_at__date=d).count()
                    chart_data.append({
                        'label': d.strftime('%m/%d'),
                        'value': count,
                    })
                context['admin_chart_data'] = chart_data

                context['admin_recent_appointments'] = Appointment.objects.select_related(
                    'user', 'service', 'staff__user'
                ).order_by('-created_at')[:6]

                context['admin_recent_payments'] = Payment.objects.filter(
                    status='success'
                ).select_related('user').order_by('-paid_at')[:5]

                context['admin_recent_reviews'] = Review.objects.filter(
                    status='pending'
                ).select_related('user', 'service').order_by('-created_at')[:5]

            except Exception as e:
                context['admin_stats_error'] = str(e)

        return context
