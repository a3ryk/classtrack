#!/usr/bin/env python3
"""
Publishes Attendly GitHub Release and uploads APK assets.
"""

import os
import sys
import json
import urllib.request
import urllib.error
import subprocess

REPO = "a3ryk/classtrack"
TAG = "v2.0.0-alpha.2"
TITLE = "Attendly v2.0.0-alpha.2 (Class Notes, Dynamic Hero Timing & Info Badges)"

RELEASE_NOTES = """# Attendly v2.0.0-alpha.2 (Class Notes, Dynamic Hero Timing & Info Badges)

> [!NOTE]
> **Optional Update (Non-Mandatory)**: This is a feature release and is **not mandatory**. Existing installations on v2.0.0-alpha.1 or prior versions will continue to function normally without any lockout.

> [!IMPORTANT]
> **Notice for Users Migrating from Earlier Packages (`com.classtrack.app`)**:
> If you are upgrading from an older version released before `v2.0.0-alpha.1` (which used package identity `com.classtrack.app`), Android's security architecture does not permit different application IDs to overwrite each other in-place:
> 1. In your existing app, navigate to **Settings > Backup & Restore > Export Backup** and save your `.attendly` backup file safely.
> 2. Uninstall the old `com.classtrack.app` build.
> 3. Install **Attendly `v2.0.0-alpha.2`** (`com.attendly`).
> 4. Go to **Settings > Backup & Restore > Restore Backup** and select your backup file. All your attendance, schedules, subjects, notes, and records will be fully restored!
> 
> *If you are already on `v2.0.0-alpha.1` (`com.attendly`), you can simply install this update directly over your existing app without uninstalling.*

---

### What's New in v2.0.0-alpha.2

#### ⏱ Dynamic Hero Class Timing (Sprout Theme)
- **Ongoing Class vs. Next Class**: The hero banner on the Today screen dynamically distinguishes between a session currently in progress (`Ongoing Class`) and an upcoming session (`Next Class`).
- **Smooth Real-Time Cross-Fade**: When crossing the minute boundary (e.g. 10:59 to 11:00), the status header smoothly updates using an animated cross-fade without rebuilding the entire screen.
- **Smart Cancellation Advance**: When the current or next class is marked as cancelled, the hero card automatically shifts to display the following active class. If all remaining sessions for the day are concluded or cancelled, the hero card gracefully collapses.

#### 📍 Option C: Top-Right Corner Action for Info Badges
- **Clean Visual Ergonomics**: Moved session info action badges to the top-right corner across Today (both Sprouts and Classic themes), Calendar, and Schedule screens, eliminating awkward middle placements.
- **Class Info Slider Sheet**: Tapping any info badge slides open an intuitive bottom sheet revealing full session metadata: subject, timing, classroom, teacher name, notes, and cancellation details.

#### 📝 Class Notes & Cancellation Reasons
- **Per-Session Custom Notes**: Add, edit, or clear rich notes for individual class sessions via the streamlined `ClassNoteDialog`.
- **Cancellation Reasons**: Log standard or custom cancellation reasons when marking classes as cancelled with `CancellationReasonDialog`.
- **Drift SQLite Schema Persistence**: Fully persisted in local SQLite with dedicated `notes` and `cancellation_reason` columns.
- **Backup & Restore Integration**: Class notes and cancellation reasons are fully preserved across `.attendly` JSON backups.

---

### Downloads & Assets

| Architecture | Package Type | File Name | Size | SHA-256 Checksum |
| :--- | :--- | :--- | :--- | :--- |
| **All Devices** | Universal Fat APK | `Attendly-v2.0.0-alpha.2.apk` | 121.65 MB | `dde54dc95b8f3c6761a2be9ea0f6fe44310385a8dc2b80fe74708f7a09829d41` |
| **ARM64** | Split-per-ABI APK | `app-arm64-v8a-release.apk` | 47.57 MB | `ceecfe57013358c4b513bd52c324687c43c462543a64c5c449fee6149a28fc84` |
| **ARMv7** | Split-per-ABI APK | `app-armeabi-v7a-release.apk` | 40.33 MB | `c401265dec53da3520e881349a6b7b2e57227d2190e7265898efa45a7b03c6bc` |
| **x86_64** | Split-per-ABI APK | `app-x86_64-release.apk` | 50.32 MB | `b660178007b1ce9d9d291b12078d386afc444a94506576054ffed7a765d7c89f` |

*Recommended: Use `app-arm64-v8a-release.apk` for modern 64-bit Android smartphones for the fastest download and smallest footprint, or `Attendly-v2.0.0-alpha.2.apk` for universal compatibility.*
"""

