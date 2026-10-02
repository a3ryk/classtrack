# Attendly Release & Update Guide

This document outlines the standard release workflow, mandatory update controls, draft protection mechanisms, and release note formatting for Attendly.

---

## 1. Overview of the Update System

Attendly features an in-app updater and an offline release notes viewer:

1. **"What's New in Attendly" (Offline Release Notes)**:
   - Displays the features of the **currently installed version** on the user's phone.
   - Reads from [`AppReleaseNotes`](../lib/core/constants/app_release_notes.dart) with 0ms latency and 100% offline support.
2. **"Check for Updates" (Remote Updater)**:
   - Queries GitHub's `/repos/a3ryk/classtrack/releases/latest` API.
   - **Draft Protection**: GitHub automatically excludes draft releases and unpublished tags. Users will **never** receive an update notification until you click **"Publish release"** on GitHub.
   - Falls back to `version.json` if GitHub API is unreachable or rate-limited.

---

## 2. Release Note Keywords, GitHub Alerts & Mandatory Update Triggers

When checking for updates, Attendly inspects the release notes via two pathways:
1. **GitHub Releases API** (direct JSON markdown parsing)
2. **GitHub Atom RSS Feed Fallback** (HTML parsing when GitHub API is rate-limited)

### Critical Trigger Rules

> [!WARNING]
> GitHub automatically transforms markdown callout syntax into HTML classes (e.g. `> [!IMPORTANT]` becomes `<div class="markdown-alert markdown-alert-important">`). The Atom feed parser scans for these rendered class names.

| Syntax / Trigger | Parser Evaluated | Result | When to Use |
| :--- | :--- | :--- | :--- |
| `> [!IMPORTANT]` | **Atom Feed HTML** (`markdown-alert-important`) | **MANDATORY** | Critical security advisory or immediate breaking change |
| `> [!WARNING]` | **JSON Parser** (`AlertCalloutType.warning`) & **Atom Feed** (`markdown-alert-warning`) | **MANDATORY** (in Atom fallback) | High-severity alerts or breaking deprecations |
| `> [!CAUTION]` | **JSON Parser** (`isMandatory = true`) & **Atom Feed** (`markdown-alert-caution`) | **MANDATORY** | High-risk breaking changes or urgent database migration required |
| `"Mandatory Update"` | **Atom Feed HTML** | **MANDATORY** | Exact phrase in release notes |
| `🚨`, `🛑` | **JSON Parser** (Line start) | **MANDATORY** | Emergency hotfix |
| `MANDATORY:`, `CRITICAL:`, `BREAKING:` | **JSON Parser** (Line start) | **MANDATORY** | Explicit lock for all older versions |
| `MIN_VERSION: <semver>` | **JSON Parser** / `min_supported_version` | **MANDATORY** for versions below `<semver>` | Schema migrations where recent versions are unaffected |
| `> [!NOTE]` | **JSON Parser** & **Atom Feed** | **OPTIONAL (Flexible)** | Informational notices, version highlights |
| `> [!TIP]` | **JSON Parser** & **Atom Feed** | **OPTIONAL (Flexible)** | Helpful tips, download hints |
| `ALERT:` / `NOTICE:` / `NOTE:` | **JSON Parser** | **OPTIONAL (Flexible)** | Informational banners without forcing updates |

### Golden Rule for Non-Mandatory Releases
To ensure an update is **strictly optional (flexible)**:
- **ONLY use** `> [!NOTE]` and `> [!TIP]` markdown callout blocks.
- **NEVER use** `> [!IMPORTANT]`, `> [!WARNING]`, or `> [!CAUTION]`.
- **NEVER use** the words `Mandatory Update`, `CRITICAL:`, `BREAKING:`, or `MANDATORY:`.
- Ensure `min_supported_version` in `version.json` is set to an older baseline (e.g. `"0.0.1"` or the true minimum compatible version).


---

## 3. Sample Release Note Templates

### Template 1: Standard Optional Release
*(Use when publishing regular feature updates and bug fixes)*

```markdown
### What's New in Attendly v1.0.0-alpha.4

✨ **Features & Enhancements**
- Added full-screen subject and slot editors with smooth transitions.
- Improved timetable sharing with instant high-resolution QR rendering.
- Added momentum scroll acceleration to Settings.

🧩 **Bug Fixes & Polish**
- Fixed camera controller race conditions during page transition.
- Fixed theme flickering when switching between light and dark modes.
```

---

### Template 2: Mandatory Update for All Older Versions
*(Use when all older versions MUST update immediately)*

```markdown
MANDATORY: Database structure updated. Please update to continue tracking attendance.

### What's New in Attendly v1.0.0-alpha.4

✨ **Performance & Fixes**
- Critical database migration to support custom time slots.
- Fixed attendance percentage recalculation bug.
```

*Or using GitHub Alert syntax:*
```markdown
> [!WARNING]
> Database migration required. You must update to keep using Attendly.

### What's New in Attendly v1.0.0-alpha.4
- 120FPS smooth animations
- Full-screen schedule management
```

---

### Template 3: Minimum Version Threshold (`MIN_VERSION`)
*(Recommended: Only forces users running builds older than `1.0.0-alpha.3`)*

```markdown
MIN_VERSION: 1.0.0-alpha.3
NOTICE: Users below v1.0.0-alpha.3 must update due to timetable sync protocol changes.

### What's New in Attendly v1.0.0-alpha.4
- Added OCR timetable photo scanner
- Added multi-sheet Excel and PDF export suite
- 120FPS radial theme switching
```

---

## 4. Step-by-Step Release Checklist

When preparing a new release:

1. **Bump Version in Code**:
   - Update `pubspec.yaml` (e.g. `version: 1.0.0-alpha.4+4`).
   - Add the new version notes to `lib/core/constants/app_release_notes.dart`.
   - Update `version.json` in the project root.
2. **Build Release APK**:
   ```bash
   flutter build apk --release
   ```
   Output: `build/app/outputs/flutter-apk/app-release.apk`
3. **Draft Release on GitHub**:
   - Go to GitHub ➔ **Releases** ➔ **Draft a new release**.
   - Set tag: `v1.0.0-alpha.4`.
   - Paste release notes (using one of the templates above).
   - Attach `app-release.apk` as a release asset (rename to `Attendly-v1.0.0-alpha.4.apk`).
4. **Publish**:
   - Click **"Publish release"**.
   - The app's in-app updater will now detect the published release immediately!
