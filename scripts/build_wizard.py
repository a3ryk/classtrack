#!/usr/bin/env python3
"""
Attendly Interactive Build & Version Assistant
Handles semantic version bumping, build number management, and automated APK compiling.
"""

import os
import re
import sys
import json
import hashlib
import argparse
import subprocess
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parent.parent
PUBSPEC_PATH = ROOT_DIR / "pubspec.yaml"
VERSION_JSON_PATH = ROOT_DIR / "version.json"
OUTPUT_APK_DIR = ROOT_DIR / "build" / "app" / "outputs" / "flutter-apk"
OUTPUT_AAB_DIR = ROOT_DIR / "build" / "app" / "outputs" / "bundle" / "release"


def read_pubspec_version():
    """Reads the current version and build number from pubspec.yaml."""
    if not PUBSPEC_PATH.exists():
        print(f"Error: pubspec.yaml not found at {PUBSPEC_PATH}")
        sys.exit(1)

    content = PUBSPEC_PATH.read_text(encoding="utf-8")
    match = re.search(r"^version:\s*([^\s+]+)(?:\+(\d+))?", content, re.MULTILINE)
    if not match:
        print("Error: Could not parse version line in pubspec.yaml")
        sys.exit(1)

    ver_name = match.group(1).strip()
    build_num = int(match.group(2)) if match.group(2) else 1
    return ver_name, build_num


def write_pubspec_version(new_ver_name, new_build_num):
    """Updates version: <name>+<build> in pubspec.yaml."""
    content = PUBSPEC_PATH.read_text(encoding="utf-8")
    updated = re.sub(
        r"^version:\s*.*$",
        f"version: {new_ver_name}+{new_build_num}",
        content,
        flags=re.MULTILINE,
    )
    PUBSPEC_PATH.write_text(updated, encoding="utf-8")


def sync_version_json(new_ver_name, new_build_num):
    """Synchronizes version.json with the new version and build number."""
    if not VERSION_JSON_PATH.exists():
        return

    try:
        data = json.loads(VERSION_JSON_PATH.read_text(encoding="utf-8"))
        data["latest_version"] = new_ver_name
        data["build_number"] = new_build_num
        data["release_title"] = f"Attendly v{new_ver_name}"
        data["download_url"] = f"https://github.com/a3ryk/classtrack/releases/download/v{new_ver_name}/Attendly-v{new_ver_name}.apk"
        data["release_page_url"] = f"https://github.com/a3ryk/classtrack/releases/tag/v{new_ver_name}"
        if "abi_assets" in data and isinstance(data["abi_assets"], dict):
            base_url = f"https://github.com/a3ryk/classtrack/releases/download/v{new_ver_name}"
            data["abi_assets"]["universal"] = f"{base_url}/Attendly-v{new_ver_name}.apk"
            data["abi_assets"]["arm64-v8a"] = f"{base_url}/app-arm64-v8a-release.apk"
            data["abi_assets"]["armeabi-v7a"] = f"{base_url}/app-armeabi-v7a-release.apk"
            data["abi_assets"]["x86_64"] = f"{base_url}/app-x86_64-release.apk"

        VERSION_JSON_PATH.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
    except Exception as e:
        print(f"Warning: Could not sync version.json: {e}")


def calculate_sha256(filepath):
    """Computes SHA-256 hash of a file."""
    h = hashlib.sha256()
    with open(filepath, "rb") as f:
        while chunk := f.read(1024 * 1024):
            h.update(chunk)
    return h.hexdigest()


def compute_next_versions(ver_name, build_num):
    """Calculates sensible next version options."""
    next_build = build_num + 1

    pre_match = re.search(r"^(.*?)-(alpha|beta|rc)\.(\d+)$", ver_name, re.IGNORECASE)
    if pre_match:
        base_ver = pre_match.group(1)
        tag_type = pre_match.group(2).lower()
        tag_num = int(pre_match.group(3))
        next_tag_ver = f"{base_ver}-{tag_type}.{tag_num + 1}"
        stable_ver = base_ver
    else:
        parts = ver_name.split(".")
        if len(parts) >= 3 and parts[2].isdigit():
            next_patch = f"{parts[0]}.{parts[1]}.{int(parts[2]) + 1}"
        else:
            next_patch = f"{ver_name}.1"
        next_tag_ver = f"{next_patch}-beta.1"
        stable_ver = next_patch

    return {
        "keep": (ver_name, build_num),
        "build_only": (ver_name, next_build),
        "tag_bump": (next_tag_ver, next_build),
        "stable_promote": (stable_ver, next_build),
    }


def select_version_interactive(current_ver, current_build):
    """Prompts user to select or customize the version."""
    options = compute_next_versions(current_ver, current_build)

    print("\n------------------------------------------------------------")
    print(" [1] Keep current:        " + f"{options['keep'][0]}+{options['keep'][1]}")
    print(" [2] Bump build only:     " + f"{options['build_only'][0]}+{options['build_only'][1]}")
    print(" [3] Bump pre-release:    " + f"{options['tag_bump'][0]}+{options['tag_bump'][1]}")
    print(" [4] Promote to stable:   " + f"{options['stable_promote'][0]}+{options['stable_promote'][1]}")
    print(" [5] Custom version & build number")
    print("------------------------------------------------------------")

    choice = input("Select version option [Default: 2]: ").strip() or "2"

    if choice == "1":
        return options["keep"]
    elif choice == "2":
        return options["build_only"]
    elif choice == "3":
        return options["tag_bump"]
    elif choice == "4":
        return options["stable_promote"]
    elif choice == "5":
        custom_name = input(f"Enter version name (e.g. 2.0.1-beta.1) [Current: {current_ver}]: ").strip() or current_ver
        custom_build_str = input(f"Enter build number integer [Current: {current_build + 1}]: ").strip() or str(current_build + 1)
        try:
            custom_build = int(custom_build_str)
        except ValueError:
            custom_build = current_build + 1
        return custom_name, custom_build
    else:
        return options["build_only"]


