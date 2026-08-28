# ClassTrack Versioning, Channels & Manifest Guide

This document defines the semantic versioning standard, multi-channel release streams (Alpha, Beta, Production), database schema migration rules, and the `version.json` remote manifest schema for ClassTrack.

---

## 1. Semantic Versioning Specification

ClassTrack follows standard Semantic Versioning combined with Flutter's integer build number:

$$\text{Version Format} = \text{MAJOR}.\text{MINOR}.\text{PATCH}+\text{BUILD}$$

### Number Breakdown:
- **`MAJOR` (e.g., `1.0.0`)**: Incompatible architectural overhauls or major redesigned paradigms.
- **`MINOR` (e.g., `1.1.0`)**: New user-facing features (e.g., Timetable QR sharing, What-If Leave Simulator, Multi-Sheet Excel exports). Backward-compatible.
- **`PATCH` (e.g., `1.1.1`)**: Bug fixes, performance optimizations, string corrections, and minor UI polishes.
- **`BUILD` (e.g., `+12`)**: Strictly monotonic integer incremented with every single binary compiled.

---

## 2. Multi-Channel Release Streams

| Channel | Target Audience | Version Number Example | Deployment Target | Stability |
| :--- | :--- | :--- | :--- | :--- |
| **Alpha / Canary** | Internal developers & core contributors | `1.1.0-alpha.1+41` | GitHub Pre-releases / Internal tester APK | Experimental |
| **Beta / Testing** | Early adopter student community | `1.1.0-beta.1+42` | GitHub Releases (Prerelease flag) | Feature Complete |
| **Production / Stable** | All university students | `1.1.0+43` | GitHub Releases (Latest) / Google Play | Production Stable |

---

## 3. Remote Manifest Specification (`version.json`)

The app polls `version.json` hosted on your GitHub repository (or CDN) to check for updates.

### Complete Schema:
```json
{
  "latest_version": "1.1.0",
  "build_number": 43,
  "min_supported_version": "1.0.0",
  "release_date": "2026-08-28",
  "release_title": "ClassTrack v1.1.0: Supercharged Analytics & In-App Updates",
  "changelog": [
    "✨ In-App 1-tap direct APK downloader & installer",
    "✨ System notifications for backups, restores, exports, and QR sync",
    "✨ App Walkthrough tour with 100% screen synchronization",
    "🧩 Fixed developer options full-screen onboarding navigation",
    "🧩 Cleaned up privacy policy presentation"
  ],
  "download_url": "https://github.com/a3ryk/classtrack/releases/download/v1.1.0/ClassTrack-v1.1.0.apk",
  "release_page_url": "https://github.com/a3ryk/classtrack/releases/tag/v1.1.0",
  "is_mandatory": false,
  "warning_message": null
}
```

### Field Definitions:
- **`latest_version`** *(string, required)*: Semantic version of the latest release.
- **`build_number`** *(integer, required)*: Monotonic build integer.
- **`min_supported_version`** *(string, required)*: If installed version is lower than this, the app locks and enforces a **Mandatory Update Screen**.
- **`release_date`** *(string, optional)*: ISO date (`YYYY-MM-DD`).
- **`release_title`** *(string, required)*: Headline displayed in the update dialog/screen.
- **`changelog`** *(array of strings, required)*: Bullet items explaining what's new (`✨`) and what's fixed (`🧩`).
- **`download_url`** *(string, optional)*: Direct HTTPS download link to `.apk`.
- **`release_page_url`** *(string, optional)*: GitHub release notes or website page.
- **`is_mandatory`** *(boolean, optional)*: Set `true` to block app usage until updated.
- **`warning_message`** *(string, optional)*: Custom red alert banner text shown on the update screen.

---

## 4. Zero-Data-Loss Database Schema Migrations

ClassTrack stores student timetables and attendance logs locally in SQLite via Drift. When releasing new versions:

1. **Strictly Additive Changes**:
   - Always use `addColumn` or nullable columns with default values when updating database tables in `app_database.dart`.
   - **Never drop or rename existing tables/columns** without writing a backward-compatible migration step in Drift's `migration.onUpgrade`.
2. **Pre-Update Safety**:
   - Before executing breaking migrations, users are encouraged to create a `.ctbackup` snapshot.
   - The backup system serializes all entities to JSON, ensuring data can be restored across different builds.
