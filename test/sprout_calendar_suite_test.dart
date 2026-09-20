import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:classtrack/core/constants/app_theme.dart';
import 'package:classtrack/data/database/app_database.dart';
import 'package:classtrack/domain/entities/class_session_entity.dart';
import 'package:classtrack/domain/entities/semester_entity.dart';
import 'package:classtrack/domain/entities/subject_entity.dart';
import 'package:classtrack/domain/services/schedule_engine.dart';
import 'package:classtrack/presentation/providers/app_state_provider.dart';
import 'package:classtrack/presentation/widgets/declare_holiday_dialog.dart';
import 'package:classtrack/presentation/widgets/add_extra_class_sheet.dart';
import 'package:classtrack/presentation/screens/schedule/reschedule_session_screen.dart';
import 'package:classtrack/presentation/screens/schedule/subject_room_manager_screen.dart';
import 'package:classtrack/presentation/screens/schedule/manage_subject_slots_screen.dart';
import 'package:classtrack/presentation/screens/calendar/calendar_screen.dart';

class FakeActiveSemesterNotifier extends ActiveSemesterNotifier {
  FakeActiveSemesterNotifier(SemesterEntity sem) : super(AppDatabase.inMemory()) {
    state = sem;
  }
}

class FakeSubjectsNotifier extends SubjectsNotifier {
  final List<SubjectEntity> initialSubs;
  FakeSubjectsNotifier(super.db, super.semesterId, super.ref, {this.initialSubs = const []}) {
    state = initialSubs;
  }

  @override
  Future<void> loadFromDb() async {
    state = initialSubs;
  }
}

class FakeTimetableSlotsNotifier extends TimetableSlotsNotifier {
  final List<TimetableSlotItem> initialSlots;
  FakeTimetableSlotsNotifier(this.initialSlots)
      : super(AppDatabase.inMemory(), 'sem-active', []) {
    state = initialSlots;
  }

  @override
  Future<void> loadFromDb([List<SubjectEntity>? updatedSubjects]) async {
    state = initialSlots;
  }
}

class FakeHolidaysNotifier extends HolidaysNotifier {
  final List<HolidayItem> holidays;
  FakeHolidaysNotifier(this.holidays) : super(AppDatabase.inMemory(), 'sem-active') {
    state = holidays;
  }

