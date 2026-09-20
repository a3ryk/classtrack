import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:classtrack/core/constants/app_theme.dart';
import 'package:classtrack/data/database/app_database.dart';
import 'package:classtrack/domain/entities/attendance_stats.dart';
import 'package:classtrack/domain/entities/semester_entity.dart';
import 'package:classtrack/domain/entities/subject_entity.dart';
import 'package:classtrack/domain/services/schedule_engine.dart';
import 'package:classtrack/presentation/providers/app_state_provider.dart';
import 'package:classtrack/presentation/screens/attendance/attendance_screen.dart';
import 'package:classtrack/presentation/screens/schedule/add_edit_subject_screen.dart';
import 'package:classtrack/presentation/widgets/sprout_what_if_simulator_sheet.dart';

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

  final sampleSubject1 = SubjectEntity(
    id: 'sub-1',
    semesterId: 'sem-active',
    name: 'Algorithms & Data Structures',
    code: 'CS201',
    category: 'CORE',
    credits: 4,
    targetAttendancePct: 75.0,
    baselineHeld: 10,
    baselineAttended: 9,
    isArchived: false,
    colorHex: '#2E5A36',
    components: [],
  );

  final sampleSubject2 = SubjectEntity(
    id: 'sub-2',
    semesterId: 'sem-active',
    name: 'Operating Systems',
    code: 'CS202',
    category: 'MAJOR',
    credits: 3,
    targetAttendancePct: 75.0,
    baselineHeld: 10,
    baselineAttended: 6,
    isArchived: false,
    colorHex: '#C94A29',
    components: [],
  );

  final sampleSlot1 = TimetableSlotItem(
    id: 'slot-1',
    semesterId: 'sem-active',
    subjectComponentId: 'sub-1',
    subjectName: 'Algorithms & Data Structures',
    subjectCode: 'CS201',
    category: 'CORE',
    componentType: 'LECTURE',
    colorHex: '#2E5A36',
    dayOfWeek: 1,
    startTime: '09:00',
    endTime: '10:00',
    room: 'Lab 3',
    teacherName: 'Prof. Hopper',
  );

  final mockStats = OverallAttendanceStats(
    totalHeld: 20,
    totalAttended: 15,
    totalAbsent: 5,
    totalCancelled: 0,
    totalPending: 0,
    overallPercentage: 75.0,
    targetPercentage: 75.0,
    marginClassesToMiss: 0,
    requiredClassesToAttend: 0,
    subjectStats: [
      SubjectAttendanceStats(
        subjectId: 'sub-1',
        subjectName: 'Algorithms & Data Structures',
        subjectCode: 'CS201',
        category: 'CORE',
        colorHex: '#2E5A36',
        totalHeld: 10,
        totalAttended: 9,
        totalAbsent: 1,
        totalCancelled: 0,
        totalPending: 0,
        currentPercentage: 90.0,
        targetPercentage: 75.0,
        marginClassesToMiss: 2,
        requiredClassesToAttend: 0,
        status: SubjectAttendanceStatus.safe,
      ),
      SubjectAttendanceStats(
        subjectId: 'sub-2',
        subjectName: 'Operating Systems',
        subjectCode: 'CS202',
        category: 'MAJOR',
        colorHex: '#C94A29',
        totalHeld: 10,
        totalAttended: 6,
        totalAbsent: 4,
        totalCancelled: 0,
        totalPending: 0,
        currentPercentage: 60.0,
        targetPercentage: 75.0,
        marginClassesToMiss: 0,
        requiredClassesToAttend: 6,
        status: SubjectAttendanceStatus.critical,
      ),
    ],
  );

  Widget createAttendanceWidget({bool isCute = true}) {
    return ProviderScope(
      overrides: [
        activeSemesterProvider.overrideWith((ref) => FakeActiveSemesterNotifier(sampleSem)),
        subjectsProvider.overrideWith((ref) => FakeSubjectsNotifier(
              AppDatabase.inMemory(),
              'sem-active',
              ref,
              initialSubs: [sampleSubject1, sampleSubject2],
            )),
        timetableSlotsProvider.overrideWith((ref) => FakeTimetableSlotsNotifier([sampleSlot1])),
        overallStatsProvider.overrideWithValue(mockStats),
      ],
      child: MaterialApp(
        theme: isCute ? getCuteTheme() : getClassicTheme(),
        home: const AttendanceScreen(),
      ),
    );
  }

  Widget createSimulatorWidget() {
    return ProviderScope(
      overrides: [
        overallStatsProvider.overrideWithValue(mockStats),
        subjectsProvider.overrideWith((ref) => FakeSubjectsNotifier(
              AppDatabase.inMemory(),
              'sem-active',
              ref,
              initialSubs: [sampleSubject1, sampleSubject2],
            )),
      ],
      child: MaterialApp(
        theme: getCuteTheme(),
        home: const Scaffold(
          body: SproutWhatIfSimulatorSheet(),
        ),
      ),
    );
  }

  Widget createAddSubjectWidget({bool isCute = true, SubjectEntity? existing}) {
    return ProviderScope(
      overrides: [
        activeSemesterProvider.overrideWith((ref) => FakeActiveSemesterNotifier(sampleSem)),
        subjectsProvider.overrideWith((ref) => FakeSubjectsNotifier(
              AppDatabase.inMemory(),
              'sem-active',
              ref,
              initialSubs: [sampleSubject1, sampleSubject2],
            )),
      ],
      child: MaterialApp(
        theme: isCute ? getCuteTheme() : getClassicTheme(),
        home: AddEditSubjectScreen(existingSubject: existing),
      ),
    );
  }

  final emojiRegex = RegExp(
    r'[\u{1F300}-\u{1F64F}\u{1F680}-\u{1F6FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F900}-\u{1F9FF}\u{1F1E0}-\u{1F1FF}]',
    unicode: true,
  );

  group('Sprouts Analytics Suite - AttendanceScreen', () {
    testWidgets('Renders Sprouts Analytics layout with hero gauge and breakdown', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      await tester.pumpWidget(createAttendanceWidget(isCute: true));
      await tester.pumpAndSettle();

      // Header
      expect(find.text('Analytics'), findsOneWidget);

      // Hero Card
      expect(find.text('Safe & Thriving'), findsOneWidget);
      expect(find.text('15 of 20 classes attended'), findsOneWidget);
      expect(find.textContaining("Sprout's Tip:"), findsOneWidget);

      // What-If Banner
      expect(find.text('Planning a Leave or Break?'), findsOneWidget);

      // Breakdown Section
      expect(find.textContaining('SUBJECT BREAKDOWN'), findsOneWidget);
      expect(find.text('Algorithms & Data Structures'), findsOneWidget);
      expect(find.text('Operating Systems'), findsOneWidget);
      expect(find.text('90.0%'), findsOneWidget);
      expect(find.text('60.0%'), findsOneWidget);

      // Room badge & cushions
      expect(find.textContaining('Lab 3'), findsOneWidget);
      expect(find.text('Safe: +2 can miss'), findsOneWidget);
      expect(find.text('Must attend next 6'), findsOneWidget);

      // Zero emoji guarantee
      final allTexts = tester.widgetList<Text>(find.byType(Text));
      for (final t in allTexts) {
        final textData = t.data ?? '';
        expect(emojiRegex.hasMatch(textData), isFalse,
            reason: 'Found emoji in AttendanceScreen text: "$textData"');
      }
    });

    testWidgets('Tapping what-if banner opens simulator sheet', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      await tester.pumpWidget(createAttendanceWidget(isCute: true));
      await tester.pumpAndSettle();

      final banner = find.text('Planning a Leave or Break?');
      expect(banner, findsOneWidget);
      await tester.tap(banner);
      await tester.pumpAndSettle();

      expect(find.byType(SproutWhatIfSimulatorSheet), findsOneWidget);
      expect(find.text('Done Simulating'), findsOneWidget);
    });

    testWidgets('Sprouts Analytics sub-navigation switches to Trends tab with charts, rhythm, and streak', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      await tester.pumpWidget(createAttendanceWidget(isCute: true));
      await tester.pumpAndSettle();

      // Sub-nav tabs are visible
      final overviewTab = find.text('Overview');
      final trendsTab = find.text('Trends');
      expect(overviewTab, findsOneWidget);
      expect(trendsTab, findsOneWidget);

      // Tap Trends tab
      await tester.tap(trendsTab);
      await tester.pumpAndSettle();

      // Timeframe pills
      expect(find.text('Past 4 Weeks'), findsOneWidget);
      expect(find.text('Past 8 Weeks'), findsOneWidget);
      expect(find.text('Full Semester'), findsOneWidget);

      // Streak & consistency hero card
      expect(find.textContaining('Classes In a Row'), findsOneWidget);
      expect(find.textContaining('% Consistency'), findsOneWidget);

      // Weekly Trajectory Chart
      expect(find.text('WEEKLY ATTENDANCE TRAJECTORY'), findsOneWidget);
      expect(find.text('75% Target'), findsOneWidget);

      // Day-of-Week Rhythm
      expect(find.text('DAY-OF-WEEK RHYTHM'), findsOneWidget);
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Best'), findsOneWidget);

      // Subject Momentum
      expect(find.text('SUBJECT MOMENTUM (PAST 4 WEEKS)'), findsOneWidget);
      expect(find.text('Algorithms & Data Structures'), findsOneWidget);
      expect(find.text('Operating Systems'), findsOneWidget);

      // Mascot Advice
      expect(find.text('Mascot Weekly Advice'), findsOneWidget);

      // Tap timeframe pills
      await tester.tap(find.text('Past 8 Weeks'));
      await tester.pumpAndSettle();
      expect(find.text('SUBJECT MOMENTUM (PAST 8 WEEKS)'), findsOneWidget);

      // Switch back to Overview
      await tester.tap(overviewTab);
      await tester.pumpAndSettle();
      expect(find.textContaining('SUBJECT BREAKDOWN'), findsOneWidget);

      // Zero emoji guarantee in Trends tab
      final allTexts = tester.widgetList<Text>(find.byType(Text));
      for (final t in allTexts) {
        final textData = t.data ?? '';
        expect(emojiRegex.hasMatch(textData), isFalse,
            reason: 'Found emoji in Trends Tab text: "$textData"');
      }
    });

    testWidgets('Classic theme preserves standard AttendanceScreen layout', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      await tester.pumpWidget(createAttendanceWidget(isCute: false));
      await tester.pumpAndSettle();

      expect(find.text('Analytics'), findsOneWidget);
      expect(find.text('SUBJECT-WISE BREAKDOWN'), findsOneWidget);
      expect(find.text('Planning to take leave?'), findsOneWidget);
      expect(find.text('Algorithms & Data Structures'), findsOneWidget);
    });
  });

  group('Sprouts Analytics Suite - SproutWhatIfSimulatorSheet', () {
    testWidgets('Supports Miss vs Attend mode toggle and stepper calculation', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      await tester.pumpWidget(createSimulatorWidget());
      await tester.pumpAndSettle();

      expect(find.text('What-If Simulator'), findsOneWidget);
      expect(find.text('Miss Classes'), findsOneWidget);
      expect(find.text('Attend Classes'), findsOneWidget);

      // Initial stepper count = 1 (min = 1, max = 30)
      expect(find.text('1'), findsOneWidget);
      expect(find.text('Upcoming Classes to Miss'), findsOneWidget);

      // Tap '+' to increment to 2
      final addBtn = find.byIcon(Icons.add_rounded);
      await tester.tap(addBtn);
      await tester.pumpAndSettle();
      expect(find.text('2'), findsOneWidget);

      // Tap '-' to decrement back to 1
      final removeBtn = find.byIcon(Icons.remove_rounded);
      await tester.tap(removeBtn);
      await tester.pumpAndSettle();
      expect(find.text('1'), findsOneWidget);

      // Tap 'Attend Classes' mode
      final attendTab = find.text('Attend Classes');
      await tester.tap(attendTab);
      await tester.pumpAndSettle();
      expect(find.text('Extra Classes to Attend'), findsOneWidget);

      // Done button
      expect(find.text('Done Simulating'), findsOneWidget);

      // Zero emoji guarantee
      final allTexts = tester.widgetList<Text>(find.byType(Text));
      for (final t in allTexts) {
        final textData = t.data ?? '';
        expect(emojiRegex.hasMatch(textData), isFalse,
            reason: 'Found emoji in SproutWhatIfSimulatorSheet: "$textData"');
      }
    });
  });

  group('Sprouts Analytics Suite - AddEditSubjectScreen', () {
    testWidgets('Renders Sprouts Add New Subject form with palette and category pills', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      await tester.pumpWidget(createAddSubjectWidget(isCute: true));
      await tester.pumpAndSettle();

      expect(find.text('Add New Subject'), findsOneWidget);
      expect(find.text('SUBJECT NAME'), findsOneWidget);
      expect(find.text('COURSE CODE'), findsOneWidget);
      expect(find.text('CREDITS'), findsOneWidget);
      expect(find.text('COLOR THEME'), findsOneWidget);
      expect(find.text('COURSE CATEGORY'), findsOneWidget);
      expect(find.text('CORE'), findsOneWidget);
      expect(find.text('MID-SEMESTER BASELINE (OPTIONAL)'), findsOneWidget);
      expect(find.text('Save Subject'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Zero emoji guarantee
      final allTexts = tester.widgetList<Text>(find.byType(Text));
      for (final t in allTexts) {
        final textData = t.data ?? '';
        expect(emojiRegex.hasMatch(textData), isFalse,
            reason: 'Found emoji in AddEditSubjectScreen: "$textData"');
      }
    });

    testWidgets('Renders Sprouts Edit Subject screen with existing data', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      await tester.pumpWidget(createAddSubjectWidget(isCute: true, existing: sampleSubject1));
      await tester.pumpAndSettle();

      expect(find.text('Edit Subject'), findsOneWidget);
      expect(find.text('Algorithms & Data Structures'), findsOneWidget);
      expect(find.text('CS201'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    });

    testWidgets('Classic theme preserves standard AddEditSubjectScreen layout', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      await tester.pumpWidget(createAddSubjectWidget(isCute: false));
      await tester.pumpAndSettle();

      expect(find.text('Add New Subject'), findsOneWidget);
      expect(find.text('SUBJECT NAME:'), findsOneWidget);
      expect(find.text('COURSE CODE:'), findsOneWidget);
      expect(find.text('Add Subject'), findsOneWidget);
    });
  });
}
