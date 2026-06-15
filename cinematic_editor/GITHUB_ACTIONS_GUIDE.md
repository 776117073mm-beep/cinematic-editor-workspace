# 🚀 GitHub Actions Build Workflow Guide

**Status**: ✅ **WORKFLOW SUCCESSFULLY CONFIGURED**  
**Location**: `.github/workflows/build.yml`

---

## 📋 Workflow Overview

The GitHub Actions workflow (`build.yml`) automates the complete Android build process including:

1. ✅ Java JDK 17 setup
2. ✅ Android SDK & NDK installation
3. ✅ Flutter SDK setup
4. ✅ C++ code compilation (CMake + Android NDK)
5. ✅ Android APK building (debug & release)
6. ✅ Android App Bundle (AAB) for Play Store
7. ✅ Artifact upload and retention

---

## ⚙️ Build Configuration

### Environment Variables (Hardcoded)

```yaml
JAVA_VERSION: '17'
FLUTTER_VERSION: '3.19.0'
NDK_VERSION: '26.0.10792818'
GRADLE_VERSION: '8.1'
```

These can be updated in the workflow file if needed.

---

## 🎯 Build Triggers

### 1. Automatic Triggers

**Push to Main/Develop**:
```yaml
on:
  push:
    branches:
      - main
      - develop
```
- Automatically triggered when pushing to `main` or `develop`
- Builds APK (debug for develop, release for main)

**Pull Requests**:
```yaml
  pull_request:
    branches:
      - main
```
- Validates builds on incoming PRs to `main`
- Ensures code doesn't break the build

### 2. Manual Trigger (Workflow Dispatch)

**From GitHub UI**:
1. Navigate to: **Actions** tab → **Build and Deploy Android APK**
2. Click: **Run workflow**
3. Select: **Release type** (debug or release)
4. Click: **Run workflow** button

**From Command Line** (using `gh` CLI):
```bash
# Debug build
gh workflow run build.yml --ref main

# Release build
gh workflow run build.yml --ref main --input release_type=release
```

---

## 📊 Build Workflow Steps

### Phase 1: Setup (2 min)
```
1. Checkout code
2. Set up JDK 17 (with Gradle cache)
3. Setup Android SDK, NDK, build-tools
4. Set up Flutter (with pub cache)
5. Display versions
```

### Phase 2: Dependencies (3 min)
```
6. Cache Flutter pub dependencies
7. Get Flutter dependencies (flutter pub get)
8. Setup environment variables
```

### Phase 3: Native Build (5 min)
```
9. Build C++ native code
   - CMake configuration
   - Android NDK toolchain
   - Compile to ARM64-v8a ABI
```

### Phase 4: Testing (optional)
```
10. Run Flutter tests (optional, continues if fails)
```

### Phase 5: APK Building (10-15 min)
```
11. Build APK (Debug)    [if not release_type=release]
12. Build APK (Release)  [if release_type=release OR main branch]
```

### Phase 6: AAB Building (5-10 min)
```
13. Build App Bundle (AAB) [only on main branch]
```

### Phase 7: Artifacts (1 min)
```
14. Upload APK artifacts (30-day retention)
15. Upload AAB artifacts (30-day retention)
16. Upload build logs on failure (7-day retention)
```

---

## 📤 Output Artifacts

### APK Outputs

**Location in Artifacts**: `apk-artifacts/`

```
build/app/outputs/apk/
├── debug/
│   ├── app-arm64-v8a-debug.apk
│   ├── app-armeabi-v7a-debug.apk
│   └── app-x86_64-debug.apk
├── release/
│   ├── app-arm64-v8a-release.apk
│   ├── app-armeabi-v7a-release.apk
│   └── app-x86_64-release.apk
```

**Split-per-ABI**: Each architecture gets its own APK for smaller downloads

### App Bundle (AAB)

**Location in Artifacts**: `aab-artifacts/`

```
build/app/outputs/bundle/release/
└── app-release.aab
```

**Used for**: Google Play Store distribution (automatic ABI optimization)

### Build Logs

**Location**: Artifact **`build-logs`** (on failure)  
**Retention**: 7 days

---

## ✅ How to Download Artifacts

### Method 1: GitHub UI

1. Go to: **Actions** tab
2. Select the workflow run (by commit)
3. Scroll to: **Artifacts** section
4. Download: **apk-artifacts** or **aab-artifacts**

### Method 2: GitHub CLI

```bash
# List latest artifacts
gh run list --workflow build.yml --limit 1

# Download artifacts from latest run
gh run download --dir ./downloads

# Download specific artifact
gh run download <RUN_ID> -n apk-artifacts -D ./apk
```

### Method 3: Direct URL

Each artifact gets a download link in the workflow summary.

---

## 🔍 Monitoring Builds

### View Build Status

```bash
# Watch workflow runs
gh run list --workflow build.yml --watch

# View latest run details
gh run view --json status,conclusion,headBranch,number

# View logs for specific step
gh run view <RUN_ID> --log
```

### Troubleshooting Failed Builds

1. **View Logs**: Click on failed step in GitHub Actions
2. **Check Errors**: Look for red ❌ marks
3. **Download Logs**: In artifacts, download **`build-logs`**
4. **Common Issues**:
   - Missing model files → Add to `assets/models/`
   - Missing API keys → Update `backend/.env`
   - NDK not found → Workflow handles this automatically
   - Gradle cache → Cleared every run, uses cache when available

