import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:attendly/core/constants/app_share_constants.dart';
import 'package:attendly/core/constants/app_theme.dart';
import 'package:attendly/data/database/app_database.dart';
import 'package:attendly/presentation/providers/app_state_provider.dart';
import 'package:attendly/presentation/providers/app_theme_style_provider.dart';
import 'package:attendly/presentation/screens/settings/settings_screen.dart';
import 'package:attendly/presentation/widgets/share_app_slider_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  String? clipboardContent;

  setUp(() {
    clipboardContent = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall methodCall) async {
        if (methodCall.method == 'Clipboard.setData') {
          clipboardContent = (methodCall.arguments as Map)['text'] as String?;
          return null;
        }
        if (methodCall.method == 'Clipboard.getData') {
          return {'text': clipboardContent};
        }
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    );
  });

  group('Share Attendly Feature Tests', () {
    test('AppShareConstants contains valid Google Drive APK link and message', () {
      expect(AppShareConstants.driveDownloadUrl, contains('drive.google.com'));
      expect(AppShareConstants.driveDownloadUrl, contains('1hG-vFWti7YJZdRlW5dHBEIMNccsvwDhZ'));
      expect(AppShareConstants.shareMessage, contains(AppShareConstants.driveDownloadUrl));
    });

    testWidgets('ShareAppSliderSheet renders in Classic theme with QR code, Copy Link, and Share buttons', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShareAppSliderSheet(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Share Attendly'), findsOneWidget);
      expect(find.text('Share APK with classmates & friends'), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text('Scan camera to download APK'), findsOneWidget);
      expect(find.text('Copy Link'), findsOneWidget);
      expect(find.text('Share Link'), findsOneWidget);

      // Tap Copy Link and verify clipboard interaction
      await tester.tap(find.text('Copy Link'));
      await tester.pump();

      expect(clipboardContent, AppShareConstants.driveDownloadUrl);
    });

    testWidgets('SettingsScreen in Classic theme renders share button in header and opens ShareAppSliderSheet', (tester) async {
      final db = AppDatabase.inMemory();

      final classicTheme = AppTheme.buildTheme(
        brightness: Brightness.light,
        styleId: 'classic_indigo',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            appThemeStyleProvider.overrideWith((ref) => FakeThemeStyleNotifier(ref, 'classic_indigo')),
          ],
          child: MaterialApp(
            theme: classicTheme,
            home: const SettingsScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify Settings title and share icon button exist in header
      expect(find.text('Settings'), findsOneWidget);
      final shareIcon = find.byIcon(Icons.share_outlined);
      expect(shareIcon, findsOneWidget);

      // Tap share icon and verify ShareAppSliderSheet opens
      await tester.tap(shareIcon);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ShareAppSliderSheet), findsOneWidget);
      expect(find.text('Share Attendly'), findsOneWidget);

      await db.close();
    });

    testWidgets('SettingsScreen in Sprouts theme renders Share with Friends tile in About section (not in header)', (tester) async {
      final db = AppDatabase.inMemory();

      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final cuteTheme = AppTheme.buildTheme(
        brightness: Brightness.light,
        styleId: 'cute_sprout',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            appThemeStyleProvider.overrideWith((ref) => FakeThemeStyleNotifier(ref, 'cute_sprout')),
          ],
          child: MaterialApp(
            theme: cuteTheme,
            home: const SettingsScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify header has Settings title but NO share icon in header
      expect(find.text('Settings'), findsOneWidget);
      expect(find.byIcon(Icons.share_outlined), findsNothing);

      // Verify "Share with Friends" tile exists in About section
      final shareTile = find.text('Share with Friends');
      expect(shareTile, findsOneWidget);
      expect(find.text('QR code & APK download link'), findsOneWidget);
      expect(find.text('Share ›'), findsOneWidget);

      // Tap share tile and verify ShareAppSliderSheet opens in cute styling
      await tester.tap(shareTile);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ShareAppSliderSheet), findsOneWidget);
      expect(find.text('Share Attendly 🌱'), findsOneWidget);

      await db.close();
    });
  });
}

class FakeThemeStyleNotifier extends StateNotifier<String> implements AppThemeStyleNotifier {
  FakeThemeStyleNotifier(Ref ref, super.initial);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
