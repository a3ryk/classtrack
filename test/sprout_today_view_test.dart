import 'package:classtrack/core/constants/app_theme.dart';
import 'package:classtrack/core/utils/date_formatter.dart';
import 'package:classtrack/data/database/app_database.dart';
import 'package:classtrack/domain/entities/attendance_stats.dart';
import 'package:classtrack/domain/entities/class_session_entity.dart';
import 'package:classtrack/domain/entities/semester_entity.dart';
import 'package:classtrack/domain/entities/user_profile_entity.dart';
import 'package:classtrack/domain/services/schedule_engine.dart';
import 'package:classtrack/presentation/providers/app_state_provider.dart';
import 'package:classtrack/presentation/providers/app_theme_style_provider.dart';
import 'package:classtrack/presentation/screens/today/sprout_today_view.dart';
import 'package:classtrack/presentation/screens/today/today_screen.dart';
import 'package:classtrack/core/theme/app_theme_registry.dart';
import 'package:classtrack/presentation/screens/main_shell.dart';
import 'package:classtrack/presentation/screens/settings/settings_screen.dart';
import 'package:classtrack/presentation/widgets/sprout_floating_nav_bar.dart';
import 'package:classtrack/presentation/widgets/wavy_bottom_bar_clipper.dart';
import 'package:classtrack/presentation/screens/profile/profile_screen.dart';
import 'package:classtrack/presentation/screens/settings/appearance_screen.dart';
import 'package:classtrack/presentation/screens/settings/notification_settings_screen.dart';
import 'package:classtrack/presentation/screens/settings/backup_restore_screen.dart';
import 'package:classtrack/presentation/screens/settings/about_screen.dart';
import 'package:classtrack/presentation/screens/settings/update_screen.dart';
import 'package:classtrack/presentation/screens/settings/licenses_screen.dart';
import 'package:classtrack/presentation/widgets/update_available_dialog.dart';
import 'package:classtrack/presentation/widgets/up_to_date_dialog.dart';
import 'package:classtrack/core/services/app_update_service.dart';
import 'package:classtrack/presentation/widgets/target_percentage_dialog.dart';
import 'package:classtrack/data/templates/programme_templates.dart';
import 'package:classtrack/domain/entities/academic_template.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeUserProfileNotifier extends UserProfileNotifier {
  final String name;
  FakeUserProfileNotifier(this.name) : super(AppDatabase.inMemory()) {
    state = UserProfileEntity(
      studentName: name,
      rollNumber: 'CS101',
      enrollmentNumber: 'EN101',
      degreeProgramme: 'B.Tech CSE',
      department: 'Computer Science',
    );
  }

  @override
  Future<void> loadFromDb() async {
    state = UserProfileEntity(
      studentName: name,
      rollNumber: 'CS101',
      enrollmentNumber: 'EN101',
      degreeProgramme: 'B.Tech CSE',
      department: 'Computer Science',
    );
  }
}

class FakeHolidaysNotifier extends HolidaysNotifier {
  final List<HolidayItem> holidays;
  FakeHolidaysNotifier(this.holidays) : super(AppDatabase.inMemory(), 'sem_1') {
    state = holidays;
  }

  @override
  Future<void> loadFromDb() async {
    state = holidays;
  }
}

class FakeThemeStyleNotifier extends AppThemeStyleNotifier {
  FakeThemeStyleNotifier(super.ref, String initial) {
    state = initial;
  }
}

class FakeActiveSemesterNotifier extends ActiveSemesterNotifier {
  FakeActiveSemesterNotifier(super.db, SemesterEntity initial) {
    state = initial;
  }

  @override
  Future<void> loadFromDb() async {}
}

class FakeSelectedUniversityNotifier extends SelectedUniversityNotifier {
  FakeSelectedUniversityNotifier(super.db, UserUniversityInfo initial) {
    state = initial;
  }

  @override
  Future<void> loadFromDb() async {}
}

class FakeActiveTemplateNotifier extends ActiveTemplateNotifier {
  FakeActiveTemplateNotifier(super.db, ProgrammeTemplate initial) {
    state = initial;
  }

  @override
  Future<void> loadFromDb() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  group('WavyBottomBarClipper & Painter Tests', () {
    test('WavyBottomBarClipper generates valid periodic closed path', () {
      const clipper = WavyBottomBarClipper(waveHeight: 6, waveCount: 4);
      const size = Size(400, 60);
      final path = clipper.getClip(size);

      expect(path, isNotNull);
      final bounds = path.getBounds();
      expect(bounds.width, 400.0);
      expect(bounds.height, 60.0);
      expect(clipper.shouldReclip(const WavyBottomBarClipper(waveHeight: 6, waveCount: 4)), false);
      expect(clipper.shouldReclip(const WavyBottomBarClipper(waveHeight: 8, waveCount: 4)), true);
    });

    test('WavyBorderPainter renders smoothly without throwing', () {
      const painter = WavyBorderPainter(
        borderColor: Colors.green,
        borderWidth: 1.0,
        waveHeight: 6.0,
        waveCount: 4,
      );
      expect(painter.shouldRepaint(const WavyBorderPainter(borderColor: Colors.green)), false);
      expect(painter.shouldRepaint(const WavyBorderPainter(borderColor: Colors.red)), true);
    });
  });

