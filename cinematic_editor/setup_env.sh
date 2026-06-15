#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════════
# setup_env.sh  -  تهيئة بيئة التطوير الكاملة
# الاستخدام: chmod +x setup_env.sh && ./setup_env.sh
# ════════════════════════════════════════════════════════════════
set -e

echo "════════════════════════════════════════════════════"
echo "  Cinematic Editor - Environment Setup"
echo "════════════════════════════════════════════════════"

# ── Flutter ──────────────────────────────────────────────────
echo "\n📱 تثبيت Flutter..."
if ! command -v flutter &>/dev/null; then
    cd /home/codespace
    wget -q https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.22.0-stable.tar.xz
    tar xf flutter_linux_3.22.0-stable.tar.xz
    echo 'export PATH="$PATH:/home/codespace/flutter/bin"' >> ~/.bashrc
    export PATH="$PATH:/home/codespace/flutter/bin"
fi
flutter --version

# ── Dependencies ─────────────────────────────────────────────
echo "\n📦 تثبيت المكتبات..."
flutter pub get

# ── Code Generation ──────────────────────────────────────────
echo "\n⚙️  توليد الكود التلقائي..."
dart run build_runner build --delete-conflicting-outputs

# ── Backend ──────────────────────────────────────────────────
echo "\n🐍 تثبيت اعتماديات Python..."
cd backend
pip install -r requirements.txt --break-system-packages -q
cd ..

# ── Firebase ─────────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════════════════"
echo "  الخطوات التالية اليدوية:"
echo "════════════════════════════════════════════════════"
echo "1. flutterfire configure   (إعداد Firebase)"
echo "2. cp backend/.env.example backend/.env && nano backend/.env"
echo "3. ضع ملفات TFLite في assets/models/"
echo "4. ضع خطوط Inter في assets/fonts/"
echo "5. flutter run"
echo "════════════════════════════════════════════════════"
