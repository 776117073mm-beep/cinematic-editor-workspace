# 📋 Quick Reference: Placeholders by File

This is a quick lookup guide for which files contain placeholders and what needs to be configured.

---

## 🔑 API Keys Required

### Backend Environment File
**File**: `backend/.env`
**Copy from**: `backend/.env.example`

```
[REQUIRED] JWT_SECRET_KEY              = <64-char random string>
[REQUIRED] AWS_ACCESS_KEY_ID           = <AWS IAM access key>
[REQUIRED] AWS_SECRET_ACCESS_KEY       = <AWS IAM secret key>
[REQUIRED] DATABASE_URL                = <PostgreSQL connection>
[REQUIRED] REDIS_URL                   = <Redis connection>
[REQUIRED] ANTHROPIC_API_KEY           = <API key from anthropic.com>
[REQUIRED] STRIPE_SECRET_KEY           = <Secret key from stripe.com>
[REQUIRED] STRIPE_WEBHOOK_SECRET       = <Webhook signing secret>
[OPTIONAL] REVENUECAT_API_KEY          = <API key from revenuecat.com>
```

---

## 🤖 Model Files Required

**Location**: `assets/models/`

| File | Size | Purpose | Source | Status |
|------|------|---------|--------|--------|
| `whisper_tiny.tflite` | ~75 MB | Speech recognition | https://github.com/usefulsensors/tiny_whisper | ❌ NOT ADDED |
| `selfie_segmentation.tflite` | ~1 MB | Background removal | https://storage.googleapis.com/mediapipe-models/... | ❌ NOT ADDED |
| `selfie_segmentation_landscape.tflite` | ~1 MB | Landscape mode (optional) | https://storage.googleapis.com/mediapipe-models/... | ⚠️ OPTIONAL |

---

## 📄 Files with Placeholders

### Backend (Python/FastAPI)

| File | Placeholder | Needed For | Type |
|------|-------------|-----------|------|
| `backend/app/core/config.py` | AWS credentials | S3 cloud storage | API Keys |
| `backend/app/core/config.py` | ANTHROPIC_API_KEY | AI text processing | API Key |
| `backend/app/api/routes/ai_routes.py` | Anthropic integration | AI command analysis | API Key |
| `backend/app/api/routes/video_routes.py` | S3 upload/storage | Video export | API Keys |
| `backend/.env.example` | ALL environment vars | Configuration | ENV Setup |

### Frontend (Flutter/Dart)

| File | Placeholder | Needed For | Type |
|------|-------------|-----------|------|
| `lib/shared/constants/app_constants.dart` | apiBaseUrl | Backend connection | URL Config |
| `lib/shared/constants/app_constants.dart` | wsBaseUrl | WebSocket connection | URL Config |
| `lib/shared/constants/app_constants.dart` | RevenueCat keys ref | Subscription validation | API Key Ref |
| `lib/features/subscription/services/subscription_service.dart` | RevenueCat API key | In-app purchases | API Key |
| `lib/features/auth/services/` | Firebase config | User authentication | Firebase Setup |
| `lib/features/export/services/export_service.dart` | MediaPipe models | Background removal | Model Files |

### Android (Kotlin)

| File | Placeholder | Needed For | Type |
|------|-------------|-----------|------|
| `android/app/src/main/kotlin/com/cinematiceditor/MediaPipePlugin.kt` | Model loading | Background segmentation | Model Files |
| `android/app/build.gradle` | NDK/CMake config | C++ compilation | Toolchain |

### Native (C++)

| File | Placeholder | Needed For | Type |
|------|-------------|-----------|------|
| `native/cpp/CMakeLists.txt` | FFmpeg linking | Video encoding | Library Config |
| `native/cpp/engine/src/cinematic_engine.cpp` | FFmpeg integration | Codec implementation | Library Setup |

---

## 🎯 Setup Priority

### Phase 1: Critical (Before Building)
- ✅ Download model files → `assets/models/`
- ✅ Create `backend/.env` from template
- ✅ Generate JWT_SECRET_KEY
- ✅ Run `flutterfire configure`

### Phase 2: Important (Before Production)
- ✅ Add AWS credentials (S3 storage)
- ✅ Add Anthropic API key (AI features)
- ✅ Add Stripe keys (payments)
- ✅ Update API URLs in app_constants.dart

### Phase 3: Optional (For Enhanced Features)
- ⚠️ Add RevenueCat key (iOS subscriptions)
- ⚠️ Add MediaPipe landscape model (landscape support)

---

## 🚀 Verification Commands

### Check Model Files
```bash
ls -lh cinematic_editor/assets/models/*.tflite
```

### Verify Backend Config
```bash
cat cinematic_editor/backend/.env | grep -E "KEY|ANTHROPIC"
```

### Check Firebase Setup
```bash
ls -la cinematic_editor/android/app/google-services.json
ls -la cinematic_editor/ios/Runner/GoogleService-Info.plist
```

### Validate Dart Constants
```bash
grep -A 5 "apiBaseUrl\|PLACEHOLDER" cinematic_editor/lib/shared/constants/app_constants.dart
```

---

## 📞 Quick Lookup

**Q: Where do I put API keys?**
A: Most API keys go in `backend/.env`. Some specific ones (Firebase, RevenueCat) have dedicated config steps.

**Q: Where do model files go?**
A: All `.tflite` files go in `assets/models/`

**Q: How do I generate Firebase config?**
A: Run `flutterfire configure` in the project root.

**Q: What if I don't have AWS?**
A: You'll need to add cloud storage support. AWS is the currently configured provider.

**Q: Can I skip any of these?**
A: Phase 1 is mandatory. Phase 2 depends on features you want. Phase 3 is truly optional.

---

**Last Updated**: 2026-06-15