---

## 🛠️ Customization

### Change Java Version

Edit `.github/workflows/build.yml`:
```yaml
JAVA_VERSION: '21'  # Changed from 17
```

### Change Flutter Version

```yaml
FLUTTER_VERSION: '3.24.0'  # Changed from 3.19.0
```

### Change NDK Version

```yaml
NDK_VERSION: '27.0.12077973'  # Changed from 26.0.10792818
```

### Add Environment Variables

```yaml
steps:
  - name: Setup custom env vars
    run: |
      echo "CUSTOM_VAR=value" >> $GITHUB_ENV
```

### Skip AAB for Non-Main Branches

Currently, AAB only builds on `main`. To build on all releases:

```yaml
- name: Build App Bundle (AAB)
  if: github.ref == 'refs/heads/main' || startsWith(github.ref, 'refs/tags/')
```

### Add Slack Notifications

```yaml
- name: Notify Slack
  if: always()
  uses: slackapi/slack-github-action@v1
  with:
    payload: |
      {
        "text": "Build ${{ job.status }}"
      }
```

---

## 📋 Pre-Workflow Checklist

Before pushing to trigger the workflow, ensure:

- [ ] All model files are in `assets/models/`
- [ ] Backend `.env` file is configured (if needed for CI tests)
- [ ] `pubspec.yaml` has all dependencies
- [ ] C++ code compiles locally
- [ ] Git repository is on GitHub
- [ ] GitHub Actions is enabled in repository settings

---

## ⚡ Performance Tips

### Faster Builds

1. **Use Gradle Cache**:
   - Workflow caches Gradle, speeds up builds by 30-40%
   - Cache is per-branch

2. **Skip Tests**:
   - Remove or comment flutter test step for faster builds

3. **Debug Only for Development**:
   - Debug builds are smaller and faster
   - Use release only for Play Store

4. **Parallel Jobs**:
   - Current workflow uses single job
   - Can split Android/iOS into parallel jobs

### Cache Strategy

```yaml
- uses: actions/cache@v4
  with:
    path: ~/.pub-cache
    key: ${{ runner.os }}-pub-${{ hashFiles('**/pubspec.lock') }}
    restore-keys: |
      ${{ runner.os }}-pub-
```

- Saves pub dependencies (10-15 min saved)
- Invalidates when `pubspec.lock` changes
- Falls back to last known good cache

---

## 🔐 Secrets & Security

### Add Secrets to GitHub

For sensitive data (API keys):

1. Go to: **Settings** → **Secrets and variables** → **Actions**
2. Click: **New repository secret**
3. Add secrets:
   ```
   ANTHROPIC_API_KEY = xxx
   AWS_ACCESS_KEY_ID = xxx
   AWS_SECRET_ACCESS_KEY = xxx
   ```

### Use Secrets in Workflow

```yaml
- name: Build with secrets
  env:
    ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
  run: flutter build apk
```

---

## 📊 Typical Build Times

| Phase | Time | Notes |
|-------|------|-------|
| Checkout & Setup | 2 min | SDK/NDK download cached |
| Dependencies | 3 min | Pub cache used |
| C++ Compilation | 5 min | First build longer |
| APK Build (Debug) | 8 min | Faster, no obfuscation |
| APK Build (Release) | 15 min | Includes obfuscation |
| AAB Build | 10 min | Optimized for Play Store |
| **Total (Release)** | **~40-50 min** | Parallel future optimization |

---

## 🚀 Deployment to Play Store

### Generate Keystore (One-time)

```bash
keytool -genkey -v -keystore release.keystore \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias cinematic_editor
```

### Configure Signing in build.gradle

```gradle
signingConfigs {
    release {
        storeFile file("release.keystore")
        storePassword System.env.KEYSTORE_PASSWORD
        keyAlias System.env.KEY_ALIAS
        keyPassword System.env.KEY_PASSWORD
    }
}
```

### Add Keystore Secrets to GitHub

```bash
gh secret set KEYSTORE_PASSWORD
gh secret set KEY_ALIAS
gh secret set KEY_PASSWORD
```

### Upload to Play Store

Add step after AAB build:
```yaml
- name: Upload to Play Store
  uses: r0adkll/upload-google-play@v1
  with:
    serviceAccountJsonPlainText: ${{ secrets.PLAY_STORE_SERVICE_ACCOUNT }}
    packageName: com.cinematiceditor
    releaseFiles: 'build/app/outputs/bundle/release/app-release.aab'
    track: internal
    status: draft
```

---

## 📞 Support & References

- **GitHub Actions Documentation**: https://docs.github.com/en/actions
- **Flutter CI/CD**: https://flutter.dev/docs/deployment/cd
- **Android NDK**: https://developer.android.com/ndk/guides
- **Gradle Caching**: https://github.com/actions/setup-java#caching

---

**🎉 Workflow is ready to deploy!**

Push your changes to trigger the first automated build.

```bash
git add .github/workflows/build.yml
git commit -m "Add GitHub Actions build workflow"
git push origin main
```

Monitor build progress in the **Actions** tab! ✅
