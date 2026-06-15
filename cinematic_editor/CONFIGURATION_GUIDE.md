# 🎬 Cinematic Editor - Configuration & Placeholder Guide

This document outlines all the configuration steps needed before building and deploying the Cinematic Editor project.

---

## 📋 Table of Contents

1. [AI Model Files](#ai-model-files)
2. [Backend API Keys](#backend-api-keys)
3. [Frontend Configuration](#frontend-configuration)
4. [Firebase Setup](#firebase-setup)
5. [GitHub Actions Workflow](#github-actions-workflow)
6. [Environment Variables](#environment-variables)

---

## 🤖 AI Model Files

### Required TFLite Models

All model files must be placed in the `assets/models/` directory before building.

#### 1. **Whisper Tiny Speech Recognition** (~75 MB)
- **File**: `whisper_tiny.tflite`
- **Purpose**: Speech-to-text transcription for audio tracks
- **Source Options**:
  - Official OpenAI: https://huggingface.co/openai/whisper-tiny
  - Pre-converted TFLite: https://github.com/usefulsensors/tiny_whisper
- **Download Steps**:
  ```bash
  # Option A: Using HuggingFace
  pip install transformers onnx tf2onnx
  python -c "from transformers import WhisperProcessor, WhisperForConditionalGeneration; model = WhisperForConditionalGeneration.from_pretrained('openai/whisper-tiny')"
  
  # Option B: Direct download (pre-converted)
  cd assets/models
  wget https://github.com/usefulsensors/tiny_whisper/releases/download/v1/whisper_tiny.tflite
  ```
- **Status**: ❌ **NOT YET CONFIGURED** - Download and place in `assets/models/`
- **Associated Files**:
  - `lib/features/audio/services/` - Audio transcription service
  - `pubspec.yaml` - `tflite_flutter: ^0.10.4` dependency

#### 2. **MediaPipe Selfie Segmentation** (~1 MB)
- **File**: `selfie_segmentation.tflite`
- **Purpose**: Real-time background removal and keying
- **Source**: Official MediaPipe Models
- **Download Steps**:
  ```bash
  cd assets/models
  wget "https://storage.googleapis.com/mediapipe-models/image_segmenter/selfie_segmenter/float16/1/selfie_segmenter.tflite"
  ```
- **Status**: ❌ **NOT YET CONFIGURED** - Download and place in `assets/models/`
- **Associated Files**:
  - `android/app/src/main/kotlin/com/cinematiceditor/MediaPipePlugin.kt` - Android Platform Channel
  - `lib/features/export/services/export_service.dart` - Segmentation service

#### 3. **MediaPipe Selfie Segmentation Landscape** (~1 MB) - Optional
- **File**: `selfie_segmentation_landscape.tflite`
- **Purpose**: Optimized segmentation for landscape video orientation
- **Source**: Official MediaPipe Models
- **Download Steps**:
  ```bash
  cd assets/models
  wget "https://storage.googleapis.com/mediapipe-models/image_segmenter/selfie_segmenter_landscape/float16/1/selfie_segmenter_landscape.tflite"
  ```
- **Status**: ⚠️ **OPTIONAL** - Recommended for landscape video support
- **Associated Files**: Same as selfie_segmentation.tflite

---

## 🔐 Backend API Keys

All API keys must be added to `backend/.env` (copied from `backend/.env.example`).

### Required Backend Configuration

#### 1. **JWT Secret Key** (Security)
- **File**: `backend/.env` → `JWT_SECRET_KEY`
- **Purpose**: Server authentication and token signing
- **Current Value**: `CHANGE_THIS_TO_A_RANDOM_64_CHAR_STRING`
- **Status**: ⚠️ **MUST CHANGE** - Generate a secure random key
- **How to Generate**:
  ```bash
  python -c "import secrets; print(secrets.token_urlsafe(64))"
  # or
  openssl rand -base64 32
  ```
- **Associated Files**:
  - `backend/app/core/security.py` - JWT token generation
  - `backend/app/core/config.py` - JWT configuration

#### 2. **AWS Credentials** (Cloud Storage)
- **Files**: 
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
  - `AWS_REGION` (default: `us-east-1`)
  - `AWS_S3_BUCKET` (default: `cinematic-editor-assets`)
- **Purpose**: Store video files, proxies, and exports in S3
- **Status**: ⚠️ **REQUIRED FOR PRODUCTION** - Get from AWS IAM console
- **How to Get**:
  1. Go to AWS IAM Console: https://console.aws.amazon.com/iam/
  2. Create new user with S3 access
  3. Generate access key and secret key
- **Associated Files**:
  - `backend/app/api/routes/video_routes.py` - Video upload
  - `backend/app/services/` - S3 storage service

#### 3. **Anthropic API Key** (AI Command Processing)
- **File**: `backend/.env` → `ANTHROPIC_API_KEY`
- **Purpose**: Process Arabic natural language commands and AI suggestions
- **Status**: ⚠️ **REQUIRED FOR AI FEATURES**
- **How to Get**:
  1. Visit: https://console.anthropic.com/
  2. Create account and API key
  3. Copy key to `backend/.env`
- **Associated Files**:
  - `backend/app/core/config.py` - Anthropic configuration
  - `backend/app/api/routes/ai_routes.py` - AI endpoint
  - `lib/features/ai_commands/services/` - Frontend AI service

#### 4. **Stripe Secret Key** (Payments)
- **Files**:
  - `STRIPE_SECRET_KEY`
  - `STRIPE_WEBHOOK_SECRET`
- **Purpose**: In-app subscription and payment processing
- **Status**: ⚠️ **REQUIRED FOR MONETIZATION**
- **How to Get**:
  1. Go to: https://dashboard.stripe.com/
  2. Navigate to API Keys → Reveal secret key
  3. Create webhook endpoint for payment events
- **Associated Files**:
  - `backend/app/services/payment_service.py`
  - `lib/features/subscription/services/`

#### 5. **RevenueCat API Key** (Subscription Validation)
- **File**: `backend/.env` → `REVENUECAT_API_KEY`
- **Purpose**: Cross-platform subscription validation (iOS/Android)
- **Status**: ⚠️ **OPTIONAL BUT RECOMMENDED** - For iOS subscription compliance
- **How to Get**:
  1. Visit: https://app.revenuecat.com/
  2. Create project and API key
  3. Copy to `backend/.env` and Flutter constants
- **Associated Files**:
  - `backend/app/core/config.py`
  - `lib/features/subscription/services/subscription_service.dart`
  - `pubspec.yaml` - `purchases_flutter: ^6.0.0`

#### 6. **Database URLs** (Backend Storage)
- **Files**:
  - `DATABASE_URL`: PostgreSQL connection string
  - `REDIS_URL`: Redis cache connection string
- **Purpose**: Project data and session caching
- **Format**: 
  - PostgreSQL: `postgresql+asyncpg://user:password@host:5432/database`
  - Redis: `redis://localhost:6379`
- **Status**: ⚠️ **REQUIRED FOR BACKEND**
- **Associated Files**:
  - `backend/app/core/config.py`
  - `backend/app/models/` - Database models

---

## 🎨 Frontend Configuration

### Flutter App Constants

**File**: `lib/shared/constants/app_constants.dart`

| Constant | Type | Purpose | Current Value | Status |
|----------|------|---------|----------------|--------|
| `apiBaseUrl` | String | Backend API endpoint | `https://api.cinematiceditor.com/v1` | ⚠️ Update for production |
| `wsBaseUrl` | String | WebSocket URL | `wss://ws.cinematiceditor.com/v1` | ⚠️ Update for production |
| `freeTrialDays` | int | Trial duration | `3` | ✅ Configurable |
| `freeExportLimit4K` | int | Max 4K exports (free) | `3` | ✅ Configurable |
| `freeExportLimit1080p` | int | Max 1080p exports (free) | `10` | ✅ Configurable |

**Associated Files Needing Configuration**:
1. `lib/features/subscription/services/subscription_service.dart` - RevenueCat keys
2. `lib/features/auth/services/` - Firebase authentication
3. `lib/core/services/api_service.dart` - API base URL

---

## 🔥 Firebase Setup

### Required Steps

Firebase is used for authentication, analytics, and crash reporting.

#### 1. **Generate Firebase Configuration**

```bash
cd cinematic_editor/
flutterfire configure
```

This command will:
- Create `google-services.json` for Android
- Create `GoogleService-Info.plist` for iOS
- Generate Firebase configuration files

#### 2. **Firebase Console**

Go to: https://console.firebase.google.com/

1. Create new project: "Cinematic Editor"
2. Add Android app:
   - Package name: `com.cinematiceditor`
   - SHA-1 fingerprint: (generated by `flutterfire configure`)
3. Add iOS app:
   - Bundle ID: `com.cinematiceditor`
4. Enable Services:
   - ✅ Authentication (Email/Password, Google Sign-In)
   - ✅ Cloud Firestore
   - ✅ Analytics
   - ✅ Crashlytics

#### 3. **Associated Dependencies**

From `pubspec.yaml`:
```yaml
firebase_core: ^3.3.0
firebase_analytics: ^11.2.1
firebase_crashlytics: ^4.0.4
firebase_auth: ^5.1.4
cloud_firestore: ^5.2.1
```

**Associated Files**:
- `lib/features/auth/services/firebase_auth_service.dart`
- `lib/core/services/firebase_service.dart`
- `lib/main.dart` - Firebase initialization

---

## 🔄 GitHub Actions Workflow

### Build Configuration

**File**: `.github/workflows/build.yml`

The workflow automatically:
1. ✅ Sets up Java JDK 17
2. ✅ Installs Android SDK & NDK
3. ✅ Sets up Flutter environment
4. ✅ Builds C++ native code
5. ✅ Compiles Android APK
6. ✅ Generates AAB for Play Store
7. ✅ Uploads artifacts

### Manual Trigger

```bash
# Trigger from GitHub UI or CLI:
gh workflow run build.yml --ref main --input release_type=release
```

### Output Artifacts

- **APK**: `build/app/outputs/apk/` (debug & release splits)
- **AAB**: `build/app/outputs/bundle/release/app-release.aab` (Play Store)
- **Logs**: Available for 30 days in Actions tab

---

## 📝 Environment Variables

### Backend Configuration

**File**: `backend/.env`

```bash
# Database
DATABASE_URL=postgresql+asyncpg://user:password@localhost/cinematic_db
REDIS_URL=redis://localhost:6379

# Security
JWT_SECRET_KEY=<YOUR_SECURE_RANDOM_64_CHAR_KEY>
JWT_ALGORITHM=HS256

# AWS
AWS_ACCESS_KEY_ID=<YOUR_AWS_ACCESS_KEY>
AWS_SECRET_ACCESS_KEY=<YOUR_AWS_SECRET_KEY>
AWS_REGION=us-east-1
AWS_S3_BUCKET=cinematic-editor-assets

# AI (Anthropic)
ANTHROPIC_API_KEY=<YOUR_ANTHROPIC_API_KEY>

# Payments
STRIPE_SECRET_KEY=<YOUR_STRIPE_SECRET_KEY>
STRIPE_WEBHOOK_SECRET=<YOUR_STRIPE_WEBHOOK_SECRET>

# Subscriptions
REVENUECAT_API_KEY=<YOUR_REVENUECAT_API_KEY>
```

### Flutter Configuration

**File**: `lib/shared/constants/app_constants.dart`

Update for your environment:
```dart
static const String apiBaseUrl = 'https://your-domain.com/api/v1';
static const String wsBaseUrl = 'wss://your-domain.com/api/v1';
```

---

## ✅ Pre-Launch Checklist

- [ ] Downloaded and placed all `.tflite` model files in `assets/models/`
- [ ] Created `backend/.env` from `backend/.env.example`
- [ ] Set all required API keys in `backend/.env`
- [ ] Generated and set JWT_SECRET_KEY
- [ ] Configured AWS S3 credentials
- [ ] Set up Anthropic API key
- [ ] Ran `flutterfire configure` and generated Firebase config
- [ ] Updated API base URLs in `lib/shared/constants/app_constants.dart`
- [ ] Created Stripe account and webhooks
- [ ] Set up RevenueCat (optional)
- [ ] Verified all Android/NDK toolchain is available
- [ ] Tested GitHub Actions workflow with manual trigger

---

## 🚀 Next Steps

1. **Download Models** (See [AI Model Files](#ai-model-files) section)
2. **Configure Backend** (See [Backend API Keys](#backend-api-keys) section)
3. **Setup Firebase** (See [Firebase Setup](#firebase-setup) section)
4. **Build Project**:
   ```bash
   cd cinematic_editor
   flutter pub get
   flutter build apk --release
   ```
5. **Deploy**:
   ```bash
   # Push to main branch to trigger GitHub Actions
   git push origin main
   ```

---

## 📞 Support

For detailed setup instructions, refer to:
- Flutter Docs: https://flutter.dev/docs
- Firebase Setup: https://firebase.google.com/docs/flutter/setup
- FastAPI Docs: https://fastapi.tiangolo.com/
- Android NDK: https://developer.android.com/ndk

---

**Last Updated**: 2026-06-15
**Status**: ⚠️ Configuration Required Before Production
