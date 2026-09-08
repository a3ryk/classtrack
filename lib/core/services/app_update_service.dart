import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
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
  final Map<String, String> abiAssets;

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
    this.abiAssets = const {},
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

    final Map<String, String> abiAssets = {};
    if (json['abi_assets'] is Map) {
      (json['abi_assets'] as Map).forEach((k, v) {
        if (k != null && v != null) {
          abiAssets[k.toString()] = v.toString();
        }
      });
    }

    String? downloadUrl = json['download_url']?.toString().trim() ?? json['apk_url']?.toString().trim();
    if (abiAssets.isNotEmpty) {
      final bestUrl = _selectBestApkFromMap(abiAssets);
      if (bestUrl != null) {
        downloadUrl = bestUrl;
      }
    }

    return AppReleaseInfo(
      latestVersion: (json['latest_version'] ?? json['version'] ?? '1.0.0').toString().trim(),
      buildNumber: json['build_number'] is int
          ? json['build_number'] as int
          : int.tryParse(json['build_number']?.toString() ?? '1') ?? 1,
      minSupportedVersion: (json['min_supported_version'] ?? json['min_version'] ?? '1.0.0').toString().trim(),
      releaseDate: (json['release_date'] ?? json['date'] ?? '').toString().trim(),
      releaseTitle: (json['release_title'] ?? json['title'] ?? 'New Update Available').toString().trim(),
      changelog: parsedChangelog,
      downloadUrl: downloadUrl,
      releasePageUrl: json['release_page_url']?.toString().trim() ?? json['page_url']?.toString().trim() ?? json['play_store_url']?.toString().trim(),
      isMandatory: json['is_mandatory'] == true || json['mandatory'] == true,
      warningMessage: customWarning?.isNotEmpty == true ? customWarning : null,
      abiAssets: abiAssets,
    );
  }

  /// Decode basic HTML entities found in Atom feeds or web markdown (supports double-encoded entities)
  static String _decodeHtmlEntities(String input) {
    String prev = '';
    String current = input;
    int passes = 0;
    while (prev != current && passes < 3) {
      prev = current;
      current = current
          .replaceAll('&amp;', '&')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .replaceAll('&quot;', '"')
          .replaceAll('&#39;', "'")
          .replaceAll('&apos;', "'");
      passes++;
    }
    return current;
  }

  /// Parse from GitHub Releases API response (strictly published, non-draft releases)
  factory AppReleaseInfo.fromGithubReleaseJson(Map<String, dynamic> json) {
    final rawTagName = (json['tag_name'] ?? '1.0.0').toString();
    final tagName = rawTagName.replaceAll(RegExp(r'^[vV]'), '');
    final body = (json['body'] ?? '').toString();
    final htmlUrl = json['html_url']?.toString();
    final publishedAt = (json['published_at'] ?? '').toString();

    // Parse true build number from tag (e.g. 1.0.0-alpha.7+7 -> 7, or alpha.7 -> 7)
    int buildNumber = 1;
    if (tagName.contains('+')) {
      buildNumber = int.tryParse(tagName.split('+').last) ?? 1;
    } else {
      final match = RegExp(r'(?:alpha|beta|rc|\+)\.?(\d+)', caseSensitive: false).firstMatch(tagName);
      if (match != null) {
        buildNumber = int.tryParse(match.group(1)!) ?? 1;
      }
    }

    // Check for APK in release assets (supports universal and --split-per-abi releases)
    String? apkUrl;
    final Map<String, String> abiAssets = {};
    if (json['assets'] is List) {
      final assets = json['assets'] as List;
      final List<Map<String, dynamic>> apkAssets = [];
      for (final asset in assets) {
        if (asset is Map<String, dynamic>) {
          final name = asset['name']?.toString().toLowerCase() ?? '';
          final url = asset['browser_download_url']?.toString();
          if (name.endsWith('.apk') && url != null) {
            apkAssets.add(asset);
            if (name.contains('arm64') || name.contains('v8a')) {
              abiAssets['arm64-v8a'] = url;
            } else if (name.contains('armeabi') || name.contains('v7a')) {
              abiAssets['armeabi-v7a'] = url;
            } else if (name.contains('x86_64') || name.contains('x64')) {
              abiAssets['x86_64'] = url;
            } else {
              abiAssets['universal'] = url;
            }
          }
        }
      }
      if (apkAssets.isNotEmpty) {
        apkUrl = _selectBestApkForDevice(apkAssets);
      }
    }

    String minSupported = '1.0.0';
    bool isMandatory = false;
    final List<String> changelog = [];
    final List<String> alertLines = [];
    bool inAlertBlock = false;

    for (final rawLine in body.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) {
        inAlertBlock = false;
        continue;
      }
      if (line.startsWith('#')) {
        inAlertBlock = false;
        continue;
      }

      final cleanLine = line.replaceAll(RegExp(r'<!--|-->'), '').trim();
      final upper = cleanLine.toUpperCase();

      // Skip markdown tables, horizontal rules, and link footnotes
      if (cleanLine.startsWith('|') ||
          cleanLine.startsWith('---') ||
          cleanLine.startsWith('===') ||
          cleanLine.startsWith('***') ||
          cleanLine.startsWith('[Full Changelog') ||
          cleanLine.startsWith('**Full Changelog') ||
          upper.startsWith('### DOWNLOAD') ||
          upper.startsWith('### ASSET')) {
        continue;
      }

      if (upper.startsWith('MIN_VERSION:') || upper.startsWith('MIN_SUPPORTED:')) {
        minSupported = cleanLine.split(':').last.trim().replaceAll(RegExp(r'^[vV]'), '');
        continue;
      }

      if (upper.startsWith('BUILD_NUMBER:') || upper.startsWith('BUILD:')) {
        final parsedBuild = int.tryParse(cleanLine.split(':').last.trim());
        if (parsedBuild != null) buildNumber = parsedBuild;
        continue;
      }

      // Check for GitHub Alert Callout Block (e.g. > [!WARNING], > [!CAUTION], > [!IMPORTANT], > [!NOTE])
      if (upper.startsWith('> [!WARNING]') ||
          upper.startsWith('> [!CAUTION]') ||
          upper.startsWith('> [!IMPORTANT]')) {
        isMandatory = true;
        inAlertBlock = true;
        continue;
      } else if (upper.startsWith('> [!NOTE]') || upper.startsWith('> [!TIP]')) {
        inAlertBlock = true;
        continue;
      }

      // If currently inside an alert blockquote, capture all subsequent `>` lines
      if (inAlertBlock) {
        if (cleanLine.startsWith('>')) {
          final content = cleanLine
              .replaceAll(RegExp(r'^>\s*'), '')
              .replaceAll(RegExp(r'\*\*'), '')
              .replaceAll(RegExp(r'^(Mandatory Update|Critical|Warning|Notice|Alert|Important):\s*', caseSensitive: false), '')
              .trim();
          if (content.isNotEmpty) {
            alertLines.add(content);
          }
          continue;
        } else {
          inAlertBlock = false;
        }
      }

      // Single-line alert checks (e.g. ⚠️ Warning message, MANDATORY: message)
      if (line.contains('⚠️') ||
          line.contains('🚨') ||
          upper.startsWith('MANDATORY:') ||
          upper.startsWith('REQUIRED:') ||
          upper.startsWith('BREAKING:') ||
          upper.startsWith('CRITICAL:') ||
          upper.startsWith('WARNING:')) {
        isMandatory = true;
        final msg = line
            .replaceAll(RegExp(r'^(>\s*|[⚠️🚨📌]\s*|(MANDATORY|REQUIRED|BREAKING|CRITICAL|WARNING|ALERT|NOTICE|NOTE):\s*)', caseSensitive: false), '')
            .replaceAll(RegExp(r'\*\*'), '')
            .trim();
        if (msg.isNotEmpty) alertLines.add(msg);
      } else if (line.contains('📌') ||
          upper.startsWith('ALERT:') ||
          upper.startsWith('NOTICE:') ||
          upper.startsWith('NOTE:')) {
        final msg = line
            .replaceAll(RegExp(r'^(>\s*|[⚠️🚨📌]\s*|(MANDATORY|REQUIRED|BREAKING|CRITICAL|WARNING|ALERT|NOTICE|NOTE):\s*)', caseSensitive: false), '')
            .replaceAll(RegExp(r'\*\*'), '')
            .trim();
        if (msg.isNotEmpty) alertLines.add(msg);
      } else {
        changelog.add(line.replaceAll(RegExp(r'^[•\-\*]\s*'), '').trim());
      }
    }

    final String? warningMessage = alertLines.isNotEmpty ? alertLines.join(' ') : null;

    return AppReleaseInfo(
      latestVersion: tagName,
      buildNumber: buildNumber,
      minSupportedVersion: minSupported,
      releaseDate: publishedAt.isNotEmpty ? publishedAt.split('T').first : '',
      releaseTitle: (json['name'] ?? 'ClassTrack $tagName').toString(),
      changelog: changelog,
      downloadUrl: apkUrl,
      releasePageUrl: htmlUrl,
      isMandatory: isMandatory,
      warningMessage: warningMessage,
      abiAssets: abiAssets,
    );
  }

  /// Parse the latest release from GitHub's public releases Atom feed (zero rate-limits)
  factory AppReleaseInfo.fromGithubAtomFeed(
    String atomXml, {
    String owner = UpdateConstants.defaultGithubOwner,
    String repo = UpdateConstants.defaultGithubRepo,
  }) {
    final entryMatch = RegExp(r'<entry>(.*?)</entry>', dotAll: true).firstMatch(atomXml);
    if (entryMatch == null) {
      throw const FormatException('No entry found in Atom feed');
    }
    final entryContent = entryMatch.group(1)!;

    // Extract tag from link or id
    String tag = '';
    final tagMatch = RegExp(r'/releases/tag/([^"<\s]+)').firstMatch(entryContent);
    if (tagMatch != null) {
      tag = tagMatch.group(1)!;
    } else {
      final idMatch = RegExp(r'<id>[^<]*/([^/<]+)</id>').firstMatch(entryContent);
      if (idMatch != null) tag = idMatch.group(1)!;
    }
    final cleanVersion = tag.replaceAll(RegExp(r'^[vV]'), '');

    // Title
    String title = 'ClassTrack $cleanVersion';
    final titleMatch = RegExp(r'<title>(.*?)</title>').firstMatch(entryContent);
    if (titleMatch != null) {
      title = _decodeHtmlEntities(titleMatch.group(1)!.trim());
    }

    // Published date
    String publishedDate = '';
    final updatedMatch = RegExp(r'<updated>(.*?)</updated>').firstMatch(entryContent);
    if (updatedMatch != null) {
      publishedDate = updatedMatch.group(1)!.split('T').first;
    }

    // Build number from tag
    int buildNumber = 1;
    if (cleanVersion.contains('+')) {
      buildNumber = int.tryParse(cleanVersion.split('+').last) ?? 1;
    } else {
      final match = RegExp(r'(?:alpha|beta|rc|\+)\.?(\d+)', caseSensitive: false).firstMatch(cleanVersion);
      if (match != null) {
        buildNumber = int.tryParse(match.group(1)!) ?? 1;
      }
    }

    // Parse HTML content
    final contentMatch = RegExp(r'<content\s+type="html">(.*?)</content>', dotAll: true).firstMatch(entryContent);
    final rawHtml = contentMatch != null ? _decodeHtmlEntities(contentMatch.group(1)!) : '';

    bool isMandatory = false;
    String? warningMessage;
    final List<String> changelog = [];

    if (rawHtml.isNotEmpty) {
      if (rawHtml.contains('markdown-alert-important') ||
          rawHtml.contains('markdown-alert-warning') ||
          rawHtml.contains('markdown-alert-caution') ||
          rawHtml.contains('Mandatory Update')) {
        isMandatory = true;
      }

      final alertMatch = RegExp(
        r'<div class="markdown-alert[^"]*">.*?<p>(?:<strong>.*?</strong>:?\s*)?(.*?)</p>',
        dotAll: true,
      ).firstMatch(rawHtml);
      if (alertMatch != null) {
        final alertText = _decodeHtmlEntities(alertMatch.group(1)!.replaceAll(RegExp(r'<[^>]*>'), '').trim());
        if (alertText.isNotEmpty) {
          warningMessage = alertText;
        }
      }

      final liMatches = RegExp(r'<li>(.*?)</li>', dotAll: true).allMatches(rawHtml);
      for (final m in liMatches) {
        final itemText = _decodeHtmlEntities(m.group(1)!.replaceAll(RegExp(r'<[^>]*>'), '').trim());
        if (itemText.isNotEmpty &&
            !itemText.startsWith('|') &&
            !itemText.startsWith('---') &&
            !itemText.startsWith('Full Changelog')) {
          changelog.add(itemText);
        }
      }
    }

    final rawTag = tag.isNotEmpty ? tag : 'v$cleanVersion';
    final baseUrl = 'https://github.com/$owner/$repo/releases/download/$rawTag';
    final Map<String, String> abiAssets = {
      'arm64-v8a': '$baseUrl/app-arm64-v8a-release.apk',
      'armeabi-v7a': '$baseUrl/app-armeabi-v7a-release.apk',
      'x86_64': '$baseUrl/app-x86_64-release.apk',
      'universal': '$baseUrl/ClassTrack-$rawTag.apk',
    };

    return AppReleaseInfo(
      latestVersion: cleanVersion,
      buildNumber: buildNumber,
      minSupportedVersion: '1.0.0',
      releaseDate: publishedDate,
      releaseTitle: title,
      changelog: changelog,
      downloadUrl: _selectBestApkFromMap(abiAssets),
      releasePageUrl: 'https://github.com/$owner/$repo/releases/tag/$rawTag',
      isMandatory: isMandatory,
      warningMessage: warningMessage,
      abiAssets: abiAssets,
    );
  }

  /// Selects the optimal APK matching device architecture from an ABI map
  static String? _selectBestApkFromMap(Map<String, String> abiMap) {
    if (abiMap.isEmpty) return null;
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

    if (deviceAbi == 'arm64' && abiMap.containsKey('arm64-v8a')) {
      return abiMap['arm64-v8a'];
    }
    if (deviceAbi == 'arm' && abiMap.containsKey('armeabi-v7a')) {
      return abiMap['armeabi-v7a'];
    }
    if (deviceAbi == 'x86_64' && abiMap.containsKey('x86_64')) {
      return abiMap['x86_64'];
    }
    return abiMap['universal'] ?? abiMap.values.firstOrNull;
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

  /// Fetches release directly from GitHub Releases API (supports pre-releases like alpha/beta)
  static Future<AppReleaseInfo?> fetchGithubRelease({
    String owner = UpdateConstants.defaultGithubOwner,
    String repo = UpdateConstants.defaultGithubRepo,
    http.Client? client,
  }) async {
    final httpClient = client ?? http.Client();
    // Query /releases to include pre-releases (which GitHub /releases/latest excludes with 404)
    final uri = Uri.parse('https://api.github.com/repos/$owner/$repo/releases');

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
        if (decoded is List && decoded.isNotEmpty) {
          final firstPublished = decoded.firstWhere(
            (r) => r is Map<String, dynamic> && r['draft'] != true,
            orElse: () => null,
          );
          if (firstPublished is Map<String, dynamic>) {
            return AppReleaseInfo.fromGithubReleaseJson(firstPublished);
          }
        } else if (decoded is Map<String, dynamic>) {
          return AppReleaseInfo.fromGithubReleaseJson(decoded);
        }
      }
    } catch (e) {
      debugPrint('[AppUpdateService] GitHub releases check failed: $e');
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
    return null;
  }

  /// Fetches release info from GitHub's public releases Atom feed (has NO 60-req/hr rate limit)
  static Future<AppReleaseInfo?> fetchGithubAtomFeed({
    String owner = UpdateConstants.defaultGithubOwner,
    String repo = UpdateConstants.defaultGithubRepo,
    http.Client? client,
  }) async {
    final httpClient = client ?? http.Client();
    final uri = Uri.parse('https://github.com/$owner/$repo/releases.atom');

    try {
      final response = await httpClient.get(
        uri,
        headers: {
          'Accept': 'application/atom+xml, text/xml',
          'User-Agent': 'ClassTrack-Updater/1.0',
        },
      ).timeout(UpdateConstants.requestTimeout);

      if (response.statusCode == 200) {
        final xml = utf8.decode(response.bodyBytes);
        return AppReleaseInfo.fromGithubAtomFeed(xml, owner: owner, repo: repo);
      }
    } catch (e) {
      debugPrint('[AppUpdateService] GitHub Atom feed check failed: $e');
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
    return null;
  }

  /// Fetches latest published release with multi-tier fallback:
  /// 1. GitHub Releases API (guarantees published status and detailed asset lists).
  /// 2. GitHub Releases Atom Feed (public, 0 rate limits, always contains latest published tag).
  /// 3. Raw version manifest with cache-busting timestamp (CDN bypass).
  static Future<AppReleaseInfo?> fetchLatestRelease({
    String? customUrl,
    String owner = UpdateConstants.defaultGithubOwner,
    String repo = UpdateConstants.defaultGithubRepo,
    http.Client? client,
  }) async {
    // 1. Primary: GitHub Releases API
    try {
      final githubRelease = await fetchGithubRelease(owner: owner, repo: repo, client: client);
      if (githubRelease != null) return githubRelease;
    } catch (_) {}

    // 1b. Secondary fallback: GitHub Releases public Atom feed (rate-limit immune)
    try {
      final atomRelease = await fetchGithubAtomFeed(owner: owner, repo: repo, client: client);
      if (atomRelease != null) return atomRelease;
    } catch (_) {}

    // 2. Tertiary fallback: Raw version manifest with cache-busting timestamp
    final String cacheBustedUrl =
        customUrl ?? '${UpdateConstants.defaultVersionCheckUrl}?t=${DateTime.now().millisecondsSinceEpoch}';
    return fetchReleaseInfo(customUrl: cacheBustedUrl, client: client);
  }

  /// Resolves the optimal APK matching device hardware architecture from an ABI map
  static Future<String?> resolveBestDownloadUrl(Map<String, String> abiAssets) async {
    if (abiAssets.isEmpty) return null;

    List<String> supportedAbis = [];
    if (Platform.isAndroid) {
      try {
        supportedAbis = await getDeviceSupportedAbis();
      } catch (_) {}
    }

    if (supportedAbis.isEmpty) {
      try {
        final current = Abi.current();
        if (current == Abi.androidArm64) {
          supportedAbis = ['arm64-v8a', 'armeabi-v7a'];
        } else if (current == Abi.androidArm) {
          supportedAbis = ['armeabi-v7a'];
        } else if (current == Abi.androidX64) {
          supportedAbis = ['x86_64', 'arm64-v8a'];
        }
      } catch (_) {}
    }

    for (final abi in supportedAbis) {
      final norm = abi.toLowerCase();
      if (norm.contains('arm64') || norm.contains('v8a')) {
        if (abiAssets.containsKey('arm64-v8a')) return abiAssets['arm64-v8a'];
      } else if (norm.contains('armeabi-v7a') || norm.contains('v7a') || (norm.contains('arm') && !norm.contains('64'))) {
        if (abiAssets.containsKey('armeabi-v7a')) return abiAssets['armeabi-v7a'];
      } else if (norm.contains('x86_64') || norm.contains('x64')) {
        if (abiAssets.containsKey('x86_64')) return abiAssets['x86_64'];
      }
    }

    if (abiAssets.containsKey('universal')) {
      return abiAssets['universal'];
    }

    return abiAssets.values.firstOrNull;
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

  /// Downloads an APK from [downloadUrl] to app cache with chunked streaming,
  /// automatic redirect following (essential for GitHub Release asset 302 redirects),
  /// and real-time progress reporting.
  static Future<File?> downloadApk({
    required String downloadUrl,
    required void Function(int receivedBytes, int totalBytes, double progressPct) onProgress,
    http.Client? client,
  }) async {
    if (!Platform.isAndroid) return null;
    final httpClient = client ?? http.Client();

    try {
      Uri currentUri = Uri.parse(downloadUrl);
      http.StreamedResponse response;
      int redirectCount = 0;

      // Follow HTTP 301/302/307/308 redirects (GitHub Releases redirect to AWS S3 CDN)
      while (true) {
        final request = http.Request('GET', currentUri);
        request.headers['User-Agent'] = 'ClassTrack-Updater/1.0';
        request.headers['Accept'] = '*/*';
        response = await httpClient.send(request);

        if (response.statusCode == 301 ||
            response.statusCode == 302 ||
            response.statusCode == 307 ||
            response.statusCode == 308) {
          final location = response.headers['location'];
          if (location != null && redirectCount < 5) {
            currentUri = Uri.parse(location);
            redirectCount++;
            continue;
          }
        }
        break;
      }

      if (response.statusCode != 200) {
        throw Exception('Download server returned HTTP ${response.statusCode}');
      }

      final totalBytes = response.contentLength ?? 0;
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(p.join(tempDir.path, 'classtrack_update.apk.tmp'));
      final targetFile = File(p.join(tempDir.path, 'classtrack_update.apk'));

      if (await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }
      if (await targetFile.exists()) {
        try {
          await targetFile.delete();
        } catch (_) {}
      }

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

      // Safe atomic rename or copy fallback
      try {
        await tempFile.rename(targetFile.path);
      } catch (_) {
        await tempFile.copy(targetFile.path);
        try {
          await tempFile.delete();
        } catch (_) {}
      }
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

  /// Queries Android device's hardware supported ABIs in preference order
  static Future<List<String>> getDeviceSupportedAbis() async {
    if (Platform.isAndroid) {
      try {
        final List<dynamic>? abis = await _installerChannel.invokeMethod<List<dynamic>>('getSupportedAbis');
        if (abis != null && abis.isNotEmpty) {
          return abis.map((e) => e.toString().toLowerCase()).toList();
        }
      } catch (_) {}
    }

    try {
      final current = Abi.current();
      if (current == Abi.androidArm64) return ['arm64-v8a', 'armeabi-v7a'];
      if (current == Abi.androidArm) return ['armeabi-v7a'];
      if (current == Abi.androidX64) return ['x86_64'];
    } catch (_) {}

    return ['arm64-v8a', 'universal'];
  }

  /// Triggers package installer on Android for downloaded APK file using native FileProvider
  static Future<bool> installApk(File apkFile) async {
    if (!Platform.isAndroid) return false;
    try {
      if (!await apkFile.exists()) return false;

      // Check install unknown apps permission via native channel
      final bool? canInstall = await _installerChannel.invokeMethod<bool>('canRequestPackageInstalls');
      if (canInstall == false) {
        await _installerChannel.invokeMethod('openInstallPermissionSettings');
        return false;
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
