import 'package:flutter_test/flutter_test.dart';
import 'package:classtrack/core/services/app_update_service.dart';

void main() {
  group('AppUpdateService Release & ABI Tests', () {
    test('GitHub Release JSON parsing with ABI assets and clean changelog', () {
      final mockGithubJson = {
        'tag_name': 'v1.0.0-alpha.7',
        'name': 'ClassTrack v1.0.0-alpha.7 (Notifications & Multi-Channel Fix)',
        'published_at': '2026-09-08T19:41:38Z',
        'html_url': 'https://github.com/a3ryk/classtrack/releases/tag/v1.0.0-alpha.7',
        'body': '''
> [!IMPORTANT]
> **Mandatory Update:** System notification channel locking fix.

### ✨ What's New in v1.0.0-alpha.7
- Multi-Channel sound and vibration routing
- Redesigned Notification Hub

### 📦 Downloads & Asset Architecture
| Asset | Target Architecture | Typical Size |
|:---|:---|:---|
| app-arm64-v8a-release.apk | Modern 64-bit ARM | ~45.7 MB |
| app-armeabi-v7a-release.apk | 32-bit Legacy ARM | ~37.8 MB |
---
**Full Changelog**: https://github.com/a3ryk/classtrack/compare/v1.0.0-alpha.6...v1.0.0-alpha.7
''',
        'assets': [
          {
            'name': 'app-arm64-v8a-release.apk',
            'browser_download_url': 'https://github.com/a3ryk/classtrack/releases/download/v1.0.0-alpha.7/app-arm64-v8a-release.apk',
          },
          {
            'name': 'app-armeabi-v7a-release.apk',
            'browser_download_url': 'https://github.com/a3ryk/classtrack/releases/download/v1.0.0-alpha.7/app-armeabi-v7a-release.apk',
          },
          {
            'name': 'app-x86_64-release.apk',
            'browser_download_url': 'https://github.com/a3ryk/classtrack/releases/download/v1.0.0-alpha.7/app-x86_64-release.apk',
          },
          {
            'name': 'ClassTrack-v1.0.0-alpha.7.apk',
            'browser_download_url': 'https://github.com/a3ryk/classtrack/releases/download/v1.0.0-alpha.7/ClassTrack-v1.0.0-alpha.7.apk',
          },
        ],
      };

      final info = AppReleaseInfo.fromGithubReleaseJson(mockGithubJson);

      expect(info.latestVersion, '1.0.0-alpha.7');
      expect(info.buildNumber, 7);
      expect(info.isMandatory, isTrue);
      expect(info.warningMessage, contains('System notification channel locking fix'));
      expect(info.abiAssets.length, 4);
      expect(info.abiAssets.containsKey('arm64-v8a'), isTrue);
      expect(info.abiAssets.containsKey('armeabi-v7a'), isTrue);
      expect(info.abiAssets.containsKey('x86_64'), isTrue);
      expect(info.abiAssets.containsKey('universal'), isTrue);

      // Verify changelog stripped markdown tables and divider lines
      for (final line in info.changelog) {
        expect(line.startsWith('|'), isFalse);
        expect(line.startsWith('---'), isFalse);
        expect(line.startsWith('**Full Changelog'), isFalse);
      }
      expect(info.changelog, contains('Multi-Channel sound and vibration routing'));
      expect(info.changelog, contains('Redesigned Notification Hub'));
    });

    test('GitHub Atom Feed XML parsing fallback (zero rate-limits)', () {
      const sampleAtomXml = '''<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom" xml:lang="en-US">
  <entry>
    <id>tag:github.com,2008:Repository/1349449512/v1.0.0-alpha.7</id>
    <updated>2026-09-08T19:41:38Z</updated>
    <link rel="alternate" type="text/html" href="https://github.com/a3ryk/classtrack/releases/tag/v1.0.0-alpha.7"/>
    <title>ClassTrack v1.0.0-alpha.7 (Notifications &amp; Multi-Channel Fix)</title>
    <content type="html">&lt;div class=&quot;markdown-alert markdown-alert-important&quot;&gt;&lt;p&gt;&lt;strong&gt;Mandatory Update:&lt;/strong&gt; Critical notification channel fix.&lt;/p&gt;&lt;/div&gt;&lt;ul&gt;&lt;li&gt;Android Multi-Channel Sound &amp;amp; Vibration Routing&lt;/li&gt;&lt;li&gt;Redesigned Notifications Hub&lt;/li&gt;&lt;/ul&gt;</content>
  </entry>
</feed>''';

      final info = AppReleaseInfo.fromGithubAtomFeed(sampleAtomXml);

      expect(info.latestVersion, '1.0.0-alpha.7');
      expect(info.buildNumber, 7);
      expect(info.releaseTitle, 'ClassTrack v1.0.0-alpha.7 (Notifications & Multi-Channel Fix)');
      expect(info.isMandatory, isTrue);
      expect(info.warningMessage, contains('Critical notification channel fix.'));
      expect(info.changelog, contains('Android Multi-Channel Sound & Vibration Routing'));
      expect(info.changelog, contains('Redesigned Notifications Hub'));

      // Check deterministic ABI assets
      expect(info.abiAssets['arm64-v8a'], contains('app-arm64-v8a-release.apk'));
      expect(info.abiAssets['armeabi-v7a'], contains('app-armeabi-v7a-release.apk'));
      expect(info.abiAssets['x86_64'], contains('app-x86_64-release.apk'));
      expect(info.abiAssets['universal'], contains('ClassTrack-v1.0.0-alpha.7.apk'));
    });

    test('Hardware ABI resolution preference order', () async {
      final Map<String, String> abiAssets = {
        'arm64-v8a': 'https://download/arm64.apk',
        'armeabi-v7a': 'https://download/armv7.apk',
        'x86_64': 'https://download/x86_64.apk',
        'universal': 'https://download/universal.apk',
      };

      final bestUrl = await AppUpdateService.resolveBestDownloadUrl(abiAssets);
      expect(bestUrl, isNotNull);
      expect(bestUrl!.isNotEmpty, isTrue);
    });

    test('Semver evaluation and update availability', () {
      expect(AppUpdateService.compareSemver('1.0.0-alpha.6', '1.0.0-alpha.7'), 1);
      expect(AppUpdateService.compareSemver('1.0.0-alpha.7', '1.0.0-alpha.7'), 0);
      expect(AppUpdateService.compareSemver('1.0.0-alpha.8', '1.0.0-alpha.7'), -1);
      expect(AppUpdateService.compareSemver('1.0.0-alpha.7', '1.0.0'), 1);

      expect(
        AppUpdateService.isUpdateAvailable(
          currentVersion: '1.0.0-alpha.6',
          remoteVersion: '1.0.0-alpha.7',
          currentBuild: 6,
          remoteBuild: 7,
        ),
        isTrue,
      );

      expect(
        AppUpdateService.isUpdateAvailable(
          currentVersion: '1.0.0-alpha.7',
          remoteVersion: '1.0.0-alpha.7',
          currentBuild: 7,
          remoteBuild: 7,
        ),
        isFalse,
      );
    });
  });
}
