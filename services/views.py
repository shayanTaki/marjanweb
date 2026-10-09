from django.shortcuts import render, get_object_or_404, redirect
from django.contrib import messages
from django.contrib.auth.decorators import login_required
from django.db.models import F, Q, Avg
from django.core.paginator import Paginator
from django.http import JsonResponse
from django.views.decorators.http import require_POST

from .models import (
    ServiceCategory, Service, Package, Article,
    ContactMessage, NewsletterSubscriber, Review,
)
from .forms import ContactForm, NewsletterForm, ReviewForm
from appointments.models import Appointment


def home(request):
    categories = ServiceCategory.objects.all()[:6]
    featured_services = Service.objects.filter(is_active=True, is_featured=True)[:6]
    if not featured_services:
        featured_services = Service.objects.filter(is_active=True)[:6]
    articles = Article.objects.filter(is_published=True)[:3]
    packages = Package.objects.filter(is_active=True, is_featured=True)[:3]
    if not packages:
        packages = Package.objects.filter(is_active=True)[:3]

    return render(request, 'home.html', {
        'categories': categories,
        'services': featured_services,
        'articles': articles,
        'packages': packages,
    })


def about(request):
    return render(request, 'about.html')


def contact(request):
    if request.method == 'POST':
        form = ContactForm(request.POST)
        if form.is_valid():
            form.save()
            messages.success(request, 'پیام شما با موفقیت ارسال شد.')
            return redirect('contact')
        else:
            messages.error(request, 'لطفاً خطاهای فرم را برطرف کنید.')
    else:
        form = ContactForm()
    return render(request, 'contact.html', {'form': form})


def service_list(request):
    categories = ServiceCategory.objects.prefetch_related('services').all()
    selected_category = request.GET.get('category')
    search = request.GET.get('q', '').strip()

    services = Service.objects.filter(is_active=True).select_related('category')

    if selected_category:
        services = services.filter(category__slug=selected_category)

    if search:
        services = services.filter(
            Q(name__icontains=search) |
            Q(short_description__icontains=search) |
            Q(description__icontains=search)
        )

    return render(request, 'services/service_list.html', {
        'categories': categories,
        'services': services,
        'selected_category': selected_category,
        'search': search,
    })


def service_detail(request, slug):
    service = get_object_or_404(Service, slug=slug, is_active=True)
    related = Service.objects.filter(
        category=service.category, is_active=True
    ).exclude(pk=service.pk)[:3]

    # reviews
    reviews_qs = service.reviews.filter(is_approved=True).select_related('user').order_by('-created_at')
    reviews = reviews_qs[:10]
    total_reviews = reviews_qs.count()

    # avg
    avg = reviews_qs.aggregate(avg=Avg('rating'))['avg'] or 0

    # distribution
    dist = {i: 0 for i in range(1, 6)}
    for r in reviews_qs.values('rating'):
        dist[r['rating']] += 1

    # آیا کاربر فعلی می‌تواند نظر بدهد؟
    can_review = False
    user_review = None
    review_form = None
    if request.user.is_authenticated:
        # بررسی نوبت انجام‌شده
        has_completed = Appointment.objects.filter(
            user=request.user,
            service=service,
            status='completed',
        ).exists()
        user_review = Review.objects.filter(user=request.user, service=service).first()
        can_review = has_completed and not user_review
        if can_review:
            review_form = ReviewForm()

    return render(request, 'services/service_detail.html', {
        'service': service,
        'related': related,
        'reviews': reviews,
        'total_reviews': total_reviews,
        'avg_rating': round(avg, 1),
        'rating_distribution': dist,
        'can_review': can_review,
        'user_review': user_review,
        'review_form': review_form,
    })


def package_list(request):
    packages = Package.objects.filter(is_active=True)
    return render(request, 'services/package_list.html', {'packages': packages})


def package_detail(request, slug):
    package = get_object_or_404(Package, slug=slug, is_active=True)
    return render(request, 'services/package_detail.html', {'package': package})


