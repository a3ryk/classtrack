# Changelog

All notable changes to **ClassTrack** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0-alpha.3] - 2026-09-22

### Attendance Notification Redesign & Smart Flow
- **Option A Visual Actions**: Replaced wordy actions with universal symbol actions (`✓ Present`, `✕ Absent`, `⊘ Cancelled`) that look sharp and legible across light and dark system notification shades.
- **BigTextStyle Auto-Expansion**: Long subject names expand cleanly in system notifications without ellipsis truncation.
- **Stage 1 Auto-Dismissal**: Configured reminder notifications to auto-dismiss via timeout when the end-of-class prompt arrives, eliminating duplicate stacked notifications.
- **Smart Early-Mark Completion Notice**: When attendance is recorded prior to class completion, Stage 2 notifies with a clean completion notice (*"Class has ended • You already marked your attendance as Present at the start of class"*) without prompt buttons.
- **Settings Toggle**: Added "Notify If Already Marked" toggle in both Classic and Sprouts notification settings.
- **Developer Tools Sandbox**: Full test notification simulator with live customizable subject name input and length presets.

### Sprout Header Share & Interactive Slider Sheet
- **Relocated Header Share Action**: Replaced redundant settings icons in the Sprout theme header with a direct Share action.
- **Interactive Share Sheet**: Built `ShareAppSliderSheet` bottom sheet with 1-tap link copying, native Android sharing (`share_plus`), and QR preview.

### Sequential GitHub Alert Cards & In-App Updater
- **Sequential Alert Callouts**: Native parsing and rendering of stacked GitHub alerts (`[!NOTE]`, `[!TIP]`, `[!IMPORTANT]`, `[!WARNING]`, `[!CAUTION]`) with custom tint icons and borders.
- **Rich Markdown Formatting**: Preserves full formatting across release dialogs and What's New screens without truncation.

### Non-Mandatory Upgrade & Migration Safety
- **Non-Mandatory Release**: Configured `is_mandatory: false` and `min_supported_version: 0.0.1` so existing installations continue running without lockout.
- **Pre-v2.0.0 Migration Guidance**: Clear 3-step export/restore instructions for users migrating from `com.classtrack.app`.

---

## [2.0.0-alpha.2] - 2026-09-22

### Dynamic Hero Timing & Class Lifecycle
- **Real-Time Ongoing vs. Next Class**: Sprout Today view now dynamically distinguishes between "Ongoing Class" and "Next Class" using real-time minute-boundary cross-fades without requiring full screen rebuilds.
- **Smart Cancelled Class Handling**: When the current or upcoming session is marked as cancelled, the hero view automatically transitions to the next available upcoming session, or gracefully collapses if all remaining sessions are cancelled or concluded.
- **Option C Corner Action Badges**: Moved session info trigger badges to the top-right corner across Today (Sprouts and Classic themes), Calendar, and Schedule screens for balanced visual hierarchy and improved ergonomics.

### Class Notes & Cancellation Reasons
- **Session Notes**: Students can now view, add, edit, and clear custom markdown-friendly notes per session via a dedicated `ClassNoteDialog`.
- **Cancellation Reasons**: When cancelling a class, users can specify standard or custom cancellation reasons via the `CancellationReasonDialog`.
- **Drift SQLite Persistence**: Extended `class_sessions` database schema with `notes` and `cancellation_reason` columns with zero data loss.
- **Class Info Slider Sheet**: Integrated a reusable bottom sheet displaying full session metadata, teacher details, room numbers, notes, and cancellation reasons.
- **Backup & Restore Compatibility**: Full serialization support for class notes and cancellation reasons in `.attendly` JSON backups.

### Upgrade & Package Migration Safety
- **Non-Mandatory Release**: Configured `is_mandatory: false` and `min_supported_version: 0.0.1` so older builds continue operating without lockout.
- **Pre-v2.0.0 Migration Notice**: Users upgrading from legacy versions (`com.classtrack.app` before `v2.0.0-alpha.1`) must export their data via `Settings > Backup & Restore > Export Backup` before installing `com.attendly` due to Android package identity separation.

---

## [2.0.0-alpha.1] - 2026-09-20

