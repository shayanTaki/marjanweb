#!/bin/bash
# ============================================================
#  Fix - بازسازی کامل دیتابیس و migration ها (Dev Only)
#  ⚠️ هشدار: تمام داده‌ها پاک می‌شوند!
# ============================================================

set -e

if [ ! -f "manage.py" ]; then
    echo "❌ این اسکریپت باید در ریشه پروژه اجرا شود."
    exit 1
fi

echo ""
echo "⚠️  این اسکریپت تمام داده‌ها را پاک می‌کند!"
echo "   (فقط برای محیط توسعه)"
echo ""
read -p "ادامه می‌دهی؟ (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "لغو شد."
    exit 0
fi

# ------------------------------------------------------------
#  1) بکاپ
# ------------------------------------------------------------
if [ -f "db.sqlite3" ]; then
    BACKUP="db.sqlite3.bak.$(date +%Y%m%d_%H%M%S)"
    cp db.sqlite3 "$BACKUP"
    echo "✅ بکاپ در: $BACKUP"
fi

# ------------------------------------------------------------
#  2) حذف دیتابیس
# ------------------------------------------------------------
echo "🗑️  حذف دیتابیس..."
rm -f db.sqlite3

# ------------------------------------------------------------
#  3) پاک کردن تمام فایل‌های migration (به‌جز __init__.py)
# ------------------------------------------------------------
echo "🗑️  پاک کردن migration ها..."
for app in accounts services appointments payments dashboard; do
    if [ -d "$app/migrations" ]; then
        find "$app/migrations" -maxdepth 1 -name "0*.py" -type f -delete 2>/dev/null || true
        find "$app/migrations" -maxdepth 1 -name "*.pyc" -type f -delete 2>/dev/null || true
        touch "$app/migrations/__init__.py"
        echo "   ✓ $app"
    fi
done

# ------------------------------------------------------------
#  4) پاک کردن __pycache__
# ------------------------------------------------------------
echo "🗑️  پاک کردن cache..."
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true

# ------------------------------------------------------------
#  5) اجرای makemigrations به‌ترتیب وابستگی
# ------------------------------------------------------------
echo ""
echo "🔧 ساخت migration برای accounts..."
python manage.py makemigrations accounts --noinput

echo ""
echo "🔧 ساخت migration برای services..."
python manage.py makemigrations services --noinput

echo ""
echo "🔧 ساخت migration برای appointments..."
python manage.py makemigrations appointments --noinput

echo ""
echo "🔧 ساخت migration برای payments..."
python manage.py makemigrations payments --noinput

echo ""
echo "🔧 ساخت migration برای dashboard..."
python manage.py makemigrations dashboard --noinput 2>/dev/null || true

# ------------------------------------------------------------
#  6) اجرای migrate
# ------------------------------------------------------------
echo ""
echo "🔧 اجرای migrate..."
python manage.py migrate --noinput

# ------------------------------------------------------------
#  7) ساخت superuser
# ------------------------------------------------------------
echo ""
echo "======================================================"
echo "  ✅ دیتابیس بازسازی شد!"
echo "======================================================"
echo ""
echo "👤 حالا یک superuser بساز:"
echo "   python manage.py createsuperuser"
echo ""
echo "📌 سپس این کارها را انجام بده:"
echo ""
echo "1️⃣  کاربر دکتر بساز (از پنل ادمین یا shell):"
echo "    http://127.0.0.1:8000/admin/accounts/customuser/add/"
echo "    → is_doctor را تیک بزن"
echo ""
echo "2️⃣  Staff بساز:"
echo "    http://127.0.0.1:8000/admin/appointments/staff/add/"
echo ""
echo "3️⃣  ساعات کاری تعریف کن:"
echo "    http://127.0.0.1:8000/admin/appointments/workinghours/add/"
echo ""
echo "4️⃣  سرویس‌ها را از پنل ادمین اضافه کن:"
echo "    http://127.0.0.1:8000/admin/services/service/add/"
echo ""
echo "5️⃣  سرور را روشن کن:"
echo "    python manage.py runserver"
echo ""
echo "======================================================"