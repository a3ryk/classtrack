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
TAG = "v2.0.0-alpha.6"
TITLE = "Attendly v2.0.0-alpha.6 (Pure AndroidX Native SplashScreen & 120 FPS Exit)"

RELEASE_NOTES_TEMPLATE = """# Attendly v2.0.0-alpha.6 (Pure AndroidX Native SplashScreen & 120 FPS Exit)

> [!NOTE]
> **Optional Update**: This release replaces duplicate Flutter splash widgets with the official AndroidX SplashScreen architecture (the same system used by Mihon), providing seamless 120 FPS launch continuity with zero scaling or framing discrepancies. It is an optional update (`is_mandatory: false`). Your existing installation will continue functioning normally without interruption.

> [!TIP]
> **Migration Guide for Users on Older Packages (`com.classtrack.app`)**:
> If you are upgrading from an older version released before `v2.0.0-alpha.1` (when the app used the `com.classtrack.app` package identity):
> 1. In your existing app, navigate to **Settings > Backup & Restore > Export Backup** and save your `.attendly` backup file safely.
> 2. Uninstall the old `com.classtrack.app` build.
> 3. Install **Attendly `v2.0.0-alpha.6`** (`com.attendly`).
> 4. Go to **Settings > Backup & Restore > Restore Backup** and select your backup file.
> 
> *If you are already on `v2.0.0-alpha.1` through `v2.0.0-alpha.5` (`com.attendly`), you can install this update directly over your existing app without uninstalling.*

---

### What's New in v2.0.0-alpha.6

#### 🚀 Pure AndroidX Native SplashScreen
- **Unified Launch Surface**: Replaced duplicate in-app splash widgets with Android's official `androidx.core:core-splashscreen` API (matching Mihon architecture). Completely eliminated dual-layer handoffs, sizing discrepancies, and squircle curvature differences.
- **Theme-Aware Background**: Splash background automatically switches between Pure White (`#FFFFFF`) and Dark Slate (`#121316`) respecting system dark mode from millisecond 0.

#### ⚡ Hardware-Accelerated 120 FPS Exit
- **Compositor-Layer Animation**: Native `ObjectAnimator` scales the launcher icon ($1.0 \to 1.25$) and fades out the surface ($1.0 \to 0.0$) using a smooth `PathInterpolator(0.2f, 0f, 0f, 1f)` (cubic ease-out) over 320ms with 0 jitter or dropped frames.
- **Post-Frame Layout Synchronization**: Flutter signals dismissal via MethodChannel (`com.attendly/splash`) strictly inside `addPostFrameCallback`, guaranteeing the timetable dashboard is already rasterized into the window buffer before the splash dismisses.
- **5000ms Safety Watchdog**: Integrated a 5-second automatic timeout in `setKeepOnScreenCondition` to ensure the splash never hangs under unexpected startup errors.

---

### Downloads & Assets

{ASSET_TABLE}

*Recommended: Use `app-arm64-v8a-release.apk` for modern 64-bit Android smartphones for the fastest download and smallest footprint, or `Attendly-v2.0.0-alpha.6.apk` for universal compatibility.*
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
        ('Attendly-v2.0.0-alpha.6.apk', 'Attendly-v2.0.0-alpha.6.apk', 'All Devices', 'Universal Fat APK'),
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