### Package Identity & Signature Modernization
- **Package Identifier Migration**: Transitioned Android package identity and namespace from `com.classtrack.app` to `com.attendly` across AndroidManifest, Kotlin sources, iOS build settings, and ProGuard configuration.
- **Production Keystore Generation**: Established dedicated 2048-bit RSA production release keystore with cryptographic validity extending through 2054.
- **Dual Scheme Signing (v1 + v2)**: Configured dual JAR (v1) and full-APK (v2) signature schemes, resolving silent installation cancellations on Samsung (Auto Blocker), Xiaomi (HyperOS/MIUI), Oppo, and Vivo devices.
- **Dart Ecosystem Alignment**: Renamed internal Dart package to `attendly` with 100% test suite verification across all 214 tests.
- **Method Channels & Providers**: Synchronized in-app package installer channel, home screen widget provider classes, system notification channel IDs, and deep links.
- **Export & Backup Naming**: Standardized Excel registers, PDF reports, and JSON database backups to `attendly_*` filenames.

---

## [1.0.0-alpha.14] - 2026-09-20

### 🚀 Performance & UI Polish Patch
- **Smooth Day Swiping**: Converted Today screen schedule to horizontal swipe navigation (`PageView.builder`) with smooth cubic curve glide back to today when the "Today 🌱" pill is tapped.
- **Bottom Navbar Clearance Fix**: Eliminated the 105px dead void above the floating navbar by normalizing bottom padding to a snug 16px across Analytics, Settings, Timetable, and Today screens.
- **Share & Scan Screen FPS Optimization**: Deferred heavy camera initialization (`MobileScannerController`) and QR matrix rendering until the incoming route transition completes, eliminating frame drops.
- **Classic Appearance Consolidation**: Grouped Display Options (`Pure OLED Black`, `Match Device Appearance`) and Home Screen Widgets into a single card section in the classic theme.
- **What-If Simulator Range Expansion**: Simulator session counters now start at 1 with support for up to 30 sessions in both Sprouts and Classic themes.
- **Timetable Stability Fixes**: Resolved null-safe `subjectCode` type cast and standardized uniform 38px pill heights across all days of the week.

---

## [1.0.0-alpha.13] - 2026-09-20

### 🌿 Sprout & Mochi Theme Suite
- **Extensible Theme Engine**: Core architectural foundation supporting multiple distinct visual styles with unified `AppThemeTokens`, dynamic theme switching, and smooth cross-fade transitions.
- **Sprout & Mochi Theme**: Soft pastel marshmallow canvas (`#FAF7F2`), woodland moss card backgrounds (`#1B3626`), fresh sprout green accents (`#689F38`), and organic squircles (`20-24px` radius).
- **Time-Aware 3D Mascot Companions**: Expressive 3D mascots across Home (waving, evening, night), Timetable (clock, foliage), Analytics (growth charts), and Settings (reading).
- **Mascot Peek Overlay**: Tap any mascot to reveal whimsical academic encouragement quotes with smooth spring animations.

### 🧭 Sprout Floating Navigation Bar
- **Capsule Bottom Navigation**: Floating pill navbar with smooth animated sliding indicator and custom theme icons.
- **Squircle Active Pill**: Soft `22px` border radius preventing edge crowding on long screen names like "Timetable" and "Analytics".
- **FittedBox Label Protection**: Edge-safe text scaling guaranteeing labels never clip on narrow Android devices.

### 📱 Dynamic Guided App Tour
- **Theme-Adaptive Navigation**: Interactive walkthrough dynamically detects active theme and maps steps to the correct tab order (`Today`, `Timetable`, `Calendar`, `Analytics`, `Settings`).
- **Sprout Visual Polish**: Quicksand typography, elevated floating margin (`96px`), mini mascot avatar, and context-aware action buttons.
- **Zero-Emoji Compliance**: Strict adherence to zero-emoji standards across all tour step descriptions and badges.

### 🔋 Battery Efficiency & Visual Polish
- **Sprout "Did You Know?" Sheet**: Dedicated Sprout-styled battery efficiency explanation sheet with `32px` sheet radius and full-pill action buttons.
- **Settings Screen Spacing Fix**: Eliminated trailing blank void above the floating navbar with balanced `16px` bottom padding.
- **Mascot Reflection Removal**: Pixel-level transparency cleanup removing the reflection puddle beneath the Today screen mascot artwork.

