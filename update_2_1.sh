#!/bin/bash
# ============================================================
#  Redesign - Single Dark Theme + Prominent Booking CTA
# ============================================================

set -e

if [ ! -f "manage.py" ]; then
    echo "ERROR: run in project root"
    exit 1
fi

echo "Redesigning site with dark theme..."

# ------------------------------------------------------------
# 1) base.html - Dark only, no theme toggle
# ------------------------------------------------------------
cat > templates/base.html << 'HTMLEOF'
{% load static %}
<!DOCTYPE html>
<html lang="fa" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{% block title %}{{ SITE_NAME }}{% endblock %}</title>
    <meta name="description" content="{% block meta_desc %}مرکز مشاوره و روانشناسی دکتر مرجان آرام{% endblock %}">

    <script src="https://cdn.tailwindcss.com"></script>
    <script>
        tailwind.config = {
            theme: {
                extend: {
                    fontFamily: { sans: ['Vazirmatn', 'sans-serif'] },
                    colors: {
                        primary: {
                            DEFAULT: '#3B82F6',
                            50:  '#EFF6FF',
                            100: '#DBEAFE',
                            300: '#93C5FD',
                            500: '#3B82F6',
                            600: '#2563EB',
                            700: '#1D4ED8',
                            900: '#1E3A8A',
                        },
                        accent: {
                            DEFAULT: '#F59E0B',
                            500: '#F59E0B',
                            600: '#D97706',
                        },
                        night: {
                            50:  '#F8FAFC',
                            100: '#E2E8F0',
                            200: '#CBD5E1',
                            300: '#94A3B8',
                            400: '#64748B',
                            500: '#475569',
                            600: '#334155',
                            700: '#1E293B',
                            800: '#131C31',
                            900: '#0A0E1F',
                            950: '#050813',
                        },
                    },
                    animation: {
                        'float': 'float 6s ease-in-out infinite',
                        'pulse-slow': 'pulse 4s cubic-bezier(0.4, 0, 0.6, 1) infinite',
                        'glow': 'glow 2s ease-in-out infinite alternate',
                    },
                    keyframes: {
                        float: {
                            '0%, 100%': { transform: 'translateY(0)' },
                            '50%': { transform: 'translateY(-20px)' },
                        },
                        glow: {
                            '0%':   { boxShadow: '0 0 20px rgba(59, 130, 246, 0.3)' },
                            '100%': { boxShadow: '0 0 40px rgba(59, 130, 246, 0.6)' },
                        },
                    },
                }
            }
        }
    </script>

    <link href="https://cdn.jsdelivr.net/gh/rastikerdar/vazirmatn@v33.003/Vazirmatn-font-face.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
    <link href="https://unpkg.com/aos@2.3.1/dist/aos.css" rel="stylesheet">

    <link rel="stylesheet" href="{% static 'css/style.css' %}">
    <link rel="stylesheet" href="{% static 'css/dark-theme.css' %}">

    {% block extra_css %}{% endblock %}
</head>
<body class="font-sans antialiased bg-night-900 text-night-100">

    {% include 'partials/header.html' %}

    {% if messages %}
        <div class="fixed top-24 left-1/2 -translate-x-1/2 z-[100] w-full max-w-md px-4 space-y-2">
            {% for message in messages %}
                <div x-data="{show:true}" x-show="show" x-init="setTimeout(()=>show = false, 5000)"
                     x-transition:enter="transition ease-out duration-300"
                     x-transition:enter-start="opacity-0 -translate-y-4"
                     class="rounded-2xl shadow-2xl backdrop-blur-lg bg-night-800/95 border border-night-600 p-4 flex items-start gap-3">
                    <div class="shrink-0">
                        {% if message.tags == 'success' %}
                            <i class="bi bi-check-circle-fill text-2xl text-emerald-400"></i>
                        {% elif message.tags == 'error' %}
                            <i class="bi bi-x-circle-fill text-2xl text-red-400"></i>
                        {% elif message.tags == 'warning' %}
                            <i class="bi bi-exclamation-triangle-fill text-2xl text-amber-400"></i>
                        {% else %}
                            <i class="bi bi-info-circle-fill text-2xl text-blue-400"></i>
                        {% endif %}
                    </div>
                    <p class="flex-1 text-sm font-medium text-night-100">{{ message }}</p>
                    <button @click="show=false" class="text-night-400 hover:text-white">
                        <i class="bi bi-x-lg"></i>
                    </button>
                </div>
            {% endfor %}
        </div>
    {% endif %}

    <main class="min-h-screen">
        {% block content %}{% endblock %}
    </main>

    {% include 'partials/footer.html' %}

    <!-- Scroll to top -->
    <button id="scrollToTop" class="fixed bottom-24 lg:bottom-6 left-6 w-12 h-12 rounded-full bg-night-700 hover:bg-primary text-white shadow-2xl transition-all opacity-0 invisible z-40">
        <i class="bi bi-arrow-up text-xl"></i>
    </button>

    <!-- ============================================== -->
    <!-- Sticky Booking CTA - Only on mobile + non-booking pages -->
    <!-- ============================================== -->
    {% block sticky_booking %}
    <div class="lg:hidden fixed bottom-0 inset-x-0 z-50 p-3 bg-night-900/95 backdrop-blur-xl border-t border-night-700">
        <a href="{% url 'appointments:book' %}"
           class="flex items-center justify-center gap-3 w-full bg-gradient-to-l from-primary to-primary-700 text-white font-black text-lg py-4 rounded-2xl shadow-2xl shadow-primary/40 animate-glow active:scale-95 transition-transform">
            <i class="bi bi-calendar2-plus-fill text-2xl"></i>
            <span>رزرو نوبت آنلاین</span>
            <i class="bi bi-arrow-left text-xl"></i>
        </a>
    </div>
    {% endblock %}

    <script src="https://unpkg.com/aos@2.3.1/dist/aos.js"></script>
    <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js"></script>

    <script>
        AOS.init({ duration: 800, once: true, offset: 50 });
        document.addEventListener('DOMContentLoaded', () => {
            const btn = document.getElementById('scrollToTop');
            if (!btn) return;
            window.addEventListener('scroll', () => {
                if (window.scrollY > 400) btn.classList.remove('opacity-0', 'invisible');
                else btn.classList.add('opacity-0', 'invisible');
            });
            btn.addEventListener('click', () => window.scrollTo({top:0, behavior:'smooth'}));
        });
    </script>

    {% block extra_js %}{% endblock %}
