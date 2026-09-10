import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:classtrack/data/database/app_database.dart';
import 'package:classtrack/domain/entities/semester_entity.dart';
import 'package:classtrack/presentation/providers/app_state_provider.dart';
import 'package:classtrack/presentation/widgets/archived_semester_report_sheet.dart';
import 'package:classtrack/presentation/widgets/semester_transition_wizard.dart';
import 'package:classtrack/presentation/screens/today/today_screen.dart';

void main() {
  group('Database Layer: Semester Transition & Archiving', () {
    test('copySelectedSubjectsToSemester resets baseline to 0 and generates unique IDs', () async {
      final db = AppDatabase.inMemory();
      final nowIso = DateTime.now().toIso8601String();

      await db.saveSemester(
        SemesterData(
          id: 'sem_old',
          name: 'Semester 1',
          startDate: '2026-01-01',
          endDate: '2026-05-30',
          defaultTargetPct: 75.0,
          status: 'ACTIVE',
          createdAt: nowIso,
          updatedAt: nowIso,
        ),
      );
      await db.saveSemester(
        SemesterData(
          id: 'sem_new',
          name: 'Semester 2',
          startDate: '2026-06-01',
          endDate: '2026-11-30',
          defaultTargetPct: 75.0,
          status: 'ACTIVE',
          createdAt: nowIso,
          updatedAt: nowIso,
        ),
      );

      // Insert 2 subjects in sem_old:
      // Sub 1: Math (baseline 10 held, 8 attended)
      // Sub 2: Physics (baseline 5 held, 4 attended)
      await db.saveSubject(
        SubjectData(
          id: 'sub_math',
          semesterId: 'sem_old',
          name: 'Mathematics',
          category: 'MAJOR',
          colorHex: '#4F46E5',
          targetAttendancePct: 75.0,
          baselineHeld: 10,
          baselineAttended: 8,
          credits: 3,
          isArchived: false,
          createdAt: nowIso,
          updatedAt: nowIso,
        ),
      );

      await db.saveSubject(
        SubjectData(
          id: 'sub_phys',
          semesterId: 'sem_old',
          name: 'Physics',
          category: 'MAJOR',
          colorHex: '#10B981',
          targetAttendancePct: 75.0,
          baselineHeld: 5,
          baselineAttended: 4,
          credits: 3,
          isArchived: false,
          createdAt: nowIso,
          updatedAt: nowIso,
        ),
      );

      // Only copy Mathematics to sem_new
      await db.copySelectedSubjectsToSemester(
        'sem_old',
        'sem_new',
        ['sub_math'],
      );

      // Verify sem_new subjects
      final newSubjects = await db.getAllSubjects('sem_new');
      expect(newSubjects.length, equals(1));
      final copiedMath = newSubjects.first;
      expect(copiedMath.name, equals('Mathematics'));
      expect(copiedMath.id, isNot(equals('sub_math'))); // fresh unique ID
      expect(copiedMath.baselineAttended, equals(0)); // fresh zero counter
      expect(copiedMath.baselineHeld, equals(0)); // fresh zero counter
      expect(copiedMath.semesterId, equals('sem_new'));

      // Verify sem_old subjects and counts remain untouched
      final oldSubjects = await db.getAllSubjects('sem_old');
      expect(oldSubjects.length, equals(2));
      final oldMath = oldSubjects.firstWhere((s) => s.id == 'sub_math');
      expect(oldMath.baselineAttended, equals(8));
      expect(oldMath.baselineHeld, equals(10));

      await db.close();
    });

    test('archiveAndTransitionSemester atomically updates statuses and active semester ID', () async {
      final db = AppDatabase.inMemory();
      final nowIso = DateTime.now().toIso8601String();

      await db.saveSemester(
        SemesterData(
          id: 'sem_1',
          name: 'Semester 1',
          startDate: '2026-01-01',
          endDate: '2026-05-30',
          defaultTargetPct: 75.0,
          status: 'ACTIVE',
          createdAt: nowIso,
          updatedAt: nowIso,
        ),
      );
      await db.setSetting('active_semester_id', 'sem_1');

      final newSem = SemesterData(
        id: 'sem_2',
        name: 'Semester 2',
        startDate: '2026-06-01',
        endDate: '2026-11-30',
        defaultTargetPct: 75.0,
        status: 'ACTIVE',
        createdAt: nowIso,
        updatedAt: nowIso,
      );

      await db.archiveAndTransitionSemester(
        oldSemesterId: 'sem_1',
        newSemester: newSem,
        carryOverSubjectIds: [],
      );

      // Verify old semester status is ARCHIVED
      final allSemesters = await db.getAllSemestersAll();
      final oldSem = allSemesters.firstWhere((s) => s.id == 'sem_1');
      expect(oldSem.status, equals('ARCHIVED'));

      // Verify new semester is saved and ACTIVE
      final createdSem = allSemesters.firstWhere((s) => s.id == 'sem_2');
      expect(createdSem.status, equals('ACTIVE'));
      expect(createdSem.name, equals('Semester 2'));

      // Verify active_semester_id setting is updated
      final activeSetting = await db.getSetting('active_semester_id');
      expect(activeSetting, equals('sem_2'));

      await db.close();
    });
  });

  group('Provider Layer: Transition & Stats', () {
    test('SemestersListNotifier.transitionSemester updates active semester and reloads list', () async {
      final db = AppDatabase.inMemory();
      final nowIso = DateTime.now().toIso8601String();

      await db.saveSemester(
        SemesterData(
          id: 'sem_old',
          name: 'Semester 1',
          startDate: '2026-01-01',
          endDate: '2026-05-30',
          defaultTargetPct: 75.0,
          status: 'ACTIVE',
          createdAt: nowIso,
          updatedAt: nowIso,
        ),
      );
      await db.setSetting('active_semester_id', 'sem_old');

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
      );

      // Load initial semesters
      await container.read(semestersListProvider.notifier).loadFromDb();
      final semOldEntity = container.read(semestersListProvider).first;
      container.read(activeSemesterProvider.notifier).updateSemester(semOldEntity);

      expect(container.read(activeSemesterProvider).id, equals('sem_old'));
      expect(container.read(activeSemesterProvider).isArchived, isFalse);

      // Perform transition
      final newSem = SemesterEntity(
        id: 'sem_new',
        name: 'Semester 2',
        startDate: DateTime(2026, 6, 1),
        endDate: DateTime(2026, 11, 30),
        academicYear: '2026-2027',
        termType: TermType.semester,
        isCurrent: true,
        isArchived: false,
      );

      await container.read(semestersListProvider.notifier).transitionSemester(
        newSemester: newSem,
        carryOverSubjectIds: [],
      );

      // Active semester should now be sem_new
      expect(container.read(activeSemesterProvider).id, equals('sem_new'));
      expect(container.read(activeSemesterProvider).name, equals('Semester 2'));

      // Old semester should be marked archived in list
      final list = container.read(semestersListProvider);
      final archivedSem = list.firstWhere((s) => s.id == 'sem_old');
      expect(archivedSem.isArchived, isTrue);

      container.dispose();
      await db.close();
    });

    test('archivedSemesterStatsProvider returns correct stats without mutating activeSemester', () async {
      final db = AppDatabase.inMemory();
      final nowIso = DateTime.now().toIso8601String();

      await db.saveSemester(
        SemesterData(
          id: 'sem_archived',
          name: 'Semester 1',
          startDate: '2026-01-01',
          endDate: '2026-05-30',
          defaultTargetPct: 75.0,
          status: 'ARCHIVED',
          createdAt: nowIso,
          updatedAt: nowIso,
        ),
      );
      await db.saveSemester(
        SemesterData(
          id: 'sem_active',
          name: 'Semester 2',
          startDate: '2026-06-01',
          endDate: '2026-11-30',
          defaultTargetPct: 80.0,
          status: 'ACTIVE',
          createdAt: nowIso,
          updatedAt: nowIso,
        ),
      );

      await db.saveSubject(
        SubjectData(
          id: 'sub_archived',
          semesterId: 'sem_archived',
          name: 'Data Structures',
          category: 'MAJOR',
          colorHex: '#4F46E5',
          targetAttendancePct: 75.0,
          baselineHeld: 20,
          baselineAttended: 18,
          credits: 3,
          isArchived: false,
          createdAt: nowIso,
          updatedAt: nowIso,
        ),
      );

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
      );

      // Set active semester to sem_active
      final activeEntity = SemesterEntity(
        id: 'sem_active',
        name: 'Semester 2',
        startDate: DateTime(2026, 6, 1),
        endDate: DateTime(2026, 11, 30),
        academicYear: '2026-2027',
        termType: TermType.semester,
        isCurrent: true,
        isArchived: false,
      );
      container.read(activeSemesterProvider.notifier).updateSemester(activeEntity);

      // Query archived stats
      final stats = await container.read(archivedSemesterStatsProvider('sem_archived').future);
      expect(stats.totalHeld, equals(20));
      expect(stats.totalAttended, equals(18));
      expect(stats.overallPercentage, equals(90.0));
      expect(stats.subjectStats.first.subjectName, equals('Data Structures'));

      // Active semester remains sem_active completely untouched
      expect(container.read(activeSemesterProvider).id, equals('sem_active'));

      container.dispose();
      await db.close();
    });

    test('dismissedEndOfTermProvider persists dismissal to SQLite app_settings', () async {
      final db = AppDatabase.inMemory();
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
      );

      expect(container.read(dismissedEndOfTermProvider).contains('sem_1'), isFalse);

      await container.read(dismissedEndOfTermProvider.notifier).dismiss('sem_1');

      expect(container.read(dismissedEndOfTermProvider).contains('sem_1'), isTrue);

      // Verify persistence in SQLite
      final rawSetting = await db.getSetting('dismissed_end_of_term_ids');
      expect(rawSetting, contains('sem_1'));

      container.dispose();
      await db.close();
    });
  });

  group('Widget Tests: ArchivedSemesterReportSheet', () {
    testWidgets('renders archived semester performance breakdown and handles reactivation', (tester) async {
      final db = AppDatabase.inMemory();
      final nowIso = DateTime.now().toIso8601String();

      final archivedSem = SemesterEntity(
        id: 'sem_archived_1',
        name: 'Semester I',
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 5, 30),
        academicYear: '2025-2026',
        termType: TermType.semester,
        isCurrent: false,
        isArchived: true,
      );

      await db.saveSemester(
        SemesterData(
          id: archivedSem.id,
          name: archivedSem.name,
          startDate: '2026-01-01',
          endDate: '2026-05-30',
          defaultTargetPct: 75.0,
          status: 'ARCHIVED',
          createdAt: nowIso,
          updatedAt: nowIso,
        ),
      );

      await db.saveSubject(
        SubjectData(
          id: 'sub_archived_math',
          semesterId: archivedSem.id,
          name: 'Calculus I',
          category: 'MAJOR',
          colorHex: '#4F46E5',
          targetAttendancePct: 75.0,
          baselineHeld: 30,
          baselineAttended: 26,
          credits: 3,
          isArchived: false,
          createdAt: nowIso,
          updatedAt: nowIso,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ArchivedSemesterReportSheet(semester: archivedSem),
            ),
          ),
        ),
      );

      // Let async stats provider load
      await tester.pumpAndSettle();

      expect(find.text('Semester I'), findsWidgets);
      expect(find.text('ARCHIVED'), findsWidgets);
      expect(find.text('TARGET MET'), findsOneWidget);
      expect(find.text('Calculus I'), findsOneWidget);
      expect(find.text('26/30 attended'), findsOneWidget);
      expect(find.text('Reactivate as Operational Term'), findsOneWidget);

      // Tap Reactivate button
      await tester.tap(find.text('Reactivate as Operational Term'));
      await tester.pumpAndSettle();

      // Expect confirmation dialog
      expect(find.text('Reactivate Semester I?'), findsOneWidget);
      expect(find.text('Reactivate Term'), findsOneWidget);

      await db.close();
    });
  });

  group('Widget Tests: SemesterTransitionWizard', () {
    testWidgets('steps through Step 0 (Report Card) -> Step 1 (Configure) -> Step 2 (Subjects) -> Complete', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final db = AppDatabase.inMemory();
      final nowIso = DateTime.now().toIso8601String();

      final currentSem = SemesterEntity(
        id: 'sem_active_1',
        name: 'Semester 3',
        startDate: DateTime.now().subtract(const Duration(days: 120)),
        endDate: DateTime.now().subtract(const Duration(days: 5)), // Ended 5 days ago
        academicYear: '2026-2027',
        termType: TermType.semester,
        isCurrent: true,
        isArchived: false,
      );

      await db.saveSemester(
        SemesterData(
          id: currentSem.id,
          name: currentSem.name,
          startDate: '2026-01-01',
          endDate: '2026-05-30',
          defaultTargetPct: 75.0,
          status: 'ACTIVE',
          createdAt: nowIso,
          updatedAt: nowIso,
        ),
      );

      await db.saveSubject(
        SubjectData(
          id: 'sub_algo',
          semesterId: currentSem.id,
          name: 'Algorithms',
          category: 'MAJOR',
          colorHex: '#6366F1',
          targetAttendancePct: 75.0,
          baselineHeld: 25,
          baselineAttended: 22,
          credits: 3,
          isArchived: false,
          createdAt: nowIso,
          updatedAt: nowIso,
        ),
      );

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
      );

      container.read(activeSemesterProvider.notifier).updateSemester(currentSem);
      await container.read(semestersListProvider.notifier).loadFromDb();
      await container.read(subjectsProvider.notifier).loadFromDb();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SemesterTransitionWizard(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Step 0: Milestone Report Card
      expect(find.text('CLOSING TERM: SEMESTER 3'), findsOneWidget);
      expect(find.text('Algorithms'), findsOneWidget);
      expect(find.text('22/25 attended'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);

      // Advance to Step 1: Configure
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Step 2 of 3: Configure your next academic term'), findsOneWidget);
      expect(find.text('TERM NAME'), findsOneWidget);
      // Smart sequential sequencer suggests Semester 4 for Semester 3
      final nameField = find.byType(TextFormField).first;
      expect((tester.widget(nameField) as TextFormField).controller?.text, equals('Semester 4'));
      expect(find.text('Continue'), findsOneWidget);

      // Advance to Step 2: Subject Setup
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Step 3 of 3: Select continuing subjects or start fresh'), findsOneWidget);
      expect(find.text('Carry Forward Subjects'), findsOneWidget);
      expect(find.text('Start Fresh (Blank)'), findsOneWidget);
      expect(find.text('Algorithms'), findsOneWidget);

      // Test Deselect and Select All
      await tester.tap(find.text('Deselect'));
      await tester.pumpAndSettle();
      expect(find.text('SELECT SUBJECTS (0/1)'), findsOneWidget);

      await tester.tap(find.text('Select All'));
      await tester.pumpAndSettle();
      expect(find.text('SELECT SUBJECTS (1/1)'), findsOneWidget);

      // Test Complete Transition
      expect(find.text('Archive & Launch New Term'), findsOneWidget);
      await tester.tap(find.text('Archive & Launch New Term'));
      await tester.pumpAndSettle();

      // Verify active semester switched to Semester 4
      expect(container.read(activeSemesterProvider).name, equals('Semester 4'));

      container.dispose();
      await db.close();
    });
  });

  group('Widget Tests: TodayScreen End-of-Term Banner', () {
    testWidgets('renders End-of-Term banner when term is expired and allows dismissal', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final db = AppDatabase.inMemory();
      final nowIso = DateTime.now().toIso8601String();

      // Expired semester (ended yesterday)
      final expiredSem = SemesterEntity(
        id: 'sem_expired',
        name: 'Spring 2026',
        startDate: DateTime.now().subtract(const Duration(days: 90)),
        endDate: DateTime.now().subtract(const Duration(days: 1)),
        academicYear: '2025-2026',
        termType: TermType.semester,
        isCurrent: true,
        isArchived: false,
      );

      await db.saveSemester(
        SemesterData(
          id: expiredSem.id,
          name: expiredSem.name,
          startDate: expiredSem.startDate.toIso8601String(),
          endDate: expiredSem.endDate!.toIso8601String(),
          defaultTargetPct: 75.0,
          status: 'ACTIVE',
          createdAt: nowIso,
          updatedAt: nowIso,
        ),
      );
      await db.setSetting('active_semester_id', 'sem_expired');

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          appInitializationProvider.overrideWith((ref) => Future.value(true)),
          realtimeClockProvider.overrideWith((ref) => Stream.value(DateTime.now())),
        ],
      );

      container.read(activeSemesterProvider.notifier).updateSemester(expiredSem);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: TodayScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // End-of-term banner should be visible
      expect(find.text('Term Completed · Spring 2026'), findsOneWidget);
      expect(find.text('Transition Now'), findsOneWidget);

      // Find close icon and dismiss banner
      final closeIcon = find.byTooltip('Dismiss');
      await tester.tap(closeIcon);
      await tester.pumpAndSettle();

      // Banner should now be dismissed
      expect(find.text('Term Completed · Spring 2026'), findsNothing);
      expect(container.read(dismissedEndOfTermProvider).contains('sem_expired'), isTrue);

      container.dispose();
      await db.close();
    });
  });
}
