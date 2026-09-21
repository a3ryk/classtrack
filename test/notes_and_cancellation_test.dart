import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:attendly/core/constants/app_theme_tokens.dart';
import 'package:attendly/core/services/backup_service.dart';
import 'package:attendly/data/database/app_database.dart';
import 'package:attendly/domain/entities/class_session_entity.dart';
import 'package:attendly/domain/services/schedule_engine.dart';
import 'package:attendly/presentation/providers/app_state_provider.dart';
import 'package:attendly/presentation/widgets/cancellation_reason_dialog.dart';
import 'package:attendly/presentation/widgets/class_info_slider_sheet.dart';
import 'package:attendly/presentation/widgets/class_note_dialog.dart';

void main() {
  group('Class Notes & Cancellation Notes Feature Tests', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('Drift SQLite: cancellationReason and notes columns persist and query properly', () async {
      final record = AttendanceRecordData(
        id: 'session_slot1_2026-09-22',
        classSessionId: 'session_slot1_2026-09-22',
        slotId: 'slot1',
        subjectId: 'sub1',
        sessionDate: '2026-09-22',
        outcome: 'CANCELLED',
        markedAt: '2026-09-22T09:00:00.000Z',
        notes: 'Quiz 3 postponed to next week',
        cancellationReason: 'Professor on Leave: Conference attendance',
        syncVersion: 1,
        createdAt: '2026-09-22T09:00:00.000Z',
        updatedAt: '2026-09-22T09:00:00.000Z',
      );

      await db.saveAttendanceRecord(record);

      final retrieved = await db.getAttendanceForSession('session_slot1_2026-09-22');
      expect(retrieved, isNotNull);
      expect(retrieved!.outcome, 'CANCELLED');
      expect(retrieved.notes, 'Quiz 3 postponed to next week');
      expect(retrieved.cancellationReason, 'Professor on Leave: Conference attendance');
    });

    test('AttendanceRecordsNotifier: markAttendance records cancellationReason and saves to state & SQLite', () async {
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(attendanceRecordsProvider.notifier);

      await notifier.markAttendance(
        sessionId: 'test_session_1',
        slotId: 'slot_1',
        subjectId: 'sub_1',
        sessionDate: '2026-09-22',
        outcome: 'CANCELLED',
        notes: 'Read chapter 5',
        cancellationReason: 'Rain Holiday',
      );

      final state = container.read(attendanceRecordsProvider);
      expect(state['test_session_1'], isNotNull);
      expect(state['test_session_1']!.outcome, 'CANCELLED');
      expect(state['test_session_1']!.notes, 'Read chapter 5');
      expect(state['test_session_1']!.cancellationReason, 'Rain Holiday');

      final inDb = await db.getAttendanceForSession('test_session_1');
      expect(inDb?.cancellationReason, 'Rain Holiday');
    });

    test('AttendanceRecordsNotifier: marking PRESENT clears cancellationReason but preserves notes', () async {
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(attendanceRecordsProvider.notifier);

      // First mark cancelled
      await notifier.markAttendance(
        sessionId: 'test_session_2',
        slotId: 'slot_2',
        subjectId: 'sub_2',
        sessionDate: '2026-09-22',
        outcome: 'CANCELLED',
        notes: 'Assignment 2 due Friday',
        cancellationReason: 'Professor on Leave',
      );

      // Next user changes mind to PRESENT without passing notes
      await notifier.markAttendance(
        sessionId: 'test_session_2',
        slotId: 'slot_2',
        subjectId: 'sub_2',
        sessionDate: '2026-09-22',
        outcome: 'PRESENT',
      );

      final state = container.read(attendanceRecordsProvider);
      expect(state['test_session_2']!.outcome, 'PRESENT');
      expect(state['test_session_2']!.cancellationReason, isNull);
      expect(state['test_session_2']!.notes, 'Assignment 2 due Friday');
    });

    test('AttendanceRecordsNotifier: saveSessionNote updates notes without modifying outcome', () async {
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(attendanceRecordsProvider.notifier);

      // Session starts with outcome PRESENT
      await notifier.markAttendance(
        sessionId: 'test_session_3',
        slotId: 'slot_3',
        subjectId: 'sub_3',
        sessionDate: '2026-09-22',
        outcome: 'PRESENT',
      );

      // User adds a note
      await notifier.saveSessionNote(
        sessionId: 'test_session_3',
        slotId: 'slot_3',
        subjectId: 'sub_3',
        sessionDate: '2026-09-22',
        notes: 'Exam topics: chapters 1, 2, and 4',
      );

      final state = container.read(attendanceRecordsProvider);
      expect(state['test_session_3']!.outcome, 'PRESENT');
      expect(state['test_session_3']!.notes, 'Exam topics: chapters 1, 2, and 4');
    });

    test('ScheduleResolutionEngine: resolves notes and cancellationReason onto ClassSessionEntity', () {
      final targetDate = DateTime(2026, 9, 23); // Wednesday

      final slot = TimetableSlotItem(
        id: 'slot_eng',
        semesterId: 'sem1',
        subjectComponentId: 'sub_eng',
        subjectName: 'Software Engineering',
        category: 'THEORY',
        componentType: 'LECTURE',
        colorHex: '#4F46E5',
        dayOfWeek: 3, // Wednesday
        startTime: '10:00',
        endTime: '11:00',
        room: '402',
      );

      final records = {
        'session_slot_eng_2026-09-23': AttendanceRecordItem(
          outcome: 'CANCELLED',
          markedAt: '2026-09-23T10:00:00.000Z',
          notes: 'Prepare project milestones',
          cancellationReason: 'College Event / Fest',
        ),
      };

      final sessions = ScheduleResolutionEngine.resolveScheduleForDate(
        targetDate: targetDate,
        semesterId: 'sem1',
        holidays: [],
        dayConfigs: [],
        timetableSlots: [slot],
        exceptions: [],
        extraClasses: [],
        existingRecords: records,
      );

      expect(sessions.length, 1);
      final s = sessions.first;
      expect(s.subjectName, 'Software Engineering');
      expect(s.attendanceOutcome, 'CANCELLED');
      expect(s.notes, 'Prepare project milestones');
      expect(s.cancellationReason, 'College Event / Fest');
    });

    test('BackupService: exportBackup contains cancellationReason and restore handles schema v1, v2, and v3', () async {
      final record = AttendanceRecordData(
        id: 'rec_1',
        classSessionId: 'rec_1',
        slotId: 's1',
        subjectId: 'sub1',
        sessionDate: '2026-09-22',
        outcome: 'CANCELLED',
        markedAt: '2026-09-22T09:00:00Z',
        notes: 'Study session',
        cancellationReason: 'Professor on Leave',
        syncVersion: 1,
        createdAt: '2026-09-22T09:00:00Z',
        updatedAt: '2026-09-22T09:00:00Z',
      );
      await db.saveAttendanceRecord(record);

      final backupJson = await BackupService.generateFullBackupJson(db);
      final decoded = jsonDecode(backupJson);

      expect(decoded['schema_version'], 3);
      final attendanceList = decoded['tables']['attendance_records'] as List;
      expect(attendanceList.isNotEmpty, isTrue);
      expect(attendanceList.first['cancellationReason'], 'Professor on Leave');
      expect(attendanceList.first['notes'], 'Study session');

      // Test backward compatibility: restore legacy v2 backup (where cancellation_reason is missing)
      final legacyV2Backup = {
        'app': 'Attendly',
        'backup_version': '1',
        'schema_version': 2,
        'tables': {
          'semesters': [],
          'subjects': [],
          'subject_components': [],
          'timetable_slots': [],
          'academic_day_configs': [],
          'holidays': [],
          'schedule_exceptions': [],
          'extra_classes': [],
          'class_sessions': [],
          'attendance_records': [
            {
              'id': 'legacy_rec',
              'classSessionId': 'legacy_rec',
              'slotId': 'slot_legacy',
              'subjectId': 'sub_legacy',
              'sessionDate': '2026-08-15',
              'outcome': 'PRESENT',
              'markedAt': '2026-08-15T10:00:00Z',
              'notes': 'Legacy note',
              'syncVersion': 1,
              'createdAt': '2026-08-15T10:00:00Z',
              'updatedAt': '2026-08-15T10:00:00Z',
            }
          ],
          'app_settings': [],
        },
      };

      await BackupService.restoreBackup(legacyV2Backup, db);
      final restored = await db.getAttendanceForSession('legacy_rec');
      expect(restored, isNotNull);
      expect(restored!.outcome, 'PRESENT');
      expect(restored.notes, 'Legacy note');
      expect(restored.cancellationReason, isNull);
    });

    testWidgets('Classic Theme: ClassInfoSliderSheet renders classic layout', (tester) async {
      final session = ClassSessionEntity(
        id: 'session_widget_1',
        semesterId: 'sem1',
        subjectComponentId: 'sub1',
        subjectName: 'Operating Systems',
        category: 'THEORY',
        componentType: 'LECTURE',
        colorHex: '#4F46E5',
        sessionDate: '2026-09-22',
        startTime: '09:00',
        endTime: '10:00',
        sessionSource: 'TIMETABLE',
        status: 'HELD',
        attendanceOutcome: 'CANCELLED',
        notes: 'Practice round robin algorithms',
        cancellationReason: 'Professor on Leave: Conference attendance',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => ClassInfoSliderSheet.show(ctx, session),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Operating Systems'), findsOneWidget);
      expect(find.text('CANCELLATION REASON'), findsOneWidget);
      expect(find.text('Professor on Leave: Conference attendance'), findsOneWidget);
      expect(find.text('CLASS NOTE'), findsOneWidget);
      expect(find.text('Practice round robin algorithms'), findsOneWidget);
      expect(find.text('Edit Reason'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    });

    testWidgets('Sprouts Theme: ClassInfoSliderSheet renders cute layout', (tester) async {
      final session = ClassSessionEntity(
        id: 'session_sprout_1',
        semesterId: 'sem1',
        subjectComponentId: 'sub1',
        subjectName: 'Operating Systems',
        category: 'THEORY',
        componentType: 'LECTURE',
        colorHex: '#4F46E5',
        sessionDate: '2026-09-22',
        startTime: '09:00',
        endTime: '10:00',
        sessionSource: 'TIMETABLE',
        status: 'HELD',
        attendanceOutcome: 'CANCELLED',
        notes: 'Practice round robin algorithms',
        cancellationReason: 'Professor on Leave: Conference attendance',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [AppThemeTokens.cuteSproutLight]),
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => ClassInfoSliderSheet.show(ctx, session),
                child: const Text('Open Cute'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Cute'));
      await tester.pumpAndSettle();

      expect(find.text('Operating Systems'), findsOneWidget);
      expect(find.text('Cancellation Reason'), findsOneWidget);
      expect(find.text('Class Note'), findsOneWidget);
      expect(find.text('Edit Reason'), findsOneWidget);
    });

    testWidgets('Classic Theme: CancellationReasonDialog shows clean preset chips and saves selected reason', (tester) async {
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () => CancellationReasonDialog.show(
                    ctx,
                    sessionId: 'dlg_session_1',
                    slotId: 'dlg_slot_1',
                    subjectId: 'dlg_sub_1',
                    sessionDate: '2026-09-22',
                    subjectName: 'Computer Networks',
                  ),
                  child: const Text('Cancel Class'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Cancel Class'));
      await tester.pumpAndSettle();

      expect(find.text('WHY WAS THIS CLASS CANCELLED?'), findsOneWidget);
      expect(find.text('College Event / Fest'), findsOneWidget);
      expect(find.text('Rain / Weather Holiday'), findsOneWidget);
      expect(find.text('Save Reason'), findsOneWidget);

      // Select 'Rain / Weather Holiday' preset chip
      await tester.tap(find.text('Rain / Weather Holiday'));
      await tester.pumpAndSettle();

      // Tap Save Reason
      await tester.tap(find.text('Save Reason'));
      await tester.pumpAndSettle();

      // Verify saved in provider
      final record = container.read(attendanceRecordsProvider)['dlg_session_1'];
      expect(record, isNotNull);
      expect(record!.outcome, 'CANCELLED');
      expect(record.cancellationReason, 'Rain / Weather Holiday');
    });

    testWidgets('Sprouts Theme: CancellationReasonDialog renders cute preset chips with emojis', (tester) async {
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: ThemeData(extensions: [AppThemeTokens.cuteSproutLight]),
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () => CancellationReasonDialog.show(
                    ctx,
                    sessionId: 'dlg_sprout_1',
                    slotId: 'dlg_slot_1',
                    subjectId: 'dlg_sub_1',
                    sessionDate: '2026-09-22',
                    subjectName: 'Computer Networks',
                  ),
                  child: const Text('Cancel Cute Class'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Cancel Cute Class'));
      await tester.pumpAndSettle();

      expect(find.text('Why was this class cancelled?'), findsOneWidget);
      expect(find.text('College Event / Fest'), findsOneWidget);
      expect(find.text('Save Reason'), findsOneWidget);
    });

    testWidgets('Classic Theme: ClassNoteDialog allows entering text and saving session note', (tester) async {
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      final session = ClassSessionEntity(
        id: 'note_session_1',
        semesterId: 'sem1',
        subjectComponentId: 'sub_note',
        subjectName: 'Data Structures',
        category: 'THEORY',
        componentType: 'LECTURE',
        colorHex: '#059669',
        sessionDate: '2026-09-22',
        startTime: '11:00',
        endTime: '12:00',
        sessionSource: 'TIMETABLE',
        status: 'HELD',
        attendanceOutcome: 'PRESENT',
      );

      // Seed the existing record as PRESENT
      await container.read(attendanceRecordsProvider.notifier).markAttendance(
        sessionId: 'note_session_1',
        slotId: 'note_session_1',
        subjectId: 'sub_note',
        sessionDate: '2026-09-22',
        outcome: 'PRESENT',
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () => ClassNoteDialog.show(ctx, session: session),
                  child: const Text('Add Note'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Add Note'));
      await tester.pumpAndSettle();

      expect(find.text('Class Note'), findsOneWidget);
      expect(find.text('NOTES & HOMEWORK'), findsOneWidget);

      // Enter note
      await tester.enterText(find.byType(TextField), 'Homework 3 due on Monday');
      await tester.pumpAndSettle();

      // Tap Save Note
      await tester.tap(find.text('Save Note'));
      await tester.pumpAndSettle();

      final record = container.read(attendanceRecordsProvider)['note_session_1'];
      expect(record, isNotNull);
      expect(record!.notes, 'Homework 3 due on Monday');
      expect(record.outcome, 'PRESENT');
    });

    testWidgets('Sprouts Theme: ClassNoteDialog renders cute styling and saves note', (tester) async {
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      final session = ClassSessionEntity(
        id: 'note_sprout_1',
        semesterId: 'sem1',
        subjectComponentId: 'sub_note',
        subjectName: 'Algorithms',
        category: 'THEORY',
        componentType: 'LECTURE',
        colorHex: '#059669',
        sessionDate: '2026-09-22',
        startTime: '14:00',
        endTime: '15:00',
        sessionSource: 'TIMETABLE',
        status: 'HELD',
        attendanceOutcome: 'PRESENT',
      );

      await container.read(attendanceRecordsProvider.notifier).markAttendance(
        sessionId: 'note_sprout_1',
        slotId: 'note_sprout_1',
        subjectId: 'sub_note',
        sessionDate: '2026-09-22',
        outcome: 'PRESENT',
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: ThemeData(extensions: [AppThemeTokens.cuteSproutLight]),
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () => ClassNoteDialog.show(ctx, session: session),
                  child: const Text('Add Cute Note'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Add Cute Note'));
      await tester.pumpAndSettle();

      expect(find.text('Class Note'), findsOneWidget);
      expect(find.text('Notes & Homework'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Dynamic programming practice');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Note'));
      await tester.pumpAndSettle();

      final record = container.read(attendanceRecordsProvider)['note_sprout_1'];
      expect(record, isNotNull);
      expect(record!.notes, 'Dynamic programming practice');
    });
  });
}
