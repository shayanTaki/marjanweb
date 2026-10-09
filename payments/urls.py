from django.urls import path
from . import views

app_name = 'payments'

urlpatterns = [
    path('', views.payment_list, name='payment_list'),
    path('start/<int:appointment_id>/', views.start_payment, name='start_payment'),
    path('verify/<str:tracking_code>/', views.verify_payment, name='verify'),
    path('detail/<str:tracking_code>/', views.payment_detail, name='payment_detail'),
    path('invoice/<str:tracking_code>/', views.download_invoice, name='invoice'),
    path('result/', views.payment_result, name='result'),
]
