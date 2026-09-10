import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:classtrack/core/services/app_update_service.dart';
import 'package:classtrack/presentation/widgets/update_available_dialog.dart';
import 'package:classtrack/presentation/screens/settings/update_screen.dart';

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
      expect(info.changelog.any((c) => c.contains('Android Multi-Channel Sound & Vibration Routing')), isTrue);
      expect(info.changelog.any((c) => c.contains('Redesigned Notifications Hub')), isTrue);

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

    test('GitHub Release Markdown preservation and effectiveMarkdown generation', () {
      final mockGithubJson = {
        'tag_name': 'v1.0.0-alpha.10',
        'name': 'ClassTrack v1.0.0-alpha.10',
        'published_at': '2026-09-10T12:00:00Z',
        'body': '''
> [!WARNING]
> Critical update required for multi-room schedule synchronization.

## ✨ What's New in v1.0.0-alpha.10
- **Real-Time Notification Attendance**: Mark `Present`, `Absent`, or `Cancelled` directly from Android notifications with instant sync to `TodayScreen`.
- **Lock Screen Actions**: Quick marking without unlocking device.
- **10+ Classes Batching**: Simultaneous classes batch cleanly into an expandable notification group.

### 🧩 Bug Fixes & Polish
- Enabled SQLite `WAL` mode to eliminate multi-isolate lock contention.
- Fixed room selection persistence in `RescheduleSessionScreen`.

---
Full details in [PR #42](https://github.com/a3ryk/classtrack/pull/42).
<!-- MIN_VERSION: 1.0.0-alpha.9 -->
''',
      };

      final info = AppReleaseInfo.fromGithubReleaseJson(mockGithubJson);

      expect(info.latestVersion, '1.0.0-alpha.10');
      expect(info.isMandatory, isTrue);
      expect(info.warningMessage, contains('Critical update required for multi-room schedule synchronization.'));
      expect(info.minSupportedVersion, '1.0.0-alpha.9');

      // Pristine markdown preserved
      expect(info.releaseNotesMarkdown, isNotNull);
      expect(info.effectiveMarkdown, contains("## ✨ What's New in v1.0.0-alpha.10"));
      expect(info.effectiveMarkdown, contains('**Real-Time Notification Attendance**:'));
      expect(info.effectiveMarkdown, contains('`Present`'));
      expect(info.effectiveMarkdown, contains('### 🧩 Bug Fixes & Polish'));
      expect(info.effectiveMarkdown, contains('[PR #42]'));

      // Directives and alert lines are extracted out of the body
      expect(info.effectiveMarkdown.contains('MIN_VERSION:'), isFalse);
      expect(info.effectiveMarkdown.contains('> [!WARNING]'), isFalse);
    });

    test('Legacy list changelog gracefully formats into markdown', () {
      const info = AppReleaseInfo(
        latestVersion: '1.0.0-alpha.9',
        buildNumber: 9,
        minSupportedVersion: '1.0.0',
        releaseDate: '2026-09-08',
        releaseTitle: 'ClassTrack v1.0.0-alpha.9',
        changelog: [
          '✨ Feature 1: Great new capability',
          '🧩 Fix 2: Resolved crash on startup',
        ],
      );

      expect(info.releaseNotesMarkdown, isNull);
      expect(info.effectiveMarkdown, contains('* ✨ Feature 1: Great new capability'));
      expect(info.effectiveMarkdown, contains('* 🧩 Fix 2: Resolved crash on startup'));
    });

    testWidgets('UpdateAvailableDialog renders MarkdownBody without overflow', (tester) async {
      final mockGithubJson = {
        'tag_name': 'v1.0.0-alpha.10',
        'name': 'ClassTrack v1.0.0-alpha.10',
        'body': '''
## ✨ What's New
- **Bold Feature**: Works with `code` formatting and [links](https://github.com).
### 🧩 Fixes
- Bug fix 1
''',
      };

      final info = AppReleaseInfo.fromGithubReleaseJson(mockGithubJson);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateAvailableDialog(releaseInfo: info),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MarkdownBody), findsOneWidget);
      expect(find.text('New version available!'), findsOneWidget);
      expect(find.text('v1.0.0-alpha.10'), findsOneWidget);
    });

    testWidgets('UpdateScreen renders MarkdownBody with rich markdown notes', (tester) async {
      final mockGithubJson = {
        'tag_name': 'v1.0.0-alpha.10',
        'name': 'ClassTrack v1.0.0-alpha.10',
        'body': '''
## ✨ Highlights
- **Notification Actions**: Quick attendance from notifications.
''',
      };

      final info = AppReleaseInfo.fromGithubReleaseJson(mockGithubJson);

      await tester.pumpWidget(
        MaterialApp(
          home: UpdateScreen(releaseInfo: info),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MarkdownBody), findsOneWidget);
    });
  });
}
