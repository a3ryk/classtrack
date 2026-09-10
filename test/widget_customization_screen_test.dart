import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:classtrack/presentation/screens/settings/widget_customization_screen.dart';

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
}