  @override
  Future<void> loadFromDb() async {
    state = holidays;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  ThemeData getCuteTheme() => AppTheme.buildTheme(
        brightness: Brightness.light,
        styleId: 'cute_sprout',
      );

  ThemeData getClassicTheme() => AppTheme.buildTheme(
        brightness: Brightness.light,
        styleId: 'classic_indigo',
      );

  final sampleSem = SemesterEntity(
    id: 'sem-active',
    name: 'Semester IV',
    academicYear: '2025-2026',
    startDate: DateTime(2026, 1, 15),
    endDate: DateTime(2026, 6, 15),
    termType: TermType.semester,
    isArchived: false,
  );

  final sampleSubject = SubjectEntity(
    id: 'sub-1',
    semesterId: 'sem-active',
    name: 'Machine Learning',
    code: 'CS401',
    category: 'MAJOR',
    credits: 4,
    targetAttendancePct: 75.0,
    baselineHeld: 0,
    baselineAttended: 0,
    isArchived: false,
    colorHex: '#558A50',
    components: [],
  );

  final sampleSlot = TimetableSlotItem(
    id: 'slot-1',
    semesterId: 'sem-active',
    subjectComponentId: 'sub-1',
    subjectName: 'Machine Learning',
    subjectCode: 'CS401',
    category: 'MAJOR',
    componentType: 'LECTURE',
    colorHex: '#558A50',
    dayOfWeek: 1,
    startTime: '09:00',
    endTime: '10:00',
    room: 'Hall A',
    teacherName: 'Dr. Turing',
  );

  final sampleSession = ClassSessionEntity(
    id: 'session-1',
    semesterId: 'sem-active',
    subjectComponentId: 'sub-1',
    subjectName: 'Machine Learning',
    subjectCode: 'CS401',
    category: 'MAJOR',
    componentType: 'LECTURE',
    colorHex: '#558A50',
    sessionDate: '2026-03-20',
    dayOfWeek: 1,
    startTime: '09:00',
    endTime: '10:00',
    sessionSource: 'TIMETABLE_RECURRING',
    status: 'PLANNED',
    room: 'Hall A',
    teacherName: 'Dr. Turing',
    attendanceOutcome: 'PRESENT',
  );

  group('Sprouts Theme Calendar & Schedule Suite Tests', () {
    testWidgets('1. DeclareHolidaySheet renders in Sprout theme with presets & date pickers', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeSemesterProvider.overrideWith((ref) => FakeActiveSemesterNotifier(sampleSem)),
            holidaysProvider.overrideWith((ref) => FakeHolidaysNotifier([])),
          ],
          child: MaterialApp(
            theme: getCuteTheme(),
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => DeclareHolidaySheet.show(context, initialDate: DateTime(2026, 3, 20)),
                  child: const Text('Open Holiday Sheet'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Holiday Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Declare Holiday'), findsWidgets);
      expect(find.text('Marked classes will not penalize attendance'), findsOneWidget);
      expect(find.text('OCCASION / TITLE (OPTIONAL)'), findsOneWidget);
      expect(find.text('Date:'), findsOneWidget);
      expect(find.text('Multi-day holiday / break'), findsOneWidget);
    });

    testWidgets('2. AddExtraClassSheet renders in Sprout theme with subject picker & times', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeSemesterProvider.overrideWith((ref) => FakeActiveSemesterNotifier(sampleSem)),
            subjectsProvider.overrideWith((ref) => FakeSubjectsNotifier(AppDatabase.inMemory(), 'sem-active', ref, initialSubs: [sampleSubject])),
          ],
          child: MaterialApp(
            theme: getCuteTheme(),
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => AddExtraClassSheet.show(context, dateIso: '2026-03-20'),
                  child: const Text('Open Extra Sheet'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Extra Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Add Extra Class'), findsWidgets);
      expect(find.text('SUBJECT'), findsOneWidget);
      expect(find.text('START TIME'), findsOneWidget);
      expect(find.text('END TIME'), findsOneWidget);
      expect(find.text('ROOM / HALL'), findsOneWidget);
    });

    testWidgets('3. RescheduleSessionScreen renders with Sprout theme styling', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeSemesterProvider.overrideWith((ref) => FakeActiveSemesterNotifier(sampleSem)),
          ],
          child: MaterialApp(
            theme: getCuteTheme(),
            home: RescheduleSessionScreen(
              session: sampleSession,
              dateIso: '2026-03-20',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reschedule Session'), findsOneWidget);
      expect(find.textContaining('Affects only today\'s session'), findsOneWidget);
      expect(find.text('START TIME'), findsOneWidget);
      expect(find.text('END TIME'), findsOneWidget);
      expect(find.text('ROOM / LOCATION (OPTIONAL)'), findsOneWidget);
      expect(find.text('Save Rescheduled Time'), findsOneWidget);
    });

    testWidgets('4. SubjectRoomManagerScreen renders with default room & overrides', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeSemesterProvider.overrideWith((ref) => FakeActiveSemesterNotifier(sampleSem)),
            timetableSlotsProvider.overrideWith((ref) => FakeTimetableSlotsNotifier([sampleSlot])),
          ],
          child: MaterialApp(
            theme: getCuteTheme(),
            home: SubjectRoomManagerScreen(
              subject: sampleSubject,
              initialRoom: 'Hall A',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Manage Rooms'), findsOneWidget);
      expect(find.text('BULK ROOM ASSIGNMENT'), findsOneWidget);
      expect(find.text('INDIVIDUAL SLOT ROOMS'), findsOneWidget);
      expect(find.text('Save Room Changes'), findsOneWidget);
    });

    testWidgets('5. ManageSubjectSlotsScreen renders with weekly slots & add button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeSemesterProvider.overrideWith((ref) => FakeActiveSemesterNotifier(sampleSem)),
            timetableSlotsProvider.overrideWith((ref) => FakeTimetableSlotsNotifier([sampleSlot])),
          ],
          child: MaterialApp(
            theme: getCuteTheme(),
            home: ManageSubjectSlotsScreen(
              subject: sampleSubject,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Machine Learning'), findsWidgets);
      expect(find.textContaining('Weekly Slots · Schedule Manager'), findsOneWidget);
      expect(find.textContaining('RECURRING SLOTS'), findsOneWidget);
      expect(find.text('MON'), findsOneWidget);
    });

    testWidgets('6. CalendarScreen renders Sprout week strip, session cards & actions', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeSemesterProvider.overrideWith((ref) => FakeActiveSemesterNotifier(sampleSem)),
            holidaysProvider.overrideWith((ref) => FakeHolidaysNotifier([])),
            resolvedDayScheduleProvider.overrideWith((ref, date) => [sampleSession]),
          ],
          child: MaterialApp(
            theme: getCuteTheme(),
            home: const CalendarScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Calendar'), findsOneWidget);
      expect(find.text('+ Holiday'), findsOneWidget);
      expect(find.text('+ Extra Class'), findsOneWidget);

      expect(find.text('Machine Learning'), findsOneWidget);
      expect(find.text('Present'), findsOneWidget);

      await tester.tap(find.text('Machine Learning'));
      await tester.pumpAndSettle();

      expect(find.text('MARK ATTENDANCE'), findsOneWidget);
      expect(find.text('SCHEDULE ACTIONS'), findsOneWidget);
      expect(find.text('Change room / time for this date only'), findsOneWidget);
      expect(find.text('Manage rooms for this subject'), findsOneWidget);
      expect(find.text('Edit this weekly slot permanently'), findsOneWidget);
      expect(find.text('Remove from this date only'), findsOneWidget);
    });

    testWidgets('7. Classic Theme isolates and preserves original layouts', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeSemesterProvider.overrideWith((ref) => FakeActiveSemesterNotifier(sampleSem)),
            holidaysProvider.overrideWith((ref) => FakeHolidaysNotifier([])),
            resolvedDayScheduleProvider.overrideWith((ref, date) => [sampleSession]),
          ],
          child: MaterialApp(
            theme: getClassicTheme(),
            home: const CalendarScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Calendar'), findsOneWidget);
    });
  });
}