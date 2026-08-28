# ClassTrack Production Release & Deployment Guide

This guide provides step-by-step instructions for building, signing, and releasing ClassTrack for **GitHub Releases (Direct APK & In-App Auto-Updating)** and **Google Play Store (App Bundle / AAB)**.

---

## 1. Pre-Build Release Checklist

Before creating a release build, ensure the following configurations are updated:

### A. Version Bump in `pubspec.yaml`
Update `version: <MAJOR>.<MINOR>.<PATCH>+<BUILD_NUMBER>`:
```yaml
version: 1.0.0+1
```
- `1.0.0` is the **Version Name** visible to users.
- `1` is the **Version Code (Build Number)**. Every new release uploaded to GitHub or Play Store **must increment the build number** (e.g. `+2`, `+3`).

### B. Remote Version Manifest Sync in `lib/core/constants/update_constants.dart`
Ensure the default version check URL points to your official repository:
```dart
static const String defaultVersionCheckUrl =
    'https://raw.githubusercontent.com/<YOUR_GITHUB_ORG_OR_USER>/classtrack/main/version.json';

static const String defaultGithubOwner = '<YOUR_GITHUB_USER>';
static const String defaultGithubRepo = 'classtrack';
```

### C. Permissions Verification (`android/app/src/main/AndroidManifest.xml`)
Verify that the following permissions are present:
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="29" />
<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES" />
```

---

## 2. Android Keystore Creation & Release Signing

For production builds, the app must be cryptographically signed with a keystore.

### Step 1: Generate Release Keystore (One-Time)
Run this command in terminal:
```bash
keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
*Keep your keystore file and passwords safe and backed up. Never commit `upload-keystore.jks` or `key.properties` to public Git repositories.*

### Step 2: Configure `android/key.properties`
Create `android/key.properties` with:
```properties
storePassword=<YOUR_KEYSTORE_PASSWORD>
keyPassword=<YOUR_KEY_PASSWORD>
keyAlias=upload
storeFile=upload-keystore.jks
```

### Step 3: Reference Keystore in `android/app/build.gradle.kts`
Ensure `build.gradle.kts` loads `key.properties` in `signingConfigs.release`.

---

## 3. Production Build Commands

Run all build commands from the root directory `d:\Projects\classtrack`.

### 📦 Option A: Universal APK (Recommended for GitHub Releases)
Generates a single standalone `.apk` that works on all Android devices (ARM64, ARMv7, x86_64):
```bash
flutter build apk --release
```
**Output File**: `build/app/outputs/flutter-apk/app-release.apk`
*Rename this file to `ClassTrack-v1.0.0.apk` before uploading to GitHub Releases.*

### ⚡ Option B: Split-per-ABI APKs (Smaller file size ~15MB each)
Generates architecture-specific lightweight APKs:
```bash
flutter build apk --release --split-per-abi
```
**Output Files**:
- `app-arm64-v8a-release.apk` (For 90%+ modern Android phones)
- `app-armeabi-v7a-release.apk` (For older 32-bit Android devices)
- `app-x86_64-release.apk` (For Android emulators and Intel tablets)

### 🏬 Option C: Android App Bundle (For Google Play Store)
Generates an `.aab` archive optimized for Google Play dynamic delivery:
```bash
flutter build appbundle --release
```
**Output File**: `build/app/outputs/bundle/release/app-release.aab`

---

## 4. GitHub Releases Publication Workflow

1. Commit all code and push to your GitHub repository:
   ```bash
   git add .
   git commit -m "Release v1.0.0"
   git push origin main
   ```
2. Create and push a Git version tag:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
3. Go to **GitHub -> Releases -> Draft a new release**:
   - **Tag**: `v1.0.0`
   - **Release Title**: `ClassTrack v1.0.0`
   - **Release Notes / Changelog**: Use bullet points starting with `✨` for features and `🧩` for fixes.
   - **Attach Binaries**: Upload `ClassTrack-v1.0.0.apk`.
4. Update `version.json` in your repository root with the new release details.

---

## 5. In-App Auto-Update Verification Checklist

- [ ] `version.json` is published and accessible over raw HTTPS.
- [ ] Version number in `version.json` is higher than installed version.
- [ ] App prompts with "Update Available" or "Update Required".
- [ ] Tapping "Update Now" downloads the APK directly in-app and opens the installer package.
- [ ] App upgrades successfully without wiping existing SQLite data or attendance records.
