from django import forms
from .models import Appointment


class AppointmentNotesForm(forms.ModelForm):
    class Meta:
        model = Appointment
        fields = ['notes']
        widgets = {
            'notes': forms.Textarea(attrs={
                'rows': 4,
                'placeholder': 'اگر توضیح یا نکته خاصی دارید اینجا بنویسید...',
                'class': 'booking-input',
            }),
        }


class CancelForm(forms.Form):
    reason = forms.CharField(
        label='دلیل لغو',
        required=False,
        widget=forms.Textarea(attrs={
            'rows': 3,
            'placeholder': 'دلیل لغو نوبت (اختیاری)',
            'class': 'booking-input',
        }),
    )
