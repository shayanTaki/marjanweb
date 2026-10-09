from django.urls import path
from . import views

app_name = 'appointments'

urlpatterns = [
    path('book/', views.book_appointment, name='book'),
    path('confirm/', views.confirm_booking, name='confirm'),
    path('my/', views.my_appointments, name='my_appointments'),
    path('detail/<int:pk>/', views.appointment_detail, name='detail'),
    path('cancel/<int:pk>/', views.cancel_appointment, name='cancel'),
    # API
    path('api/calendar/', views.api_calendar, name='api_calendar'),
    path('api/slots/', views.api_slots, name='api_slots'),
]
