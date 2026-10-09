#!/bin/bash
# ============================================================
#  Fix: Git Bash path conversion issue
# ============================================================

set -e

if [ ! -f "manage.py" ]; then
    echo "ERROR: run in project root"
    exit 1
fi

echo "Fixing paths in templates..."

# ------------------------------------------------------------
#  تشخیص فایل موجود برای hero و doctor
# ------------------------------------------------------------
HERO_FILE=""
for f in media/hero/hero-main.jpg media/hero/hero-main.webp media/doctors/marjan-aram-1.jpg media/doctors/marjan-aram-1.webp media/doctors/marjan-aram-2.jpg; do
    if [ -f "$f" ]; then
        HERO_FILE="/$f"
        break
    fi
done

DOCTOR_FILE=""
for f in media/doctors/marjan-aram-1.jpg media/doctors/marjan-aram-1.webp media/doctors/marjan-aram-2.jpg; do
    if [ -f "$f" ]; then
        DOCTOR_FILE="/$f"
        break
    fi
done

echo "Hero:   ${HERO_FILE:-NOT FOUND}"
echo "Doctor: ${DOCTOR_FILE:-NOT FOUND}"

# ------------------------------------------------------------
#  پاکسازی home.html با پایتون (بدون argument از bash)
# ------------------------------------------------------------
MSYS_NO_PATHCONV=1 python << 'PYEOF'
import io
import os
import re

# ---------- پیدا کردن عکس‌ها با پایتون ----------
def find_first(paths):
    for p in paths:
        if os.path.exists(p):
            return '/' + p.replace('\\', '/')
    return ''

HERO = find_first([
    'media/hero/hero-main.jpg',
    'media/hero/hero-main.webp',
    'media/doctors/marjan-aram-1.jpg',
    'media/doctors/marjan-aram-1.webp',
    'media/doctors/marjan-aram-2.jpg',
])

DOCTOR = find_first([
    'media/doctors/marjan-aram-1.jpg',
    'media/doctors/marjan-aram-1.webp',
    'media/doctors/marjan-aram-2.jpg',
]) or HERO

print(f"[INFO] Hero URL:   {HERO or 'EMPTY'}")
print(f"[INFO] Doctor URL: {DOCTOR or 'EMPTY'}")

if not HERO:
    print("[WARN] No image found! Run download_images.sh first.")
    print("       Will keep placeholders.")

# ---------- اصلاح home.html ----------
path = 'templates/home.html'
with io.open(path, 'r', encoding='utf-8') as f:
    content = f.read()

changed = False

# 1) پاکسازی مسیرهای خراب (C:/Program Files/Git/...)
broken_pattern = re.compile(r'src="(?:file:///)?C:/Program Files/Git/([^"]+)"', re.IGNORECASE)
def fix_broken(m):
    return 'src="/' + m.group(1).replace('\\', '/')
content_new = broken_pattern.sub(fix_broken, content)
if content_new != content:
    content = content_new
    changed = True
    print("[OK] Fixed broken Windows paths")

# 2) جایگزینی Hero image (هر onerror رو حذف کن که مشکل نداره)
if HERO:
    # جایگزینی ساده: هر src که به media/hero یا media/doctors اشاره دارد را با HERO
    content = re.sub(
        r'src="[^"]*media/(?:hero|doctors)/[^"]*"',
        f'src="{HERO}"',
        content
    )

    # اگر placeholder قبلی هنوز هست (آیکون bi-person-heart در Hero)
    old_hero_patterns = [
        # الگوی رایج placeholder hero
        r'<div class="absolute inset-0 rounded-\[3rem\] bg-night-800 border border-night-700 flex items-center justify-center overflow-hidden">\s*<i class="bi bi-person-heart text-\[12rem\] text-primary/30"></i>\s*</div>',
    ]
    for pat in old_hero_patterns:
        if re.search(pat, content):
            new_block = f'''<div class="absolute inset-0 rounded-[3rem] bg-night-800 border border-night-700 overflow-hidden">
                        <img src="{HERO}" alt="دکتر مرجان آرام" class="w-full h-full object-cover object-top">
                    </div>'''
            content = re.sub(pat, new_block, content)
            changed = True
            print("[OK] Hero placeholder replaced")

    # اگر بلوک Hero image از قبل هست، onerror را حذف کن
    content = re.sub(r'\s*onerror="[^"]*"', '', content)
    if 'onerror=' not in content:
        changed = True

# 3) ذخیره
with io.open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print(f"[DONE] home.html saved (changed={changed})")
PYEOF

# ------------------------------------------------------------
#  اصلاح about.html
# ------------------------------------------------------------
MSYS_NO_PATHCONV=1 python << 'PYEOF'
import io, os, re

# پیدا کردن عکس‌ها
def find_first(paths):
    for p in paths:
        if os.path.exists(p):
            return '/' + p.replace('\\', '/')
    return ''

CLINIC_1 = find_first(['media/clinic/clinic-1.jpg', 'media/services/service-1.jpg'])
CLINIC_2 = find_first(['media/clinic/clinic-2.jpg', 'media/services/service-2.jpg'])
SERVICE_1 = find_first(['media/services/service-1.jpg'])
SERVICE_2 = find_first(['media/services/service-2.jpg'])

path = 'templates/about.html'
if not os.path.exists(path):
    print("[SKIP] about.html not found")
else:
    with io.open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # پاکسازی path های خراب
    content = re.sub(
        r'src="(?:file:///)?C:/Program Files/Git/([^"]+)"',
        lambda m: 'src="/' + m.group(1).replace('\\', '/'),
        content,
        flags=re.IGNORECASE,
    )

    # جایگزینی عکس‌های گالری
    if CLINIC_1:
        content = content.replace('/media/clinic/clinic-1.jpg', CLINIC_1)
    if CLINIC_2:
        content = content.replace('/media/clinic/clinic-2.jpg', CLINIC_2)
    if SERVICE_1:
        content = content.replace('/media/services/service-1.jpg', SERVICE_1)
    if SERVICE_2:
        content = content.replace('/media/services/service-2.jpg', SERVICE_2)

    with io.open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("[OK] about.html fixed")

# ---------- Fix service_list.html ----------
path = 'templates/services/service_list.html'
if os.path.exists(path):
    with io.open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    content = re.sub(
        r'src="(?:file:///)?C:/Program Files/Git/([^"]+)"',
        lambda m: 'src="/' + m.group(1).replace('\\', '/'),
        content,
        flags=re.IGNORECASE,
    )
    with io.open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("[OK] service_list.html fixed")

# ---------- Fix service_detail.html ----------
path = 'templates/services/service_detail.html'
if os.path.exists(path):
    with io.open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    content = re.sub(
        r'src="(?:file:///)?C:/Program Files/Git/([^"]+)"',
        lambda m: 'src="/' + m.group(1).replace('\\', '/'),
        content,
        flags=re.IGNORECASE,
    )
    with io.open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("[OK] service_detail.html fixed")
PYEOF

# ------------------------------------------------------------
#  نمایش نتیجه
# ------------------------------------------------------------
echo ""
echo "=============== بررسی مسیرها در home.html ==============="
grep -oE 'src="[^"]*"' templates/home.html 2>/dev/null | head -20 || echo "(no src found)"
echo ""

echo "======================================================"
echo "  [OK] Paths fixed!"
echo "======================================================"
echo ""
echo "Restart server: python manage.py runserver"
echo "Hard refresh:   Ctrl+Shift+R"
echo ""