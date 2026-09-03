# Changelog

All notable changes to **ClassTrack** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
