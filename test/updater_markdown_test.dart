import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:attendly/core/services/app_update_service.dart';
import 'package:attendly/presentation/widgets/release_alert_callout_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Updater Alert Callouts & Markdown Parsing Tests', () {
    test('Sequential parsing of GitHub alerts maintains exact written order and preserves markdown', () {
      const releaseBody = '''
> [!CAUTION]
> Critical migration required to prevent data loss.

> [!WARNING]
> Background sync will pause during installation.

> [!NOTE]
> Steps to update safely:
> 1. Open Settings > Backup & Restore
> 2. Export database JSON
> 3. Tap Update Now

> [!TIP]
> Long-press any attendance card on the Today screen for quick notes!

## ✨ Features
* Feature 1
* Feature 2
''';

      final releaseInfo = AppReleaseInfo.fromGithubReleaseJson({
        'tag_name': 'v2.0.0',
        'name': 'Attendly v2.0.0',
        'body': releaseBody,
        'published_at': '2026-09-22T10:00:00Z',
      });

      expect(releaseInfo.isMandatory, isTrue);
      expect(releaseInfo.alertCallouts.length, 4);

      // Verify exact serial order: Caution -> Warning -> Note -> Tip
      expect(releaseInfo.alertCallouts[0].type, AlertCalloutType.caution);
      expect(releaseInfo.alertCallouts[0].markdown, contains('Critical migration required'));

      expect(releaseInfo.alertCallouts[1].type, AlertCalloutType.warning);
      expect(releaseInfo.alertCallouts[1].markdown, contains('Background sync will pause'));

      expect(releaseInfo.alertCallouts[2].type, AlertCalloutType.note);
      expect(releaseInfo.alertCallouts[2].markdown, contains('1. Open Settings'));
      expect(releaseInfo.alertCallouts[2].markdown, contains('2. Export database'));
      expect(releaseInfo.alertCallouts[2].markdown, contains('3. Tap Update Now'));

      expect(releaseInfo.alertCallouts[3].type, AlertCalloutType.tip);
      expect(releaseInfo.alertCallouts[3].markdown, contains('Long-press any attendance card'));

      // Verify clean markdown does not contain alert callouts
      expect(releaseInfo.effectiveMarkdown, isNot(contains('[!CAUTION]')));
      expect(releaseInfo.effectiveMarkdown, isNot(contains('[!TIP]')));
      expect(releaseInfo.effectiveMarkdown, contains('Feature 1'));
    });

    test('Parsing preserves **bold** and *italic* formatting without stripping', () {
      const releaseBody = '''
> [!WARNING]
> Please re-grant **notification permission** in *Android 13+* settings.
''';

      final releaseInfo = AppReleaseInfo.fromGithubReleaseJson({
        'tag_name': 'v2.0.1',
        'name': 'Attendly v2.0.1',
        'body': releaseBody,
      });

      expect(releaseInfo.alertCallouts.length, 1);
      expect(releaseInfo.alertCallouts[0].type, AlertCalloutType.warning);
      expect(releaseInfo.alertCallouts[0].markdown, contains('**notification permission**'));
      expect(releaseInfo.alertCallouts[0].markdown, contains('*Android 13+*'));
    });

    test('JSON manifest with alerts array parses serially', () {
      final json = {
        'version': '2.0.2',
        'alerts': [
          {'type': 'warning', 'markdown': 'Sync is temporarily disabled.'},
          {'type': 'tip', 'markdown': 'Use the new QR code share button.'},
        ],
        'changelog': ['Feature A', 'Feature B'],
      };

      final releaseInfo = AppReleaseInfo.fromJson(json);
      expect(releaseInfo.alertCallouts.length, 2);
      expect(releaseInfo.alertCallouts[0].type, AlertCalloutType.warning);
      expect(releaseInfo.alertCallouts[0].markdown, 'Sync is temporarily disabled.');
      expect(releaseInfo.alertCallouts[1].type, AlertCalloutType.tip);
      expect(releaseInfo.alertCallouts[1].markdown, 'Use the new QR code share button.');
    });

    test('Backward compatibility: legacy warning_message and note keys parse correctly', () {
      final json = {
        'version': '2.0.3',
        'is_mandatory': true,
        'warning_message': 'Critical security patch.',
        'note': 'Backup before continuing.',
        'tip': 'Try dark mode!',
      };

      final releaseInfo = AppReleaseInfo.fromJson(json);
      expect(releaseInfo.alertCallouts.length, 3);
      expect(releaseInfo.alertCallouts[0].type, AlertCalloutType.caution);
      expect(releaseInfo.alertCallouts[0].markdown, 'Critical security patch.');
      expect(releaseInfo.alertCallouts[1].type, AlertCalloutType.note);
      expect(releaseInfo.alertCallouts[1].markdown, 'Backup before continuing.');
      expect(releaseInfo.alertCallouts[2].type, AlertCalloutType.tip);
      expect(releaseInfo.alertCallouts[2].markdown, 'Try dark mode!');
    });
  });

  group('ReleaseAlertCalloutCard Widget Rendering Tests', () {
    testWidgets('Renders Tip card with lightbulb icon and zero hardcoded text', (tester) async {
      const callout = ReleaseAlertCallout(
        type: AlertCalloutType.tip,
        markdown: 'You can now share Attendly with friends via QR code.',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ReleaseAlertCalloutCard(callout: callout, isCute: true),
          ),
        ),
      );

      // Verify Bulb icon is present!
      expect(find.byIcon(Icons.lightbulb_rounded), findsOneWidget);

      // Verify Markdown body is present
      expect(find.byType(MarkdownBody), findsOneWidget);
      expect(find.textContaining('You can now share Attendly with friends'), findsOneWidget);

      // Verify ZERO hardcoded prefix text ("Tip:" must NOT be found)
      expect(find.textContaining('Tip:'), findsNothing);
      expect(find.textContaining('TIP:'), findsNothing);
      expect(find.textContaining('Note:'), findsNothing);
    });

    testWidgets('Renders Warning card with warning icon and zero hardcoded text', (tester) async {
      const callout = ReleaseAlertCallout(
        type: AlertCalloutType.warning,
        markdown: 'Background sync will pause during installation.',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ReleaseAlertCalloutCard(callout: callout, isCute: false),
          ),
        ),
      );

      // Verify Warning icon is present
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

      // Verify Markdown body is present
      expect(find.byType(MarkdownBody), findsOneWidget);
      expect(find.textContaining('Background sync will pause'), findsOneWidget);

      // Verify ZERO hardcoded prefix text
      expect(find.textContaining('Warning:'), findsNothing);
      expect(find.textContaining('WARNING:'), findsNothing);
    });

    testWidgets('Renders Note card with steps directly without "Migration Steps" title', (tester) async {
      const callout = ReleaseAlertCallout(
        type: AlertCalloutType.note,
        markdown: '1. First step\n2. Second step\n3. Third step',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ReleaseAlertCalloutCard(callout: callout, isCute: true),
          ),
        ),
      );

      expect(find.byIcon(Icons.sticky_note_2_rounded), findsOneWidget);
      expect(find.byType(MarkdownBody), findsOneWidget);
      expect(find.textContaining('Migration Steps'), findsNothing);
      expect(find.textContaining('First step'), findsOneWidget);
    });

    testWidgets('ReleaseAlertCalloutsList renders multiple callouts sequentially', (tester) async {
      const callouts = [
        ReleaseAlertCallout(type: AlertCalloutType.caution, markdown: 'Critical Caution'),
        ReleaseAlertCallout(type: AlertCalloutType.warning, markdown: 'Important Warning'),
        ReleaseAlertCallout(type: AlertCalloutType.note, markdown: 'Helpful Note'),
        ReleaseAlertCallout(type: AlertCalloutType.tip, markdown: 'Useful Tip'),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ReleaseAlertCalloutsList(alertCallouts: callouts, isCute: true),
          ),
        ),
      );

      expect(find.byType(ReleaseAlertCalloutCard), findsNWidgets(4));
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.byIcon(Icons.sticky_note_2_rounded), findsOneWidget);
      expect(find.byIcon(Icons.lightbulb_rounded), findsOneWidget);
    });
  });
}
