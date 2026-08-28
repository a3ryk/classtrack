# ClassTrack In-App Updater Guide

A production-ready, secure, and customizable In-App Update system for **ClassTrack**.

---

## 1. Overview & Architecture

The ClassTrack In-App Updater allows the application to automatically or manually check for new app releases, compare versions using semantic versioning, display interactive release notes (changelogs), and provide direct downloads or store links without requiring third-party proprietary services.

```
┌────────────────────────────────────────────────────────┐
│               ClassTrack App (Client)                  │
│                                                        │
│  Settings > Check for Updates                          │
│         │                                              │
│         ▼                                              │
│  AppUpdateService.fetchReleaseInfo()                   │
└───────────────────────┬────────────────────────────────┘
                        │ HTTPS Request (10s Timeout)
                        ▼
┌────────────────────────────────────────────────────────┐
│           Remote Version Manifest (JSON)               │
│  (Hosted on GitHub, GitHub Pages, Firebase, or CDN)    │
│                                                        │
│  {                                                     │
│    "latest_version": "1.2.0",                         │
│    "min_supported_version": "1.0.0",                   │
│    "changelog": ["✨ New features", "🛠️ Bug fixes"],   │
│    "download_url": "https://.../app-release.apk"       │
│  }                                                     │
└───────────────────────┬────────────────────────────────┘
                        │
                        ▼
┌────────────────────────────────────────────────────────┐
│             Semver & State Resolution                  │
│                                                        │
│  • Up to date?  ──> Show UpToDateDialog                │
│  • Optional?    ──> Show UpdateAvailableDialog (Later) │
│  • Mandatory?   ──> Show Blocking Mandatory Dialog     │
└────────────────────────────────────────────────────────┘
```

---

## 2. Setting Up & Hosting `version.json`

You can host your `version.json` anywhere that serves static JSON over **HTTPS**.

### Option A: GitHub Raw URL (Easiest & Free)
1. Push `version.json` to the `main` branch of your GitHub repository.
2. The raw URL will be:
   ```
   https://raw.githubusercontent.com/<YOUR_USERNAME>/<YOUR_REPO>/main/version.json
   ```
3. Update `UpdateConstants.defaultVersionCheckUrl` in `lib/core/constants/update_constants.dart`:
   ```dart
   static const String defaultVersionCheckUrl =
       'https://raw.githubusercontent.com/<YOUR_USERNAME>/<YOUR_REPO>/main/version.json';
   ```

### Option B: GitHub Pages / Cloudflare Pages / Vercel
1. Place `version.json` in the `public/` or `docs/` folder of your web deployment.
2. Endpoint: `https://your-domain.com/version.json`

### Option C: GitHub Releases API Fallback (Automatic)
If `version.json` is unreachable or not configured, the updater automatically queries GitHub's public Releases API:
```
https://api.github.com/repos/<owner>/<repo>/releases/latest
```
It will extract the release tag, changelog notes, and any `.apk` attached in the release assets automatically.

---

## 3. `version.json` Schema Reference

Here is the complete JSON structure:

```json
{
  "latest_version": "1.2.0",
  "build_number": 2,
  "min_supported_version": "1.0.0",
  "release_date": "2026-08-25",
  "release_title": "ClassTrack v1.2.0 Feature Release",
  "changelog": [
    "✨ Modern responsive bottom navigation bar with crisp active state",
    "⚡ Multi-day Batch Add Slots with strict validations",
    "🛠️ Fixed university selector dropdown assertion crash",
    "🎨 Sleek 8px refined input borders across all modals",
    "🔒 Secure In-App Updater with changelog viewing and semver comparison"
  ],
  "download_url": "https://github.com/<owner>/<repo>/releases/download/v1.2.0/classtrack-v1.2.0.apk",
  "release_page_url": "https://github.com/<owner>/<repo>/releases",
  "is_mandatory": false
}
```

### Field Definitions:

| Field | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `latest_version` | `String` | Yes | The latest version string (e.g., `"1.2.0"`). |
| `build_number` | `int` | No | Internal build number (e.g., `2`). |
| `min_supported_version` | `String` | No | Minimum app version required to continue using the app. If the user\'s version is lower, the update becomes **mandatory**. |
| `release_date` | `String` | No | Date of release displayed in the modal (e.g., `"2026-08-25"`). |
| `release_title` | `String` | No | Title shown in the update modal. |
| `changelog` | `List<String>` | Yes | Array of bullet points describing improvements and fixes. |
| `download_url` | `String` | No | Direct link to the APK file or installer. |
| `release_page_url` | `String` | No | Web link to the GitHub release page or Play Store/App Store listing. |
| `is_mandatory` | `bool` | No | Set to `true` to force a blocking update. |

---

## 4. Mandatory vs. Flexible Updates

- **Flexible (Optional) Update**:
  - `is_mandatory: false` and `min_supported_version <= current_version`.
  - User can tap **Update Now** or tap **Later** to dismiss the dialog.
- **Mandatory (Forced) Update**:
  - `is_mandatory: true` OR `min_supported_version > current_version`.
  - Used when critical database migrations or breaking API changes are released.
  - Dialog cannot be dismissed via back button or clicking outside (`PopScope(canPop: false)`).

---

## 5. Publishing a New Release Workflow

Follow these 4 simple steps whenever releasing a new version:

### Step 1: Bump Version in `pubspec.yaml`
```yaml
# Format: <version>+<build_number>
version: 1.2.0+2
```

### Step 2: Build the Release Binary
```bash
# Build Android APK
flutter build apk --release

# Output located at: build/app/outputs/flutter-apk/app-release.apk
```

### Step 3: Create a GitHub Release
1. Go to your repository on GitHub $\rightarrow$ **Releases** $\rightarrow$ **Draft a new release**.
2. Tag: `v1.2.0`.
3. Title: `ClassTrack v1.2.0`.
4. Attach `app-release.apk` to the release assets.
5. Publish Release.

### Step 4: Update `version.json`
Update your hosted `version.json` with the new version number, changelog, and APK link. All installed apps will immediately detect the update when checking!

---

## 6. Security & Hardening Features

- **Strict HTTPS Enforcement**: Rejects any non-HTTPS version check URLs (protects against MITM attacks on public Wi-Fi).
- **Safe Semver Parser**: Strips prefixes (`v`, `V`), ignores extra metadata safely, and prevents integer parsing crashes.
- **Strict Network Timeout**: All update checks are protected with a 10-second timeout to prevent connection hangs.
- **External Intent Isolation**: Download links are opened securely using `LaunchMode.externalApplication`.
