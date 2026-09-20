import 'package:classtrack/core/constants/app_theme.dart';
import 'package:classtrack/core/constants/app_theme_tokens.dart';
import 'package:classtrack/core/ui/theme_transition_wrapper.dart';
import 'package:classtrack/core/theme/app_theme_registry.dart';
import 'package:classtrack/data/database/app_database.dart';
import 'package:classtrack/domain/entities/class_session_entity.dart';
import 'package:classtrack/presentation/providers/app_state_provider.dart';
import 'package:classtrack/presentation/providers/app_theme_style_provider.dart';
import 'package:classtrack/presentation/screens/main_shell.dart';
import 'package:classtrack/presentation/screens/settings/appearance_screen.dart';
import 'package:classtrack/presentation/screens/settings/settings_screen.dart';
import 'package:classtrack/presentation/widgets/mascot_peek_overlay.dart';
import 'package:classtrack/presentation/widgets/sprout_floating_nav_bar.dart';
import 'package:classtrack/presentation/widgets/today_class_card.dart';
import 'package:classtrack/presentation/widgets/walkthrough/app_walkthrough_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Cute & Extensible Theme Engine Tests', () {
    test('AppThemeRegistry contains default classic and cute sprout themes', () {
      expect(AppThemeRegistry.registeredThemes.length, greaterThanOrEqualTo(2));

      final classic = AppThemeRegistry.getTheme('classic_indigo');
      expect(classic.id, 'classic_indigo');
      expect(classic.isDefault, true);
      expect(AppThemeRegistry.isCute(classic.id), false);
      expect(classic.navIcons.containsKey('today'), true);
      expect(classic.navIcons.containsKey('analytics'), true);
      expect(classic.navIcons.containsKey('timetable'), true);
      expect(classic.navIcons.containsKey('calendar'), true);

      final cute = AppThemeRegistry.getTheme('cute_sprout');
      expect(cute.id, 'cute_sprout');
      expect(cute.isDefault, false);
      expect(AppThemeRegistry.isCute(cute.id), true);
      expect(cute.title, 'Sprout & Mochi');
      expect(cute.navIcons.containsKey('today'), true);
      expect(cute.navIcons['today'], Icons.spa_rounded);

      // Unknown ID falls back to default
      final fallback = AppThemeRegistry.getTheme('non_existent_theme');
      expect(fallback.id, AppThemeRegistry.defaultThemeId);
    });

    test('AppThemeTokens verifies properties and radii for classic and cute styles', () {
      final classicLight = AppThemeTokens.classicLight;
      expect(classicLight.isCute, false);
      expect(classicLight.cardRadius, 12.0);
      expect(classicLight.buttonRadius, 8.0);

      final cuteLight = AppThemeTokens.cuteSproutLight;
      expect(cuteLight.isCute, true);
      expect(cuteLight.cardRadius, 20.0);
      expect(cuteLight.buttonRadius, 999.0);
      expect(cuteLight.scaffoldBg, const Color(0xFFFAF7F2));

      final cuteDark = AppThemeTokens.cuteSproutDark;
      expect(cuteDark.isCute, true);
      expect(cuteDark.cardRadius, 20.0);
      expect(cuteDark.buttonRadius, 999.0);
      expect(cuteDark.scaffoldBg, const Color(0xFF122419));
    });

    testWidgets('AppTheme.buildTheme constructs complete ThemeData with extensions', (tester) async {
      final classicTheme = AppTheme.buildTheme(
        brightness: Brightness.light,
        styleId: 'classic_indigo',
      );
      expect(classicTheme.brightness, Brightness.light);
      final classicTokens = classicTheme.extension<AppThemeTokens>();
      expect(classicTokens, isNotNull);
      expect(classicTokens!.isCute, false);

      final cuteTheme = AppTheme.buildTheme(
        brightness: Brightness.light,
        styleId: 'cute_sprout',
      );
      expect(cuteTheme.brightness, Brightness.light);
      final cuteTokens = cuteTheme.extension<AppThemeTokens>();
      expect(cuteTokens, isNotNull);
      expect(cuteTokens!.isCute, true);
      expect(cuteTokens.buttonRadius, 999.0);

      final cuteDarkTheme = AppTheme.buildTheme(
        brightness: Brightness.dark,
        styleId: 'cute_sprout',
      );
      expect(cuteDarkTheme.brightness, Brightness.dark);
      final cuteDarkTokens = cuteDarkTheme.extension<AppThemeTokens>();
      expect(cuteDarkTokens, isNotNull);
      expect(cuteDarkTokens!.isCute, true);
    });

    test('AppThemeStyleNotifier persists theme style to SQLite database', () async {
      final db = AppDatabase.inMemory();
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
      );

      final notifier = container.read(appThemeStyleProvider.notifier);
      expect(container.read(appThemeStyleProvider), 'classic_indigo');
      expect(notifier.isCute, false);

      await notifier.setThemeStyle('cute_sprout');
      expect(container.read(appThemeStyleProvider), 'cute_sprout');
      expect(notifier.isCute, true);

      // Verify persistence in SQLite table
      final saved = await db.getSetting('active_theme_style');
      expect(saved, 'cute_sprout');

      // Verify toggle
      await notifier.toggleThemeStyle();
      expect(container.read(appThemeStyleProvider), 'classic_indigo');
      expect(await db.getSetting('active_theme_style'), 'classic_indigo');

      await db.close();
      container.dispose();
    });

    testWidgets('MascotPeekOverlay displays quote and auto-dismisses smoothly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) {
                return ElevatedButton(
                  onPressed: () {
                    MascotPeekOverlay.show(
                      ctx,
                      quote: "Yay! Sprout mode activated! Let's track some classes together! 🌱",
                    );
                  },
                  child: const Text('Show Mascot'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Mascot'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Attendly Mascot'), findsOneWidget);
      expect(find.text("Yay! Sprout mode activated! Let's track some classes together! 🌱"), findsOneWidget);

      // Tap to dismiss
      await tester.tap(find.text('Attendly Mascot'));
      await tester.pumpAndSettle();
      expect(find.text('Attendly Mascot'), findsNothing);
    });

    testWidgets('AppearanceScreen renders Theme Style section and registered themes', (tester) async {
      final db = AppDatabase.inMemory();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
          ],
          child: MaterialApp(
            builder: (context, child) => ThemeTransitionWrapper(
              child: child ?? const SizedBox.shrink(),
            ),
            home: const AppearanceScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Drag ListView to reveal Theme Style and Sprout & Mochi
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(find.text('THEME STYLE'), findsOneWidget);
      expect(find.text('Classic Attendly'), findsOneWidget);
      expect(find.text('Sprout & Mochi'), findsOneWidget);
      expect(find.text('Cute 🌱'), findsOneWidget);

      // Tap on Sprout & Mochi
      await tester.tap(find.text('Sprout & Mochi'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 700));

      // Mascot popup should not be shown on theme switch
      expect(find.text('Attendly Mascot'), findsNothing);

      await tester.pumpAndSettle();

      await db.close();
    });

    testWidgets('TodayClassCard adapts to cute pill buttons and outcome icons', (tester) async {
      final session = ClassSessionEntity(
        id: 'sess_1',
        semesterId: 'sem_1',
        subjectComponentId: 'sub_1',
        subjectName: 'Data Structures',
        category: 'Theory',
        componentType: 'Lecture',
        sessionDate: '2026-09-12',
        startTime: '10:00',
        endTime: '11:00',
        sessionSource: 'TIMETABLE',
        status: 'SCHEDULED',
        attendanceOutcome: 'PRESENT',
        colorHex: '#689F38',
      );

      String? updatedOutcome;

      final cuteTheme = AppTheme.buildTheme(
        brightness: Brightness.light,
        styleId: 'cute_sprout',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            realtimeClockProvider.overrideWith((ref) => Stream.value(DateTime.now())),
          ],
          child: MaterialApp(
            theme: cuteTheme,
            home: Scaffold(
              body: TodayClassCard(
                session: session,
                onOutcomeChanged: (val) => updatedOutcome = val,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Data Structures'), findsOneWidget);
      expect(find.text('Present'), findsOneWidget);
      expect(find.text('Absent'), findsOneWidget);
      expect(find.text('Cancelled'), findsOneWidget);

      // Cute sprout icon for Present
      expect(find.byIcon(Icons.spa_rounded), findsOneWidget);

      // Tap Absent
      await tester.tap(find.text('Absent'));
      await tester.pump();
      expect(updatedOutcome, 'ABSENT');
    });

    testWidgets('SettingsScreen in Sprouts theme has SproutFloatingNavBar and NO top left back button in MainShell', (tester) async {
      final db = AppDatabase.inMemory();
      addTearDown(() => db.close());

      final cuteTheme = AppTheme.buildTheme(
        brightness: Brightness.light,
        styleId: 'cute_sprout',
      );

      await db.setSetting('active_theme_style', 'cute_sprout');

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          hasCompletedOnboardingProvider.overrideWith((ref) => HasCompletedOnboardingNotifier(db)),
          mainShellTabProvider.overrideWith((ref) => 4),
        ],
      );
      addTearDown(() => container.dispose());

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: cuteTheme,
            home: const MainShell(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify we are on Settings screen with Sprout companion header
      expect(find.descendant(of: find.byType(SettingsScreen), matching: find.text('Settings')), findsOneWidget);
      expect(find.text('Your academic companion'), findsOneWidget);

      // Verify NO back button in AppBar
      expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
      expect(find.byIcon(Icons.chevron_left_rounded), findsNothing);

      // Verify Settings UI cards and sections remain intact
      expect(find.text('Student Profile'), findsOneWidget);
      expect(find.text('PREFERENCES'), findsOneWidget);
      expect(find.text('Appearance & Themes'), findsOneWidget);

      // Verify exactly ONE SproutFloatingNavBar is present at bottom
      expect(find.byType(SproutFloatingNavBar), findsOneWidget);

      // Tapping Calendar (index 2) updates tab
      await tester.tap(find.widgetWithText(GestureDetector, 'Calendar'));
      await tester.pumpAndSettle();

      expect(container.read(mainShellTabProvider), 2);
    });

    testWidgets('Switching to Sprouts in AppearanceScreen and backing out shows bottom nav and no back button on Settings', (tester) async {
      final db = AppDatabase.inMemory();
      addTearDown(() => db.close());

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          hasCompletedOnboardingProvider.overrideWith((ref) => HasCompletedOnboardingNotifier(db)),
        ],
      );
      addTearDown(() => container.dispose());

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: Consumer(
            builder: (context, ref, _) {
              final activeStyle = ref.watch(appThemeStyleProvider);
              final currentTheme = AppTheme.buildTheme(
                brightness: Brightness.light,
                styleId: activeStyle,
              );
              return MaterialApp(
                theme: currentTheme,
                home: const MainShell(),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // In classic mode, open Settings from TodayScreen
      final settingsIcon = find.byIcon(Icons.settings_outlined);
      expect(settingsIcon, findsOneWidget);
      await tester.tap(settingsIcon);
      await tester.pumpAndSettle();

      // Tap Appearance tile in classic Settings
      await tester.tap(find.text('Appearance & Themes'));
      await tester.pumpAndSettle();

      // Scroll to find Sprout & Mochi in AppearanceScreen
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      // Select Sprout & Mochi
      await tester.tap(find.text('Sprout & Mochi'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      // Tap Back on AppearanceScreen
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      // Verify we are back on Settings (MainShell tab 4)
      expect(find.descendant(of: find.byType(SettingsScreen), matching: find.text('Settings')), findsOneWidget);
      expect(find.text('Your academic companion'), findsOneWidget);

      // Verify NO top-left back button
      expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
      expect(find.byIcon(Icons.chevron_left_rounded), findsNothing);

      // Verify EXACTLY ONE bottom navigation bar is visible!
      expect(find.byType(SproutFloatingNavBar), findsOneWidget);
    });

    testWidgets('AppWalkthroughOverlay correctly navigates Sprout tabs and adapts theme', (tester) async {
      final db = AppDatabase.inMemory();
      addTearDown(() => db.close());
      await db.setSetting('active_theme_style', 'cute_sprout');

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          activeTourProvider.overrideWith((ref) => true),
        ],
      );
      addTearDown(() => container.dispose());

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: Consumer(
            builder: (context, ref, _) {
              final activeStyle = ref.watch(appThemeStyleProvider);
              final currentTheme = AppTheme.buildTheme(
                brightness: Brightness.light,
                styleId: activeStyle,
              );
              return MaterialApp(
                theme: currentTheme,
                home: const MainShell(),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify overlay is visible
      expect(find.byType(AppWalkthroughOverlay), findsOneWidget);
      expect(find.text('1. Today & Live Attendance'), findsOneWidget);
      expect(container.read(mainShellTabProvider), 0);

      // Tap Next -> Step 2 (Timetable in Sprout: tab 1)
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('2. Weekly Timetable Grid'), findsOneWidget);
      expect(container.read(mainShellTabProvider), 1);

      // Tap Next -> Step 3 (Batch Setup in Sprout: tab 1)
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('3. Supercharged Batch Setup'), findsOneWidget);
      expect(container.read(mainShellTabProvider), 1);

      // Tap Next -> Step 4 (Calendar in Sprout: tab 2)
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('4. Calendar & Date Overrides'), findsOneWidget);
      expect(container.read(mainShellTabProvider), 2);

      // Tap Next -> Step 5 (Analytics in Sprout: tab 3)
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('5. Subject Analytics & Margins'), findsOneWidget);
      expect(container.read(mainShellTabProvider), 3);

      // Tap Next -> Step 6 (What-If Simulator in Sprout: tab 3)
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('6. What-If Leave Simulator'), findsOneWidget);
      expect(container.read(mainShellTabProvider), 3);

      // Tap Next -> Step 7 (Settings & Mascot in Sprout: tab 4)
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('7. Settings, Mascot & Profile'), findsOneWidget);
      expect(container.read(mainShellTabProvider), 4);

      // Finish tour
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      // Overlay dismissed and tab resets to 0
      expect(find.byType(AppWalkthroughOverlay), findsNothing);
      expect(container.read(activeTourProvider), false);
      expect(container.read(mainShellTabProvider), 0);
    });

    testWidgets('SproutFloatingNavBar renders soft squircle active pill with FittedBox labels', (tester) async {
      final cuteDef = AppThemeRegistry.getTheme('cute_sprout');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.buildTheme(brightness: Brightness.light, styleId: 'cute_sprout'),
          home: Scaffold(
            bottomNavigationBar: SproutFloatingNavBar(
              currentIndex: 1, // Timetable
              onTap: (_) {},
              items: cuteDef.navItems,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the active pill container decoration
      final animatedPos = tester.widget<AnimatedPositioned>(find.byType(AnimatedPositioned));
      final pillContainer = animatedPos.child as Container;
      final decoration = pillContainer.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(22));

      // Verify Timetable label is rendered within a FittedBox
      final timetableFinder = find.text('Timetable');
      expect(timetableFinder, findsOneWidget);
      expect(find.ancestor(of: timetableFinder, matching: find.byType(FittedBox)), findsOneWidget);
    });
  });
}

