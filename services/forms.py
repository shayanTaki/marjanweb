from django import forms
from .models import ContactMessage, NewsletterSubscriber, Review


class ContactForm(forms.ModelForm):
    class Meta:
        model = ContactMessage
        fields = ['name', 'phone', 'email', 'subject', 'message']
        widgets = {
            'name': forms.TextInput(attrs={'class': 'form-input', 'placeholder': 'نام و نام خانوادگی'}),
            'phone': forms.TextInput(attrs={'class': 'form-input', 'placeholder': '۰۹۱۲۳۴۵۶۷۸۹', 'dir': 'ltr'}),
            'email': forms.EmailInput(attrs={'class': 'form-input', 'placeholder': 'example@mail.com', 'dir': 'ltr'}),
            'subject': forms.TextInput(attrs={'class': 'form-input', 'placeholder': 'موضوع'}),
            'message': forms.Textarea(attrs={'class': 'form-input', 'rows': 5, 'placeholder': 'متن پیام...'}),
        }


class NewsletterForm(forms.ModelForm):
    class Meta:
        model = NewsletterSubscriber
        fields = ['email']
        widgets = {
            'email': forms.EmailInput(attrs={
                'class': 'newsletter-input',
                'placeholder': 'ایمیل خود را وارد کنید',
                'dir': 'ltr',
            }),
        }


class ReviewForm(forms.ModelForm):
    rating = forms.ChoiceField(
        choices=[(i, f'{i} ستاره') for i in range(1, 6)],
        widget=forms.RadioSelect(attrs={'class': 'star-rating-input'}),
        label='امتیاز شما',
    )

    class Meta:
        model = Review
        fields = ['rating', 'comment']
        widgets = {
            'comment': forms.Textarea(attrs={
                'class': 'form-input',
                'rows': 4,
                'placeholder': 'تجربه خود را با دیگران به اشتراک بگذارید... (اختیاری)',
            }),
        }
        labels = {
            'comment': 'نظر شما',
        }
