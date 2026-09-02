# ClassTrack Release & Update Guide

This document outlines the standard release workflow, mandatory update controls, draft protection mechanisms, and release note formatting for ClassTrack.

---

## 1. Overview of the Update System

ClassTrack features an in-app updater and an offline release notes viewer:

1. **"What's New in ClassTrack" (Offline Release Notes)**:
   - Displays the features of the **currently installed version** on the user's phone.
   - Reads from [`AppReleaseNotes`](../lib/core/constants/app_release_notes.dart) with 0ms latency and 100% offline support.
2. **"Check for Updates" (Remote Updater)**:
   - Queries GitHub's `/repos/a3ryk/classtrack/releases/latest` API.
   - **Draft Protection**: GitHub automatically excludes draft releases and unpublished tags. Users will **never** receive an update notification until you click **"Publish release"** on GitHub.
   - Falls back to `version.json` if GitHub API is unreachable or rate-limited.

---

## 2. Release Note Keywords & Mandatory Updates

When drafting a release on GitHub, ClassTrack automatically inspects the release description (`body`) for warning tags and minimum version requirements.

### Keyword Reference

| Keyword / Format | Effect on App | Use Case |
| :--- | :--- | :--- |
| `MIN_VERSION: 1.0.0-alpha.3` | Forces update **only** for users running a version below `1.0.0-alpha.3`. Users already on `alpha.3` or higher are not blocked. | Recommended for schema migrations or deprecations. |
| `MANDATORY: <message>` | Locks the update screen for **all** users on older versions. Non-dismissible modal. | Critical security patches or breaking API changes. |
| `REQUIRED: <message>` | Same as `MANDATORY:`. | Breaking changes. |
| `BREAKING: <message>` | Same as `MANDATORY:`. | Breaking database changes. |
| `CRITICAL: <message>` | Same as `MANDATORY:`. | Critical bug fix requiring immediate upgrade. |
| `> [!WARNING] <message>` | Markdown alert block. Treated as mandatory update with red warning banner. | GitHub standard alert syntax. |
| `⚠️ WARNING: <message>` | Emoji prefix. Treated as mandatory update. | Quick warning note. |
| `ALERT:` / `NOTICE:` / `NOTE:` | Displays an informational notice card (blue/amber) without locking the app. | Non-breaking notices (e.g. "Backup recommended"). |

---

## 3. Sample Release Note Templates

### Template 1: Standard Optional Release
*(Use when publishing regular feature updates and bug fixes)*

```markdown
### What's New in ClassTrack v1.0.0-alpha.4

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

### What's New in ClassTrack v1.0.0-alpha.4

✨ **Performance & Fixes**
- Critical database migration to support custom time slots.
- Fixed attendance percentage recalculation bug.
```

*Or using GitHub Alert syntax:*
```markdown
> [!WARNING]
> Database migration required. You must update to keep using ClassTrack.

### What's New in ClassTrack v1.0.0-alpha.4
- 120FPS smooth animations
- Full-screen schedule management
```

---

### Template 3: Minimum Version Threshold (`MIN_VERSION`)
*(Recommended: Only forces users running builds older than `1.0.0-alpha.3`)*

```markdown
MIN_VERSION: 1.0.0-alpha.3
NOTICE: Users below v1.0.0-alpha.3 must update due to timetable sync protocol changes.

### What's New in ClassTrack v1.0.0-alpha.4
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
   - Attach `app-release.apk` as a release asset (rename to `ClassTrack-v1.0.0-alpha.4.apk`).
4. **Publish**:
   - Click **"Publish release"**.
   - The app's in-app updater will now detect the published release immediately!
