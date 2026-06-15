#!/usr/bin/env bash
# بناء نسخة الإنتاج
set -e
echo "🔨 بناء APK للإنتاج..."
flutter build apk \
    --release \
    --obfuscate \
    --split-debug-info=build/debug-info \
    --target-platform android-arm64
echo "✅ APK: build/app/outputs/flutter-apk/app-release.apk"
