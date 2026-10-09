#!/bin/bash
# ============================================================
#  Make All External Resources Local
# ============================================================

set -e

if [ ! -f "manage.py" ]; then
    echo "ERROR: run in project root"
    exit 1
fi

echo "=========================================="
echo "  Making All Resources Local"
echo "=========================================="
echo ""

# ============================================================
#  Setup directories
# ============================================================
mkdir -p static/vendor/tailwind
mkdir -p static/vendor/aos
mkdir -p static/vendor/alpine
mkdir -p static/vendor/chartjs
mkdir -p static/vendor/bootstrap-icons/fonts
mkdir -p static/vendor/vazirmatn/fonts/webfonts
mkdir -p static/vendor/images

UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

DOWNLOAD() {
    local URL="$1"
    local OUT="$2"
    local REFERER="${3:-}"
    if [ -f "$OUT" ] && [ -s "$OUT" ]; then
        echo "  [SKIP] $(basename $OUT) already exists"
        return 0
    fi
    echo "  [GET] $(basename $OUT) ← $URL"
    if [ -n "$REFERER" ]; then
        curl -sL --max-time 60 -A "$UA" -H "Referer: $REFERER" -o "$OUT" "$URL" || {
            echo "  [FAIL] curl failed for $URL"
            return 1
        }
    else
        curl -sL --max-time 60 -A "$UA" -o "$OUT" "$URL" || {
            echo "  [FAIL] curl failed for $URL"
            return 1
        }
    fi
    # Validate file isn't empty or error page
    local SIZE=$(stat -f%z "$OUT" 2>/dev/null || stat -c%s "$OUT" 2>/dev/null || echo 0)
    if [ "$SIZE" -lt 200 ]; then
        echo "  [WARN] File too small ($SIZE bytes)"
    else
        echo "  [OK] $SIZE bytes"
    fi
}

# ============================================================
#  TAILWIND
# ============================================================
echo ""
echo "[1/8] Downloading Tailwind CSS..."
DOWNLOAD "https://cdn.tailwindcss.com/3.4.1" "static/vendor/tailwind/tailwind.js"

# ============================================================
#  AOS (Animate On Scroll)
# ============================================================
echo ""
echo "[2/8] Downloading AOS..."
DOWNLOAD "https://unpkg.com/aos@2.3.1/dist/aos.css" "static/vendor/aos/aos.css"
DOWNLOAD "https://unpkg.com/aos@2.3.1/dist/aos.js" "static/vendor/aos/aos.js"

# ============================================================
#  ALPINE.JS
# ============================================================
echo ""
echo "[3/8] Downloading Alpine.js..."
DOWNLOAD "https://cdn.jsdelivr.net/npm/alpinejs@3.14.1/dist/cdn.min.js" "static/vendor/alpine/alpine.min.js"

# ============================================================
#  CHART.JS
# ============================================================
echo ""
echo "[4/8] Downloading Chart.js..."
DOWNLOAD "https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js" "static/vendor/chartjs/chart.min.js"

# ============================================================
#  BOOTSTRAP ICONS (CSS + Fonts)
# ============================================================
echo ""
echo "[5/8] Downloading Bootstrap Icons..."
DOWNLOAD "https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" \
         "static/vendor/bootstrap-icons/bootstrap-icons.min.css"
DOWNLOAD "https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/fonts/bootstrap-icons.woff2" \
         "static/vendor/bootstrap-icons/fonts/bootstrap-icons.woff2"
DOWNLOAD "https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/fonts/bootstrap-icons.woff" \
         "static/vendor/bootstrap-icons/fonts/bootstrap-icons.woff"

# Fix CSS paths (relative to local structure)
if [ -f "static/vendor/bootstrap-icons/bootstrap-icons.min.css" ]; then
    sed -i 's|\./fonts/|fonts/|g' static/vendor/bootstrap-icons/bootstrap-icons.min.css 2>/dev/null || \
    sed -i '' 's|\./fonts/|fonts/|g' static/vendor/bootstrap-icons/bootstrap-icons.min.css 2>/dev/null || true
    echo "  [OK] CSS paths fixed"
fi

# ============================================================
#  VAZIRMATN FONT
# ============================================================
echo ""
echo "[6/8] Downloading Vazirmatn font..."