</body>
</html>
HTMLEOF

echo "[OK] base.html (dark only)"

# ------------------------------------------------------------
# 2) Header - بدون toggle, دکمه رزرو بزرگ‌تر
# ------------------------------------------------------------
cat > templates/partials/header.html << 'HTMLEOF'
{% load static %}
<header x-data="{scrolled:false, mobileMenu:false, servicesOpen:false}"
        @scroll.window="scrolled = window.scrollY > 30"
        :class="scrolled ? 'bg-night-900/95 shadow-2xl border-b border-night-700' : 'bg-night-900/70'"
        class="fixed top-0 inset-x-0 z-50 backdrop-blur-xl transition-all duration-300">
    <div class="max-w-7xl mx-auto px-4 lg:px-8">
        <div class="flex items-center justify-between h-20">

            <!-- Logo -->
            <a href="{% url 'home' %}" class="flex items-center gap-3 shrink-0">
                <div class="w-12 h-12 rounded-2xl bg-gradient-to-br from-primary to-primary-700 flex items-center justify-center shadow-lg shadow-primary/40">
                    <i class="bi bi-heart-pulse-fill text-white text-2xl"></i>
                </div>
                <div class="hidden sm:block">
                    <div class="font-bold text-lg text-white leading-tight">{{ SITE_NAME }}</div>
                    <div class="text-xs text-night-400">مشاوره و روانشناسی</div>
                </div>
            </a>

            <!-- Nav -->
            <nav class="hidden lg:flex items-center gap-1 bg-night-800/60 backdrop-blur rounded-full px-2 py-2 border border-night-700">
                <a href="{% url 'home' %}" class="px-5 py-2 rounded-full text-sm font-semibold text-night-200 hover:bg-primary hover:text-white transition-all">خانه</a>

                {% if nav_categories %}
                <div class="relative" @mouseenter="servicesOpen=true" @mouseleave="servicesOpen=false">
                    <button class="px-5 py-2 rounded-full text-sm font-semibold text-night-200 hover:bg-primary hover:text-white transition-all flex items-center gap-1.5">
                        خدمات
                        <i class="bi bi-chevron-down text-xs transition-transform" :class="servicesOpen ? 'rotate-180' : ''"></i>
                    </button>
                    <div x-show="servicesOpen" x-cloak
                         x-transition:enter="transition ease-out duration-200"
                         x-transition:enter-start="opacity-0 translate-y-2"
                         class="absolute top-full right-0 mt-3 w-[640px] bg-night-800 rounded-3xl shadow-2xl border border-night-700 p-6 z-50">
                        <div class="grid grid-cols-2 gap-3">
                            {% for cat in nav_categories %}
                            <a href="{% url 'service_list' %}?category={{ cat.slug }}"
                               class="group flex items-start gap-3 p-3 rounded-2xl hover:bg-primary/10 transition">
                                <div class="w-11 h-11 rounded-xl bg-primary/20 group-hover:bg-primary flex items-center justify-center transition shrink-0">
                                    <i class="bi {{ cat.icon|default:'bi-heart-pulse' }} text-primary group-hover:text-white transition"></i>
                                </div>
                                <div class="min-w-0">
                                    <div class="font-bold text-sm text-white group-hover:text-primary transition truncate">{{ cat.name }}</div>
                                    <div class="text-xs text-night-400 line-clamp-1 mt-0.5">{{ cat.description|default:"مشاهده خدمات" }}</div>
                                </div>
                            </a>
                            {% endfor %}
                        </div>
                        <div class="mt-4 pt-4 border-t border-night-700">
                            <a href="{% url 'service_list' %}" class="flex items-center justify-center gap-2 text-primary font-bold text-sm hover:underline">
                                مشاهده همه خدمات <i class="bi bi-arrow-left"></i>
                            </a>
                        </div>
                    </div>
                </div>
                {% else %}
                <a href="{% url 'service_list' %}" class="px-5 py-2 rounded-full text-sm font-semibold text-night-200 hover:bg-primary hover:text-white transition-all">خدمات</a>
                {% endif %}

                <a href="{% url 'package_list' %}" class="px-5 py-2 rounded-full text-sm font-semibold text-night-200 hover:bg-primary hover:text-white transition-all">بسته‌ها</a>
                <a href="{% url 'article_list' %}" class="px-5 py-2 rounded-full text-sm font-semibold text-night-200 hover:bg-primary hover:text-white transition-all">مقالات</a>
                <a href="{% url 'about' %}" class="px-5 py-2 rounded-full text-sm font-semibold text-night-200 hover:bg-primary hover:text-white transition-all">درباره</a>
                <a href="{% url 'contact' %}" class="px-5 py-2 rounded-full text-sm font-semibold text-night-200 hover:bg-primary hover:text-white transition-all">تماس</a>
            </nav>

            <!-- Actions -->
            <div class="flex items-center gap-3">

                <a href="tel:{{ SITE_PHONE }}" class="hidden xl:flex items-center gap-2 text-sm font-semibold text-night-200 hover:text-primary transition">
                    <i class="bi bi-telephone-fill"></i>
                    <span dir="ltr">{{ SITE_PHONE }}</span>
                </a>

                <!-- ★ PROMINENT BOOKING BUTTON ★ -->
                <a href="{% url 'appointments:book' %}"
                   class="hidden sm:inline-flex items-center gap-2 bg-gradient-to-l from-primary to-primary-700 hover:from-primary-600 hover:to-primary-700 text-white font-black text-sm px-6 py-3 rounded-full shadow-lg shadow-primary/40 hover:shadow-primary/60 hover:scale-105 transition-all">
                    <i class="bi bi-calendar2-plus-fill text-lg"></i>
                    <span>رزرو نوبت</span>
                </a>

                {% if user.is_authenticated %}
                <div x-data="{open:false}" class="relative">
                    <button @click="open = !open" @click.outside="open = false" class="flex items-center gap-2">
                        {% if user.avatar %}
                            <img src="{{ user.avatar.url }}" class="w-10 h-10 rounded-full object-cover border-2 border-primary/50">
                        {% else %}
                            <div class="w-10 h-10 rounded-full bg-gradient-to-br from-primary to-primary-700 text-white flex items-center justify-center font-bold text-sm">
                                {{ user.first_name|first|default:user.username|first }}
                            </div>
                        {% endif %}
                    </button>
                    <div x-show="open" x-transition x-cloak
                         class="absolute left-0 mt-3 w-56 bg-night-800 rounded-2xl shadow-2xl border border-night-700 py-2 z-50">
                        <div class="px-4 py-3 border-b border-night-700">
                            <div class="font-bold text-sm text-white">{{ user.get_full_name|default:user.username }}</div>
                            <div class="text-xs text-night-400" dir="ltr">{{ user.phone_number|default:user.email }}</div>
                        </div>
                        <a href="{% url 'accounts:profile' %}" class="flex items-center gap-3 px-4 py-2.5 text-sm text-night-200 hover:bg-night-700">
                            <i class="bi bi-person-circle text-night-400"></i> پروفایل من
                        </a>
                        <a href="{% url 'appointments:my_appointments' %}" class="flex items-center gap-3 px-4 py-2.5 text-sm text-night-200 hover:bg-night-700">
                            <i class="bi bi-calendar-check text-night-400"></i> نوبت‌های من
                        </a>
                        {% if user.is_staff or user.is_doctor or user.is_secretary %}
                        <a href="{% url 'dashboard:home' %}" class="flex items-center gap-3 px-4 py-2.5 text-sm text-night-200 hover:bg-night-700">
                            <i class="bi bi-speedometer2 text-night-400"></i> پنل مدیریت
                        </a>
                        {% endif %}
                        <hr class="my-1 border-night-700">
                        <a href="{% url 'accounts:logout' %}" class="flex items-center gap-3 px-4 py-2.5 text-sm text-red-400 hover:bg-red-500/10">
                            <i class="bi bi-box-arrow-right"></i> خروج
                        </a>
                    </div>
                </div>
                {% else %}
                <a href="{% url 'accounts:login' %}" class="hidden sm:inline-flex items-center gap-2 text-sm font-semibold text-night-200 hover:text-white transition px-3">
                    <i class="bi bi-person"></i> ورود
                </a>
                {% endif %}

                <button @click="mobileMenu = true" class="lg:hidden w-10 h-10 rounded-xl bg-night-800 border border-night-700 flex items-center justify-center">
                    <i class="bi bi-list text-2xl text-white"></i>
                </button>
            </div>
        </div>
    </div>

    <!-- Mobile Menu -->
    <div x-show="mobileMenu" x-cloak class="fixed inset-0 z-[60] lg:hidden">
        <div @click="mobileMenu = false" class="absolute inset-0 bg-black/70 backdrop-blur-sm"></div>
        <aside x-show="mobileMenu"
               x-transition:enter="transition ease-out duration-300"
               x-transition:enter-start="translate-x-full"
               x-transition:enter-end="translate-x-0"
               class="absolute top-0 right-0 h-full w-80 max-w-full bg-night-800 shadow-2xl p-6 overflow-y-auto">
            <div class="flex items-center justify-between mb-8">
                <div class="font-bold text-lg text-white">{{ SITE_NAME }}</div>
                <button @click="mobileMenu = false" class="w-10 h-10 rounded-xl bg-night-700 flex items-center justify-center">
                    <i class="bi bi-x-lg text-white"></i>
                </button>
            </div>

            <nav class="flex flex-col gap-2">
                <a href="{% url 'home' %}" class="flex items-center gap-3 px-4 py-3 rounded-xl hover:bg-primary/10 hover:text-primary font-semibold text-night-200">
                    <i class="bi bi-house"></i> خانه
                </a>
                <a href="{% url 'service_list' %}" class="flex items-center gap-3 px-4 py-3 rounded-xl hover:bg-primary/10 hover:text-primary font-semibold text-night-200">
                    <i class="bi bi-grid"></i> خدمات
                </a>
                <a href="{% url 'package_list' %}" class="flex items-center gap-3 px-4 py-3 rounded-xl hover:bg-primary/10 hover:text-primary font-semibold text-night-200">
                    <i class="bi bi-box-seam"></i> بسته‌ها
                </a>
                <a href="{% url 'article_list' %}" class="flex items-center gap-3 px-4 py-3 rounded-xl hover:bg-primary/10 hover:text-primary font-semibold text-night-200">
                    <i class="bi bi-newspaper"></i> مقالات
                </a>
                <a href="{% url 'about' %}" class="flex items-center gap-3 px-4 py-3 rounded-xl hover:bg-primary/10 hover:text-primary font-semibold text-night-200">
                    <i class="bi bi-info-circle"></i> درباره
                </a>
                <a href="{% url 'contact' %}" class="flex items-center gap-3 px-4 py-3 rounded-xl hover:bg-primary/10 hover:text-primary font-semibold text-night-200">
                    <i class="bi bi-telephone"></i> تماس
                </a>
            </nav>

            <div class="mt-8 pt-6 border-t border-night-700">
                <a href="{% url 'appointments:book' %}" class="flex items-center justify-center gap-2 bg-gradient-to-l from-primary to-primary-700 text-white font-black py-4 rounded-2xl w-full shadow-lg shadow-primary/30">
                    <i class="bi bi-calendar2-plus-fill text-xl"></i>
                    رزرو نوبت
                </a>
                {% if not user.is_authenticated %}
                    <a href="{% url 'accounts:login' %}" class="flex items-center justify-center gap-2 mt-3 border-2 border-primary text-primary font-bold py-3 rounded-2xl w-full">
                        ورود / ثبت‌نام
                    </a>
                {% endif %}
            </div>
        </aside>
    </div>
