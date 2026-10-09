from django.urls import path
from . import views

app_name = 'dashboard'

urlpatterns = [
    path('', views.home, name='home'),
    path('calendar/', views.calendar_view, name='calendar'),
    path('appointments/', views.appointments_list, name='appointments'),
    path('appointments/add/', views.add_appointment_manual, name='add_appointment'),
    path('appointments/<int:pk>/status/', views.change_appointment_status, name='change_status'),
    path('appointments/<int:pk>/time/', views.update_appointment_time, name='update_time'),
    path('block-time/', views.block_time, name='block_time'),
    path('payments/', views.payments_list, name='payments'),
    path('api/day/', views.api_day_appointments, name='api_day'),
]
