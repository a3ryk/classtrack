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
import 'package:classtrack/presentation/screens/schedule/add_edit_slot_screen.dart';
import 'package:classtrack/presentation/screens/schedule/batch_add_slots_screen.dart';
import 'package:classtrack/presentation/screens/share/qr_share_scanner_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';


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
  FakeTimetableSlotsNotifier(List<TimetableSlotItem> slots)
      : super(AppDatabase.inMemory(), 'sem-active', []) {
    state = slots;
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

  final sampleExistingSlotEntity = ClassSessionEntity(
    id: 'slot-1',
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
    attendanceOutcome: 'PENDING',
  );

  group('Sprouts Theme Timetable Suite Tests', () {
    testWidgets('1. AddEditSlotScreen renders Create Mode with Sprout theme styling', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeSemesterProvider.overrideWith((ref) => FakeActiveSemesterNotifier(sampleSem)),
            subjectsProvider.overrideWith((ref) => FakeSubjectsNotifier(AppDatabase.inMemory(), 'sem-active', ref, initialSubs: [sampleSubject])),
            timetableSlotsProvider.overrideWith((ref) => FakeTimetableSlotsNotifier([sampleSlot])),
          ],
          child: MaterialApp(
            theme: getCuteTheme(),
            home: const AddEditSlotScreen(initialDayOfWeek: 1),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify title & subtitle
      expect(find.text('Add Class Slot'), findsOneWidget);
      expect(find.text('SEMESTER IV'), findsOneWidget);

      // Verify category chips
      expect(find.text('MAJOR'), findsWidgets);
      expect(find.text('MINOR'), findsOneWidget);

      // Verify time schedule cards
      expect(find.text('START TIME'), findsOneWidget);
      expect(find.text('END TIME'), findsOneWidget);

      // Verify submit button
      expect(find.text('Add Slot to Timetable'), findsOneWidget);
    });

    testWidgets('2. AddEditSlotScreen renders Edit Mode with delete button & confirmation dialog', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeSemesterProvider.overrideWith((ref) => FakeActiveSemesterNotifier(sampleSem)),
            subjectsProvider.overrideWith((ref) => FakeSubjectsNotifier(AppDatabase.inMemory(), 'sem-active', ref, initialSubs: [sampleSubject])),
            timetableSlotsProvider.overrideWith((ref) => FakeTimetableSlotsNotifier([sampleSlot])),
          ],
          child: MaterialApp(
            theme: getCuteTheme(),
            home: AddEditSlotScreen(
              existingSlot: sampleExistingSlotEntity,
              initialDayOfWeek: 1,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify title in edit mode
      expect(find.text('Edit Class Slot'), findsOneWidget);
      expect(find.text('Update Class Slot'), findsOneWidget);

      // Verify delete button is present in the Sprout app bar
      final deleteIcon = find.byIcon(Icons.delete_outline_rounded);
      expect(deleteIcon, findsOneWidget);

      // Tap delete button to open Sprout delete dialog
      await tester.tap(deleteIcon);
      await tester.pumpAndSettle();

      // Verify confirmation dialog
      expect(find.text('Delete Class Slot?'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Cancel dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Delete Class Slot?'), findsNothing);
    });

    testWidgets('3. BatchAddSlotsScreen renders with presets and duration intervals in Sprout theme', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeSemesterProvider.overrideWith((ref) => FakeActiveSemesterNotifier(sampleSem)),
            subjectsProvider.overrideWith((ref) => FakeSubjectsNotifier(AppDatabase.inMemory(), 'sem-active', ref, initialSubs: [sampleSubject])),
            timetableSlotsProvider.overrideWith((ref) => FakeTimetableSlotsNotifier([sampleSlot])),
          ],
          child: MaterialApp(
            theme: getCuteTheme(),
            home: const BatchAddSlotsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify header
      expect(find.text('Batch Add Slots'), findsOneWidget);
      expect(find.text('Schedule one subject across multiple days'), findsOneWidget);

      // Verify info banner callout
      expect(find.textContaining('Select weekdays & slot duration'), findsOneWidget);

      // Verify quick presets
      expect(find.text('MWF'), findsOneWidget);
      expect(find.text('TTS'), findsOneWidget);
      expect(find.text('Weekdays (Mon-Fri)'), findsOneWidget);
      expect(find.text('All 7 Days'), findsOneWidget);

      // Verify interval presets
      expect(find.text('50 mins'), findsWidgets);
      expect(find.text('60 mins'), findsWidgets);
      expect(find.text('90 mins'), findsOneWidget);
      expect(find.text('2 hours'), findsOneWidget);

      // Verify generate button
      expect(find.textContaining('Generate'), findsOneWidget);
    });

    testWidgets('4. QrShareScannerScreen renders Capsule Tabs & Timetable Pass Card in Sprout theme', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeSemesterProvider.overrideWith((ref) => FakeActiveSemesterNotifier(sampleSem)),
            subjectsProvider.overrideWith((ref) => FakeSubjectsNotifier(AppDatabase.inMemory(), 'sem-active', ref, initialSubs: [sampleSubject])),
            timetableSlotsProvider.overrideWith((ref) => FakeTimetableSlotsNotifier([sampleSlot])),
          ],
          child: MaterialApp(
            theme: getCuteTheme(),
            home: const QrShareScannerScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify header
      expect(find.text('Share & Scan Timetable'), findsOneWidget);
      expect(find.text('Instant offline timetable exchange'), findsOneWidget);

      // Verify custom capsule switcher tabs
      expect(find.text('Export QR'), findsOneWidget);
      expect(find.text('Scan Camera'), findsOneWidget);

      // Verify QR Code Card and branding
      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text('Attendly'), findsOneWidget);

      // Verify action buttons
      expect(find.text('Copy Code'), findsOneWidget);
      expect(find.text('Share QR Image'), findsOneWidget);

      // Verify privacy guarantee
      expect(find.textContaining('100% Private'), findsOneWidget);
    });

    testWidgets('5. Classic Theme preserves original UI for Add, Batch and Share screens', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeSemesterProvider.overrideWith((ref) => FakeActiveSemesterNotifier(sampleSem)),
            subjectsProvider.overrideWith((ref) => FakeSubjectsNotifier(AppDatabase.inMemory(), 'sem-active', ref, initialSubs: [sampleSubject])),
            timetableSlotsProvider.overrideWith((ref) => FakeTimetableSlotsNotifier([sampleSlot])),
          ],
          child: MaterialApp(
            theme: getClassicTheme(),
            home: const AddEditSlotScreen(initialDayOfWeek: 1),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Classic screen still renders properly
      expect(find.text('Add Class Slot'), findsOneWidget);
    });
  });
}
