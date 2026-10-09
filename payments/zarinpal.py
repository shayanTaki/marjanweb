"""
کلاینت زرین‌پال - پشتیبانی از Sandbox و Production
مستندات: https://docs.zarinpal.com/
"""
import requests
from django.conf import settings


class ZarinpalError(Exception):
    pass


class Zarinpal:
    SANDBOX_BASE = 'https://sandbox.zarinpal.com'
    PRODUCTION_BASE = 'https://payment.zarinpal.com'
    SANDBOX_PG = 'https://sandbox.zarinpal.com/pg/StartPay/'
    PRODUCTION_PG = 'https://payment.zarinpal.com/pg/StartPay/'

    def __init__(self):
        self.merchant_id = getattr(settings, 'ZARINPAL_MERCHANT_ID', '') or '00000000-0000-0000-0000-000000000000'
        self.sandbox = getattr(settings, 'ZARINPAL_SANDBOX', True)
        self.base = self.SANDBOX_BASE if self.sandbox else self.PRODUCTION_BASE
        self.pg_base = self.SANDBOX_PG if self.sandbox else self.PRODUCTION_PG

    def request(self, amount, description, callback_url, email='', mobile=''):
        """
        درخواست پرداخت
        return: {'authority': '...', 'payment_url': '...'}
        """
        url = self.base + '/pg/rest/WebGate/PaymentRequest.json'
        data = {
            'MerchantID': self.merchant_id,
            'Amount': int(amount),
            'Description': description,
            'CallbackURL': callback_url,
        }
        if email:
            data['Email'] = email
        if mobile:
            data['Mobile'] = mobile

        try:
            res = requests.post(url, json=data, timeout=15)
            res.raise_for_status()
            result = res.json()
        except requests.RequestException as e:
            raise ZarinpalError(f'خطا در ارتباط با درگاه: {str(e)}')

        status = result.get('Status')
        if status == 100:
            authority = result.get('Authority')
            return {
                'authority': authority,
                'payment_url': self.pg_base + authority,
            }
        else:
            raise ZarinpalError(f'خطای درگاه زرین‌پال (کد {status})')

    def verify(self, amount, authority):
        """
        تأیید پرداخت
        return: {'ref_id': '...', 'card_pan': '...'}
        """
        url = self.base + '/pg/rest/WebGate/PaymentVerification.json'
        data = {
            'MerchantID': self.merchant_id,
            'Amount': int(amount),
            'Authority': authority,
        }

        try:
            res = requests.post(url, json=data, timeout=15)
            res.raise_for_status()
            result = res.json()
        except requests.RequestException as e:
            raise ZarinpalError(f'خطا در ارتباط با درگاه: {str(e)}')

        status = result.get('Status')
        if status in (100, 101):
            return {
                'ref_id': str(result.get('RefID', '')),
                'card_pan': result.get('CardPan', ''),
                'status': status,
            }
        else:
            raise ZarinpalError(f'پرداخت تأیید نشد (کد {status})')


def get_zarinpal():
    return Zarinpal()
