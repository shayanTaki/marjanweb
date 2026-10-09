from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import CustomUser


@admin.register(CustomUser)
class CustomUserAdmin(UserAdmin):
    list_display = ('username', 'phone_number', 'first_name', 'last_name', 'is_doctor', 'is_secretary', 'is_staff')
    search_fields = ('username', 'phone_number', 'first_name', 'last_name')
    list_filter = ('is_doctor', 'is_secretary', 'is_staff', 'is_active')