# Try CDN CSS first
DOWNLOAD "https://cdn.jsdelivr.net/gh/rastikerdar/vazirmatn@v33.003/Vazirmatn-font-face.css" \
         "static/vendor/vazirmatn/vazirmatn.css"

# Download all font files
FONTS=(
    "Vazirmatn-Thin.woff2"
    "Vazirmatn-ExtraLight.woff2"
    "Vazirmatn-Light.woff2"
    "Vazirmatn-Regular.woff2"
    "Vazirmatn-Medium.woff2"
    "Vazirmatn-SemiBold.woff2"
    "Vazirmatn-Bold.woff2"
    "Vazirmatn-ExtraBold.woff2"
    "Vazirmatn-Black.woff2"
)

for FONT in "${FONTS[@]}"; do
    DOWNLOAD "https://cdn.jsdelivr.net/gh/rastikerdar/vazirmatn@v33.003/fonts/webfonts/$FONT" \
             "static/vendor/vazirmatn/fonts/webfonts/$FONT"
done

# Fix CSS paths to be relative
if [ -f "static/vendor/vazirmatn/vazirmatn.css" ]; then
    # Replace "fonts/webfonts/" if already relative
    # If CSS references absolute CDN URLs, replace them
    sed -i 's|https://cdn.jsdelivr.net/gh/rastikerdar/vazirmatn@v33.003/fonts/webfonts/|fonts/webfonts/|g' \
           static/vendor/vazirmatn/vazirmatn.css 2>/dev/null || \
    sed -i '' 's|https://cdn.jsdelivr.net/gh/rastikerdar/vazirmatn@v33.003/fonts/webfonts/|fonts/webfonts/|g' \
           static/vendor/vazirmatn/vazirmatn.css 2>/dev/null || true
    echo "  [OK] CSS paths fixed"
fi

# ============================================================
#  ENAMAD LOGO (with Referer to bypass hotlink)
# ============================================================
echo ""
echo "[7/8] Downloading Enamad logo..."
DOWNLOAD "https://trustseal.enamad.ir/logo.aspx?id=579249&Code=5B9BO6ucAdCp6ko4MvM4HaxCP4GSH5xv" \
         "static/vendor/images/enamad-logo.png" \
         "https://marjanaram.ir/"

# ============================================================
#  VERIFY
# ============================================================
echo ""
echo "[8/8] Verifying downloads..."
echo ""
ls -lh static/vendor/tailwind/ static/vendor/aos/ static/vendor/alpine/ static/vendor/chartjs/ 2>/dev/null
echo ""
ls -lh static/vendor/bootstrap-icons/ 2>/dev/null
echo ""
ls -lh static/vendor/vazirmatn/ 2>/dev/null
echo ""
ls -lh static/vendor/images/ 2>/dev/null

# ============================================================
#  UPDATE TEMPLATES
# ============================================================
echo ""
echo "=========================================="
echo "  Updating templates..."
echo "=========================================="

python << 'PYEOF'
import os
import re
import glob

# ============================================================
#  URL REPLACEMENT MAP
# ============================================================
REPLACEMENTS = [
    # Tailwind
    ('https://cdn.tailwindcss.com', "{% static 'vendor/tailwind/tailwind.js' %}"),
    ('https://cdn.tailwindcss.com/3.4.1', "{% static 'vendor/tailwind/tailwind.js' %}"),

    # AOS
    ('https://unpkg.com/aos@2.3.1/dist/aos.css', "{% static 'vendor/aos/aos.css' %}"),
    ('https://unpkg.com/aos@2.3.1/dist/aos.js', "{% static 'vendor/aos/aos.js' %}"),

    # Alpine.js
    ('https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js', "{% static 'vendor/alpine/alpine.min.js' %}"),
    ('https://cdn.jsdelivr.net/npm/alpinejs@3.14.1/dist/cdn.min.js', "{% static 'vendor/alpine/alpine.min.js' %}"),

    # Chart.js
    ('https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js', "{% static 'vendor/chartjs/chart.min.js' %}"),
    ('https://cdn.jsdelivr.net/npm/chart.js', "{% static 'vendor/chartjs/chart.min.js' %}"),

    # Bootstrap Icons
    ('https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css', "{% static 'vendor/bootstrap-icons/bootstrap-icons.min.css' %}"),

    # Vazirmatn
    ('https://cdn.jsdelivr.net/gh/rastikerdar/vazirmatn@v33.003/Vazirmatn-font-face.css', "{% static 'vendor/vazirmatn/vazirmatn.css' %}"),

    # Google Fonts (Roboto)
    ('https://fonts.googleapis.com/css?family=Roboto:100,100italic,200,200italic,300,300italic,400,400italic,500,500italic,600,600italic,700,700italic,800,800italic,900,900italic&display=swap', ''),
    ('https://fonts.googleapis.com/css?family=Roboto+Slab:100,100italic,200,200italic,300,300italic,400,400italic,500,500italic,600,600italic,700,700italic,800,800italic,900,900italic&display=swap', ''),

    # Enamad logo
    ("https://trustseal.enamad.ir/logo.aspx?id=579249&Code=5B9BO6ucAdCp6ko4MvM4HaxCP4GSH5xv", "{% static 'vendor/images/enamad-logo.png' %}"),
    ("https://trustseal.enamad.ir/logo.aspx?id=579249&amp;Code=5B9BO6ucAdCp6ko4MvM4HaxCP4GSH5xv", "{% static 'vendor/images/enamad-logo.png' %}"),
]


