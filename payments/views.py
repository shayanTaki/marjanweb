from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth.decorators import login_required
from django.contrib import messages
from django.http import HttpResponse, JsonResponse
from django.urls import reverse
from django.utils import timezone
from django.views.decorators.http import require_GET

from .models import Payment
from .zarinpal import get_zarinpal, ZarinpalError
from .invoice import generate_invoice
from appointments.models import Appointment


@login_required
def payment_list(request):
    payments = Payment.objects.filter(user=request.user).order_by('-created_at')
    return render(request, 'payments/payment_list.html', {'payments': payments})


@login_required
def payment_detail(request, tracking_code):
    payment = get_object_or_404(Payment, tracking_code=tracking_code, user=request.user)
    return render(request, 'payments/payment_detail.html', {'payment': payment})


@login_required
def start_payment(request, appointment_id):
    """شروع فرآیند پرداخت برای یک نوبت"""
    appointment = get_object_or_404(Appointment, pk=appointment_id, user=request.user)

    if appointment.payment_status == 'paid':
        messages.info(request, 'این نوبت قبلاً پرداخت شده است.')
        return redirect('appointments:detail', pk=appointment.pk)

    amount = appointment.service.price

    # ساخت رکورد پرداخت
    payment = Payment.objects.create(
        user=request.user,
        appointment=appointment,
        amount=amount,
        status='pending',
        gateway='zarinpal',
    )

    # آدرس بازگشت
    callback_url = request.build_absolute_uri(
        reverse('payments:verify', args=[payment.tracking_code])
    )

    try:
        zp = get_zarinpal()
        result = zp.request(
            amount=int(amount),
            description=f'پرداخت نوبت {appointment.service.name}',
            callback_url=callback_url,
            email=request.user.email or '',
            mobile=request.user.phone_number or '',
        )
        payment.authority = result['authority']
        payment.save()

        return redirect(result['payment_url'])
    except ZarinpalError as e:
        payment.mark_failed(error_message=str(e))
        messages.error(request, f'خطا در اتصال به درگاه: {str(e)}')
        return redirect('appointments:detail', pk=appointment.pk)


@login_required
def verify_payment(request, tracking_code):
    """بررسی نتیجه پرداخت پس از بازگشت از درگاه"""
    payment = get_object_or_404(Payment, tracking_code=tracking_code, user=request.user)

    status = request.GET.get('Status', '')
    authority = request.GET.get('Authority', '')

    # بررسی لغو از طرف کاربر
    if status != 'OK':
        payment.mark_failed(error_message='کاربر پرداخت را لغو کرد')
        messages.warning(request, 'پرداخت لغو شد.')
        return redirect('payments:payment_detail', tracking_code=payment.tracking_code)

    # بررسی تطابق Authority
    if authority != payment.authority:
        payment.mark_failed(error_message='Authority نامطابق')
        messages.error(request, 'خطای امنیتی در تأیید پرداخت.')
        return redirect('payments:payment_detail', tracking_code=payment.tracking_code)

    # تأیید
    try:
        zp = get_zarinpal()
        result = zp.verify(int(payment.amount), authority)
        payment.mark_success(ref_id=result['ref_id'], gateway_response=str(result))
        messages.success(request, f'پرداخت با موفقیت انجام شد. شماره تراکنش: {result["ref_id"]}')
    except ZarinpalError as e:
        payment.mark_failed(error_message=str(e))
        messages.error(request, f'خطا در تأیید پرداخت: {str(e)}')

    return redirect('payments:payment_detail', tracking_code=payment.tracking_code)


@login_required
def download_invoice(request, tracking_code):
    """دانلود فاکتور PDF"""
    payment = get_object_or_404(Payment, tracking_code=tracking_code, user=request.user)

    if payment.status != 'success':
        messages.error(request, 'فقط فاکتور پرداخت‌های موفق قابل دانلود است.')
        return redirect('payments:payment_detail', tracking_code=tracking_code)

    pdf = generate_invoice(payment)
    response = HttpResponse(pdf, content_type='application/pdf')
    response['Content-Disposition'] = f'attachment; filename="invoice-{payment.tracking_code}.pdf"'
    return response


@login_required
def payment_result(request):
    """صفحه نتیجه پرداخت (اگر callback ورودی نداشتیم)"""
    return render(request, 'payments/result.html')
