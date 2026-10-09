#!/bin/bash
# ============================================================
#  Git Commit & Push - Complete Project
#  Save as: git_push.sh in project root (next to manage.py)
# ============================================================

set -e

# ---------- Check location ----------
if [ ! -f "manage.py" ]; then
    echo "❌ ERROR: This script must be run in the project root"
    echo "   (where manage.py exists)"
    exit 1
fi

echo ""
echo "=========================================="
echo "  🚀 Git Commit & Push"
echo "=========================================="
echo ""

# ============================================================
#  STEP 1: Setup .gitignore
# ============================================================
echo "[1/7] Updating .gitignore..."

cat > .gitignore << 'GITEOF'
# ==================== Python ====================
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg
MANIFEST

# ==================== Django ====================
*.log
local_settings.py
db.sqlite3
db.sqlite3-journal
media/
staticfiles/

# ==================== Environment ====================
.env
.env.*
!.env.example
venv/
env/
ENV/
env.bak/
venv.bak/

# ==================== IDE ====================
.idea/
.vscode/
*.swp
*.swo
*~
.project
.pydevproject

# ==================== OS ====================
.DS_Store
Thumbs.db
desktop.ini

# ==================== Node (optional) ====================
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# ==================== Testing ====================
.coverage
htmlcov/
.pytest_cache/
.tox/

# ==================== Backups ====================
*.bak
*.backup
db.sqlite3.bak*

# ==================== Temp ====================
*.tmp
.cache/
GITEOF

echo "  ✓ .gitignore updated"
echo ""

# ============================================================
#  STEP 2: Ensure .env.example exists
# ============================================================
echo "[2/7] Ensuring .env.example exists..."

if [ ! -f ".env.example" ]; then
    cat > .env.example << 'ENVEOF'
# ==================== Django ====================
SECRET_KEY=django-insecure-change-me-in-production
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1

# ==================== Zarinpal Payment ====================
ZARINPAL_MERCHANT_ID=your-merchant-id-here
ZARINPAL_SANDBOX=True

# ==================== SMS (Kavenegar) ====================
SMS_API_KEY=your-api-key
SMS_SENDER=10008663
ENVEOF
    echo "  ✓ .env.example created"
else
    echo "  ✓ .env.example already exists"
fi
echo ""

# ============================================================
#  STEP 3: Create README.md
# ============================================================
echo "[3/7] Creating README.md..."

cat > README.md << 'READMEEOF'
# 🩺 مرجان آرام - وب‌سایت مشاوره و روانشناسی

وب‌سایت کامل مشاوره و روانشناسی با سیستم رزرو نوبت آنلاین، پرداخت، داشبورد مدیریت و پنل ادمین سفارشی.

---

## ✨ ویژگی‌ها

- ✅ صفحات عمومی (خانه، خدمات، بسته‌ها، مقالات، درباره، تماس)
- ✅ سیستم احراز هویت با شماره موبایل و پروفایل کاربری
- ✅ رزرو نوبت با تقویم شمسی و انتخاب پرسنل
- ✅ درگاه پرداخت زرین‌پال با فاکتور PDF
- ✅ داشبورد مدیریت با نمودارهای آماری
- ✅ سیستم نظرات و امتیازدهی کاربران
- ✅ پنل ادمین کاملاً فارسی و سفارشی
- ✅ طراحی مدرن دارک با Tailwind CSS
- ✅ ۱۰۰٪ آفلاین (بدون CDN خارجی)
- ✅ ریسپانسیو کامل (موبایل/تبلت/دسکتاپ)

---

## 🛠 نصب و راه‌اندازی

### پیش‌نیازها
- Python 3.10 یا بالاتر
- pip
- Git

### مراحل نصب

```bash
# 1. Clone مخزن
git clone <repo-url>
cd marjanaram

# 2. ساخت محیط مجازی
python -m venv venv
source venv/bin/activate    # در Linux/Mac
# venv\Scripts\activate     # در Windows

# 3. نصب پکیج‌ها
pip install -r requirements.txt

# 4. کپی فایل تنظیمات
cp .env.example .env
# سپس SECRET_KEY را در .env ویرایش کنید

# 5. اجرای مایگریشن‌ها
python manage.py migrate

# 6. ساخت کاربر ادمین
python manage.py createsuperuser

# 7. (اختیاری) افزودن داده‌های نمونه
python manage.py seed_data

# 8. اجرای سرور
python manage.py runserver