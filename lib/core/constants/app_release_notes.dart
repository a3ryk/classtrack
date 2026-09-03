import '../services/app_update_service.dart';

/// Centralized offline registry for bundled release notes
class AppReleaseNotes {
  AppReleaseNotes._();

  static const String currentVersion = '1.0.0-alpha.6';

  static final Map<String, AppReleaseInfo> _releases = {
    '1.0.0-alpha.6': const AppReleaseInfo(
      latestVersion: '1.0.0-alpha.6',
      buildNumber: 6,
      minSupportedVersion: '1.0.0-alpha.6',
      releaseDate: 'September 2026',
      releaseTitle: 'ClassTrack v1.0.0-alpha.6 (Telegram Theme Transitions & Appearance Hub)',
      changelog: [
        '✨ Dedicated Appearance & Themes Hub: Unified minimalist appearance screen with live interactive attendance hero, AMOLED Pure OLED Black toggle, and match-device schedule',
        '✨ Telegram-Style Radial Theme Transitions: Center-locked circular wave emanating outward for Dark and inward for Light with tuned 650ms momentum',
        '✨ 1:1 Native Resolution Theme Capture: True devicePixelRatio snapshot capture eliminating screen resize artifacts and blur across all Android displays',
        '✨ Rock-Solid Theme Cards: Fixed 1.5px border geometry eliminating card shaking and flex reflow during theme switching',
        '✨ Instant Touch Responsiveness: Visually synchronized anti-spam lock release and 0ms onTapDown gesture dispatch preventing dropped clicks',
        '✨ Active 100% Progress Meter: Full emerald progress arc and clean "100%" typography in the appearance preview hero',
        '✨ Unified Navigation Hierarchy: Standardized iOS-style chevron back buttons and centered titles across Appearance, About, and Backup & Restore',
        '✨ Fixed-Height Alphabetical State Picker: Rock-solid 72% height searchable state/UT selector preventing sheet collapse during filtering',
        '🧩 Fixed holiday sheet dismissal choreography to eliminate the 0.1ms button flash before downward glide',
        '🧩 Harmonized settings typography and layout constraints across all device form factors',
      ],
      isMandatory: true,
      warningMessage: 'Mandatory update required for appearance stability, theme transition fidelity, and navigation polish.',
    ),
    '1.0.0-alpha.5': const AppReleaseInfo(
      latestVersion: '1.0.0-alpha.5',
      buildNumber: 5,
      minSupportedVersion: '1.0.0-alpha.5',
      releaseDate: 'September 2026',
      releaseTitle: 'ClassTrack v1.0.0-alpha.5 (Multi-Room Timetables & Smart Schedule Management)',
      changelog: [
        '✨ Dedicated Full-Screen Schedule & Room Managers: Full-screen Subject Room Manager and Reschedule Session screens replacing cramped dialog modals',
        '✨ Multi-Room Timetable Resolution: Support for subjects held across different classrooms on different days (e.g., Mon/Wed/Fri in Room 101, Tue/Thu in Lab B) with 1-tap bulk apply',
        '✨ Date-Specific Room & Time Overrides: Reschedule or move individual class sessions for a single date without altering recurring weekly timetable templates',
        '✨ Dynamic Schedule & Analytics Breakdown: Today screen, Calendar, and Attendance analytics dynamically resolve per-day room locations and attendance outcomes',
        '✨ Native Split-per-ABI In-App Updater: Smart on-device architecture detection (ARM64, ARMv7, x86_64) ensuring fast, lightweight, and exact-match APK downloads directly from GitHub Releases',
        '✨ Overflow-Free Scrollable Action Sheets: Fixed RenderFlex overflow in quick-action bottom sheets with responsive constraints and momentum scroll physics',
        '✨ Smart Change Detection & Dynamic Button Locking: Action buttons lock and dim automatically when no edits are detected and unlock instantly on modification',
        '✨ Auto-Backup Frequency & Time Calculation: Accurate duration evaluation and background verification for scheduled automated database backups',
        '🧩 Fixed slot ID targeting to update existing weekly timetable records in-place without duplicate entries',
        '🧩 Fixed disabled input border rendering and darkened outlines during single-day cancellations',
      ],
      isMandatory: true,
      warningMessage: 'Mandatory update required for multi-room schedule synchronization and auto-backup stability.',
    ),
    '1.0.0-alpha.4': const AppReleaseInfo(
      latestVersion: '1.0.0-alpha.4',
      buildNumber: 4,
      minSupportedVersion: '1.0.0-alpha.4',
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
      isMandatory: true,
      warningMessage: 'Mandatory update required for database persistence and timetable stability.',
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

  /// Checks if a version exists in the local registry
  static bool hasVersion(String versionStr) {
    final clean = versionStr.trim().replaceAll(RegExp(r'^[vV]'), '').split('+').first;
    return _releases.containsKey(clean);
  }

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
