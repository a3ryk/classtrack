# Classtrack — Offline-First University Attendance App

**Classtrack** is a fast, offline-first mobile application built with **Flutter & Dart** designed for university students in India (supporting FYUGP, FYIMP under NEP 2020, Gauhati University, Delhi University, Mumbai University, etc.) and adaptable to any academic system worldwide.

---

## 📱 Features

- **Zero Internet Required**: Powered by a local embedded **SQLite** database (`drift`). All student data stays 100% on device.
- **One-Tap Attendance**: Quick `Present`, `Absent`, and `Cancelled` action pills with a 4-second Undo snackbar.
- **Predictive "What-If" Simulator**: Interactively test future missed classes to see projected percentage drops before taking leave.
- **5-Level Scheduling Engine**: Accurately resolves recurring timetables, holidays, weekly off-days, extra classes, and schedule exceptions.
- **Indian Academic Structure Templates**: Built-in support for FYUGP (Major, Minor, AEC, MDC, SEC, VAC) and FYIMP degree slots.
- **Multi-Format Data Exports**: Export attendance logs as Excel (`.xlsx`), PDF reports, CSV, or encrypted JSON backups.
- **Human-Centric UI**: Material 3 Expressive UI supporting Light, Dark, and System theme modes with high-contrast accessibility (WCAG AA).

---

## 🚀 How to Run & Test in Android Studio

### Prerequisites
1. **Flutter SDK** (v3.24+ / v3.35.1) installed and added to `PATH`.
2. **Android Studio** with the **Flutter** and **Dart** plugins installed.
3. An **Android Emulator** (AVD) set up, or an Android device connected via USB with Developer Mode enabled.

### Running via Android Studio
1. Launch **Android Studio**.
2. Click **Open** and select the project folder: `d:\Projects\classtrack`.
3. Wait for Android Studio to index files and run `flutter pub get` automatically.
4. Select your target device (e.g. `Pixel 8 Pro AVD` or connected Android phone) from the device dropdown at the top toolbar.
5. Click the green **Run** button (or press `Shift + F10`).

### Running via Terminal
Open a terminal in the project directory (`d:\Projects\classtrack`) and run:

```bash
# Get dependencies
flutter pub get

# Run the app on a connected device / emulator
flutter run
```

---

## 🧪 Running Unit & Widget Tests

To execute the automated test suite verifying attendance math, schedule resolution, and UI rendering:

```bash
flutter test
```

---

## 🏗️ Technical Architecture Overview

The codebase strictly follows **Clean Architecture**:

- `lib/core/`: Application constants, Light/Dark theme definitions (`app_theme.dart`), and formatting utilities.
- `lib/data/`: 
  - `database/`: Drift SQLite ORM tables (`tables.dart`) running on a background isolate with Write-Ahead Logging (WAL) enabled.
  - `templates/`: FYUGP and FYIMP academic programme templates.
- `lib/domain/`:
  - `services/schedule_engine.dart`: 5-level schedule resolution algorithm.
  - `services/attendance_math.dart`: Predictive mathematics engine for margin classes ($M$) and required classes ($N$).
- `lib/presentation/`:
  - `providers/`: Riverpod state management.
  - `screens/`: Today, Attendance, Calendar, Schedule, and Settings tab views.
  - `widgets/`: Radial percentage ring painter, tactile class cards, and status badges.

---

## 🔒 Offline & Data Sovereignty Q&A

**Q: Do I need an online cloud database to use this app?**  
**A:** **No.** The application uses an embedded local SQLite database (`drift`). Everything runs locally on your phone with zero network latency, zero cloud subscription costs, and 100% data privacy.

**Q: What if I want to switch phones in the future?**  
**A:** You can export a full versioned **JSON Backup** or **Excel workbook** under **Settings** $\rightarrow$ **Backup & Restore** and restore it on any new device.
