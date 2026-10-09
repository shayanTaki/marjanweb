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