def get_github_token():
    proc = subprocess.run(['git', 'credential', 'fill'], input='protocol=https\nhost=github.com\n', text=True, capture_output=True)
    for line in proc.stdout.splitlines():
        if line.startswith('password='):
            return line[len('password='):].strip()
    return None

def main():
    token = get_github_token()
    if not token:
        print("Error: Could not retrieve GitHub token from git credentials.")
        sys.exit(1)

    headers = {
        'Authorization': f'Bearer {token}',
        'User-Agent': 'Attendly-Publisher',
        'Accept': 'application/vnd.github+json'
    }

    # 1. Create or get existing release
    rel_url = f"https://api.github.com/repos/{REPO}/releases"
    payload = {
        'tag_name': TAG,
        'target_commitish': 'production',
        'name': TITLE,
        'body': RELEASE_NOTES,
        'draft': False,
        'prerelease': True
    }

    print(f">> Creating release {TAG} on {REPO}...")
    req = urllib.request.Request(rel_url, data=json.dumps(payload).encode('utf-8'), headers=headers, method='POST')
    try:
        with urllib.request.urlopen(req) as resp:
            release_data = json.loads(resp.read())
            print(f"Release created successfully! URL: {release_data.get('html_url')}")
    except urllib.error.HTTPError as e:
        err_body = e.read().decode('utf-8')
        if e.code == 422: # Already exists
            print(f"Release {TAG} already exists. Fetching existing release...")
            get_req = urllib.request.Request(f"https://api.github.com/repos/{REPO}/releases/tags/{TAG}", headers=headers)
            with urllib.request.urlopen(get_req) as resp:
                release_data = json.loads(resp.read())
        else:
            print(f"HTTP Error {e.code}: {err_body}")
            sys.exit(1)

    release_id = release_data['id']
    upload_url_tmpl = release_data['upload_url'] # e.g. https://uploads.github.com/.../assets{?name,label}
    upload_base = upload_url_tmpl.split('{')[0]

    # Existing assets
    existing_assets = {a['name']: a['id'] for a in release_data.get('assets', [])}

    # 2. Upload assets
    apk_dir = os.path.join('build', 'app', 'outputs', 'flutter-apk')
    assets_to_upload = [
        ('Attendly-v2.0.0-alpha.2.apk', 'Attendly-v2.0.0-alpha.2.apk'),
        ('app-arm64-v8a-release.apk', 'app-arm64-v8a-release.apk'),
        ('app-armeabi-v7a-release.apk', 'app-armeabi-v7a-release.apk'),
        ('app-x86_64-release.apk', 'app-x86_64-release.apk')
    ]

    for filename, asset_name in assets_to_upload:
        filepath = os.path.join(apk_dir, filename)
        if not os.path.exists(filepath):
            print(f"Error: File not found: {filepath}")
            sys.exit(1)

        # Delete existing if present
        if asset_name in existing_assets:
            print(f"Deleting existing asset {asset_name} (ID: {existing_assets[asset_name]})...")
            del_url = f"https://api.github.com/repos/{REPO}/releases/assets/{existing_assets[asset_name]}"
            del_req = urllib.request.Request(del_url, headers=headers, method='DELETE')
            urllib.request.urlopen(del_req)

        file_size = os.path.getsize(filepath)
        size_mb = file_size / (1024 * 1024)
        print(f">> Uploading {asset_name} ({size_mb:.2f} MB)...")

        with open(filepath, 'rb') as f:
            file_data = f.read()

        upload_url = f"{upload_base}?name={asset_name}"
        upload_headers = {
            'Authorization': f'Bearer {token}',
            'User-Agent': 'Attendly-Publisher',
            'Content-Type': 'application/vnd.android.package-archive',
            'Content-Length': str(file_size)
        }

        up_req = urllib.request.Request(upload_url, data=file_data, headers=upload_headers, method='POST')
        with urllib.request.urlopen(up_req) as up_resp:
            print(f"   Upload complete! (HTTP {up_resp.status})")

    print("\n============================================================")
    print("  All 4 APK Assets Successfully Published to GitHub Release!")
    print(f"  Release Page: {release_data.get('html_url')}")
    print("============================================================\n")

if __name__ == '__main__':
    main()
