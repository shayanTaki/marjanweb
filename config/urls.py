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
