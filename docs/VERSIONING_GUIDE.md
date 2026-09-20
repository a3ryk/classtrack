# Attendly Versioning & Build Guide

This guide defines the semantic versioning standard, beta patch cycles, build number rules, and automated build scripts for Attendly.

---

## 1. Version Structure: Which One is the Build Number?

In Flutter and Android, the version string in `pubspec.yaml` consists of two distinct components separated by a plus sign (`+`):

$$\text{version: } \underbrace{\text{2.0.0-alpha.1}}_{\text{Version Name (versionName)}} + \underbrace{\text{15}}_{\text{Build Number (versionCode)}}$$

### The Difference:

| Component | Example | Where it is Used | Rule |
|---|---|---|---|
| **Version Name** (`versionName`) | `2.0.0`, `2.0.1-beta.1` | Displayed to users inside the app (Settings, About), in update dialogs, and on GitHub release tags. | Follows Semantic Versioning: `MAJOR.MINOR.PATCH[-PRERELEASE]`. |
| **Build Number** (`versionCode`) | `15`, `16`, `17` | Used internally by Android OS to verify whether an APK is newer than the installed app. | **Must always increase (+1) with every build.** If an APK has the same or lower build number, Android rejects the install with `INSTALL_FAILED_VERSION_DOWNGRADE`. |

---

## 2. Beta Patching Workflow

When releasing updates, you do not need to make major version jumps. You can patch betas iteratively:

```text
Current Stable: v2.0.0+15
       │
       ▼
1. You fix a bug and start testing:
   Version: 2.0.1-beta.1+16
   GitHub Tag: v2.0.1-beta.1 (Pre-release)
       │
       ▼
2. A tester finds an issue in beta 1:
   Version: 2.0.1-beta.2+17  (Beta patch 2)
   GitHub Tag: v2.0.1-beta.2 (Pre-release)
       │
       ▼
3. Beta 2 is tested and solid:
   Version: 2.0.1+18  (Promoted to Stable)
   GitHub Tag: v2.0.1 (Latest release)
```

### When to Bump What:
* **Patch Update (`2.0.0` -> `2.0.1`)**: Bug fixes, minor visual polish, performance tweaks.
* **Minor Update (`2.0.0` -> `2.1.0`)**: New features (e.g. a new screen, widgets, or backup provider).
* **Major Update (`2.0.0` -> `3.0.0`)**: Complete redesigns or breaking database shifts.
* **Beta Counter (`beta.1` -> `beta.2`)**: Increments for every test build within that release cycle.

---

## 3. Interactive Build Scripts

To avoid editing `pubspec.yaml` and `version.json` manually before each build, helper scripts are available in the project root:

### Available Scripts:
* **`build.bat`**: The master interactive assistant. Asks what you want to compile and how you want to bump the version, then compiles and calculates the SHA-256 hash.
* **`build_fat.bat`**: Quick shortcut to compile the universal `Attendly-v<version>.apk` (works on all devices).
* **`build_split.bat`**: Quick shortcut to compile split-per-ABI APKs (`arm64-v8a`, `armeabi-v7a`, `x86_64`).
* **`bump_version.bat`**: Updates `pubspec.yaml` and `version.json` without running compilation.

### What the Script Does Automatically:
1. Displays your current Version Name and Build Number.
2. Prompts you with version choices (Keep, Bump build only, Bump beta patch, Promote to stable, or Custom).
3. Synchronizes `pubspec.yaml` and `version.json` in one go.
4. Compiles the APKs with dual-scheme signing (v1 + v2).
5. Renames the universal APK to `Attendly-v<version>.apk` in `build/app/outputs/flutter-apk/`.
6. Calculates and displays the file size and SHA-256 hash for release notes.
