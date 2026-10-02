#!/usr/bin/env python3
"""
Publishes Attendly GitHub Release and uploads APK assets.
"""

import os
import sys
import json
import hashlib
import urllib.request
import urllib.error
import subprocess

REPO = "a3ryk/classtrack"
TAG = "v2.0.0-alpha.4"
TITLE = "Attendly v2.0.0-alpha.4 (X / Instagram Constant Launch & 120 FPS Anti-Jitter Transition)"

RELEASE_NOTES_TEMPLATE = """# Attendly v2.0.0-alpha.4 (X / Instagram Constant Launch & 120 FPS Anti-Jitter Transition)

> [!NOTE]
> **Optional Update**: This release introduces a seamless launcher-to-app splash transition similar to modern apps like X and Instagram, alongside launch stability optimizations. It is an optional update (`is_mandatory: false`). Your existing installation will continue functioning normally without interruption.

> [!TIP]
> **Migration Guide for Users on Older Packages (`com.classtrack.app`)**:
> If you are upgrading from an older version released before `v2.0.0-alpha.1` (when the app used the `com.classtrack.app` package identity):
> 1. In your existing app, navigate to **Settings > Backup & Restore > Export Backup** and save your `.attendly` backup file safely.
> 2. Uninstall the old `com.classtrack.app` build.
> 3. Install **Attendly `v2.0.0-alpha.4`** (`com.attendly`).
> 4. Go to **Settings > Backup & Restore > Restore Backup** and select your backup file.
> 
> *If you are already on `v2.0.0-alpha.1`, `v2.0.0-alpha.2`, or `v2.0.0-alpha.3` (`com.attendly`), you can install this update directly over your existing app without uninstalling.*

---

### What's New in v2.0.0-alpha.4

#### ⚡ X / Instagram Constant Launch Experience
- **Eliminated the Circular Loader**: Removed the generic spinning circular progress indicator and blank loading canvas entirely during cold start.
- **Unbroken Visual Continuity**: The native Android launch screen (the centered app launcher icon on a clean background) now stays 100% constant and stationary while database hydration completes in the background. To the user's eye, it never leaves the native splash screen.
- **Zero Clutter**: Completely free of loading bars, percentage counters, and secondary subtitles.

#### 🚀 60/120 FPS Hardware-Accelerated Zoom-Through Reveal
- **Silky Easing**: The moment SQLite hydration finishes, the centered icon smoothly scales up (`1.0 → 1.45`) and dissolves over **350ms** (`Curves.easeOutCubic`) as your timetable dashboard smoothly reveals underneath.
- **`RepaintBoundary` Isolation**: Both the splash overlay and the `MainShell` are isolated on dedicated GPU compositor render layers, preventing repaint cascades and layout passes on underlying timetable cards.
- **Asset Precaching**: The launcher icon is precached in memory on mount (`precacheImage`), eliminating image decode hitches or initial frame blanking.
- **Post-Frame Layout Coordination**: The zoom-through sequence starts on `WidgetsBinding.instance.addPostFrameCallback`, guaranteeing the transition only begins after the initial frame of `MainShell` has already laid out cleanly.

#### 📱 Prominent 124dp Native Icon Geometry
- **Scaled for High-Density Displays**: Sized the centered icon prominently at **124×124 dp** with a clean 28dp squircle radius, matching modern Android 12+ adaptive icon display bounds.

#### 📖 Expanded Documentation & Trigger Safety
- **Mandatory Trigger Reference**: Thoroughly documented update parsing behavior across GitHub API and Atom fallback feeds in `UPDATER_GUIDE.md` and `docs/RELEASE_AND_UPDATES_GUIDE.md`.

---

### Downloads & Assets

{ASSET_TABLE}

*Recommended: Use `app-arm64-v8a-release.apk` for modern 64-bit Android smartphones for the fastest download and smallest footprint, or `Attendly-v2.0.0-alpha.4.apk` for universal compatibility.*
"""

def compute_sha256(filepath):
    h = hashlib.sha256()
    with open(filepath, 'rb') as f:
        while chunk := f.read(65536):
            h.update(chunk)
    return h.hexdigest()

def get_github_token():
    proc = subprocess.run(['git', 'credential', 'fill'], input='protocol=https\nhost=github.com\n\n', text=True, capture_output=True)
    for line in proc.stdout.splitlines():
        if line.startswith('password='):
            return line[len('password='):].strip()
    return None

def main():
    token = get_github_token()
    if not token:
        print("Error: Could not retrieve GitHub token from git credentials.")
        sys.exit(1)

    apk_dir = os.path.join('build', 'app', 'outputs', 'flutter-apk')
    assets_to_upload = [
        ('Attendly-v2.0.0-alpha.4.apk', 'Attendly-v2.0.0-alpha.4.apk', 'All Devices', 'Universal Fat APK'),
        ('app-arm64-v8a-release.apk', 'app-arm64-v8a-release.apk', 'ARM64', 'Split-per-ABI APK'),
        ('app-armeabi-v7a-release.apk', 'app-armeabi-v7a-release.apk', 'ARMv7', 'Split-per-ABI APK'),
        ('app-x86_64-release.apk', 'app-x86_64-release.apk', 'x86_64', 'Split-per-ABI APK')
    ]

    # Verify APKs exist and build asset table
    table_rows = [
        "| Architecture | Package Type | File Name | Size | SHA-256 Checksum |",
        "| :--- | :--- | :--- | :--- | :--- |"
    ]
    for filename, asset_name, arch, pkg_type in assets_to_upload:
        filepath = os.path.join(apk_dir, filename)
        if not os.path.exists(filepath):
            print(f"Error: File not found: {filepath}")
            sys.exit(1)
        size_mb = os.path.getsize(filepath) / (1024 * 1024)
        checksum = compute_sha256(filepath)
        table_rows.append(f"| **{arch}** | {pkg_type} | `{asset_name}` | {size_mb:.2f} MB | `{checksum}` |")

    release_body = RELEASE_NOTES_TEMPLATE.replace('{ASSET_TABLE}', '\\n'.join(table_rows))

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
        'body': release_body,
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
    for item in assets_to_upload:
        filename, asset_name = item[0], item[1]
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
