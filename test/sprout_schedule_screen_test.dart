import 'package:classtrack/core/constants/app_theme.dart';
import 'package:classtrack/data/database/app_database.dart';
import 'package:classtrack/domain/entities/semester_entity.dart';
import 'package:classtrack/domain/services/schedule_engine.dart';
import 'package:classtrack/presentation/providers/app_state_provider.dart';
import 'package:classtrack/presentation/screens/schedule/schedule_screen.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeActiveSemesterNotifier extends ActiveSemesterNotifier {
  FakeActiveSemesterNotifier(SemesterEntity sem) : super(AppDatabase.inMemory()) {
    state = sem;
  }
}

class FakeTimetableSlotsNotifier extends TimetableSlotsNotifier {
  FakeTimetableSlotsNotifier(List<TimetableSlotItem> slots)
      : super(AppDatabase.inMemory(), 'sem-test', []) {
    state = slots;
  }

  @override
  Future<void> loadFromDb([List<dynamic>? updatedSubjects]) async {
    // Keep in-memory state
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  final sampleActiveSem = SemesterEntity(
    id: 'sem-active',
    name: 'Semester IV',
    academicYear: '2025-2026',
    startDate: DateTime(2026, 1, 15),
    endDate: null,
    termType: TermType.semester,
    isArchived: false,
  );

  final sampleSlots = <TimetableSlotItem>[
    // Day 1 = Monday
    TimetableSlotItem(
      id: 'slot-1',
      semesterId: 'sem-active',
      subjectComponentId: 'sub-comp-1',
      subjectName: 'Computer Networks',
      subjectCode: 'CS401',
      category: 'Core',
      componentType: 'Theory',
      colorHex: '#4CAF50',
      dayOfWeek: 1, // Monday
      startTime: '09:00',
      endTime: '10:30',
      room: '102',
      teacherName: 'Dr. Ramesh Sharma',
    ),
    TimetableSlotItem(
      id: 'slot-2',
      semesterId: 'sem-active',
      subjectComponentId: 'sub-comp-2',
      subjectName: 'Database Systems Lab',
      subjectCode: 'CS402',
      category: 'Core',
      componentType: 'Lab',
      colorHex: '#2196F3',
      dayOfWeek: 1, // Monday
      startTime: '11:00',
      endTime: '13:00',
      room: 'Lab 3',
      teacherName: 'Prof. Ananya Roy',
    ),
    TimetableSlotItem(
      id: 'slot-3',
      semesterId: 'sem-active',
      subjectComponentId: 'sub-comp-3',
      subjectName: 'Elective Seminar',
      subjectCode: null,
      category: 'Elective',
      componentType: 'Seminar',
      colorHex: '#9C27B0',
      dayOfWeek: 1, // Monday
      startTime: '14:00',
      endTime: '15:00',
      room: null,
      teacherName: null,
    ),
  ];

  group('Sprouts Theme Timetable Screen Tests', () {
    testWidgets('ScheduleScreen renders Sprouts header with squircle buttons and zero emojis', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      final cuteTheme = AppTheme.buildTheme(
        brightness: Brightness.light,
        styleId: 'cute_sprout',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeSemesterProvider.overrideWith((ref) => FakeActiveSemesterNotifier(sampleActiveSem)),
            timetableSlotsProvider.overrideWith((ref) => FakeTimetableSlotsNotifier(sampleSlots)),
          ],
          child: MaterialApp(
            theme: cuteTheme,
            home: const ScheduleScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Title and semester header
      expect(find.text('Timetable'), findsOneWidget);
      expect(find.text('SEMESTER IV · 2025-2026'), findsOneWidget);

      // 2. Action squircle buttons
      expect(find.byIcon(Icons.calendar_view_week_rounded), findsOneWidget);
      expect(find.byIcon(Icons.qr_code_scanner_rounded), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsWidgets); // header + cards

      // 3. Horizontal weekday selector
      for (final day in ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']) {
        expect(find.text(day), findsOneWidget);
      }
    });

    testWidgets('Day selector switches days and renders slot cards on Monday', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      final cuteTheme = AppTheme.buildTheme(
        brightness: Brightness.light,
        styleId: 'cute_sprout',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeSemesterProvider.overrideWith((ref) => FakeActiveSemesterNotifier(sampleActiveSem)),
            timetableSlotsProvider.overrideWith((ref) => FakeTimetableSlotsNotifier(sampleSlots)),
          ],
          child: MaterialApp(
            theme: cuteTheme,
            home: const ScheduleScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Monday pill
      await tester.tap(find.text('Mon'));
      await tester.pumpAndSettle();

      // Verify Monday schedule summary
      expect(find.text('MONDAY SCHEDULE'), findsOneWidget);
      expect(find.text('3 Classes'), findsOneWidget);

      // Verify slot card content
      expect(find.text('Computer Networks'), findsOneWidget);
      expect(find.text('09:00'), findsOneWidget);
      expect(find.text('10:30'), findsOneWidget);
      expect(find.text('1h 30m'), findsOneWidget);
      expect(find.text('Theory'), findsOneWidget);
      expect(find.text('Room 102'), findsOneWidget);
      expect(find.text('Dr. Ramesh Sharma'), findsOneWidget);

      // Second slot
      expect(find.text('Database Systems Lab'), findsOneWidget);
      expect(find.text('11:00'), findsOneWidget);
      expect(find.text('13:00'), findsOneWidget);
      expect(find.text('2h'), findsOneWidget);
      expect(find.text('Lab 3'), findsOneWidget);
      expect(find.text('Prof. Ananya Roy'), findsOneWidget);

      // Third slot (null subjectCode, room, teacher)
      expect(find.text('Elective Seminar'), findsOneWidget);
      expect(find.text('14:00'), findsOneWidget);
      expect(find.text('15:00'), findsOneWidget);
      expect(find.text('1h'), findsOneWidget);
      expect(find.text('Seminar'), findsOneWidget);

      // Verify Timekeeper Sprout Speech Bubble footer at the bottom
      expect(find.text('A consistent you builds a brighter future!'), findsOneWidget);
      expect(find.textContaining('3 classes for Monday'), findsOneWidget);
      expect(find.byType(Image), findsWidgets);
    });

    testWidgets('Empty weekday renders Sprouts botanical empty state', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      final cuteTheme = AppTheme.buildTheme(
        brightness: Brightness.light,
        styleId: 'cute_sprout',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeSemesterProvider.overrideWith((ref) => FakeActiveSemesterNotifier(sampleActiveSem)),
            timetableSlotsProvider.overrideWith((ref) => FakeTimetableSlotsNotifier(sampleSlots)),
          ],
          child: MaterialApp(
            theme: cuteTheme,
            home: const ScheduleScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Sunday pill (day 0, has no classes in sampleSlots)
      await tester.tap(find.text('Sun'));
      await tester.pumpAndSettle();

      expect(find.text('Rest & Recharge Day'), findsOneWidget);
      expect(find.textContaining('No classes scheduled for Sunday'), findsOneWidget);
      expect(find.text('Add Class Slot'), findsOneWidget);
    });

    testWidgets('Unset semester renders No Active Semester empty state', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      final cuteTheme = AppTheme.buildTheme(
        brightness: Brightness.light,
        styleId: 'cute_sprout',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeSemesterProvider.overrideWith((ref) => FakeActiveSemesterNotifier(SemesterEntity.empty())),
            timetableSlotsProvider.overrideWith((ref) => FakeTimetableSlotsNotifier([])),
          ],
          child: MaterialApp(
            theme: cuteTheme,
            home: const ScheduleScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('NO ACTIVE SEMESTER · SETUP REQUIRED'), findsOneWidget);
      expect(find.text('No Active Semester'), findsOneWidget);
      expect(find.text('Create Semester'), findsOneWidget);
    });

    testWidgets('Classic theme preserves classic schedule layout', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      final classicTheme = AppTheme.buildTheme(
        brightness: Brightness.light,
        styleId: 'classic_indigo',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeSemesterProvider.overrideWith((ref) => FakeActiveSemesterNotifier(sampleActiveSem)),
            timetableSlotsProvider.overrideWith((ref) => FakeTimetableSlotsNotifier(sampleSlots)),
          ],
          child: MaterialApp(
            theme: classicTheme,
            home: const ScheduleScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Classic uses standard Text without Sprout subtitle
      expect(find.text('Timetable'), findsOneWidget);
      expect(find.text('SEMESTER IV · 2025-2026'), findsNothing);
    });
  });
}