  group('Sprout Mascot Dashboard Today View Tests', () {
    final todayIso = DateFormatter.toIsoDate(DateTime.now());
    final sampleSessions = [
      ClassSessionEntity(
        id: 'sess_1',
        semesterId: 'sem_1',
        subjectComponentId: 'sub_1',
        subjectName: 'Computer Networks',
        category: 'Core',
        componentType: 'Theory',
        sessionDate: todayIso,
        startTime: '10:00',
        endTime: '11:00',
        sessionSource: 'TIMETABLE_RECURRING',
        status: 'SCHEDULED',
        room: 'Lab 3',
        attendanceOutcome: 'PENDING',
        colorHex: '#4CAF50',
      ),
      ClassSessionEntity(
        id: 'sess_2',
        semesterId: 'sem_1',
        subjectComponentId: 'sub_2',
        subjectName: 'Machine Learning',
        category: 'Core',
        componentType: 'Theory',
        sessionDate: todayIso,
        startTime: '11:30',
        endTime: '12:30',
        sessionSource: 'TIMETABLE_RECURRING',
        status: 'SCHEDULED',
        room: 'Auditorium',
        attendanceOutcome: 'PRESENT',
        colorHex: '#2196F3',
      ),
    ];

    testWidgets('Renders student greeting, mascot art, and overall attendance care card', (tester) async {
      final db = AppDatabase.inMemory();
      final targetDate = DateTime.now();

      final cuteTheme = AppTheme.buildTheme(
        brightness: Brightness.light,
        styleId: 'cute_sprout',
      );

      final stats = OverallAttendanceStats(
        totalHeld: 14,
        totalAttended: 10,
        totalAbsent: 4,
        totalCancelled: 0,
        totalPending: 0,
        overallPercentage: 71.4,
        targetPercentage: 75.0,
        marginClassesToMiss: 0,
        requiredClassesToAttend: 2,
        subjectStats: [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            userProfileProvider.overrideWith((ref) => FakeUserProfileNotifier('Hirok')),
            overallStatsProvider.overrideWithValue(stats),
            resolvedDayScheduleProvider(targetDate).overrideWithValue(sampleSessions),
            realtimeClockProvider.overrideWith((ref) => Stream.value(DateTime.now())),
          ],
          child: MaterialApp(
            theme: cuteTheme,
            home: SproutTodayView(
              selectedDate: targetDate,
              onDateChanged: (_) {},
              onGoToToday: () {},
              onPickDate: () {},
              onSessionTap: (_, __) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Student name in greeting
      expect(find.text('Hirok!'), findsOneWidget);
      expect(find.text("Show up. You're doing great!"), findsOneWidget);

      // Overall attendance care card
      expect(find.text('Overall Attendance'), findsOneWidget);
      expect(find.text('71.4%'), findsOneWidget);
      expect(find.text('Target 75%'), findsOneWidget);
      expect(find.text('Needs a little more care'), findsOneWidget);
      expect(find.text('Attend 2 more classes to reach your target.'), findsOneWidget);

      // Next Class section
      expect(find.text('Next Class'), findsOneWidget);
      expect(find.text('Computer Networks'), findsWidgets);
      expect(find.text('Room Lab 3'), findsOneWidget);

      await db.close();
    });

    testWidgets('Displays thriving state when attendance is at or above target', (tester) async {
      final db = AppDatabase.inMemory();
      final targetDate = DateTime(2026, 9, 15);

      final cuteTheme = AppTheme.buildTheme(
        brightness: Brightness.light,
        styleId: 'cute_sprout',
      );

      final stats = OverallAttendanceStats(
        totalHeld: 20,
        totalAttended: 18,
        totalAbsent: 2,
        totalCancelled: 0,
        totalPending: 0,
        overallPercentage: 90.0,
        targetPercentage: 75.0,
        marginClassesToMiss: 4,
        requiredClassesToAttend: 0,
        subjectStats: [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            userProfileProvider.overrideWith((ref) => FakeUserProfileNotifier('Alice')),
            overallStatsProvider.overrideWithValue(stats),
            resolvedDayScheduleProvider(targetDate).overrideWithValue([]),
            realtimeClockProvider.overrideWith((ref) => Stream.value(DateTime.now())),
          ],
          child: MaterialApp(
            theme: cuteTheme,
            home: SproutTodayView(
              selectedDate: targetDate,
              onDateChanged: (_) {},
              onGoToToday: () {},
              onPickDate: () {},
              onSessionTap: (_, __) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Alice!'), findsOneWidget);
      expect(find.text('90.0%'), findsOneWidget);
      expect(find.text('Sprout is thriving!'), findsOneWidget);
      expect(find.text('You can safely miss 4 classes and stay above target.'), findsOneWidget);

      // Empty state when no classes
      expect(find.text('All Caught Up!'), findsOneWidget);
      expect(find.textContaining('No classes scheduled for this date'), findsOneWidget);

      await db.close();
    });

    testWidgets('Shows holiday banner when active holiday covers date', (tester) async {
      final db = AppDatabase.inMemory();
      final targetDate = DateTime(2026, 9, 15);

      final cuteTheme = AppTheme.buildTheme(
        brightness: Brightness.light,
        styleId: 'cute_sprout',
      );

      final holidays = [
        HolidayItem(
          title: 'Campus Festival',
          startDate: '2026-09-14',
          endDate: '2026-09-16',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            holidaysProvider.overrideWith((ref) => FakeHolidaysNotifier(holidays)),
            resolvedDayScheduleProvider(targetDate).overrideWithValue([]),
            realtimeClockProvider.overrideWith((ref) => Stream.value(DateTime.now())),
          ],
          child: MaterialApp(
            theme: cuteTheme,
            home: SproutTodayView(
              selectedDate: targetDate,
              onDateChanged: (_) {},
              onGoToToday: () {},
              onPickDate: () {},
              onSessionTap: (_, __) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Campus Festival'), findsOneWidget);
      expect(find.textContaining('Classes are suspended for today'), findsOneWidget);

      await db.close();
    });

    testWidgets('Invokes onPickDate and onGoToToday callbacks', (tester) async {
      final db = AppDatabase.inMemory();
      // Date in past (so Today button appears)
      final pastDate = DateTime(2026, 1, 1);

      final cuteTheme = AppTheme.buildTheme(
        brightness: Brightness.light,
        styleId: 'cute_sprout',
      );

      bool pickedDate = false;
      bool wentToToday = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            resolvedDayScheduleProvider(pastDate).overrideWithValue([]),
            realtimeClockProvider.overrideWith((ref) => Stream.value(DateTime.now())),
          ],
          child: MaterialApp(
            theme: cuteTheme,
            home: SproutTodayView(
              selectedDate: pastDate,
              onDateChanged: (_) {},
              onGoToToday: () => wentToToday = true,
              onPickDate: () => pickedDate = true,
              onSessionTap: (_, __) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Today 🌱 button
      expect(find.text('Today 🌱'), findsOneWidget);
      await tester.tap(find.text('Today 🌱'));
      await tester.pump();
      expect(wentToToday, true);

      // Tap Date chip
      await tester.tap(find.text(DateFormatter.formatHeaderDate(pastDate)));
      await tester.pump();
      expect(pickedDate, true);

      await db.close();
    });

    testWidgets('TodayScreen dynamically renders SproutTodayView when cute theme active', (tester) async {
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
            userProfileProvider.overrideWith((ref) => FakeUserProfileNotifier('Mochi')),
            realtimeClockProvider.overrideWith((ref) => Stream.value(DateTime.now())),
          ],
          child: MaterialApp(
            theme: cuteTheme,
            home: const TodayScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // SproutTodayView is rendered
      expect(find.byType(SproutTodayView), findsOneWidget);
      expect(find.text('Mochi!'), findsOneWidget);
      expect(find.text('Overall Attendance'), findsOneWidget);

      await db.close();
    });

    testWidgets('TodayScreen renders Classic layout when classic theme is active', (tester) async {
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
            realtimeClockProvider.overrideWith((ref) => Stream.value(DateTime.now())),
          ],
          child: MaterialApp(
            theme: classicTheme,
            home: const TodayScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // SproutTodayView is NOT rendered, PageView is rendered for classic swipeable day pager
      expect(find.byType(SproutTodayView), findsNothing);
      expect(find.byType(PageView), findsOneWidget);

      await db.close();
    });

    testWidgets('SproutTodayView displays Next Class and NOT duplicate schedule list on today', (tester) async {
      final db = AppDatabase.inMemory();
      final now = DateTime.now();
      final todayIso = DateFormatter.toIsoDate(now);

      final cuteTheme = AppTheme.buildTheme(
        brightness: Brightness.light,
        styleId: 'cute_sprout',
      );

      final sampleSessions = [
        ClassSessionEntity(
          id: 'sess-1',
          semesterId: 'sem_1',
          subjectComponentId: 'sub-comp-1',
          subjectName: 'Artificial Intelligence',
          subjectCode: 'CS501',
          category: 'Core',
          componentType: 'Lecture',
          startTime: '09:00',
          endTime: '10:00',
          sessionSource: 'TIMETABLE_RECURRING',
          status: 'SCHEDULED',
          room: 'Room 301',
          colorHex: '#10B981',
          sessionDate: todayIso,
          attendanceOutcome: 'PENDING',
        ),
        ClassSessionEntity(
          id: 'sess-2',
          semesterId: 'sem_1',
          subjectComponentId: 'sub-comp-2',
          subjectName: 'Software Engineering',
          subjectCode: 'CS502',
          category: 'Core',
          componentType: 'Lecture',
          startTime: '11:00',
          endTime: '12:00',
          sessionSource: 'TIMETABLE_RECURRING',
          status: 'SCHEDULED',
          room: 'Room 302',
          colorHex: '#3B82F6',
          sessionDate: todayIso,
          attendanceOutcome: 'PENDING',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            userProfileProvider.overrideWith((ref) => FakeUserProfileNotifier('TestUser')),
            overallStatsProvider.overrideWithValue(OverallAttendanceStats(
              totalHeld: 0,
              totalAttended: 0,
              totalAbsent: 0,
              totalCancelled: 0,
              totalPending: 2,
              overallPercentage: 100.0,
              targetPercentage: 75.0,
              marginClassesToMiss: 0,
              requiredClassesToAttend: 0,
              subjectStats: [],
            )),
            resolvedDayScheduleProvider(now).overrideWithValue(sampleSessions),
            realtimeClockProvider.overrideWith((ref) => Stream.value(now)),
          ],
          child: MaterialApp(
            theme: cuteTheme,
            home: SproutTodayView(
              selectedDate: now,
              onDateChanged: (_) {},
              onGoToToday: () {},
              onPickDate: () {},
              onSessionTap: (_, __) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Next Class hero header is displayed
      expect(find.text('Next Class'), findsOneWidget);
      expect(find.text('Artificial Intelligence'), findsOneWidget);

      // Duplicate Today's Schedule list is NOT displayed
      expect(find.textContaining("Today's Schedule"), findsNothing);

      await db.close();
    });

    testWidgets('Tapping Next Class outcome button displays modal bottom sheet with Cancelled option', (tester) async {
      final db = AppDatabase.inMemory();
      final now = DateTime.now();
      final todayIso = DateFormatter.toIsoDate(now);

      final cuteTheme = AppTheme.buildTheme(
        brightness: Brightness.light,
        styleId: 'cute_sprout',
      );

      final sampleSessions = [
        ClassSessionEntity(
          id: 'sess-1',
          semesterId: 'sem_1',
          subjectComponentId: 'sub-comp-1',
          subjectName: 'Database Systems',
          subjectCode: 'CS301',
          category: 'Core',
          componentType: 'Lecture',
          startTime: '09:00',
          endTime: '10:00',
          sessionSource: 'TIMETABLE_RECURRING',
          status: 'SCHEDULED',
          room: 'Room 101',
          colorHex: '#10B981',
          sessionDate: todayIso,
          attendanceOutcome: 'PENDING',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            userProfileProvider.overrideWith((ref) => FakeUserProfileNotifier('TestUser')),
            overallStatsProvider.overrideWithValue(OverallAttendanceStats(
              totalHeld: 0,
              totalAttended: 0,
              totalAbsent: 0,
              totalCancelled: 0,
              totalPending: 1,
              overallPercentage: 100.0,
              targetPercentage: 75.0,
              marginClassesToMiss: 0,
              requiredClassesToAttend: 0,
              subjectStats: [],
            )),
            resolvedDayScheduleProvider(now).overrideWithValue(sampleSessions),
            realtimeClockProvider.overrideWith((ref) => Stream.value(now)),
          ],
          child: MaterialApp(
            theme: cuteTheme,
            home: SproutTodayView(
              selectedDate: now,
              onDateChanged: (_) {},
              onGoToToday: () {},
              onPickDate: () {},
              onSessionTap: (_, __) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the outcome button on Next Class card ("Mark") with Sprout seedling emoji
      expect(find.text('Mark'), findsOneWidget);
      expect(find.text('🌱'), findsWidgets);

      // Tap outcome button
      await tester.tap(find.text('Mark'));
      await tester.pumpAndSettle();

      // Modal bottom sheet opens with minimalist floating capsule
      expect(find.text('Present'), findsOneWidget);
      expect(find.text('Absent'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Bottom sheet is closed
      expect(find.text('Cancel'), findsNothing);

      await db.close();
    });

    testWidgets('SproutTodayView renders Sprout-native session cards with outcome pill on past dates', (tester) async {
      final db = AppDatabase.inMemory();
      final pastDate = DateTime.now().subtract(const Duration(days: 2));
      final pastIso = DateFormatter.toIsoDate(pastDate);

      final cuteTheme = AppTheme.buildTheme(
        brightness: Brightness.light,
        styleId: 'cute_sprout',
      );

      final pastSessions = [
        ClassSessionEntity(
          id: 'past-sess-1',
          semesterId: 'sem_1',
          subjectComponentId: 'sub-comp-1',
          subjectName: 'Mobile Development',
          subjectCode: 'CS401',
          category: 'Core',
          componentType: 'Lecture',
          startTime: '09:00',
          endTime: '10:00',
          sessionSource: 'TIMETABLE_RECURRING',
          status: 'SCHEDULED',
          room: 'Room 201',
          colorHex: '#10B981',
          sessionDate: pastIso,
          attendanceOutcome: 'PRESENT',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            userProfileProvider.overrideWith((ref) => FakeUserProfileNotifier('TestUser')),
            overallStatsProvider.overrideWithValue(OverallAttendanceStats(
              totalHeld: 1,
              totalAttended: 1,
              totalAbsent: 0,
              totalCancelled: 0,
              totalPending: 0,
              overallPercentage: 100.0,
              targetPercentage: 75.0,
              marginClassesToMiss: 0,
              requiredClassesToAttend: 0,
              subjectStats: [],
            )),
            resolvedDayScheduleProvider(pastDate).overrideWithValue(pastSessions),
            realtimeClockProvider.overrideWith((ref) => Stream.value(DateTime.now())),
          ],
          child: MaterialApp(
            theme: cuteTheme,
            home: SproutTodayView(
              selectedDate: pastDate,
              onDateChanged: (_) {},
              onGoToToday: () {},
              onPickDate: () {},
              onSessionTap: (_, __) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Subject displayed
      expect(find.text('Mobile Development'), findsOneWidget);
      // Header count chip
      expect(find.text('1 class'), findsOneWidget);
      // Trailing status pill ("Present")
      expect(find.text('Present'), findsOneWidget);

      await db.close();
    });

    testWidgets('SproutTodayView renders Sprout-native session cards with upcoming badge on future dates', (tester) async {
      final db = AppDatabase.inMemory();
      final futureDate = DateTime.now().add(const Duration(days: 3));
      final futureIso = DateFormatter.toIsoDate(futureDate);

      final cuteTheme = AppTheme.buildTheme(
        brightness: Brightness.light,
        styleId: 'cute_sprout',
      );

      final futureSessions = [
        ClassSessionEntity(
          id: 'future-sess-1',
          semesterId: 'sem_1',
          subjectComponentId: 'sub-comp-2',
          subjectName: 'Cloud Computing',
          subjectCode: 'CS402',
          category: 'Core',
          componentType: 'Lecture',
          startTime: '11:00',
          endTime: '12:00',
          sessionSource: 'TIMETABLE_RECURRING',
          status: 'SCHEDULED',
          room: 'Room 303',
          colorHex: '#3B82F6',
          sessionDate: futureIso,
          attendanceOutcome: 'PENDING',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            userProfileProvider.overrideWith((ref) => FakeUserProfileNotifier('TestUser')),
            overallStatsProvider.overrideWithValue(OverallAttendanceStats(
              totalHeld: 0,
              totalAttended: 0,
              totalAbsent: 0,
              totalCancelled: 0,
              totalPending: 1,
              overallPercentage: 100.0,
              targetPercentage: 75.0,
              marginClassesToMiss: 0,
              requiredClassesToAttend: 0,
              subjectStats: [],
            )),
            resolvedDayScheduleProvider(futureDate).overrideWithValue(futureSessions),
            realtimeClockProvider.overrideWith((ref) => Stream.value(DateTime.now())),
          ],
          child: MaterialApp(
            theme: cuteTheme,
            home: SproutTodayView(
              selectedDate: futureDate,
              onDateChanged: (_) {},
              onGoToToday: () {},
              onPickDate: () {},
              onSessionTap: (_, __) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Subject displayed
      expect(find.text('Cloud Computing'), findsOneWidget);
      // Trailing upcoming badge
      expect(find.text('Upcoming'), findsOneWidget);
      // No outcome buttons on future date
      expect(find.text('Mark'), findsNothing);
      expect(find.text('Present'), findsNothing);

      await db.close();
    });

    test('ThemeAssetConfig and AppThemeRegistry are properly registered', () {
      final cuteDef = AppThemeRegistry.getTheme('cute_sprout');
      expect(cuteDef.navItems.length, 5);
      expect(cuteDef.navItems.map((e) => e.label).toList(), ['Home', 'Timetable', 'Calendar', 'Analytics', 'Settings']);
      expect(cuteDef.assets.todayMascot, isNotEmpty);
      expect(cuteDef.assets.navHome, isNotNull);
      expect(cuteDef.assets.navTimetable, isNotNull);
      expect(cuteDef.assets.navCalendar, isNotNull);
      expect(cuteDef.assets.navAnalytics, isNotNull);
      expect(cuteDef.assets.navSettings, isNotNull);

      final classicDef = AppThemeRegistry.getTheme('classic_indigo');
      expect(classicDef.navItems.length, 4);
      expect(classicDef.navItems.map((e) => e.label).toList(), ['Today', 'Analytics', 'Timetable', 'Calendar']);
    });

    testWidgets('MainShell renders SproutFloatingNavBar with 5 tabs in cute theme', (tester) async {
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
            realtimeClockProvider.overrideWith((ref) => Stream.value(DateTime.now())),
          ],
          child: MaterialApp(
            theme: cuteTheme,
            home: const MainShell(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(SproutFloatingNavBar), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Timetable'), findsOneWidget);
      expect(find.text('Calendar'), findsOneWidget);
      expect(find.text('Analytics'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      await db.close();
    });

    testWidgets('SproutTodayView does NOT render settings button in top action strip', (tester) async {
      final db = AppDatabase.inMemory();
      final now = DateTime.now();

      final cuteTheme = AppTheme.buildTheme(
        brightness: Brightness.light,
        styleId: 'cute_sprout',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            userProfileProvider.overrideWith((ref) => FakeUserProfileNotifier('TestUser')),
            resolvedDayScheduleProvider(now).overrideWithValue([]),
            realtimeClockProvider.overrideWith((ref) => Stream.value(now)),
          ],
          child: MaterialApp(
            theme: cuteTheme,
            home: SproutTodayView(
              selectedDate: now,
              onDateChanged: (_) {},
              onGoToToday: () {},
              onPickDate: () {},
              onSessionTap: (_, __) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Settings gear icon should NOT be in the Sprout today view top strip
      expect(find.byIcon(Icons.settings_outlined), findsNothing);
      // Holiday palm button is still present
      expect(find.text('🌴'), findsOneWidget);

      await db.close();
    });

    testWidgets('SettingsScreen hides < Back button on cute theme', (tester) async {
      final db = AppDatabase.inMemory();

      final cuteTheme = AppTheme.buildTheme(
        brightness: Brightness.light,
        styleId: 'cute_sprout',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            userProfileProvider.overrideWith((ref) => FakeUserProfileNotifier('TestUser')),
            appThemeStyleProvider.overrideWith((ref) => FakeThemeStyleNotifier(ref, 'cute_sprout')),
          ],
          child: MaterialApp(
            theme: cuteTheme,
            home: const SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // On cute theme, Settings is a top-level tab so '< Back' must NOT appear
      expect(find.text('Back'), findsNothing);
      expect(find.byIcon(Icons.chevron_left_rounded), findsNothing);
      expect(find.text('Settings'), findsOneWidget);

      await db.close();
    });

    testWidgets('SettingsScreen in cute theme renders Sprout hero card and uppercase headers without emojis', (tester) async {
      final db = AppDatabase.inMemory();

      final cuteTheme = AppTheme.buildTheme(
        brightness: Brightness.light,
        styleId: 'cute_sprout',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            userProfileProvider.overrideWith((ref) => FakeUserProfileNotifier('Mochi Takahashi')),
            appThemeStyleProvider.overrideWith((ref) => FakeThemeStyleNotifier(ref, 'cute_sprout')),
            activeSemesterProvider.overrideWith((ref) => FakeActiveSemesterNotifier(
              db,
              SemesterEntity(
                id: 'sem_1',
                name: 'Sem 4',
                academicYear: '2026',
                startDate: DateTime(2026, 1, 1),
                endDate: DateTime(2026, 12, 31),
              ),
            )),
          ],
          child: MaterialApp(
            theme: cuteTheme,
            home: const SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Monogram initials and student info
      expect(find.text('MT'), findsOneWidget);
      expect(find.text('Mochi Takahashi'), findsOneWidget);
      expect(find.text('Sem 4'), findsOneWidget);
      expect(find.text('Edit Profile ›'), findsOneWidget);

      // Section headers are uppercase without emojis
      expect(find.text('PREFERENCES'), findsOneWidget);
      expect(find.text('NOTIFICATIONS'), findsOneWidget);
      expect(find.text('DATA & STORAGE'), findsOneWidget);

      // Attendance target stepper
      expect(find.text('−'), findsOneWidget);
      expect(find.text('+'), findsOneWidget);

      // Scroll to reveal ABOUT section header
      await tester.scrollUntilVisible(find.text('ABOUT'), 300);
      expect(find.text('ABOUT'), findsOneWidget);

      await db.close();
    });

    testWidgets('SproutFloatingNavBar layout wraps foreground items in Positioned.fill', (tester) async {
      final cuteDef = AppThemeRegistry.getTheme('cute_sprout');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: SproutFloatingNavBar(
              currentIndex: 0,
              onTap: (_) {},
              items: cuteDef.navItems,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Positioned.fill exists inside the navbar Stack
      expect(find.byType(Positioned), findsWidgets);
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('Tapping session on Sprouts theme displays minimalist floating action sheet', (tester) async {
      final db = AppDatabase.inMemory();
      final today = DateUtils.dateOnly(DateTime.now());
      final todayIso = DateFormatter.toIsoDate(today);

      final cuteTheme = AppTheme.buildTheme(
        brightness: Brightness.light,
        styleId: 'cute_sprout',
      );

      final sampleSessions = [
        ClassSessionEntity(
          id: 'sess-tap-1',
          semesterId: 'sem_1',
          subjectComponentId: 'sub-comp-1',
          subjectName: 'Operating Systems',
          subjectCode: 'CS401',
          category: 'Core',
          componentType: 'Lecture',
          startTime: '09:00',
          endTime: '10:00',
          sessionSource: 'TIMETABLE_RECURRING',
          status: 'SCHEDULED',
          room: 'Room 304',
          colorHex: '#10B981',
          sessionDate: todayIso,
          attendanceOutcome: 'PENDING',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            appThemeStyleProvider.overrideWith((ref) => FakeThemeStyleNotifier(ref, 'cute_sprout')),
            userProfileProvider.overrideWith((ref) => FakeUserProfileNotifier('Mochi')),
            overallStatsProvider.overrideWithValue(OverallAttendanceStats(
              totalHeld: 0,
              totalAttended: 0,
              totalAbsent: 0,
              totalCancelled: 0,
              totalPending: 1,
              overallPercentage: 100.0,
              targetPercentage: 75.0,
              marginClassesToMiss: 0,
              requiredClassesToAttend: 0,
              subjectStats: [],
            )),
            resolvedDayScheduleProvider(today).overrideWithValue(sampleSessions),
            realtimeClockProvider.overrideWith((ref) => Stream.value(today)),
          ],
          child: MaterialApp(
            theme: cuteTheme,
            home: const TodayScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on the card body of the session
      expect(find.text('Operating Systems'), findsOneWidget);
      await tester.tap(find.text('Operating Systems'));
      await tester.pumpAndSettle();

      // Verify Sprout-exclusive floating capsule actions are present
      expect(find.text('🌱 Timetable Slot'), findsOneWidget);
      expect(find.text('Change room / time today'), findsOneWidget);
      expect(find.text('Single-day adjustment'), findsOneWidget);
      expect(find.text('Manage subject rooms'), findsOneWidget);
      expect(find.text('Edit weekly schedule'), findsOneWidget);
      expect(find.text('Remove for today only'), findsOneWidget);
      expect(find.text('Manage all slots'), findsOneWidget);

      await db.close();
    });

    testWidgets('Tapping session on Classic theme preserves classic action sheet', (tester) async {
      final db = AppDatabase.inMemory();
      final today = DateUtils.dateOnly(DateTime.now());
      final todayIso = DateFormatter.toIsoDate(today);

      final classicTheme = AppTheme.buildTheme(
        brightness: Brightness.light,
        styleId: 'classic_indigo',
      );

      final sampleSessions = [
        ClassSessionEntity(
          id: 'sess-classic-1',
          semesterId: 'sem_1',
          subjectComponentId: 'sub-comp-1',
          subjectName: 'Linear Algebra',
          subjectCode: 'MA201',
          category: 'Core',
          componentType: 'Lecture',
          startTime: '10:00',
          endTime: '11:00',
          sessionSource: 'TIMETABLE_RECURRING',
          status: 'SCHEDULED',
          room: 'Hall B',
          colorHex: '#4F46E5',
          sessionDate: todayIso,
          attendanceOutcome: 'PENDING',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            appThemeStyleProvider.overrideWith((ref) => FakeThemeStyleNotifier(ref, 'classic_indigo')),
            activeSemesterProvider.overrideWith((ref) => FakeActiveSemesterNotifier(
              db,
              SemesterEntity(
                id: 'sem_1',
                name: 'Semester 1',
                academicYear: '2026',
                startDate: DateTime(2026, 1, 1),
                endDate: DateTime(2026, 12, 31),
              ),
            )),
            userProfileProvider.overrideWith((ref) => FakeUserProfileNotifier('ClassicUser')),
            overallStatsProvider.overrideWithValue(OverallAttendanceStats(
              totalHeld: 0,
              totalAttended: 0,
              totalAbsent: 0,
              totalCancelled: 0,
              totalPending: 1,
              overallPercentage: 100.0,
              targetPercentage: 75.0,
              marginClassesToMiss: 0,
              requiredClassesToAttend: 0,
              subjectStats: [],
            )),
            resolvedDayScheduleProvider(today).overrideWithValue(sampleSessions),
            realtimeClockProvider.overrideWith((ref) => Stream.value(today)),
          ],
          child: MaterialApp(
            theme: classicTheme,
            home: const TodayScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on the classic session card
      expect(find.text('Linear Algebra'), findsOneWidget);
      await tester.tap(find.text('Linear Algebra'));
      await tester.pumpAndSettle();

      // Verify Classic-exclusive action sheet is present and Sprout badge is absent
      expect(find.text('🌱 Timetable Slot'), findsNothing);
      expect(find.text('Change room / time for today only'), findsOneWidget);
      expect(find.text('Manage rooms for this subject'), findsOneWidget);
      expect(find.text('Edit this weekly slot permanently'), findsOneWidget);

      await db.close();
    });

    testWidgets('ProfileScreen in cute theme renders hero identity card, status pills, and uppercase headers without emojis', (tester) async {
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
            userProfileProvider.overrideWith((ref) => FakeUserProfileNotifier('Mochi Takahashi')),
            activeSemesterProvider.overrideWith((ref) => FakeActiveSemesterNotifier(
              db,
              SemesterEntity(
                id: 'sem_1',
                name: 'Sem 4',
                academicYear: '2026',
                startDate: DateTime(2026, 1, 1),
                endDate: DateTime(2026, 12, 31),
              ),
            )),
            selectedUniversityProvider.overrideWith((ref) => FakeSelectedUniversityNotifier(
              db,
              const UserUniversityInfo(
                state: 'Karnataka',
                universityName: 'National Institute of Tech',
                locationType: 'CAMPUS',
              ),
            )),
            activeTemplateProvider.overrideWith((ref) => FakeActiveTemplateNotifier(
              db,
              ProgrammeTemplates.fyugpTemplate,
            )),
          ],
          child: MaterialApp(
            theme: cuteTheme,
            home: const ProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Back navigation & App bar
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      // Hero identity card elements
      expect(find.text('MT'), findsOneWidget);
      expect(find.text('Mochi Takahashi'), findsOneWidget);
      expect(find.text('Roll: CS101 • Enr: EN101'), findsOneWidget);
      expect(find.text('Sem 4'), findsOneWidget);
      expect(find.text('National Institute of Tech'), findsAtLeastNWidgets(1));

      // Section 1: Academic details (uppercase without emojis)
      expect(find.text('ACADEMIC DETAILS'), findsOneWidget);
      expect(find.text('B.Tech CSE'), findsOneWidget);
      expect(find.text('Computer Science'), findsOneWidget);

      // Section 2: Manage identity & structure
      await tester.scrollUntilVisible(find.text('MANAGE IDENTITY & STRUCTURE'), 300);
      expect(find.text('MANAGE IDENTITY & STRUCTURE'), findsOneWidget);

      // Action tiles (scroll to ensure visible in ListView)
      await tester.scrollUntilVisible(find.text('Edit Student Profile'), 300);
      expect(find.text('Edit Student Profile'), findsOneWidget);
      expect(find.text('Academic Period & Semesters'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('University & Affiliated College'), 300);
      expect(find.text('University & Affiliated College'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Degree Curriculum Structure'), 300);
      expect(find.text('Degree Curriculum Structure'), findsOneWidget);

      await db.close();
    });

    testWidgets('ProfileScreen in classic theme renders classic circular avatar and layout', (tester) async {
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
            userProfileProvider.overrideWith((ref) => FakeUserProfileNotifier('Classic Student')),
            activeSemesterProvider.overrideWith((ref) => FakeActiveSemesterNotifier(
              db,
              SemesterEntity(
                id: 'sem_1',
                name: 'Sem 1',
                academicYear: '2026',
                startDate: DateTime(2026, 1, 1),
                endDate: DateTime(2026, 12, 31),
              ),
            )),
            selectedUniversityProvider.overrideWith((ref) => FakeSelectedUniversityNotifier(
              db,
              const UserUniversityInfo(
                state: 'Delhi',
                universityName: 'Delhi University',
                locationType: 'CAMPUS',
              ),
            )),
            activeTemplateProvider.overrideWith((ref) => FakeActiveTemplateNotifier(
              db,
              ProgrammeTemplates.fyugpTemplate,
            )),
          ],
          child: MaterialApp(
            theme: classicTheme,
            home: const ProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Back navigation & App bar
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      // Hero identity card elements in classic circular mode
      expect(find.text('CS'), findsOneWidget);
      expect(find.text('Classic Student'), findsAtLeastNWidgets(1));

      // Classic has standard mixed-case headers without Sprout all-caps styling
      expect(find.text('ACADEMIC DETAILS'), findsNothing);
      expect(find.text('MANAGE IDENTITY & STRUCTURE'), findsNothing);

      await db.close();
    });

    testWidgets('AppearanceScreen in cute theme renders Live Preview, Color Mode, Theme Style, and Display & Widgets without emoji headings', (tester) async {
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
            overallStatsProvider.overrideWithValue(OverallAttendanceStats(
              totalHeld: 10,
              totalAttended: 9,
              totalAbsent: 1,
              totalCancelled: 0,
              totalPending: 0,
              overallPercentage: 90.0,
              targetPercentage: 75.0,
              marginClassesToMiss: 1,
              requiredClassesToAttend: 0,
              subjectStats: [],
            )),
          ],
          child: MaterialApp(
            theme: cuteTheme,
            home: const AppearanceScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Navigation & Title (zero emojis)
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);

      // Section 1: Live preview
      expect(find.text('LIVE PREVIEW'), findsOneWidget);
      expect(find.text('90.0% Overall'), findsOneWidget);
      expect(find.text('Present'), findsOneWidget);

      // Section 2: Color mode (Light, Dark, System)
      expect(find.text('COLOR MODE'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);

      // Section 3: Theme Style
      await tester.scrollUntilVisible(find.text('THEME STYLE'), 100);
      expect(find.text('THEME STYLE'), findsOneWidget);
      expect(find.text('Sprout & Mochi'), findsOneWidget);
      expect(find.text('Classic Attendly'), findsOneWidget);

      // Section 4: Display & Widgets (Unified card)
      await tester.scrollUntilVisible(find.text('DISPLAY & WIDGETS'), 100);
      expect(find.text('DISPLAY & WIDGETS'), findsOneWidget);
      expect(find.text('Pure OLED Black'), findsOneWidget);
      expect(find.text('AMOLED'), findsOneWidget);
      expect(find.text('Match System Schedule'), findsOneWidget);

      // Home Screen Widgets tile
      await tester.scrollUntilVisible(find.text('Home Screen Widgets'), 100);
      expect(find.text('Home Screen Widgets'), findsOneWidget);

      await db.close();
    });

    testWidgets('AppearanceScreen in classic theme preserves classic indigo layout and cards', (tester) async {
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
            overallStatsProvider.overrideWithValue(OverallAttendanceStats(
              totalHeld: 10,
              totalAttended: 9,
              totalAbsent: 1,
              totalCancelled: 0,
              totalPending: 0,
              overallPercentage: 90.0,
              targetPercentage: 75.0,
              marginClassesToMiss: 1,
              requiredClassesToAttend: 0,
              subjectStats: [],
            )),
          ],
          child: MaterialApp(
            theme: classicTheme,
            home: const AppearanceScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Navigation & Title
      expect(find.text('Back'), findsOneWidget);
      // Both themes now share unified DISPLAY & WIDGETS section header
      await tester.scrollUntilVisible(find.text('DISPLAY & WIDGETS'), 150);
      expect(find.text('DISPLAY & WIDGETS'), findsOneWidget);

      await db.close();
    });

    testWidgets('NotificationSettingsScreen in cute theme renders Sprouts layout and timing sheet without emojis', (tester) async {
      final db = AppDatabase.inMemory();
      final sproutTheme = AppTheme.buildTheme(
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
            theme: sproutTheme,
            home: const NotificationSettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Sprouts Navigation & Title
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);

      // Sprouts uppercase typography headers (Zero emojis)
      expect(find.text('CLASS REMINDERS'), findsOneWidget);
      expect(find.text('SOUND & FEEDBACK'), findsOneWidget);

      // Hero status display
      expect(find.text('Reminders Active'), findsOneWidget);

      // Tap Info button to open Did You Know? battery efficiency sheet
      final infoBtn = find.byIcon(Icons.info_outline_rounded);
      expect(infoBtn, findsOneWidget);
      await tester.tap(infoBtn);
      await tester.pumpAndSettle();

      // Verify Sprout battery sheet content
      expect(find.text('Did You Know?'), findsOneWidget);
      expect(find.text('100% Battery Friendly'), findsOneWidget);
      expect(find.text('Exact Scheduled Alarms'), findsOneWidget);
      expect(find.text('Never Runs in the Background'), findsOneWidget);
      expect(find.text('Zero Idle CPU Usage'), findsOneWidget);
      expect(find.text('Got It'), findsOneWidget);

      // Tap Got It to dismiss
      await tester.tap(find.text('Got It'));
      await tester.pumpAndSettle();
      expect(find.text('Did You Know?'), findsNothing);

      await db.close();
    });

    testWidgets('BackupRestoreScreen in cute theme renders Sprouts layout with action buttons without emojis', (tester) async {
      final db = AppDatabase.inMemory();
      final sproutTheme = AppTheme.buildTheme(
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
            theme: sproutTheme,
            home: const BackupRestoreScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Navigation & Title
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Backup & Restore'), findsOneWidget);

      // Action buttons
      expect(find.text('Backup Now'), findsOneWidget);
      expect(find.text('Restore'), findsOneWidget);

      // Section headers (Zero emojis)
      expect(find.text('AUTOMATION & SCHEDULES'), findsOneWidget);
      expect(find.textContaining('LOCAL SNAPSHOTS'), findsOneWidget);

      await db.close();
    });

    testWidgets('AboutScreen and PrivacyPolicyScreen in cute theme render Sprouts layout without emojis', (tester) async {
      final db = AppDatabase.inMemory();
      final sproutTheme = AppTheme.buildTheme(
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
            theme: sproutTheme,
            home: const AboutScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Navigation & Title
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);

      // Section headers (Zero emojis)
      expect(find.text('APP & UPDATES'), findsOneWidget);
      expect(find.text('LEGAL & DATA ETHICS'), findsOneWidget);
      expect(find.text('COMMUNITY & SOURCE'), findsOneWidget);

      // Tiles
      expect(find.text('Check for updates'), findsOneWidget);
      expect(find.text('What\'s new'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);

      // Tap Privacy Policy to verify PrivacyPolicyScreen renders
      await tester.tap(find.text('Privacy Policy'));
      await tester.pumpAndSettle();

      expect(find.text('OFFLINE-FIRST ARCHITECTURE'), findsOneWidget);
      expect(find.text('Your Data Stays on Your Device'), findsOneWidget);

      await db.close();
    });

    testWidgets('TargetPercentageSheet in cute theme renders Sprouts slider sheet with steppers and presets', (tester) async {
      final db = AppDatabase.inMemory();
      final sproutTheme = AppTheme.buildTheme(
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
            theme: sproutTheme,
            home: const Scaffold(
              body: TargetPercentageSheet(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Title & Hero percentage
      expect(find.text('Attendance Target'), findsOneWidget);
      expect(find.text('75.0%'), findsOneWidget);
      expect(find.text('BALANCED TARGET'), findsOneWidget);

      // Preset pills
      expect(find.text('65%'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
      expect(find.text('80%'), findsOneWidget);
      expect(find.text('85%'), findsOneWidget);
      expect(find.text('90%'), findsOneWidget);

      // Save Target button
      expect(find.text('Save Target'), findsOneWidget);

      // Tap 85% pill
      await tester.tap(find.text('85%'));
      await tester.pumpAndSettle();

      expect(find.text('85.0%'), findsOneWidget);
      expect(find.text('HONORS TARGET'), findsOneWidget);

      await db.close();
    });

    testWidgets('UpdateScreen in cute theme renders Sprouts layout and zero emojis', (tester) async {
      final sproutTheme = AppTheme.buildTheme(
        brightness: Brightness.light,
        styleId: 'cute_sprout',
      );

      const releaseInfo = AppReleaseInfo(
        latestVersion: '1.0.0-alpha.12',
        buildNumber: 12,
        minSupportedVersion: '1.0.0-alpha.1',
        releaseDate: 'September 2026',
        releaseTitle: 'Attendly v1.0.0-alpha.12 (Sprouts Theme Suite)',
        changelog: ['Sprouts theme layout and slider sheets', 'Strictly offline SQLite guarantees'],
        isMandatory: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: sproutTheme,
          home: const UpdateScreen(
            releaseInfo: releaseInfo,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Software Update'), findsOneWidget);
      expect(find.text('SOFTWARE UPDATE'), findsOneWidget);
      expect(find.text('v1.0.0-alpha.12'), findsOneWidget);
      expect(find.text('New version available!'), findsOneWidget);
      expect(find.text('RELEASE NOTES'), findsOneWidget);
      expect(find.text('Update Now'), findsOneWidget);
      expect(find.text('Not now'), findsOneWidget);
    });

    testWidgets('UpdateAvailableDialog in cute theme renders Sprouts squircle dialog and zero emojis', (tester) async {
      final sproutTheme = AppTheme.buildTheme(
        brightness: Brightness.light,
        styleId: 'cute_sprout',
      );

      const releaseInfo = AppReleaseInfo(
        latestVersion: '1.0.0-alpha.12',
        buildNumber: 12,
        minSupportedVersion: '1.0.0-alpha.1',
        releaseDate: 'September 2026',
        releaseTitle: 'Attendly v1.0.0-alpha.12 (Sprouts Theme Suite)',
        changelog: ['Sprouts theme layout and slider sheets'],
        isMandatory: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: sproutTheme,
          home: const Scaffold(
            body: UpdateAvailableDialog(
              releaseInfo: releaseInfo,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('New version available!'), findsOneWidget);
      expect(find.text('v1.0.0-alpha.12'), findsOneWidget);
      expect(find.text('Download'), findsOneWidget);
      expect(find.text('Not now'), findsOneWidget);
    });

    testWidgets('UpToDateSheet in cute theme renders Sprouts squircle slider sheet with zero emojis', (tester) async {
      final sproutTheme = AppTheme.buildTheme(
        brightness: Brightness.light,
        styleId: 'cute_sprout',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: sproutTheme,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  UpToDateDialog.show(
                    ctx,
                    currentVersion: '1.0.0-alpha.12',
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
      expect(find.text('LATEST'), findsOneWidget);
      expect(find.text('v1.0.0-alpha.12'), findsOneWidget);
      expect(find.text('What\'s New'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);

      // Verify zero auto_awesome sparkles icon in Sprouts theme
      expect(find.byIcon(Icons.auto_awesome_rounded), findsNothing);

      // Dismiss on Done
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.byType(UpToDateSheet), findsNothing);
    });

    testWidgets('LicensesScreen in cute theme renders Sprouts layout, package search, and zero emojis', (tester) async {
      final sproutTheme = AppTheme.buildTheme(
        brightness: Brightness.light,
        styleId: 'cute_sprout',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: sproutTheme,
          home: const LicensesScreen(
            currentVersion: '1.0.0-alpha.12',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Open Source Licenses'), findsOneWidget);
      expect(find.text('OPEN SOURCE CREDITS'), findsOneWidget);
      expect(find.text('v1.0.0-alpha.12'), findsOneWidget);
      expect(find.text('Software Licenses'), findsOneWidget);
      expect(find.textContaining('PACKAGES & LIBRARIES'), findsOneWidget);
      expect(find.text('Search packages...'), findsOneWidget);

      // Verify flutter package item exists
      expect(find.text('flutter'), findsOneWidget);

      // Tap on flutter package to open detail sheet
      await tester.tap(find.text('flutter'));
      await tester.pumpAndSettle();

      expect(find.text('OPEN SOURCE'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);

      // Close sheet
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // Search functionality
      await tester.enterText(find.byType(TextField), 'drift');
      await tester.pumpAndSettle();

      expect(find.widgetWithText(InkWell, 'drift'), findsOneWidget);
      expect(find.widgetWithText(InkWell, 'flutter'), findsNothing);
    });

    testWidgets('Sprout theme TodayScreen supports smooth day swiping and glides back to today', (tester) async {
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
            userProfileProvider.overrideWith((ref) => FakeUserProfileNotifier('Hirok')),
            realtimeClockProvider.overrideWith((ref) => Stream.value(DateTime.now())),
          ],
          child: MaterialApp(
            theme: cuteTheme,
            home: const TodayScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially on today: "Today 🌱" pill is not visible
      expect(find.byType(SproutTodayView), findsOneWidget);
      expect(find.text('Today 🌱'), findsNothing);

      // Swipe left to go to tomorrow
      await tester.fling(find.byType(PageView), const Offset(-500, 0), 1000);
      await tester.pumpAndSettle();

      // Now on tomorrow: "Today 🌱" pill is visible in the top action strip
      expect(find.text('Today 🌱'), findsOneWidget);

      // Tap "Today 🌱" pill to glide smoothly back to today
      await tester.tap(find.text('Today 🌱'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      // Back to today: "Today 🌱" pill is hidden
      expect(find.text('Today 🌱'), findsNothing);

      await db.close();
    });
  });
}