def article_list(request):
    articles = Article.objects.filter(is_published=True)
    search = request.GET.get('q', '').strip()
    if search:
        articles = articles.filter(
            Q(title__icontains=search) | Q(summary__icontains=search) | Q(content__icontains=search)
        )
    paginator = Paginator(articles, 9)
    page_obj = paginator.get_page(request.GET.get('page', 1))
    return render(request, 'services/article_list.html', {
        'articles': page_obj,
        'page_obj': page_obj,
        'search': search,
    })


def article_detail(request, slug):
    article = get_object_or_404(Article, slug=slug, is_published=True)
    Article.objects.filter(pk=article.pk).update(views=F('views') + 1)
    related = Article.objects.filter(is_published=True).exclude(pk=article.pk)[:3]
    return render(request, 'services/article_detail.html', {
        'article': article,
        'related': related,
    })


def newsletter_subscribe(request):
    if request.method == 'POST':
        form = NewsletterForm(request.POST)
        if form.is_valid():
            email = form.cleaned_data['email']
            obj, created = NewsletterSubscriber.objects.get_or_create(email=email)
            if created:
                messages.success(request, 'عضویت شما در خبرنامه ثبت شد.')
            else:
                messages.info(request, 'این ایمیل قبلاً عضو شده است.')
        else:
            messages.error(request, 'ایمیل معتبر نیست.')
    return redirect(request.META.get('HTTP_REFERER', 'home'))


# ============================================================
#  REVIEW VIEWS
# ============================================================

@login_required
@require_POST
def submit_review(request, slug):
    """ثبت نظر جدید — فقط برای کاربران با نوبت completed"""
    service = get_object_or_404(Service, slug=slug, is_active=True)

    # بررسی: آیا این کاربر می‌تواند نظر بدهد؟
    appointment = Appointment.objects.filter(
        user=request.user,
        service=service,
        status='completed',
    ).order_by('-date').first()

    if not appointment:
        messages.error(request, 'فقط کاربرانی که این سرویس را دریافت کرده‌اند می‌توانند نظر بدهند.')
        return redirect('service_detail', slug=slug)

    if Review.objects.filter(user=request.user, service=service).exists():
        messages.warning(request, 'شما قبلاً برای این سرویس نظر داده‌اید.')
        return redirect('service_detail', slug=slug)

    form = ReviewForm(request.POST)
    if form.is_valid():
        review = form.save(commit=False)
        review.user = request.user
        review.service = service
        review.appointment = appointment
        review.status = 'pending'
        review.is_approved = False
        review.save()
        messages.success(request, 'نظر شما ثبت شد و پس از تأیید نمایش داده می‌شود. سپاسگزاریم! 🌟')
    else:
        messages.error(request, 'لطفاً امتیاز و نظر خود را به‌درستی وارد کنید.')

    return redirect('service_detail', slug=slug)


def reviews_list_api(request, slug):
    """API برای دریافت نظرات با فیلتر"""
    service = get_object_or_404(Service, slug=slug, is_active=True)
    rating_filter = request.GET.get('rating')
    page = int(request.GET.get('page', 1))

    qs = service.reviews.filter(is_approved=True).select_related('user').order_by('-created_at')
    if rating_filter and rating_filter.isdigit():
        qs = qs.filter(rating=int(rating_filter))

    paginator = Paginator(qs, 10)
    page_obj = paginator.get_page(page)

    data = {
        'reviews': [
            {
                'id': r.id,
                'user': r.user.get_full_name() or r.user.username,
                'initial': r.user_initial(),
                'rating': r.rating,
                'comment': r.comment,
                'admin_reply': r.admin_reply,
                'created_at': r.created_at.strftime('%Y/%m/%d'),
                'is_verified': bool(r.appointment),
            }
            for r in page_obj
        ],
        'has_next': page_obj.has_next(),
        'total': paginator.count,
    }
    return JsonResponse(data)


def custom_404(request, exception):
    return render(request, '404.html', status=404)


def custom_500(request):
    return render(request, '500.html', status=500)