---

## [1.0.0-alpha.12] - 2026-09-12

### 🌟 Brand Identity Overhaul (Attendly & New App Icon)
- **Brand Rebranding to Attendly**: Officially renamed the app from ClassTrack to **Attendly** across the entire UI, settings, dialogs, widgets, database backups, notifications, and metadata while preserving internal package stability.
- **Brand New App Icon**: Modernized application launcher icon with clean geometry, dark/light adaptive icon support, and refined asset bundling for Android launchers.
- **Dual Brand Compatibility**: Full backward compatibility ensuring existing `.ctbackup` files and `ClassTrack` backup directories remain restorable and discoverable.

### 🛡️ Automatic Backup Storage Permission Guard
- **Strict Storage Permission Guard**: Toggling Automatic Backup switch now checks and requests storage permission on Android, preventing phantom "UI-only" backups into hidden sandboxes.
- **Permission Revocation Safe**: Background auto-backup checks verify storage permissions before saving to prevent crashes and hidden writes, providing an in-app 1-tap "Grant" recovery banner.
- **Public Directory Storage**: Directly targets `/storage/emulated/0/Attendly/backups` with fallback discovery for legacy `ClassTrack/backups`.

### 🛠️ Developer Release Inspector & Markdown Updater Polish
- **Developer Release Inspector**: Dedicated GitHub release inspector in Developer Options allowing developers and testers to pull, inspect, and preview any release notes with a testing bypass for mandatory version locks.
- **Markdown Changelog Rendering Improvements**: GitHub Flavored Markdown parser enhancements for update screens and release notes.
- **Visual Simplification**: Clean floating sparkle icon without box tint, clean text-only "Done" button, and direct checkmark badges without surrounding circular container clutter.
- **Minimalist Privacy Policy**: Clean, focused layout without em-dash artifacts or clutter.

---

## [1.0.0-alpha.11] - 2026-09-11

### ✨ Features & Architecture
- **Home Screen Widgets Suite**: Three native Android AppWidgets for glanceable timetable and attendance tracking:
  - *Next Up Live Pill (2×1)*: Dynamic status pulse dot, lecture timing, room tag, and high-contrast countdown chip.
  - *Today's Agenda Card (4×2)*: Date header with term attendance badge, hero active lecture card, 1-tap direct attendance action buttons (`[✓ Present]` and `[✗ Absent]`), and upcoming schedule stack.
  - *Attendance Gauge Card (2×2)*: Overall attendance percentage with color-coded progress gauge bar and safe bunk / cushion calculator.
