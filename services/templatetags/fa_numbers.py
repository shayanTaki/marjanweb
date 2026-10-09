# -*- coding: utf-8 -*-
"""Template filters for Persian numbers and currency"""
from django import template
from decimal import Decimal, InvalidOperation

register = template.Library()

PERSIAN_DIGITS = '\u06f0\u06f1\u06f2\u06f3\u06f4\u06f5\u06f6\u06f7\u06f8\u06f9'
ENGLISH_DIGITS = '0123456789'
TRANS_TABLE = str.maketrans(ENGLISH_DIGITS, PERSIAN_DIGITS)


@register.filter(name='to_fa')
def to_fa(value):
    """تبدیل اعداد انگلیسی به فارسی"""
    if value is None or value == '':
        return ''
    try:
        return str(value).translate(TRANS_TABLE)
    except Exception:
        return str(value)


@register.filter(name='price_fa')
def price_fa(value):
    """تبدیل عدد به قیمت فارسی با جداکننده هزارگان"""
    if value is None or value == '':
        return ''
    try:
        n = int(value)
    except (ValueError, TypeError, InvalidOperation):
        try:
            n = int(float(value))
        except Exception:
            return str(value)
    # جداکننده هزارگان با کاما
    formatted = f"{n:,}"
    return formatted.translate(TRANS_TABLE)


@register.filter(name='duration_fa')
def duration_fa(value):
    """نمایش مدت زمان به فارسی: ۶۰ دقیقه"""
    if not value:
        return ''
    return f"{str(value).translate(TRANS_TABLE)} \u062f\u0642\u06cc\u0642\u0647"


@register.filter(name='years_fa')
def years_fa(value):
    """نمایش سال تجربه: ۱۵ سال تجربه"""
    if not value:
        return ''
    return f"{str(value).translate(TRANS_TABLE)} \u0633\u0627\u0644 \u062a\u062c\u0631\u0628\u0647"


@register.filter(name='digits_fa')
def digits_fa(value):
    """همان to_fa برای fallback"""
    return to_fa(value)
