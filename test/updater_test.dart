import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:classtrack/core/services/app_update_service.dart';
import 'package:classtrack/presentation/widgets/update_available_dialog.dart';
import 'package:classtrack/presentation/screens/settings/update_screen.dart';
import 'package:classtrack/presentation/screens/settings/privacy_policy_screen.dart';
import 'package:classtrack/presentation/widgets/up_to_date_dialog.dart';
import 'package:classtrack/core/constants/app_release_notes.dart';

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

      // Clean markdown extracts content and strips duplicate title
      expect(info.releaseNotesMarkdown, isNotNull);
      expect(info.effectiveMarkdown.contains("## ✨ What's New in v1.0.0-alpha.10"), isFalse);
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

    test('Markdown HTML entity decoding and asset table stripping', () {
      final mockGithubJson = {
        'tag_name': 'v1.0.0-alpha.11',
        'name': 'Attendly v1.0.0-alpha.11',
        'body': '''
## ✨ What's New
- Navigate to Settings &rarr; Appearance &rarr; Home Screen Widgets
- Status &bull; All features verified &check;
- Test &mdash; en-dash &ndash; quotes &quot;hello&quot; and &apos;world&apos;
- Numeric decimal &#8594; arrow and check &#10003;

### 📦 Downloads & Assets
| Asset | Target Platform | Size |
|:---|:---|:---|
| app-arm64-v8a-release.apk | Android 64-bit | 45 MB |
| app-armeabi-v7a-release.apk | Android 32-bit | 38 MB |

**Full Changelog**: https://github.com/a3ryk/classtrack/compare/v1.0.0-alpha.10...v1.0.0-alpha.11
''',
      };

      final info = AppReleaseInfo.fromGithubReleaseJson(mockGithubJson);
      expect(info.effectiveMarkdown, contains('Settings → Appearance → Home Screen Widgets'));
      expect(info.effectiveMarkdown, contains('Status • All features verified ✓'));
      expect(info.effectiveMarkdown, contains('quotes "hello" and \'world\''));
      expect(info.effectiveMarkdown, contains('Numeric decimal → arrow and check ✓'));
      // Table and footer stripped
      expect(info.effectiveMarkdown.contains('| Asset |'), isFalse);
      expect(info.effectiveMarkdown.contains('app-arm64-v8a-release.apk'), isFalse);
      expect(info.effectiveMarkdown.contains('Full Changelog'), isFalse);
    });

    testWidgets('UpdateScreen allows dismiss when isDevInspectMode is true even for mandatory updates', (tester) async {
      const mandatoryInfo = AppReleaseInfo(
        latestVersion: '1.0.0',
        buildNumber: 10,
        minSupportedVersion: '1.0.0',
        releaseDate: '2026-09-12',
        releaseTitle: 'Critical Update',
        changelog: ['Critical security fix'],
        isMandatory: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: UpdateScreen(
            releaseInfo: mandatoryInfo,
            isDevInspectMode: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Dev inspect banner rendered
      expect(find.textContaining('DEV INSPECT MODE'), findsOneWidget);
      expect(find.text('Exit'), findsOneWidget);
      expect(find.text('Exit Dev Preview'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    });

    testWidgets('PrivacyPolicyScreen renders cleanly with zero em-dashes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PrivacyPolicyScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Your Data Stays on Your Device'), findsOneWidget);

      // Verify zero em-dashes and en-dashes across all Text widgets
      final allTextWidgets = tester.widgetList<Text>(find.byType(Text));
      for (final textWidget in allTextWidgets) {
        final str = textWidget.data ?? textWidget.textSpan?.toPlainText() ?? '';
        expect(str.contains('—'), isFalse, reason: 'Em-dash found in: "$str"');
        expect(str.contains('–'), isFalse, reason: 'En-dash found in: "$str"');
      }
    });

    testWidgets('UpToDateDialog renders verified badge, version metadata, and action buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpToDateDialog(
              currentVersion: '1.0.0-alpha.11',
              lastCheckedTime: DateTime.now(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('You\'re on the Latest Version'), findsOneWidget);
      expect(find.text('v1.0.0-alpha.11'), findsOneWidget);
      expect(find.text('LATEST'), findsOneWidget);
      expect(find.text('What\'s New'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('UpToDateSheet renders cleanly with bottom sheet layout and dismisses on Done', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  UpToDateDialog.show(
                    ctx,
                    currentVersion: '1.0.0-alpha.11',
                    lastCheckedTime: DateTime.now(),
                  );
                },
                child: const Text('Check Updates'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Check Updates'));
      await tester.pumpAndSettle();

      expect(find.byType(UpToDateSheet), findsOneWidget);
      expect(find.text('You\'re on the Latest Version'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.byType(UpToDateSheet), findsNothing);
    });

    testWidgets('UpdateScreen in isWhatsNewMode renders sleek hero, hides mandatory warnings, and sanitizes branding', (tester) async {
      const releaseWithMandatory = AppReleaseInfo(
        latestVersion: '1.0.0-alpha.11',
        buildNumber: 11,
        minSupportedVersion: '1.0.0-alpha.11',
        releaseDate: 'September 2026',
        releaseTitle: 'ClassTrack v1.0.0-alpha.11 (Home Screen Widgets & Design Overhaul)',
        changelog: ['✨ Enhanced ClassTrack experience with faster startup'],
        isMandatory: true,
        warningMessage: 'Mandatory update required for app stability and features.',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: UpdateScreen(
            releaseInfo: releaseWithMandatory,
            isWhatsNewMode: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Hero header checks
      expect(find.text('What\'s New in Attendly'), findsOneWidget);
      expect(find.text('Home Screen Widgets & Design Overhaul'), findsOneWidget);
      expect(find.text('v1.0.0-alpha.11'), findsOneWidget);
      expect(find.text('September 2026'), findsOneWidget);
      expect(find.text('Current Version'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);

      // Crucial: False mandatory warning banner MUST NOT be rendered
      expect(find.textContaining('Mandatory update required'), findsNothing);
      expect(find.text('Critical Update Required'), findsNothing);
      expect(find.text('Update Now'), findsNothing);

      // Back navigation & Done button (clean text-only button without icon)
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsNothing);

      // MarkdownBody must have sanitized 'ClassTrack' to 'Attendly'
      expect(find.textContaining('Attendly experience'), findsOneWidget);
      expect(find.textContaining('ClassTrack'), findsNothing);
    });

    test('AppReleaseNotes offline registry branding is Attendly across all releases', () {
      final releases = AppReleaseNotes.getAllReleases();
      expect(releases.isNotEmpty, isTrue);

      for (final release in releases) {
        expect(
          release.releaseTitle.contains('ClassTrack'),
          isFalse,
          reason: 'Release ${release.latestVersion} title contains ClassTrack: "${release.releaseTitle}"',
        );
        expect(
          release.releaseTitle.startsWith('Attendly v1.0.0-alpha.'),
          isTrue,
          reason: 'Release ${release.latestVersion} should start with Attendly: "${release.releaseTitle}"',
        );
        for (final item in release.changelog) {
          expect(
            item.contains('ClassTrack'),
            isFalse,
            reason: 'Changelog item in ${release.latestVersion} contains ClassTrack: "$item"',
          );
        }
      }
    });
  });
}