</header>

<div class="h-20"></div>
HTMLEOF

echo "[OK] header.html"

# ------------------------------------------------------------
# 3) CSS Dark Theme
# ------------------------------------------------------------
cat > static/css/dark-theme.css << 'CSSEOF'
/* ============================================================
   Marjan Aram - Dark Theme
   Single theme, no toggle
   ============================================================ */

* { -webkit-tap-highlight-color: transparent; }
html { scroll-behavior: smooth; }
body {
    font-family: 'Vazirmatn', system-ui, sans-serif;
    background-color: #0A0E1F;
    color: #E2E8F0;
    min-height: 100vh;
}

/* Background gradient */
body::before {
    content: '';
    position: fixed;
    inset: 0;
    background:
        radial-gradient(ellipse 60% 40% at 80% 10%, rgba(59, 130, 246, 0.15), transparent),
        radial-gradient(ellipse 50% 30% at 20% 90%, rgba(245, 158, 11, 0.08), transparent);
    pointer-events: none;
    z-index: -1;
}

/* Scrollbar */
::-webkit-scrollbar { width: 10px; height: 10px; }
::-webkit-scrollbar-track { background: #0A0E1F; }
::-webkit-scrollbar-thumb { background: #334155; border-radius: 10px; border: 2px solid #0A0E1F; }
::-webkit-scrollbar-thumb:hover { background: #3B82F6; }

::selection { background: #3B82F6; color: white; }

/* Smooth transitions */
a, button { transition: all 0.25s ease; }

/* x-cloak */
[x-cloak] { display: none !important; }

/* Line clamp */
.line-clamp-1 { display: -webkit-box; -webkit-line-clamp: 1; -webkit-box-orient: vertical; overflow: hidden; }
.line-clamp-2 { display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }
.line-clamp-3 { display: -webkit-box; -webkit-line-clamp: 3; -webkit-box-orient: vertical; overflow: hidden; }

/* Cards */
.card-dark {
    background: linear-gradient(180deg, #131C31 0%, #0F1626 100%);
    border: 1px solid #1E293B;
    border-radius: 24px;
    transition: all 0.3s ease;
}
.card-dark:hover {
    border-color: rgba(59, 130, 246, 0.5);
    box-shadow: 0 20px 40px -10px rgba(59, 130, 246, 0.3);
    transform: translateY(-4px);
}

/* Inputs */
.form-input {
    width: 100%;
    padding: 0.85rem 1rem;
    border-radius: 1rem;
    border: 1px solid #334155;
    background: #0F1626;
    color: #E2E8F0;
    font-family: inherit;
    font-size: 0.875rem;
    transition: all 0.2s;
}
.form-input:focus {
    outline: none;
    border-color: #3B82F6;
    background: #131C31;
    box-shadow: 0 0 0 4px rgba(59, 130, 246, 0.15);
}
.form-input::placeholder { color: #64748B; }

/* Override Tailwind backgrounds to work in dark theme */
.bg-white { background-color: #131C31 !important; }
.bg-slate-50 { background-color: #0F1626 !important; }
.bg-slate-100 { background-color: #1E293B !important; }
.bg-slate-200 { background-color: #334155 !important; }

.text-dark { color: #FFFFFF !important; }
.text-slate-700 { color: #E2E8F0 !important; }
.text-slate-600 { color: #CBD5E1 !important; }
.text-slate-500 { color: #94A3B8 !important; }
.text-slate-400 { color: #64748B !important; }

.border-slate-100 { border-color: #1E293B !important; }
.border-slate-200 { border-color: #334155 !important; }
.divide-slate-100 > * + * { border-color: #1E293B !important; }
.divide-slate-50 > * + * { border-color: #131C31 !important; }

/* Buttons - Primary */
.btn-primary {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 0.5rem;
    padding: 0.9rem 1.75rem;
    border-radius: 1rem;
    font-weight: 800;
    color: white;
    background: linear-gradient(135deg, #3B82F6, #1D4ED8);
    box-shadow: 0 10px 25px -5px rgba(59, 130, 246, 0.4);
    transition: all 0.25s ease;
}
.btn-primary:hover {
    transform: translateY(-2px);
    box-shadow: 0 15px 35px -5px rgba(59, 130, 246, 0.6);
}

/* Accent glow for CTA */
@keyframes glow {
    0%, 100% { box-shadow: 0 0 20px rgba(59, 130, 246, 0.4), 0 10px 25px -5px rgba(59, 130, 246, 0.4); }
    50%      { box-shadow: 0 0 40px rgba(59, 130, 246, 0.8), 0 10px 25px -5px rgba(59, 130, 246, 0.6); }
}

/* Floating animation */
@keyframes float {
    0%, 100% { transform: translateY(0); }
    50%      { transform: translateY(-20px); }
}
.animate-float { animation: float 6s ease-in-out infinite; }

/* Mobile body padding for sticky booking bar */
@media (max-width: 1023px) {
    body { padding-bottom: 100px; }
}
CSSEOF

echo "[OK] dark-theme.css"

# ------------------------------------------------------------
# 4) Footer - Dark styled
# ------------------------------------------------------------
cat > templates/partials/footer.html << 'HTMLEOF'
<footer class="bg-night-950 border-t border-night-800 mt-24 relative overflow-hidden">
    <div class="absolute -top-32 -right-32 w-96 h-96 bg-primary/10 rounded-full blur-3xl"></div>
    <div class="absolute -bottom-32 -left-32 w-96 h-96 bg-accent/5 rounded-full blur-3xl"></div>

    <!-- Newsletter -->
    <div class="relative border-b border-night-800">
        <div class="max-w-7xl mx-auto px-4 lg:px-8 py-12">
            <div class="grid md:grid-cols-2 gap-8 items-center">
                <div>
                    <h3 class="text-2xl font-black text-white mb-2">عضویت در خبرنامه</h3>
                    <p class="text-night-400 text-sm">جدیدترین مقالات و تخفیف‌ها را در ایمیل خود دریافت کنید.</p>
                </div>
                <form method="post" action="{% url 'newsletter_subscribe' %}" class="flex gap-3">
                    {% csrf_token %}
                    <input type="email" name="email" required placeholder="example@mail.com"
                           class="flex-1 px-5 py-3.5 rounded-2xl bg-night-900 border border-night-700 text-white placeholder-night-500 focus:outline-none focus:border-primary focus:ring-4 focus:ring-primary/10 transition"
                           dir="ltr">
                    <button type="submit" class="bg-gradient-to-l from-primary to-primary-700 text-white font-bold px-6 py-3.5 rounded-2xl hover:shadow-lg hover:shadow-primary/40 transition">
                        <i class="bi bi-send"></i>
                        <span class="hidden sm:inline mr-2">عضویت</span>
                    </button>
                </form>
            </div>
        </div>
    </div>

    <div class="relative max-w-7xl mx-auto px-4 lg:px-8 py-16">
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-10">

            <div class="lg:col-span-1">
                <div class="flex items-center gap-3 mb-4">
                    <div class="w-12 h-12 rounded-2xl bg-gradient-to-br from-primary to-accent flex items-center justify-center shadow-lg shadow-primary/30">
                        <i class="bi bi-heart-pulse-fill text-white text-2xl"></i>
                    </div>
                    <div>
                        <div class="font-bold text-xl text-white">{{ SITE_NAME }}</div>
                        <div class="text-xs text-night-400">مشاوره و روانشناسی</div>
                    </div>
                </div>
                <p class="text-sm leading-7 text-night-400">
                    ارائه‌دهنده خدمات مشاوره تخصصی خانواده، فردی، طلاق و روانشناسی با بهترین کیفیت.
                </p>
            </div>

            <div>
                <h4 class="text-white font-bold mb-5">دسترسی سریع</h4>
                <ul class="space-y-3 text-sm">
                    <li><a href="{% url 'home' %}" class="text-night-300 hover:text-primary transition flex items-center gap-2"><i class="bi bi-chevron-left text-xs"></i> خانه</a></li>
                    <li><a href="{% url 'service_list' %}" class="text-night-300 hover:text-primary transition flex items-center gap-2"><i class="bi bi-chevron-left text-xs"></i> خدمات</a></li>
                    <li><a href="{% url 'package_list' %}" class="text-night-300 hover:text-primary transition flex items-center gap-2"><i class="bi bi-chevron-left text-xs"></i> بسته‌ها</a></li>
                    <li><a href="{% url 'article_list' %}" class="text-night-300 hover:text-primary transition flex items-center gap-2"><i class="bi bi-chevron-left text-xs"></i> مقالات</a></li>
                </ul>
            </div>

            <div>
                <h4 class="text-white font-bold mb-5">اطلاعات تماس</h4>
                <ul class="space-y-4 text-sm">
                    <li class="flex items-start gap-3 text-night-300">
                        <i class="bi bi-geo-alt-fill text-primary mt-1"></i>
                        <span class="leading-7">{{ SITE_ADDRESS }}</span>
                    </li>
                    <li class="flex items-center gap-3">
                        <i class="bi bi-telephone-fill text-primary"></i>
                        <a href="tel:{{ SITE_PHONE }}" dir="ltr" class="text-night-300 hover:text-primary transition">{{ SITE_PHONE }}</a>
                    </li>
                    <li class="flex items-center gap-3 text-night-300">
                        <i class="bi bi-clock-fill text-primary"></i>
                        <span>هر روز ۱۰ صبح تا ۷ عصر</span>
                    </li>
                </ul>
            </div>

            <div>
                <h4 class="text-white font-bold mb-5">شبکه‌های اجتماعی</h4>
                <div class="flex gap-3">
                    <a href="#" class="w-11 h-11 rounded-xl bg-night-800 hover:bg-primary flex items-center justify-center text-night-200 hover:text-white transition-all">
                        <i class="bi bi-instagram text-xl"></i>
                    </a>
                    <a href="#" class="w-11 h-11 rounded-xl bg-night-800 hover:bg-primary flex items-center justify-center text-night-200 hover:text-white transition-all">
                        <i class="bi bi-telegram text-xl"></i>
                    </a>
                    <a href="#" class="w-11 h-11 rounded-xl bg-night-800 hover:bg-primary flex items-center justify-center text-night-200 hover:text-white transition-all">
                        <i class="bi bi-whatsapp text-xl"></i>
                    </a>
                </div>
                <div class="mt-6 p-4 rounded-2xl bg-night-900 border border-night-800">
                    <div class="text-xs text-night-400 mb-2">کد نظام روانشناسی</div>
                    <div class="text-white font-bold">۷۶۴۲۷</div>
                </div>
            </div>
        </div>

        <div class="mt-12 pt-8 border-t border-night-800 flex flex-col md:flex-row justify-between items-center gap-4 text-sm text-night-400">
            <p>تمامی حقوق برای <span class="text-white font-semibold">{{ SITE_NAME }}</span> محفوظ است © ۱۴۰۴</p>
            <p>طراحی و توسعه با <i class="bi bi-heart-fill text-red-500"></i></p>
        </div>
    </div>
</footer>
HTMLEOF

echo "[OK] footer.html"

# ------------------------------------------------------------
# 5) home.html - Redesigned dark hero
# ------------------------------------------------------------
cat > templates/home.html << 'HTMLEOF'
{% extends 'base.html' %}
{% load static %}
{% load fa_numbers %}

{% block title %}{{ SITE_NAME }} - مشاوره تخصصی خانواده و روانشناسی{% endblock %}

{% block content %}

<!-- ============ HERO ============ -->
<section class="relative overflow-hidden pt-8 pb-24">
    <div class="absolute top-20 right-10 w-96 h-96 bg-primary/20 rounded-full blur-[120px] animate-float"></div>
    <div class="absolute bottom-20 left-10 w-96 h-96 bg-accent/10 rounded-full blur-[120px] animate-float" style="animation-delay:1.5s"></div>

    <div class="relative max-w-7xl mx-auto px-4 lg:px-8">
        <div class="grid lg:grid-cols-2 gap-12 items-center">
            <div data-aos="fade-left">
                <div class="inline-flex items-center gap-2 bg-primary/10 border border-primary/30 text-primary px-4 py-2 rounded-full text-sm font-bold mb-6">
                    <span class="w-2 h-2 rounded-full bg-primary animate-pulse"></span>
                    <span>مرکز تخصصی مشاوره و روانشناسی</span>
                </div>

                <h1 class="text-4xl md:text-5xl lg:text-6xl font-black text-white leading-tight mb-6">
                    آرامش را با
                    <span class="relative inline-block text-primary">
                        مرجان آرام
                        <svg class="absolute -bottom-2 right-0 w-full" viewBox="0 0 200 12" fill="none">
                            <path d="M2 9C50 3 150 3 198 9" stroke="#F59E0B" stroke-width="3" stroke-linecap="round"/>
                        </svg>
                    </span>
                    <br>تجربه کنید
                </h1>

                <p class="text-lg text-night-300 leading-8 mb-8 max-w-xl">
                    با بیش از ۱۵ سال سابقه درخشان در زمینه مشاوره خانواده، فردی، قبل از ازدواج و درمان افسردگی و اضطراب، در کنار شما هستیم.
                </p>

                <!-- CTA Buttons -->
                <div class="flex flex-wrap gap-4 mb-10">
                    <a href="{% url 'appointments:book' %}"
                       class="group inline-flex items-center gap-3 bg-gradient-to-l from-primary to-primary-700 text-white font-black text-lg px-8 py-5 rounded-2xl shadow-2xl shadow-primary/50 hover:shadow-primary/70 hover:scale-105 transition-all animate-glow">
                        <i class="bi bi-calendar2-plus-fill text-2xl"></i>
                        <span>رزرو نوبت آنلاین</span>
                        <i class="bi bi-arrow-left text-xl group-hover:-translate-x-1 transition-transform"></i>
                    </a>
                    <a href="{% url 'service_list' %}" class="inline-flex items-center gap-2 bg-night-800 hover:bg-night-700 border border-night-700 text-white font-bold px-8 py-5 rounded-2xl transition">
                        <i class="bi bi-grid"></i>
                        <span>مشاهده خدمات</span>
                    </a>
                </div>

                <!-- Trust -->
                <div class="flex items-center gap-6 flex-wrap">
                    <div class="flex items-center gap-2">
                        <i class="bi bi-shield-check text-emerald-400 text-xl"></i>
                        <span class="text-sm font-semibold text-night-200">مجوز رسمی</span>
                    </div>
                    <div class="flex items-center gap-2">
                        <i class="bi bi-star-fill text-amber-400 text-xl"></i>
                        <span class="text-sm font-semibold text-night-200">رضایت ۹۸٪ بیماران</span>
                    </div>
                    <div class="flex items-center gap-2">
                        <i class="bi bi-people-fill text-primary text-xl"></i>
                        <span class="text-sm font-semibold text-night-200">+۵۰۰۰ مشاوره موفق</span>
                    </div>
                </div>
            </div>

            <!-- Visual -->
            <div data-aos="fade-right" class="relative">
                <div class="relative w-full aspect-square max-w-lg mx-auto">
                    <div class="absolute inset-0 rounded-[3rem] bg-gradient-to-br from-primary to-accent rotate-6 opacity-30 blur-2xl"></div>
                    <div class="absolute inset-0 rounded-[3rem] bg-night-800 border border-night-700 flex items-center justify-center overflow-hidden">
                        <i class="bi bi-person-heart text-[12rem] text-primary/30"></i>
                    </div>

                    <div class="absolute -top-4 -right-4 bg-night-800 border border-night-700 rounded-2xl shadow-2xl p-4 flex items-center gap-3 animate-float">
                        <div class="w-12 h-12 rounded-xl bg-emerald-500/20 flex items-center justify-center">
                            <i class="bi bi-check-circle-fill text-emerald-400 text-xl"></i>
                        </div>
                        <div>
                            <div class="text-xs text-night-400">رضایت بیماران</div>
                            <div class="font-bold text-white">۹۸٪</div>
                        </div>
                    </div>

                    <div class="absolute -bottom-4 -left-4 bg-night-800 border border-night-700 rounded-2xl shadow-2xl p-4 flex items-center gap-3 animate-float" style="animation-delay:1s">
                        <div class="w-12 h-12 rounded-xl bg-primary/20 flex items-center justify-center">
                            <i class="bi bi-award-fill text-primary text-xl"></i>
                        </div>
                        <div>
                            <div class="text-xs text-night-400">سابقه کار</div>
                            <div class="font-bold text-white">۱۵+ سال</div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</section>

<!-- ============ STATS ============ -->
<section class="relative -mt-12 z-10">
    <div class="max-w-6xl mx-auto px-4 lg:px-8">
        <div class="bg-night-800/70 backdrop-blur-xl border border-night-700 rounded-3xl shadow-2xl p-8 grid grid-cols-2 md:grid-cols-4 gap-6" data-aos="fade-up">
            <div class="text-center">
                <div class="text-4xl md:text-5xl font-black text-primary mb-2">۵۰۰۰+</div>
                <div class="text-sm text-night-400 font-semibold">مشاوره موفق</div>
            </div>
            <div class="text-center">
                <div class="text-4xl md:text-5xl font-black text-accent mb-2">۱۵+</div>
                <div class="text-sm text-night-400 font-semibold">سال تجربه</div>
            </div>
            <div class="text-center">
                <div class="text-4xl md:text-5xl font-black text-emerald-400 mb-2">۹۸٪</div>
                <div class="text-sm text-night-400 font-semibold">رضایت بیماران</div>
            </div>
            <div class="text-center">
                <div class="text-4xl md:text-5xl font-black text-primary mb-2">۲۴/۷</div>
                <div class="text-sm text-night-400 font-semibold">پشتیبانی</div>
            </div>
        </div>
    </div>
</section>

<!-- ============ SERVICES ============ -->
<section class="py-20 lg:py-28">
    <div class="max-w-7xl mx-auto px-4 lg:px-8">
        <div class="text-center max-w-2xl mx-auto mb-14" data-aos="fade-up">
            <div class="inline-flex items-center gap-2 bg-accent/10 border border-accent/30 text-accent px-4 py-2 rounded-full text-sm font-bold mb-4">
                <i class="bi bi-grid-3x3-gap-fill"></i>
                <span>خدمات ما</span>
            </div>
            <h2 class="text-3xl md:text-4xl font-black text-white mb-4">خدمات تخصصی مشاوره</h2>
            <p class="text-night-400 leading-8">ما با تیمی از متخصصان مجرب، خدمات متنوع مشاوره را در محیطی امن و آرام به شما ارائه می‌دهیم.</p>
        </div>

        <div class="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
            {% for service in services %}
            <a href="{% url 'service_detail' service.slug %}" data-aos="fade-up" data-aos-delay="{{ forloop.counter0 }}00"
               class="group relative bg-gradient-to-b from-night-800 to-night-900 rounded-3xl p-6 border border-night-700 hover:border-primary/50 hover:shadow-2xl hover:shadow-primary/20 transition-all duration-300 hover:-translate-y-2">
                <div class="w-16 h-16 rounded-2xl bg-primary/10 border border-primary/30 group-hover:bg-primary group-hover:border-primary flex items-center justify-center mb-5 transition-all">
                    <i class="bi bi-heart-pulse text-2xl text-primary group-hover:text-white transition"></i>
                </div>
                <h3 class="text-xl font-bold text-white mb-3">{{ service.name }}</h3>
                <p class="text-night-400 text-sm leading-7 mb-5 line-clamp-2">{{ service.short_description|default:service.description|truncatewords:15 }}</p>

                <div class="flex items-center justify-between pt-4 border-t border-night-700">
                    <div>
                        <div class="text-xs text-night-500 mb-1">شروع از</div>
                        <div class="font-black text-primary text-lg">{{ service.price|price_fa }} <span class="text-xs font-normal text-night-400">تومان</span></div>
                    </div>
                    <div class="w-10 h-10 rounded-full bg-primary/10 group-hover:bg-primary group-hover:text-white text-primary flex items-center justify-center transition">
                        <i class="bi bi-arrow-left"></i>
                    </div>
                </div>
            </a>
            {% empty %}
            <div class="col-span-full text-center py-16 bg-night-800 rounded-3xl border border-dashed border-night-700">
                <i class="bi bi-inbox text-5xl text-night-500 mb-4"></i>
                <p class="text-night-400">هنوز خدمتی ثبت نشده است.</p>
            </div>
            {% endfor %}
        </div>

        {% if services %}
        <div class="text-center mt-12">
            <a href="{% url 'service_list' %}" class="inline-flex items-center gap-2 bg-night-800 hover:bg-primary text-white font-bold px-8 py-3 rounded-2xl border border-night-700 hover:border-primary transition-all">
                مشاهده همه خدمات
                <i class="bi bi-arrow-left"></i>
            </a>
        </div>
        {% endif %}
    </div>
</section>

<!-- ============ BIG CTA ============ -->
<section class="py-20">
    <div class="max-w-7xl mx-auto px-4 lg:px-8">
        <div class="relative overflow-hidden rounded-[2rem] bg-gradient-to-bl from-primary via-primary-600 to-primary-700 p-10 md:p-16" data-aos="zoom-in">
            <div class="absolute top-0 right-0 w-72 h-72 bg-white/10 rounded-full blur-3xl"></div>
            <div class="absolute bottom-0 left-0 w-96 h-96 bg-accent/20 rounded-full blur-3xl"></div>

            <div class="relative grid lg:grid-cols-2 gap-8 items-center">
                <div class="text-white">
                    <h2 class="text-3xl md:text-4xl font-black mb-4 leading-tight">همین حالا نوبت خود را رزرو کنید</h2>
                    <p class="text-white/90 text-lg leading-8 mb-8">فقط با چند کلیک ساده، نوبت مشاوره خود را رزرو کنید و اولین قدم را به سوی آرامش بردارید.</p>
                    <div class="flex flex-wrap gap-4">
                        <a href="{% url 'appointments:book' %}" class="inline-flex items-center gap-3 bg-white text-primary font-black text-lg px-8 py-5 rounded-2xl hover:bg-night-50 hover:scale-105 transition-all shadow-2xl">
                            <i class="bi bi-calendar2-plus-fill text-2xl"></i>
                            <span>رزرو نوبت</span>
                        </a>
                        <a href="tel:{{ SITE_PHONE }}" class="inline-flex items-center gap-2 bg-white/10 backdrop-blur border-2 border-white/30 text-white font-bold px-8 py-5 rounded-2xl hover:bg-white/20 transition">
                            <i class="bi bi-telephone-fill"></i>
                            <span>تماس تلفنی</span>
                        </a>
                    </div>
                </div>
                <div class="hidden lg:flex justify-center">
                    <div class="w-64 h-64 rounded-full bg-white/10 backdrop-blur border border-white/20 flex items-center justify-center animate-float">
                        <i class="bi bi-calendar2-heart text-[8rem] text-white/60"></i>
                    </div>
                </div>
            </div>
        </div>
    </div>
</section>

{% endblock %}
HTMLEOF

echo "[OK] home.html"

# ------------------------------------------------------------
# 6) Hide sticky booking bar on booking pages
# ------------------------------------------------------------
python - << 'PYEOF'
import io, os

# در book.html و detail.html، بلوک sticky_booking را خالی کن
for path in ['templates/appointments/book.html', 'templates/appointments/detail.html']:
    if os.path.exists(path):
        with io.open(path, 'r', encoding='utf-8') as f:
            content = f.read()

        if '{% block sticky_booking %}' not in content:
            # اضافه کردن یک بلاک خالی قبل از {% endblock %} انتهایی
            content = content.replace(
                '{% endblock %}',
                '{% block sticky_booking %}{% endblock %}\n{% endblock %}',
                1
            )
            with io.open(path, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"[OK] {path}")
PYEOF

echo ""
echo "======================================================"
echo "  [OK] Redesign Complete!"
echo "======================================================"
echo ""
echo "Restart server:"
echo "   python manage.py runserver"
echo ""
echo "Hard refresh: Ctrl+Shift+R"
echo ""
echo "What's new:"
echo "  - Dark theme only (no toggle)"
echo "  - Prominent booking CTA (top header + hero + sticky bottom on mobile)"
echo "  - Better contrast and readability"
echo "  - Glass morphism header"
echo ""
echo "Test: http://127.0.0.1:8000/"
echo ""