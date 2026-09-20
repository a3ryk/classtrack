import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendly/core/constants/app_theme_tokens.dart';
import 'package:attendly/presentation/screens/settings/widget_customization_screen.dart';

void main() {
  testWidgets('WidgetCustomizationScreen renders preview, opacity slider, themes, and toggles without overflow on 320px screen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: WidgetCustomizationScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify AppBar title
    expect(find.text('Home Screen Widgets'), findsOneWidget);

    // Verify Section Headers
    expect(find.text('LIVE PREVIEW'), findsOneWidget);
    expect(find.text('BACKGROUND TRANSPARENCY'), findsOneWidget);

    // Verify Widget Selector Chips exist
    expect(find.text('Agenda'), findsOneWidget);
    expect(find.text('Gauge'), findsOneWidget);

    // Verify Default Agenda Preview is visible
    expect(find.byKey(const ValueKey('preview_agenda')), findsOneWidget);

    // Switch to Next Up
    await tester.tap(find.widgetWithText(GestureDetector, 'Next Up'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('preview_pill')), findsOneWidget);

    // Switch to Gauge
    await tester.tap(find.widgetWithText(GestureDetector, 'Gauge'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('preview_gauge')), findsOneWidget);

    // Verify Opacity Presets exist
    expect(find.text('0%'), findsOneWidget);
    expect(find.text('25%'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('75%'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);

    // Scroll down to reveal Color Theme and Information & Privacy
    await tester.scrollUntilVisible(
      find.text('COLOR THEME & PALETTE'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('COLOR THEME & PALETTE'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('INFORMATION & PRIVACY'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('INFORMATION & PRIVACY'), findsOneWidget);
    expect(find.text('Privacy Shield'), findsOneWidget);
    expect(find.text('Show Room Numbers'), findsOneWidget);

    // Scroll further down to reveal remaining toggles and button
    await tester.scrollUntilVisible(
      find.text('Force Sync All Widgets'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Show Tomorrow\'s First Class'), findsOneWidget);
    expect(find.text('24-Hour Time Format'), findsOneWidget);
    expect(find.text('1-Tap Direct Attendance'), findsOneWidget);
    expect(find.text('Force Sync All Widgets'), findsOneWidget);
  });

  testWidgets('WidgetCustomizationScreen renders Sprout theme with zero emoji headers, presets, preview switching, and no overflow', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final sproutTheme = ThemeData.light().copyWith(
      extensions: [AppThemeTokens.cuteSproutLight],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: sproutTheme,
          home: const WidgetCustomizationScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify AppBar title
    expect(find.text('Home Screen Widgets'), findsOneWidget);

    // Verify Pure Uppercase Section Headers (Zero emojis)
    expect(find.text('LIVE PREVIEW'), findsOneWidget);
    expect(find.text('BACKGROUND TRANSPARENCY'), findsOneWidget);

    // Verify Widget Selector Chips exist
    expect(find.text('Agenda'), findsOneWidget);
    expect(find.text('Gauge'), findsOneWidget);

    // Verify Default Agenda Preview is visible
    expect(find.byKey(const ValueKey('preview_agenda')), findsOneWidget);

    // Switch to Next Up
    await tester.tap(find.widgetWithText(GestureDetector, 'Next Up'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('preview_pill')), findsOneWidget);

    // Switch to Gauge
    await tester.tap(find.widgetWithText(GestureDetector, 'Gauge'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('preview_gauge')), findsOneWidget);

    // Verify Opacity Presets exist
    expect(find.text('0%'), findsOneWidget);
    expect(find.text('25%'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('75%'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);

    // Tap 50% preset chip
    await tester.tap(find.text('50%'));
    await tester.pumpAndSettle();

    // Scroll down to reveal Color Theme and Information & Privacy
    await tester.scrollUntilVisible(
      find.text('COLOR THEME & PALETTE'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('COLOR THEME & PALETTE'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('INFORMATION & PRIVACY'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('INFORMATION & PRIVACY'), findsOneWidget);
    expect(find.text('Privacy Shield'), findsOneWidget);
    expect(find.text('Show Room Numbers'), findsOneWidget);

    // Scroll further down to reveal remaining section and sync button
    await tester.scrollUntilVisible(
      find.text('HOW TO ADD WIDGETS'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('HOW TO ADD WIDGETS'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Force Sync All Widgets'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Force Sync All Widgets'), findsOneWidget);
  });

  testWidgets('Sprout theme live preview has full interactive parity: actions, themes, privacy, and room toggles', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final sproutTheme = ThemeData.light().copyWith(
      extensions: [AppThemeTokens.cuteSproutLight],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: sproutTheme,
          home: const WidgetCustomizationScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify default Agenda widget is present and interactive
    expect(find.byKey(const ValueKey('preview_agenda')), findsOneWidget);
    expect(find.text('✓ Present'), findsOneWidget);
    expect(find.text('Absent'), findsOneWidget);

    // Tap Present action button inside widget preview
    await tester.tap(find.text('✓ Present'));
    await tester.pumpAndSettle();
    expect(find.text('Marked Present via Widget!'), findsOneWidget);

    // Scroll to Privacy Shield switch and toggle it
    await tester.scrollUntilVisible(
      find.text('Privacy Shield'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Privacy Shield'), findsOneWidget);

    final switchFinder = find.byType(Switch).first;
    await tester.ensureVisible(switchFinder);
    await tester.pumpAndSettle();
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    // Scroll back to top to verify preview reflects Privacy Shield
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('preview_agenda')),
      -150,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('***% Attendance'), findsOneWidget);

    // 3. Scroll to Color Theme and tap Always Light and Pure AMOLED Dark
    await tester.scrollUntilVisible(
      find.text('COLOR THEME & PALETTE'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Always Light'), findsOneWidget);
    await tester.tap(find.text('Always Light'));
    await tester.pumpAndSettle();

    expect(find.text('Pure AMOLED Dark'), findsOneWidget);
    await tester.tap(find.text('Pure AMOLED Dark'));
    await tester.pumpAndSettle();
  });
}

