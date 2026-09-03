import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import '../constants/app_release_notes.dart';
import '../constants/update_constants.dart';

/// Release Information Model
class AppReleaseInfo {
  final String latestVersion;
  final int buildNumber;
  final String minSupportedVersion;
  final String releaseDate;
  final String releaseTitle;
  final List<String> changelog;
  final String? downloadUrl;
  final String? releasePageUrl;
  final bool isMandatory;
  final String? warningMessage;

  const AppReleaseInfo({
    required this.latestVersion,
    required this.buildNumber,
    required this.minSupportedVersion,
    required this.releaseDate,
    required this.releaseTitle,
    required this.changelog,
    this.downloadUrl,
    this.releasePageUrl,
    this.isMandatory = false,
    this.warningMessage,
  });

  /// Parse from standard ClassTrack version.json format
  factory AppReleaseInfo.fromJson(Map<String, dynamic> json) {
    List<String> parsedChangelog = [];
    if (json['changelog'] is List) {
      parsedChangelog = (json['changelog'] as List)
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } else if (json['changelog'] is String) {
      parsedChangelog = (json['changelog'] as String)
          .split('\n')
          .map((e) => e.replaceAll(RegExp(r'^[•\-\*]\s*'), '').trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    final customWarning = json['warning_message']?.toString().trim() ??
        json['warning']?.toString().trim() ??
        json['mandatory_message']?.toString().trim() ??
        json['notice']?.toString().trim() ??
        json['alert']?.toString().trim();

    return AppReleaseInfo(
      latestVersion: (json['latest_version'] ?? json['version'] ?? '1.0.0').toString().trim(),
      buildNumber: json['build_number'] is int
          ? json['build_number'] as int
          : int.tryParse(json['build_number']?.toString() ?? '1') ?? 1,
      minSupportedVersion: (json['min_supported_version'] ?? json['min_version'] ?? '1.0.0').toString().trim(),
      releaseDate: (json['release_date'] ?? json['date'] ?? '').toString().trim(),
      releaseTitle: (json['release_title'] ?? json['title'] ?? 'New Update Available').toString().trim(),
      changelog: parsedChangelog,
      downloadUrl: json['download_url']?.toString().trim() ?? json['apk_url']?.toString().trim(),
      releasePageUrl: json['release_page_url']?.toString().trim() ?? json['page_url']?.toString().trim() ?? json['play_store_url']?.toString().trim(),
      isMandatory: json['is_mandatory'] == true || json['mandatory'] == true,
      warningMessage: customWarning?.isNotEmpty == true ? customWarning : null,
    );
  }

  /// Parse from GitHub Releases API response (strictly published, non-draft releases)
  factory AppReleaseInfo.fromGithubReleaseJson(Map<String, dynamic> json) {
    final tagName = (json['tag_name'] ?? '1.0.0').toString().replaceAll(RegExp(r'^[vV]'), '');
    final body = (json['body'] ?? '').toString();
    final htmlUrl = json['html_url']?.toString();
    final publishedAt = (json['published_at'] ?? '').toString();

    // Check for APK in release assets (supports universal and --split-per-abi releases)
    String? apkUrl;
    if (json['assets'] is List) {
      final assets = json['assets'] as List;
      final List<Map<String, dynamic>> apkAssets = [];
      for (final asset in assets) {
        if (asset is Map<String, dynamic>) {
          final name = asset['name']?.toString().toLowerCase() ?? '';
          if (name.endsWith('.apk')) {
            apkAssets.add(asset);
          }
        }
      }
      if (apkAssets.isNotEmpty) {
        apkUrl = _selectBestApkForDevice(apkAssets);
      }
    }

    String minSupported = '1.0.0';
    String? extractedWarning;
    bool isMandatory = false;
    final List<String> changelog = [];

    for (final rawLine in body.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#')) continue;

      final cleanLine = line.replaceAll(RegExp(r'<!--|-->'), '').trim();
      final upper = cleanLine.toUpperCase();

      if (upper.startsWith('MIN_VERSION:') || upper.startsWith('MIN_SUPPORTED:')) {
        minSupported = cleanLine.split(':').last.trim().replaceAll(RegExp(r'^[vV]'), '');
        continue;
      }

      if (line.contains('[!WARNING]') ||
          line.contains('[!CAUTION]') ||
          line.contains('⚠️') ||
          line.contains('🚨') ||
          upper.startsWith('MANDATORY:') ||
          upper.startsWith('REQUIRED:') ||
          upper.startsWith('BREAKING:') ||
          upper.startsWith('CRITICAL:') ||
          upper.startsWith('WARNING:')) {
        isMandatory = true;
        extractedWarning = line
            .replaceAll(RegExp(r'^(>\s*\[!(WARNING|CAUTION|IMPORTANT|NOTE)\]\s*|[⚠️🚨📌]\s*|(MANDATORY|REQUIRED|BREAKING|CRITICAL|WARNING|ALERT|NOTICE|NOTE):\s*)', caseSensitive: false), '')
            .trim();
      } else if (line.contains('[!IMPORTANT]') ||
          line.contains('[!NOTE]') ||
          line.contains('📌') ||
          upper.startsWith('ALERT:') ||
          upper.startsWith('NOTICE:') ||
          upper.startsWith('NOTE:')) {
        extractedWarning = line
            .replaceAll(RegExp(r'^(>\s*\[!(WARNING|CAUTION|IMPORTANT|NOTE)\]\s*|[⚠️🚨📌]\s*|(MANDATORY|REQUIRED|BREAKING|CRITICAL|WARNING|ALERT|NOTICE|NOTE):\s*)', caseSensitive: false), '')
            .trim();
      } else {
        changelog.add(line.replaceAll(RegExp(r'^[•\-\*]\s*'), '').trim());
      }
    }

    return AppReleaseInfo(
      latestVersion: tagName,
      buildNumber: 1,
      minSupportedVersion: minSupported,
      releaseDate: publishedAt.isNotEmpty ? publishedAt.split('T').first : '',
      releaseTitle: (json['name'] ?? 'ClassTrack $tagName').toString(),
      changelog: changelog,
      downloadUrl: apkUrl,
      releasePageUrl: htmlUrl,
      isMandatory: isMandatory,
      warningMessage: extractedWarning?.isNotEmpty == true ? extractedWarning : null,
    );
  }

  /// Selects the optimal APK asset matching device architecture (supports split-per-abi & universal)
  static String? _selectBestApkForDevice(List<Map<String, dynamic>> apkAssets) {
    if (apkAssets.isEmpty) return null;
    if (apkAssets.length == 1) {
      return apkAssets.first['browser_download_url']?.toString();
    }

    String deviceAbi = '';
    try {
      final current = Abi.current();
      if (current == Abi.androidArm64) {
        deviceAbi = 'arm64';
      } else if (current == Abi.androidArm) {
        deviceAbi = 'arm';
      } else if (current == Abi.androidX64) {
        deviceAbi = 'x86_64';
      }
    } catch (_) {}

    // 1. Exact ABI match (e.g. arm64-v8a, armeabi-v7a, x86_64)
    if (deviceAbi == 'arm64') {
      for (final a in apkAssets) {
        final name = a['name']?.toString().toLowerCase() ?? '';
        if (name.contains('arm64') || name.contains('v8a') || name.contains('aarch64')) {
          return a['browser_download_url']?.toString();
        }
      }
    } else if (deviceAbi == 'arm') {
      for (final a in apkAssets) {
        final name = a['name']?.toString().toLowerCase() ?? '';
        if ((name.contains('arm') && !name.contains('arm64')) || name.contains('v7a') || name.contains('armeabi')) {
          return a['browser_download_url']?.toString();
        }
      }
    } else if (deviceAbi == 'x86_64') {
      for (final a in apkAssets) {
        final name = a['name']?.toString().toLowerCase() ?? '';
        if (name.contains('x86_64') || name.contains('x64')) {
          return a['browser_download_url']?.toString();
        }
      }
    }

    // 2. Look for universal APK
    for (final a in apkAssets) {
      final name = a['name']?.toString().toLowerCase() ?? '';
      if (name.contains('universal') ||
          (!name.contains('arm') && !name.contains('v8a') && !name.contains('v7a') && !name.contains('x86'))) {
        return a['browser_download_url']?.toString();
      }
    }

    // 3. Fallback to first available APK
    return apkAssets.first['browser_download_url']?.toString();
  }
}

/// Robust, Secure In-App Update Engine
class AppUpdateService {
  AppUpdateService._();

  /// Clean semantic version parsing with pre-release support (e.g. "v1.0.0-alpha.3" -> [1, 0, 0, 3])
  static List<int> parseSemver(String versionStr) {
    try {
      final clean = versionStr
          .trim()
          .replaceAll(RegExp(r'^[vV]'), '')
          .split('+').first;

      final parts = clean.split('-');
      final baseParts = parts.first.split('.');
      final List<int> numbers = [];
      for (int i = 0; i < 3; i++) {
        if (i < baseParts.length) {
          numbers.add(int.tryParse(baseParts[i]) ?? 0);
        } else {
          numbers.add(0);
        }
      }

      if (parts.length > 1) {
        final preStr = parts.sublist(1).join('-');
        final match = RegExp(r'(\d+)').allMatches(preStr);
        if (match.isNotEmpty) {
          numbers.add(int.tryParse(match.last.group(1)!) ?? 0);
        } else {
          numbers.add(0);
        }
      } else {
        numbers.add(999999);
      }

      return numbers;
    } catch (_) {
      return [1, 0, 0, 0];
    }
  }

  /// Compares currentVersion and remoteVersion.
  /// Returns > 0 if remoteVersion is newer than currentVersion.
  /// Returns 0 if versions are equal.
  /// Returns < 0 if remoteVersion is older than currentVersion.
  static int compareSemver(String currentVersion, String remoteVersion) {
    final curr = parseSemver(currentVersion);
    final remote = parseSemver(remoteVersion);

    for (int i = 0; i < math.max(curr.length, remote.length); i++) {
      final c = i < curr.length ? curr[i] : 0;
      final r = i < remote.length ? remote[i] : 0;
      if (r > c) return 1;
      if (r < c) return -1;
    }
    return 0;
  }

  /// Determines if an update is available based on semver and build numbers
  static bool isUpdateAvailable({
    required String currentVersion,
    required String remoteVersion,
    int currentBuild = 0,
    int remoteBuild = 0,
  }) {
    final semverDiff = compareSemver(currentVersion, remoteVersion);
    if (semverDiff > 0) return true;
    if (semverDiff == 0 && remoteBuild > currentBuild && remoteBuild > 0 && currentBuild > 0) {
      return true;
    }
    return false;
  }

  /// Determines if update must be forced (e.g. breaking DB migration or remote mandatory flag)
  static bool isMandatoryUpdate({
    required String currentVersion,
    required String minSupportedVersion,
    bool isMandatoryFlag = false,
  }) {
    if (isMandatoryFlag) return true;
    if (minSupportedVersion.isNotEmpty) {
      final diff = compareSemver(currentVersion, minSupportedVersion);
      if (diff > 0) return true; // current version is below minimum supported version
    }
    return false;
  }

  /// Securely fetches remote version metadata via HTTPS
  static Future<AppReleaseInfo?> fetchReleaseInfo({
    String? customUrl,
    http.Client? client,
  }) async {
    final httpClient = client ?? http.Client();
    final urlStr = customUrl ?? UpdateConstants.defaultVersionCheckUrl;

    try {
      final uri = Uri.tryParse(urlStr);
      if (uri == null) {
        debugPrint('[AppUpdateService] Invalid URL format: $urlStr');
        return null;
      }

      // Security check: Enforce HTTPS for non-localhost endpoints to prevent MITM attacks
      if (uri.scheme != 'https' && uri.host != 'localhost' && uri.host != '127.0.0.1') {
        debugPrint('[AppUpdateService] Security Warning: Refusing non-HTTPS version check URL.');
        return null;
      }

      final response = await httpClient.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'ClassTrack-Updater/1.0',
        },
      ).timeout(UpdateConstants.requestTimeout);

      if (response.statusCode == 200) {
        final decoded = json.decode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) {
          return AppReleaseInfo.fromJson(decoded);
        }
      } else {
        debugPrint('[AppUpdateService] HTTP ${response.statusCode} from version endpoint.');
      }
    } catch (e) {
      debugPrint('[AppUpdateService] Failed to check for updates: $e');
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
    return null;
  }