def run_command(cmd, desc):
    """Runs a shell command and streams output."""
    print(f"\n>> {desc}")
    print(f">> Executing: {' '.join(cmd)}\n")
    res = subprocess.run(cmd, cwd=str(ROOT_DIR))
    if res.returncode != 0:
        print(f"\nError: Command failed with exit code {res.returncode}")
        sys.exit(res.returncode)


def post_build_fat(ver_name):
    """Copies and renames output to Attendly-<version>.apk."""
    default_apk = OUTPUT_APK_DIR / "app-release.apk"
    named_apk = OUTPUT_APK_DIR / f"Attendly-v{ver_name}.apk"

    if default_apk.exists():
        import shutil
        shutil.copy2(default_apk, named_apk)
        size_mb = named_apk.stat().st_size / (1024 * 1024)
        sha256 = calculate_sha256(named_apk)
        print("\n============================================================")
        print("  Universal Fat APK Generated Successfully!")
        print("============================================================")
        print(f"  File:   {named_apk.name}")
        print(f"  Path:   {named_apk}")
        print(f"  Size:   {size_mb:.2f} MB")
        print(f"  SHA256: {sha256}")
        print("============================================================\n")
    else:
        print(f"Warning: Expected output not found at {default_apk}")


def post_build_split():
    """Reports split APK files."""
    print("\n============================================================")
    print("  Split-per-ABI APKs Generated Successfully!")
    print("============================================================")
    for abi in ["arm64-v8a", "armeabi-v7a", "x86_64"]:
        apk_path = OUTPUT_APK_DIR / f"app-{abi}-release.apk"
        if apk_path.exists():
            size_mb = apk_path.stat().st_size / (1024 * 1024)
            sha256 = calculate_sha256(apk_path)
            print(f"  [{abi}]")
            print(f"    File:   {apk_path.name} ({size_mb:.2f} MB)")
            print(f"    SHA256: {sha256}")
    print("============================================================\n")


def main():
    parser = argparse.ArgumentParser(description="Attendly Interactive Build & Version Assistant")
    parser.add_argument("--type", choices=["fat", "split", "all", "bundle", "bump-only"], help="Target build type")
    parser.add_argument("--non-interactive", action="store_true", help="Run without prompts")
    args = parser.parse_args()

    current_ver, current_build = read_pubspec_version()

    print("============================================================")
    print("         Attendly Build & Version Assistant")
    print("============================================================")
    print(f"  Current Version Name:  {current_ver}")
    print(f"  Current Build Number:  {current_build}  (Android versionCode)")
    print("============================================================")

    # Determine build target
    build_type = args.type
    if not build_type:
        print("\nSelect Build Target:")
        print("  [1] Universal Fat APK (All devices in 1 APK - Attendly-v<ver>.apk)")
        print("  [2] Split-per-ABI APKs (Lightweight ~45MB each: arm64, armv7, x86_64)")
        print("  [3] Complete Suite (Universal + Split APKs)")
        print("  [4] Google Play App Bundle (app-release.aab)")
        print("  [5] Bump Version Only (Do not compile)")
        print("  [0] Exit")
        choice = input("\nEnter choice [Default: 1]: ").strip() or "1"

        type_map = {
            "1": "fat",
            "2": "split",
            "3": "all",
            "4": "bundle",
            "5": "bump-only",
            "0": "exit",
        }
        build_type = type_map.get(choice, "fat")
        if build_type == "exit":
            print("Operation cancelled.")
            return

    # Select version
    if args.non_interactive:
        new_ver, new_build = current_ver, current_build + 1
    else:
        new_ver, new_build = select_version_interactive(current_ver, current_build)

    # Apply version changes if changed
    if new_ver != current_ver or new_build != current_build:
        print(f"\nUpdating version: {current_ver}+{current_build} -> {new_ver}+{new_build}")
        write_pubspec_version(new_ver, new_build)
        sync_version_json(new_ver, new_build)
        print("Updated pubspec.yaml and version.json successfully.")
    else:
        print(f"\nMaintaining version: {new_ver}+{new_build}")

    if build_type == "bump-only":
        print("\nVersion bumped successfully. No compilation requested.")
        return

    # Confirm execution
    if not args.non_interactive:
        confirm = input(f"\nProceed with building [{build_type.upper()}]? [Y/n]: ").strip().lower()
        if confirm and confirm != "y":
            print("Build cancelled.")
            return

    # Execute builds
    if build_type == "fat":
        run_command(["flutter", "build", "apk", "--release"], "Compiling Universal Fat APK...")
        post_build_fat(new_ver)
    elif build_type == "split":
        run_command(["flutter", "build", "apk", "--release", "--split-per-abi"], "Compiling Split-per-ABI APKs...")
        post_build_split()
    elif build_type == "all":
        run_command(["flutter", "build", "apk", "--release"], "Step 1/2: Compiling Universal Fat APK...")
        post_build_fat(new_ver)
        run_command(["flutter", "build", "apk", "--release", "--split-per-abi"], "Step 2/2: Compiling Split-per-ABI APKs...")
        post_build_split()
    elif build_type == "bundle":
        run_command(["flutter", "build", "appbundle", "--release"], "Compiling Google Play App Bundle (.aab)...")
        aab_path = OUTPUT_AAB_DIR / "app-release.aab"
        if aab_path.exists():
            size_mb = aab_path.stat().st_size / (1024 * 1024)
            print(f"\nApp Bundle ready: {aab_path} ({size_mb:.2f} MB)")


if __name__ == "__main__":
    main()
