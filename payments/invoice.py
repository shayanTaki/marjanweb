"""تولید فاکتور PDF با ReportLab - پشتیبانی فارسی"""
import io
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.units import mm
from reportlab.pdfgen import canvas
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from django.conf import settings
from pathlib import Path

# تلاش برای رجیستر فونت فارسی
FONT_NAME = 'Helvetica'

def _try_register_persian_font():
    global FONT_NAME
    # فونت‌های رایج در سیستم
    candidates = [
        '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
        'C:/Windows/Fonts/tahoma.ttf',
        '/System/Library/Fonts/Supplemental/Tahoma.ttf',
        '/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf',
    ]
    for path in candidates:
        if Path(path).exists():
            try:
                pdfmetrics.registerFont(TTFont('PersianFont', path))
                FONT_NAME = 'PersianFont'
                return
            except Exception:
                continue

_try_register_persian_font()


def _fa(text):
    """تبدیل ارقام انگلیسی به فارسی (ساده)"""
    if text is None:
        return ''
    return str(text)


def generate_invoice(payment):
    """فاکتور PDF - برگشت به‌صورت bytes"""
    buffer = io.BytesIO()
    c = canvas.Canvas(buffer, pagesize=A4)
    width, height = A4

    # پس‌زمینه هدر
    c.setFillColor(colors.HexColor('#2B6CF5'))
    c.rect(0, height - 80, width, 80, fill=1, stroke=0)

    # عنوان
    c.setFillColor(colors.white)
    c.setFont(FONT_NAME, 22)
    c.drawCentredString(width / 2, height - 45, 'Marjan Aram Clinic')
    c.setFont(FONT_NAME, 12)
    c.drawCentredString(width / 2, height - 62, 'Invoice / Receipt')

    # اطلاعات فاکتور
    c.setFillColor(colors.black)
    c.setFont(FONT_NAME, 11)

    y = height - 120
    c.drawString(50, y, f'Tracking Code: {payment.tracking_code}')
    c.drawString(50, y - 18, f'Date: {payment.created_at.strftime("%Y-%m-%d %H:%M")}')
    c.drawString(50, y - 36, f'Status: {payment.get_status_display()}')

    # خط جداکننده
    c.setStrokeColor(colors.HexColor('#e2e8f0'))
    c.line(50, y - 50, width - 50, y - 50)

    # اطلاعات مشتری
    y -= 80
    c.setFont(FONT_NAME, 12)
    c.setFillColor(colors.HexColor('#2B6CF5'))
    c.drawString(50, y, 'Customer Information')
    c.setFillColor(colors.black)
    c.setFont(FONT_NAME, 10)
    y -= 20
    c.drawString(50, y, f'Name: {payment.user.get_full_name() or payment.user.username}')
    c.drawString(50, y - 15, f'Phone: {payment.user.phone_number or "-"}')
    c.drawString(50, y - 30, f'Email: {payment.user.email or "-"}')

    # جدول خدمات
    y -= 70
    c.setFillColor(colors.HexColor('#2B6CF5'))
    c.setFont(FONT_NAME, 12)
    c.drawString(50, y, 'Service Details')

    # هدر جدول
    y -= 25
    c.setFillColor(colors.HexColor('#f1f5f9'))
    c.rect(50, y - 5, width - 100, 22, fill=1, stroke=0)

    c.setFillColor(colors.black)
    c.setFont(FONT_NAME, 10)
    c.drawString(60, y, 'Description')
    c.drawString(350, y, 'Date')
    c.drawString(450, y, 'Amount')

    # ردیف جدول
    y -= 30
    if payment.appointment:
        app = payment.appointment
        c.drawString(60, y, app.service.name[:35])
        c.drawString(350, y, str(app.date))
    else:
        c.drawString(60, y, 'Payment')
        c.drawString(350, y, '-')
    c.drawString(450, y, f'{payment.amount:,.0f} T')

    # خط پایین
    c.setStrokeColor(colors.HexColor('#e2e8f0'))
    c.line(50, y - 10, width - 50, y - 10)

    # مبلغ کل
    y -= 45
    c.setFillColor(colors.HexColor('#2B6CF5'))
    c.setFont(FONT_NAME, 14)
    c.drawString(350, y, 'Total:')
    c.drawString(450, y, f'{payment.amount:,.0f} Toman')

    # اطلاعات تراکنش
    if payment.ref_id:
        y -= 60
        c.setFillColor(colors.black)
        c.setFont(FONT_NAME, 10)
        c.drawString(50, y, f'Ref ID: {payment.ref_id}')
        c.drawString(50, y - 15, f'Gateway: {payment.get_gateway_display()}')

    # فوتر
    c.setFillColor(colors.HexColor('#64748b'))
    c.setFont(FONT_NAME, 9)
    c.drawCentredString(width / 2, 40, 'Marjan Aram Clinic - Counseling & Psychology Center')
    c.drawCentredString(width / 2, 25, 'Tehran, Iran  |  Phone: 09016828512')

    c.showPage()
    c.save()

    pdf = buffer.getvalue()
    buffer.close()
    return pdf