  /// Fallback: Fetches release directly from GitHub Releases API
  static Future<AppReleaseInfo?> fetchGithubRelease({
    String owner = UpdateConstants.defaultGithubOwner,
    String repo = UpdateConstants.defaultGithubRepo,
    http.Client? client,
  }) async {
    final httpClient = client ?? http.Client();
    final uri = Uri.parse('https://api.github.com/repos/$owner/$repo/releases/latest');

    try {
      final response = await httpClient.get(
        uri,
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'ClassTrack-Updater/1.0',
        },
      ).timeout(UpdateConstants.requestTimeout);

      if (response.statusCode == 200) {
        final decoded = json.decode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) {
          return AppReleaseInfo.fromGithubReleaseJson(decoded);
        }
      }
    } catch (e) {
      debugPrint('[AppUpdateService] GitHub fallback release check failed: $e');
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
    return null;
  }

  /// Fetches latest published release.
  /// Prioritizes GitHub Releases API to guarantee draft/unpublished releases are ignored.
  /// Falls back to the raw version manifest if GitHub API is unreachable or rate-limited.
  static Future<AppReleaseInfo?> fetchLatestRelease({
    String? customUrl,
    String owner = UpdateConstants.defaultGithubOwner,
    String repo = UpdateConstants.defaultGithubRepo,
    http.Client? client,
  }) async {
    // 1. Primary: GitHub Releases API (draft-immune)
    final githubRelease = await fetchGithubRelease(owner: owner, repo: repo, client: client);
    if (githubRelease != null) return githubRelease;

    // 2. Secondary fallback: Raw version manifest
    return fetchReleaseInfo(customUrl: customUrl, client: client);
  }

  /// Hybrid Release Notes Fetcher:
  /// 1. Checks offline bundled notes in AppReleaseNotes.
  /// 2. If not found in the local registry (e.g. newly installed build without hardcoded notes),
  ///    dynamically queries GitHub Releases tag endpoint:
  ///    https://api.github.com/repos/a3ryk/classtrack/releases/tags/v$cleanVersion
  /// 3. Safely falls back to local default if network is unavailable.
  static Future<AppReleaseInfo> fetchReleaseNotesForVersion({
    required String versionStr,
    String owner = UpdateConstants.defaultGithubOwner,
    String repo = UpdateConstants.defaultGithubRepo,
    http.Client? client,
  }) async {
    final clean = versionStr.trim().replaceAll(RegExp(r'^[vV]'), '').split('+').first;

    if (AppReleaseNotes.hasVersion(clean)) {
      return AppReleaseNotes.getForVersion(clean);
    }

    final httpClient = client ?? http.Client();
    try {
      final uri = Uri.parse('https://api.github.com/repos/$owner/$repo/releases/tags/v$clean');
      final response = await httpClient.get(
        uri,
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'ClassTrack-App',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final decoded = json.decode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) {
          return AppReleaseInfo.fromGithubReleaseJson(decoded);
        }
      }
    } catch (_) {
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }

    return AppReleaseNotes.getForVersion(clean);
  }

  /// Downloads an APK from [downloadUrl] to app cache with chunked streaming and progress reporting.
  /// Once downloaded, verifies integrity and returns the saved File.
  static Future<File?> downloadApk({
    required String downloadUrl,
    required void Function(int receivedBytes, int totalBytes, double progressPct) onProgress,
    http.Client? client,
  }) async {
    if (!Platform.isAndroid) return null;
    final httpClient = client ?? http.Client();

    try {
      final uri = Uri.parse(downloadUrl);
      final request = http.Request('GET', uri);
      final response = await httpClient.send(request);

      if (response.statusCode != 200) {
        throw Exception('Download server returned HTTP ${response.statusCode}');
      }

      final totalBytes = response.contentLength ?? 0;
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(p.join(tempDir.path, 'classtrack_update.apk.tmp'));
      final targetFile = File(p.join(tempDir.path, 'classtrack_update.apk'));

      if (await tempFile.exists()) await tempFile.delete();
      if (await targetFile.exists()) await targetFile.delete();

      final sink = tempFile.openWrite();
      int receivedBytes = 0;

      await for (final chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        final pct = totalBytes > 0 ? (receivedBytes / totalBytes) : 0.0;
        onProgress(receivedBytes, totalBytes, pct.clamp(0.0, 1.0));
      }

      await sink.flush();
      await sink.close();

      // Atomic rename once complete
      await tempFile.rename(targetFile.path);
      return targetFile;
    } catch (e) {
      debugPrint('[AppUpdateService] APK download failed: $e');
      rethrow;
    } finally {
      if (client == null) httpClient.close();
    }
  }

  static const MethodChannel _installerChannel =
      MethodChannel('com.classtrack.app/package_installer');

  /// Triggers package installer on Android for downloaded APK file using native FileProvider
  static Future<bool> installApk(File apkFile) async {
    if (!Platform.isAndroid) return false;
    try {
      if (!await apkFile.exists()) return false;

      // Check / request install unknown apps permission
      final status = await Permission.requestInstallPackages.status;
      if (status.isDenied) {
        final req = await Permission.requestInstallPackages.request();
        if (!req.isGranted) {
          await openAppSettings();
          return false;
        }
      }

      // Invoke native PackageInstaller with FileProvider content URI
      final bool? success = await _installerChannel.invokeMethod<bool>(
        'installApk',
        {'filePath': apkFile.path},
      );

      return success ?? false;
    } catch (e) {
      debugPrint('[AppUpdateService] APK install trigger failed: $e');
      return false;
    }
  }
}
