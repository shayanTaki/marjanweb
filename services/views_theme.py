from django.http import JsonResponse
from django.views.decorators.http import require_POST
from django.views.decorators.csrf import csrf_exempt
import json


@csrf_exempt
@require_POST
def set_theme(request):
    """ذخیره تم کاربر در کوکی"""
    try:
        data = json.loads(request.body)
        theme = data.get('theme', 'light')
        if theme not in ('light', 'dark', 'system'):
            return JsonResponse({'ok': False, 'error': 'invalid theme'}, status=400)
    except (json.JSONDecodeError, AttributeError):
        return JsonResponse({'ok': False, 'error': 'invalid json'}, status=400)

    response = JsonResponse({'ok': True, 'theme': theme})
    response.set_cookie(
        'theme', theme,
        max_age=60 * 60 * 24 * 365,
        samesite='Lax',
    )
    return response
