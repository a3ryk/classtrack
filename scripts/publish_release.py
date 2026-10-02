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
import time

REPO = "a3ryk/classtrack"
TAG = "v2.0.0-alpha.8"
TITLE = "Attendly v2.0.0-alpha.8 (Refined Splash Icon & Circular Mask Alignment)"

RELEASE_NOTES_TEMPLATE = """# Attendly v2.0.0-alpha.8 (Refined Splash Icon & Circular Mask Alignment)

> [!NOTE]
> **Optional Update**: This release refines the native Android splash screen icon presentation by scaling it down to a balanced 96dp and aligning with Android 12+'s circular viewport mask to completely eliminate hexagonal/octagonal cut artifacts. It is an optional update (`is_mandatory: false`). Your existing installation will continue functioning normally without interruption.

> [!TIP]
> **Migration Guide for Users on Older Packages (`com.classtrack.app`)**:
> If you are upgrading from an older version released before `v2.0.0-alpha.1` (when the app used the `com.classtrack.app` package identity):
> 1. In your existing app, navigate to **Settings > Backup & Restore > Export Backup** and save your `.attendly` backup file safely.
> 2. Uninstall the old `com.classtrack.app` build.
> 3. Install **Attendly `v2.0.0-alpha.8`** (`com.attendly`).
> 4. Go to **Settings > Backup & Restore > Restore Backup** and select your backup file.
> 
> *If you are already on `v2.0.0-alpha.1` through `v2.0.0-alpha.7` (`com.attendly`), you can install this update directly over your existing app without uninstalling.*

---

### What's New in v2.0.0-alpha.8

#### 🎨 Refined Splash Icon Dimensions (96dp × 96dp)
- **Balanced Proportions**: Rescaled the centered native Android splash icon from the default oversized 160dp down to 96dp using a dedicated `@drawable/splash_screen_icon`, matching modern clean splash aesthetics without overwhelming the display.

#### ⭕ Circular Mask Alignment (Zero Octagonal Cuts)
- **Geometry Synchronization**: Generated 4x supersampled, anti-aliased circular splash drawables with alpha transparency across all display densities (`mdpi`, `hdpi`, `xhdpi`, `xxhdpi`, `xxxhdpi`). The circular geometry matches Android 12+'s internal splash viewport mask 1:1, permanently eliminating diagonal chops, harsh chamfers, and octagonal cuts.

#### 🛡️ Launcher Asset Isolation
- **100% Unmodified OS Launcher**: Kept `@mipmap/launcher_icon`, `@mipmap/ic_launcher`, and all OS home-screen launcher icon assets completely untouched.

#### 📱 Modern Edge-to-Edge Windowing & Material Themes
- **Transparent System Bars & Cutout Mode**: Full edge-to-edge windowing, display cutout `shortEdges` mode preventing notch letterboxing, and Android 10+ contrast overlay disabling.

---

### Downloads & Assets

{ASSET_TABLE}

*Recommended: Use `app-arm64-v8a-release.apk` for modern 64-bit Android smartphones for the fastest download and smallest footprint, or `Attendly-v2.0.0-alpha.8.apk` for universal compatibility.*
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
        ('Attendly-v2.0.0-alpha.8.apk', 'Attendly-v2.0.0-alpha.8.apk', 'All Devices', 'Universal Fat APK'),
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
    existing_assets = {a['name']: a for a in release_data.get('assets', [])}

    # 2. Upload assets
    for item in assets_to_upload:
        filename, asset_name = item[0], item[1]
        filepath = os.path.join(apk_dir, filename)
        if not os.path.exists(filepath):
            print(f"Error: File not found: {filepath}")
            sys.exit(1)

        file_size = os.path.getsize(filepath)
        size_mb = file_size / (1024 * 1024)

        # Check existing if present
        if asset_name in existing_assets:
            existing = existing_assets[asset_name]
            if existing.get('size') == file_size:
                print(f"Asset {asset_name} already uploaded ({size_mb:.2f} MB). Skipping upload.")
                continue
            else:
                print(f"Deleting existing asset {asset_name} (ID: {existing['id']}) due to size mismatch...")
                del_url = f"https://api.github.com/repos/{REPO}/releases/assets/{existing['id']}"
                del_req = urllib.request.Request(del_url, headers=headers, method='DELETE')
                urllib.request.urlopen(del_req)

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

        max_retries = 3
        for attempt in range(1, max_retries + 1):
            try:
                up_req = urllib.request.Request(upload_url, data=file_data, headers=upload_headers, method='POST')
                with urllib.request.urlopen(up_req) as up_resp:
                    print(f"   Upload complete! (HTTP {up_resp.status})")
                    break
            except Exception as ex:
                print(f"   [Attempt {attempt}/{max_retries}] Upload error: {ex}")
                if attempt == max_retries:
                    raise
                time.sleep(3)

    print("\n============================================================")
    print("  All 4 APK Assets Successfully Published to GitHub Release!")
    print(f"  Release Page: {release_data.get('html_url')}")
    print("============================================================\n")

if __name__ == '__main__':
    main()
