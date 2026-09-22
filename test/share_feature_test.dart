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

  group('Share Attendly Feature Tests', () {
    test('AppShareConstants contains valid Google Drive APK link and message', () {
      expect(AppShareConstants.driveDownloadUrl, contains('drive.google.com'));
      expect(AppShareConstants.driveDownloadUrl, contains('1hG-vFWti7YJZdRlW5dHBEIMNccsvwDhZ'));
      expect(AppShareConstants.shareMessage, contains(AppShareConstants.driveDownloadUrl));
    });

    testWidgets('ShareAppSliderSheet renders in Classic theme with QR code, Copy Link, and Share buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => ShareAppSliderSheet.show(ctx),
                child: const Text('Open Share Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Share Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Share Attendly'), findsOneWidget);
      expect(find.text('Share APK with classmates & friends'), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text('Scan camera to download APK'), findsOneWidget);
      expect(find.text('Copy Link'), findsOneWidget);
      expect(find.text('Share Link'), findsOneWidget);

      // Tap Copy Link and verify clipboard interaction
      await tester.tap(find.text('Copy Link'));
      await tester.pumpAndSettle();

      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      expect(clipboardData?.text, AppShareConstants.driveDownloadUrl);
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

      await tester.pumpAndSettle();

      // Verify Settings title and share icon button exist in header
      expect(find.text('Settings'), findsOneWidget);
      final shareIcon = find.byIcon(Icons.share_outlined);
      expect(shareIcon, findsOneWidget);

      // Tap share icon and verify ShareAppSliderSheet opens
      await tester.tap(shareIcon);
      await tester.pumpAndSettle();

      expect(find.byType(ShareAppSliderSheet), findsOneWidget);
      expect(find.text('Share Attendly'), findsOneWidget);

      await db.close();
    });

    testWidgets('SettingsScreen in Sprouts theme renders Share with Friends tile in About section (not in header)', (tester) async {
      final db = AppDatabase.inMemory();

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

      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

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
