import '../services/app_update_service.dart';

/// Centralized offline registry for bundled release notes
class AppReleaseNotes {
  AppReleaseNotes._();

  static const String currentVersion = '1.0.0-alpha.4';

  static final Map<String, AppReleaseInfo> _releases = {
    '1.0.0-alpha.4': const AppReleaseInfo(
      latestVersion: '1.0.0-alpha.4',
      buildNumber: 4,
      minSupportedVersion: '1.0.0-alpha.1',
      releaseDate: 'September 2026',
      releaseTitle: 'ClassTrack v1.0.0-alpha.4 (Schedule Engine & Room Fixes)',
      changelog: [
        '✨ Complete Room & Class Name Persistence: Fixed Drift SQLite column updates so editing, clearing, or removing rooms, teachers, and course codes persists instantly to the database',
        '✨ Dynamic Subject Renaming Synchronization: Renaming a subject now immediately refreshes all Weekly Timetable slots, Today class cards, and Extra Classes across the entire app',
        '✨ Reschedule Room Handling: Single-date reschedules now accurately respect updated or cleared room/lab entries without falling back to weekly defaults',
        '✨ 120FPS Silky Smooth Settings Scrolling: Hardware-accelerated repaint boundaries and fluid momentum physics on settings screens',
        '✨ Offline-Accurate "What\'s New": Instantly loads local build changelogs for the installed version in 0ms without network dependence',
        '✨ Draft-Immune In-App Updater: GitHub Releases API integration that automatically ignores unpublished draft releases and unreleased git commits',
        '✨ Flexible Notice & Warning Engine: Support for plain warning/notice messages, breaking alert cards, and minimum version constraints',
        '🧩 Fixed SQLite upsert omitting cleared/null fields in Timetable Slots, Extra Classes, and Subjects',
      ],
      isMandatory: false,
    ),
    '1.0.0-alpha.3': const AppReleaseInfo(
      latestVersion: '1.0.0-alpha.3',
      buildNumber: 3,
      minSupportedVersion: '1.0.0-alpha.1',
      releaseDate: 'September 2026',
      releaseTitle: 'ClassTrack v1.0.0-alpha.3 (Performance & Full Screens)',
      changelog: [
        '✨ 120FPS Smooth Theme Transitions: Hardware-accelerated radial animations with zero frame drop jitter',
        '✨ Dedicated Full-Screen Schedule Editors: Full-screen Add/Edit Subject, Batch Add Slots, and Class Slot editors replacing cramped dialog modals',
        '✨ Instant 120FPS Timetable Share: Optimized QR code generator and lazy camera controller initialization',
        '✨ Enhanced In-App Updater: Draft-release immunity and instant offline What\'s New changelog view',
        '✨ 120FPS Smooth Settings Scrolling: Isolated hardware render boundaries and fluid momentum scrolling',
        '🧩 Fixed camera driver locking during page slide transitions',
        '🧩 Fixed visual theme jump when selecting the active theme mode',
      ],
      isMandatory: false,
    ),
    '1.0.0-alpha.2': const AppReleaseInfo(
      latestVersion: '1.0.0-alpha.2',
      buildNumber: 2,
      minSupportedVersion: '1.0.0-alpha.1',
      releaseDate: 'August 2026',
      releaseTitle: 'ClassTrack v1.0.0-alpha.2 (Timetable Sharing & OCR)',
      changelog: [
        '✨ High-Res QR Timetable Share: Instant schedule sync with sharable QR card images and batch import preview',
        '✨ AI Timetable Scanner: Convert photos and documents into timetable slots with on-device OCR',
        '✨ Multi-Date Export Suite: Official multi-sheet Excel & printable PDF registers with attendance summaries',
        '✨ Encrypted Local Backups: Scheduled auto-backups and 1-tap .ctbackup restoration',
        '✨ What-If Attendance Simulator: Safe miss margin (+N) calculator and required attendance planner',
        '🧩 Fixed notification text sanitization for broad Android device compatibility',
      ],
      isMandatory: false,
    ),
    '1.0.0-alpha.1': const AppReleaseInfo(
      latestVersion: '1.0.0-alpha.1',
      buildNumber: 1,
      minSupportedVersion: '1.0.0-alpha.1',
      releaseDate: 'August 2026',
      releaseTitle: 'ClassTrack v1.0.0-alpha.1 (Foundational Release)',
      changelog: [
        '✨ Live Today Dashboard: Real-time lecture countdowns & 1-tap attendance marking',
        '✨ Weekly Timetable Engine: Multi-day batch repeat and custom course category tagging',
        '✨ Calendar Overrides: Date-specific exceptions, reschedule single sessions, or add makeup labs',
        '✨ Margin Analytics: Safe miss margins and attendance percentage tracking',
      ],
      isMandatory: false,
    ),
  };

  /// Returns the release info for the specified version, falling back to current or latest available
  static AppReleaseInfo getForVersion(String versionStr) {
    final clean = versionStr.trim().replaceAll(RegExp(r'^[vV]'), '').split('+').first;
    if (_releases.containsKey(clean)) {
      return _releases[clean]!;
    }
    return _releases[currentVersion] ?? _releases.values.first;
  }

  /// Returns all available release notes in descending order
  static List<AppReleaseInfo> getAllReleases() {
    return _releases.values.toList();
  }
}