- **In-App Widget Customization Studio**: Accessible via Settings &rarr; Appearance &rarr; Home Screen Widgets:
  - Responsive segmented form-factor switcher (`Next Up`, `Agenda`, `Gauge`) with zero text truncation.
  - Butter-smooth height adaptation via `AnimatedSize` (260ms, `Curves.easeOutCubic`) and fade/scale transitions.
  - Frosted glassmorphism background opacity slider ($0\%$ to $100\%$) over contrasting realistic wallpaper backdrops (*Oceanic Aurora*, *Sunset Glow*, *Minimal Slate*, *AMOLED Black*).
  - 6 cohesive theme palettes (*Material You*, *AMOLED Black*, *Midnight Obsidian*, *Emerald Forest*, *Rose Velvet*, *Sunset Amber*).
  - Granular privacy and display switches (Privacy Shield, Show Room Numbers, Show Tomorrow's First Class, 24-Hour Time Format, 1-Tap Direct Attendance).
- **Semester Archiving & 3-Step Transition Wizard**:
  - Automated end-of-term detection with dismissible hero banner on Today screen.
  - Multi-step transition wizard with 60 FPS shared-axis transitions and `AnimatedSize` height adaptation.
  - Step 1 (Milestone Report Card): Final term percentage, goal achievement status, held/attended metrics, and premature archiving warning.
  - Step 2 (Term Configuration & Smart Sequencer): `SemesterSequencer` engine predicting next sequential term name (Roman, Arabic, Year presets, and academic year rollover).
  - Step 3 (Subject Setup): Selective carry-over checklist with fresh UUIDs and clean 0/0 baseline attendance.
  - Atomic SQLite Drift transaction (`archiveAndTransitionSemester`) archiving active term, creating new term, and updating `app_settings`.
  - Read-only historical performance viewer (`ArchivedSemesterReportSheet`) via Academic History without hijacking operational timetable slots or reminders.
- **Modern GitHub Markdown for App Updater**:
  - Integrated `flutter_markdown_plus: ^1.0.12` for rich GitHub Flavored Markdown (GFM) rendering.
  - Interactive clickable links, syntax-highlighted code blocks, bold/italic spans, and theme-adaptive contrast in update dialogs and updater screen.
  - Backward compatibility with offline bundled release notes and automatic stripping of metadata directives.

### 🧩 Bug Fixes & Stability
- **Crash-Proof Deserialization (`ClassCastException` Fix)**: Replaced rigid `prefs.getInt` calls with polymorphic type pattern matching on `prefs.all[key]`, completely eliminating `java.lang.ClassCastException: java.lang.Long cannot be cast to java.lang.Integer` crashes when reading Dart 64-bit numerical values from Android SharedPreferences.
- **Native RemoteViews Opacity & Color Filter Fix**: Updated Kotlin providers to apply composite 32-bit ARGB `widget_bg_color` directly to `setColorFilter` and `setImageAlpha`, ensuring genuine translucency across all Android OEM launcher engines.
- **Semester Setup Guards**: Blocked and guided users when attempting to scan QR codes or add batch classes without an active semester on `WelcomeSetupCard` and `AttendanceScreen`, displaying a helpful "Semester Setup Required" dialog with direct navigation to `EditSemesterDialog`.
- **Classmate QR Scanner Routing & Auto-Onboarding**: Fixed Analytics screen Option 2 to route directly to `QrShareScannerScreen(initialTabIndex: 1)` with automatic semester initialization and resilient Base64 decoding.
- **Settings & Appearance Clean-Up**: Removed duplicate "Home Screen Widgets" entry from `SettingsScreen` and refined typography in `AppearanceScreen`.

---

## [1.0.0-alpha.10] - 2026-09-10

### ✨ Features & Architecture
- **Real-Time Notification Attendance**: Mark Present, Absent, or Cancelled directly from Android notifications with instant multi-isolate synchronization to Today and Calendar views via `IsolateNameServer`.
- **Lock Screen Attendance Actions**: Quick attendance marking directly from lock screen or status bar without requiring device unlock or PIN entry (`showsUserInterface: false` with public card visibility).
- **10+ Concurrent Classes Support**: Simultaneous classes batch cleanly into an expandable notification group with a single chime alert, deterministic IDs, and independent dismissal.
- **Developer Test Alert Simulation**: Moved test notification generator to Developer Options with 100% non-destructive simulation and verification toast.
- **Clean-Slate Alarm Reconciliation**: Automatic purge of stale alarms on schedule changes or cancellations before scheduling rolling 7-day window, eliminating ghost alerts.
- **Cross-Midnight Scheduling Support**: Overnight lectures and labs now automatically advance end-of-class reminders by +1 day.
- **Multi-Isolate SQLite WAL Mode**: Configured Write-Ahead Logging (`PRAGMA journal_mode = WAL;`) and busy timeout to eliminate multi-isolate database lock contention.

### 🧩 Bug Fixes & Polish
- **Extra Class Rescheduling & Removal**: RescheduleSessionScreen now cleanly routes one-off extra classes to update or delete without timetable exception conflicts.
- **Streamlined Notification Settings**: Removed developer test alerts and rainbow clutter from notification settings, organizing into clean Sound & Vibration preferences.
- **Dual Reminder Cancellation**: Marking attendance either in-app or from notifications immediately dismisses both start and end class reminders.

---

## [1.0.0-alpha.9] - 2026-09-09

### ✨ Features & Architecture
- **Zero-Drop Changelog Parsing**: In-app updater and update dialogs now parse and render 100% of release notes from GitHub API, Atom feeds, and manifest sources without dropping bullet items, with robust support for bold title prefixes (`- **Title**: Description`).
- **Extra Class Edit & Deletion**: Complete lifecycle management for extra classes on Today and Calendar views, enabling students to edit timings, rooms, and notes, or delete one-off sessions with instant database commit and visual sync.
- **Fluid Notification Settings & Slider Dismissal**: Encapsulated stateful switch tiles in `RepaintBoundary` for zero frame drops, and added micro-frame choreography to the reminder slider sheet to eliminate close jitter.
- **GitHub Release Publishing Guidelines**: Established project standards (`docs/RELEASE_GUIDELINES.md`) governing release title structure, git tag naming, asset naming, and markdown conventions.

### 🧩 Bug Fixes & Stability
- **Extra Class Card Actions**: Added contextual Edit and Delete actions with custom confirmation sheets across Today screen and Calendar schedules.
- **Changelog Rendering Fidelity**: Fixed issue where structured release notes would appear truncated or miss key feature items in the updater dialog.

---

## [1.0.0-alpha.8] - 2026-09-09

### ✨ Features & Architecture
- **Multi-Tier GitHub Releases Priority**: In-app updater checks published GitHub Releases first (Tier 1 GitHub API &rarr; Tier 1b Rate-Limit-Free Atom Feed &rarr; Tier 2 Cache-Busted manifest).
- **Native Hardware ABI Architecture Detection**: Automatically resolves device architecture via `Build.SUPPORTED_ABIS` (`arm64-v8a`, `armeabi-v7a`, `x86_64`) to download exact matching APKs instead of oversized universal packages.
- **Redirect-Aware Asset Downloader**: Follows HTTP 301/302/307/308 redirects up to 5 hops, properly handling GitHub Release asset downloads that redirect to AWS S3 pre-signed CDN URLs.
- **Fluid Extra Class Tactile Bottom Sheet**: Replaced clunky `AlertDialog` popup with an interactive 320ms bottom slider sheet with side-by-side time pickers and immediate database commit.
- **On-The-Fly In-Sheet Subject Creation**: Students can create, categorize (`MAJOR`, `MINOR`, `AEC`, etc.), and color-code new subjects directly in the sheet without leaving the calendar screen.
- **Modern Subject Selector & Modal Picker**: Replaced standard Flutter `DropdownButton` menu with an interactive subject card and dedicated modal picker sheet with live search, category badges, active checkmarks, and single `+ Add New Subject` action.
- **Storage & Notification Permissions Enforcement**: Enforced runtime storage permission checks across all restore entry points (Settings and Onboarding) and runtime notification permission checks when enabling reminder switches or sending test alerts.

### 🧩 Bug Fixes & Stability
- **Eliminated Java 8 Compiler Warnings**: Configured `-Xlint:-options` across all Gradle subprojects to eliminate obsolete source/target 8 warnings from third-party plugins.
- **Android Manifest Install Location**: Added `android:installLocation="auto"` to resolve device storage constraints during installation.
- **Clock Icon Uniformity**: Harmonized Start and End time picker icons to use consistent `Icons.access_time_rounded`.
- **Eliminated Duplicate Plus Icons**: Removed redundant plus prefixes in buttons and menus (`+  + New Subject`).

---

## [1.0.0-alpha.7] - 2026-09-09

### ✨ Features & Architecture
- **Android Multi-Channel Sound & Vibration Routing**: Registered 4 dedicated Android system notification channels (`classtrack_reminders_all`, `classtrack_reminders_sound`, `classtrack_reminders_vibrate`, `classtrack_reminders_silent`) in `NotificationService`, dynamically resolving notifications according to preferences to fix Android OS channel lock.
- **Redesigned Notifications Hub (Anti-AI-Slop)**: Streamlined single-word "Notifications" title across App Bar and settings menu, eliminating all redundant secondary subtext and clutter.
- **Tactile Reminder Timing Bottom Sheet**: Replaced awkward text inputs and keyboard popups with a smooth 340ms bottom sheet featuring big bold hero display, 0-60m continuous slider, micro-haptics, and `[-1m]` / `[+1m]` steppers.
- **Top-Right "Did You Know?" Battery Efficiency Sheet**: Non-popup slider bottom sheet accessible from top-right info button explaining zero idle battery consumption, exact scheduled alarms, and no background service overhead.
- **Refined Minimalist Design Language**: Replaced hospital-green pill with signature slate badges and uniform blue accent icons matching Apple/Linear-grade quality standards.

### 🧩 Bug Fixes & Stability
- **Test Notification Dispatch**: Added runtime notification permission verification prior to test alert dispatch and zero-vibration pattern fallbacks for older devices.
- **Settings Hierarchy Standardization**: Unified iOS-style chevron back buttons and centered titles across settings views.

---

## [1.0.0-alpha.6] - 2026-09-04

### ✨ Features & Appearance
- **Dedicated Appearance & Themes Hub**: Unified minimalist appearance screen with live interactive attendance hero, AMOLED Pure OLED Black toggle, and match-device schedule.
- **Telegram-Style Radial Theme Transitions**: Center-locked circular wave emanating outward for Dark and inward for Light with tuned 650ms momentum.
- **1:1 Native Resolution Theme Capture**: True devicePixelRatio snapshot capture eliminating screen resize artifacts and blur across all Android displays.
- **Rock-Solid Theme Cards**: Fixed 1.5px border geometry eliminating card shaking and flex reflow during theme switching.
- **Instant Touch Responsiveness**: Visually synchronized anti-spam lock release and 0ms onTapDown gesture dispatch preventing dropped clicks.
- **Active 100% Progress Meter**: Full emerald progress arc and clean "100%" typography in the appearance preview hero.
- **Fixed-Height Alphabetical State Picker**: Rock-solid 72% height searchable state/UT selector preventing sheet collapse during filtering.

### 🧩 Bug Fixes & Polish
- **Dismissal Choreography**: Fixed holiday sheet dismissal choreography to eliminate the 0.1ms button flash before downward glide.
- **Layout Constraints**: Harmonized settings typography and layout constraints across all device form factors.

---

## [1.0.0-alpha.5] - 2026-09-03

### ✨ Features & Architecture
- **Dedicated Full-Screen Room & Reschedule Screens**: Added full-screen `SubjectRoomManagerScreen` and `RescheduleSessionScreen` replacing cramped inline dialogs.
- **Multi-Room Timetable Resolution**: Dynamic support for subjects scheduled in different classrooms across different weekdays (e.g. Mon/Wed/Fri in Room 101, Tue/Thu in Lab B) with 1-tap bulk apply across all days.
- **Date-Specific Single-Day Overrides**: Reschedule or move individual class sessions for a single date without altering recurring weekly timetable templates.
- **Dynamic Schedule & Analytics Breakdown**: Today dashboard, Calendar, and Attendance analytics dynamically compute per-day room locations and attendance stats directly from live SQLite.
- **Native Split-per-ABI In-App Updater**: Added intelligent on-device architecture detection (`dart:ffi` `Abi.current()`) to automatically select and download matching APK architecture (ARM64, ARMv7, x86_64) directly from GitHub Releases.
- **Dynamic Change Detection & Smart Button Locking**: Action buttons automatically lock and dim when no edits are detected and unlock immediately upon user input.
- **Overflow-Free Action Sheets**: Fixed 56px bottom RenderFlex overflow in quick-action menus using responsive constraints and momentum scroll physics.
- **Automated Backup Timing & Frequency Verification**: Fixed backup duration calculations and robust background check routines.

### 🧩 Bug Fixes & Stability
- **Weekly Slot ID Resolution**: Fixed slot targeting (`sourceRefId ?? id`) to update existing timetable slots in-place without generating duplicate orphaned entries.
- **Disabled Input Styling**: Prevented input border from darkening when room field is disabled during single-date class cancellations.
- **Soft Placeholder Styling**: Configured global and screen-level muted placeholder hint styles (`#94A3B8` light / `#64748B` dark) with regular font weight.

---

## [1.0.0-alpha.4] - 2026-09-03

### ✨ Features & Improvements
- **Complete Room & Metadata Persistence**: Fixed Drift SQLite column updates so editing, clearing, or removing rooms, teachers, and course codes persists instantly.
- **Dynamic Subject Renaming Synchronization**: Renaming a subject immediately refreshes all Weekly Timetable slots, Today class cards, and Extra Classes across the app.
- **120FPS Smooth Settings Scrolling**: Hardware-accelerated repaint boundaries and fluid momentum physics on settings screens.
- **Offline-Accurate "What's New"**: Instantly loads local build changelogs for the installed version in 0ms without network dependence.
- **Draft-Immune In-App Updater**: GitHub Releases API integration that automatically ignores unpublished draft releases.

---

## [1.0.0-alpha.3] - 2026-09-03

### ✨ Features & UI Polish
- **Full-Screen Subject Slot Manager**: Created dedicated `ManageSubjectSlotsScreen` replacing cramped slot management dialogs with a full-screen view, responsive subject summary cards, bulk weekday slot editor, 1-tap delete/edit, and an Add Slot FAB.
- **Android Edge-to-Edge System Navigation**: Seamless transparent system navigation bar and status bar matching light/dark app themes across all Android versions, eliminating the black bottom strip.
- **Luxury 120fps Theme Transition**: Overhauled the radial theme wave with a 3-layer soft ambient light aura, Apple/Linear-grade fluid easing curve (`Cubic(0.2, 0.0, 0.0, 1.0)`), and smooth 520ms liquid expansion.
- **Global Fluid Page Transitions**: Enabled iOS-standard `CupertinoPageTransitionsBuilder` across the entire app theme for buttery smooth horizontal screen sliding with native swipe-to-go-back gesture support.
- **Silky Smooth Tab Switching**: Integrated state-preserving `FadeIndexedStack` with 200ms `easeInOutCubic` cross-fade across **Today**, **Analytics**, **Timetable**, and **Calendar** tabs.
- **Zero-Scroll Share Tab**: Refined QR card dimensions (`180px` QR, `240px` card) with generous vertical breathing room around header pills and branding, ensuring a single-view fit on all screen sizes with zero scrolling.
- **High-Performance Update & What's New Screen**: Optimized `UpdateScreen` with `RepaintBoundary` texture caching, `fastOutSlowIn` micro-drift opening, precomputed changelog parsing, and direct 44px clean icon styling.
- **First-Boot Dual Permissions**: Automatic combined request for storage and notification permissions on initial launch to ensure zero-friction local backup creation and progress alerts.
- **Calendar "No Active Semester" Empty State**: Replaced plain text with a rich empty state featuring a circular graduation cap badge, descriptive subtitle, and 1-tap `+ Create Semester` button.

### 🧩 Bug Fixes & Stability
- **Layout Overflows**: Fixed horizontal `RenderFlex` overflow (5.7px) in the Timetable weekday pills row and header text overflow (12px) in `BatchAddSlotDialog` by applying responsive `Expanded` layouts.
- **Phantom Theme Ripple**: Added effective visual brightness detection to bypass radial ripple animations when switching between modes that share identical visual brightness (e.g. System Light ↔ Explicit Light).
- **High-Contrast Dialog Actions**: Updated Reschedule and Slot dialogs with prominent `Cancel` and `Save Change` button styling across both Light and Dark themes.

---

## [1.0.0-alpha.2] - 2026-08-28

### 🧩 Bug Fixes & Enhancements
- **Native APK Installer**: Resolved in-app APK installation via Android `FileProvider` and `PackageInstaller` intent.
- **Onboarding Backup Restore**: Resilient SAF file picker fallbacks for restoring `.ctbackup` files directly during the Welcome onboarding flow.
- **What's New Release Notes**: Dedicated release notes view with category badges and Done action dismissal.
- **High-Density QR Share**: 250px high-density image export with custom ClassTrack footer branding.

---

## [1.0.0-alpha.1] - 2026-08-28

### 🚀 Initial Preview Release
- **100% Offline & Private Architecture**: Zero telemetry, cloud tracking, or mandatory logins with encrypted local SQLite database.
- **Today Dashboard**: Real-time lecture countdowns, quick attendance marking (Present / Absent / Cancelled / Holiday), and overall attendance health ring.
- **Timetable Engine**: Multi-day batch repeat, flexible time slots, and custom color tagging.
- **Calendar & Exceptions**: Date-specific slot rescheduling, cancellations, extra makeup classes, and official holiday suppression.
- **Margin Analytics & Simulator**: Minimum attendance target forecasting, safe miss margins, and required attend calculators.
- **Export & Backup Suite**: Multi-sheet Excel and printable PDF registers, scheduled local backups, and `.ctbackup` import/export.