def ensure_static_load(text):
    """Ensure {% load static %} is present when static tag is used"""
    if '{% static ' in text and '{% load static %}' not in text:
        # Find first {% extends %} and add after it
        if '{% extends' in text:
            lines = text.split('\n')
            for i, line in enumerate(lines):
                if line.strip().startswith('{% extends'):
                    lines.insert(i + 1, '{% load static %}')
                    break
            return '\n'.join(lines)
        else:
            return '{% load static %}\n' + text
    return text


def apply_replacements(text):
    for old, new in REPLACEMENTS:
        if old in text:
            text = text.replace(old, new)
    return text


# ============================================================
#  Process all templates
# ============================================================
templates = []
for pattern in ['templates/*.html', 'templates/**/*.html']:
    templates.extend(glob.glob(pattern, recursive=True))

processed = 0
for path in sorted(set(templates)):
    try:
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()

        original = content
        content = apply_replacements(content)
        content = ensure_static_load(content)

        if content != original:
            with open(path, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"[OK] {path}")
            processed += 1
    except Exception as e:
        print(f"[ERR] {path}: {e}")

# ============================================================
#  Process admin templates (they already have static loaded)
# ============================================================
admin_templates = glob.glob('templates/admin/*.html')
for path in admin_templates:
    try:
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()

        original = content
        content = apply_replacements(content)

        if content != original:
            with open(path, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"[OK] {path}")
            processed += 1
    except Exception as e:
        print(f"[ERR] {path}: {e}")

print(f"\n[DONE] {processed} files updated")
PYEOF

# ============================================================
#  VERIFY NO EXTERNAL URLS LEFT
# ============================================================
echo ""
echo "=========================================="
echo "  Remaining External URLs"
echo "=========================================="
echo ""

grep -rEn "https?://(cdn|unpkg|jsdelivr|fonts\.googleapis|fonts\.gstatic|trustseal)" \
    --include="*.html" \
    templates/ 2>/dev/null \
    | grep -v "schema.org" \
    | grep -v "w3.org" \
    | grep -v "creativecommons" \
    || echo "  [OK] No external CDN URLs found in templates"

echo ""

# ============================================================
#  Collectstatic
# ============================================================
echo "Collecting static files..."
python manage.py collectstatic --noinput 2>&1 | tail -3 || true

echo ""
echo "=========================================="
echo "  [OK] Offline setup complete!"
echo "=========================================="
echo ""
echo "Summary of local resources:"
echo "  static/vendor/tailwind/tailwind.js"
echo "  static/vendor/aos/aos.css + aos.js"
echo "  static/vendor/alpine/alpine.min.js"
echo "  static/vendor/chartjs/chart.min.js"
echo "  static/vendor/bootstrap-icons/ (CSS + fonts)"
echo "  static/vendor/vazirmatn/ (CSS + 9 font files)"
echo "  static/vendor/images/enamad-logo.png"
echo ""
echo "Next steps:"
echo "1. Ctrl+C to stop server"
echo "2. python manage.py runserver"
echo "3. Ctrl+Shift+R in browser"
echo ""
echo "Everything will now work OFFLINE!"
echo ""