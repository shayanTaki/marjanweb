from django.conf import settings
from .models import ServiceCategory


def site_settings(request):
    # خواندن تم از کوکی (اگر وجود دارد)
    theme = request.COOKIES.get('theme', 'light')
    return {
        'SITE_NAME': getattr(settings, 'SITE_NAME', 'Marjan Aram'),
        'SITE_PHONE': getattr(settings, 'SITE_PHONE', ''),
        'SITE_ADDRESS': getattr(settings, 'SITE_ADDRESS', ''),
        'nav_categories': ServiceCategory.objects.prefetch_related('services').all()[:8],
        'current_theme': theme,
    }
