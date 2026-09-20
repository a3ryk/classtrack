import 'package:attendly/core/constants/app_theme.dart';
import 'package:attendly/data/database/app_database.dart';
import 'package:attendly/data/templates/programme_templates.dart';
import 'package:attendly/domain/entities/attendance_stats.dart';
import 'package:attendly/domain/entities/semester_entity.dart';
import 'package:attendly/domain/entities/user_profile_entity.dart';
import 'package:attendly/presentation/providers/app_state_provider.dart';
import 'package:attendly/presentation/widgets/archived_semester_report_sheet.dart';
import 'package:attendly/presentation/widgets/edit_semester_dialog.dart';
import 'package:attendly/presentation/widgets/semester_history_dialog.dart';
import 'package:attendly/presentation/widgets/semester_transition_wizard.dart';
import 'package:attendly/presentation/widgets/template_selector_dialog.dart';
import 'package:attendly/presentation/widgets/university_selector_dialog.dart';
import 'package:attendly/presentation/widgets/user_profile_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;

class FakeSubjectsNotifier extends SubjectsNotifier {
  FakeSubjectsNotifier(super.db, super.semesterId, super.ref) {
    state = [];
  }

  @override
  Future<void> loadFromDb() async {
    state = [];
  }
}

class FakeUserProfileNotifier extends UserProfileNotifier {
  FakeUserProfileNotifier() : super(AppDatabase.inMemory()) {
    state = const UserProfileEntity(
      studentName: 'Alex Johnson',
      rollNumber: '21BCSE042',
      enrollmentNumber: 'EN20210084',
      degreeProgramme: 'B.Tech Computer Science',
      department: 'School of Computing',
    );
  }
}

class FakeActiveSemesterNotifier extends ActiveSemesterNotifier {
  FakeActiveSemesterNotifier(SemesterEntity sem) : super(AppDatabase.inMemory()) {
    state = sem;
  }
}

class FakeSemestersListNotifier extends SemestersListNotifier {
  FakeSemestersListNotifier(List<SemesterEntity> sems) : super(AppDatabase.inMemory()) {
    state = sems;
  }
}

class FakeSelectedUniversityNotifier extends SelectedUniversityNotifier {
  FakeSelectedUniversityNotifier() : super(AppDatabase.inMemory()) {
    state = const UserUniversityInfo(
      state: 'Delhi (National Capital Territory)',
      universityName: 'University of Delhi (DU)',
      locationType: 'CAMPUS',
    );
  }
}

class FakeActiveTemplateNotifier extends ActiveTemplateNotifier {
  FakeActiveTemplateNotifier() : super(AppDatabase.inMemory()) {
    state = ProgrammeTemplates.noneTemplate;
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

  final sampleArchivedSem = SemesterEntity(
    id: 'sem-archived',
    name: 'Semester III',
    academicYear: '2025-2026',
    startDate: DateTime(2025, 8, 1),
    endDate: DateTime(2025, 12, 20),
    termType: TermType.semester,
    isArchived: true,
  );

  group('Sprouts Identity & Structure Slidders Suite Tests', () {
    testWidgets('UserProfileSheet renders Sprout layout with zero emojis in headers', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      final cuteThemeLight = AppTheme.buildTheme(
        brightness: Brightness.light,
        styleId: 'cute_sprout',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileProvider.overrideWith((ref) => FakeUserProfileNotifier()),
          ],
          child: MaterialApp(
            theme: cuteThemeLight,
            home: const Scaffold(
              body: UserProfileSheet(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Student Profile'), findsOneWidget);
      expect(find.text('STUDENT FULL NAME'), findsOneWidget);
      expect(find.text('Save Profile'), findsOneWidget);
      expect(find.textContaining('🎓'), findsNothing);
      expect(find.textContaining('✨'), findsNothing);
    });

    testWidgets('SemesterHistorySheet renders Sprout layout with active & archived terms', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      final cuteThemeLight = AppTheme.buildTheme(
        brightness: Brightness.light,
        styleId: 'cute_sprout',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeSemesterProvider.overrideWith((ref) => FakeActiveSemesterNotifier(sampleActiveSem)),
            semestersListProvider.overrideWith((ref) => FakeSemestersListNotifier([sampleActiveSem, sampleArchivedSem])),
          ],
          child: MaterialApp(
            theme: cuteThemeLight,
            home: const Scaffold(
              body: SemesterHistorySheet(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Academic History'), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget);
      expect(find.text('ARCHIVED'), findsOneWidget);
      expect(find.text('Start Next Term'), findsOneWidget);
      expect(find.text('Blank Term'), findsOneWidget);
    });

    testWidgets('EditSemesterDialog renders Sprout layout with term type pills & presets', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      final cuteThemeLight = AppTheme.buildTheme(
        brightness: Brightness.light,
        styleId: 'cute_sprout',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeSemesterProvider.overrideWith((ref) => FakeActiveSemesterNotifier(sampleActiveSem)),
          ],
          child: MaterialApp(
            theme: cuteThemeLight,
            home: Scaffold(
              body: EditSemesterDialog(semesterToEdit: sampleActiveSem),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit Academic Term'), findsOneWidget);
      expect(find.text('TERM STRUCTURE TYPE'), findsOneWidget);
      expect(find.text('QUICK PRESETS'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
    });

    testWidgets('ArchivedSemesterReportSheet renders Sprout layout with metrics and zero emojis', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      final cuteThemeDark = AppTheme.buildTheme(
        brightness: Brightness.dark,
        styleId: 'cute_sprout',
      );

      final fakeStats = OverallAttendanceStats(
        totalHeld: 120,
        totalAttended: 99,
        totalAbsent: 21,
        totalCancelled: 5,
        totalPending: 0,
        overallPercentage: 82.5,
        targetPercentage: 75.0,
        marginClassesToMiss: 8,
        requiredClassesToAttend: 0,
        subjectStats: [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            archivedSemesterStatsProvider('sem-archived').overrideWith((ref) => Future.value(fakeStats)),
          ],
          child: MaterialApp(
            theme: cuteThemeDark,
            home: Scaffold(
              body: ArchivedSemesterReportSheet(semester: sampleArchivedSem),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Semester III'), findsOneWidget);
      expect(find.text('ARCHIVED'), findsOneWidget);
      expect(find.text('FINAL ATTENDANCE'), findsOneWidget);
      expect(find.text('82.5%'), findsOneWidget);
      expect(find.text('Reactivate as Operational Term'), findsOneWidget);
      expect(find.textContaining('📊'), findsNothing);
    });

    testWidgets('UniversitySelectorSheet renders Sprout layout with 3-step configuration', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      final cuteThemeLight = AppTheme.buildTheme(
        brightness: Brightness.light,
        styleId: 'cute_sprout',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedUniversityProvider.overrideWith((ref) => FakeSelectedUniversityNotifier()),
          ],
          child: MaterialApp(
            theme: cuteThemeLight,
            home: const Scaffold(
              body: UniversitySelectorSheet(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('University & College'), findsOneWidget);
      expect(find.text('STEP 1: SELECT STATE / UT'), findsOneWidget);
      expect(find.text('STEP 3: CAMPUS TYPE'), findsOneWidget);
      expect(find.text('Main Campus'), findsOneWidget);
      expect(find.text('Affiliated College'), findsOneWidget);
      expect(find.text('Save University'), findsOneWidget);
    });

    testWidgets('TemplateSelectorSheet renders Sprout layout with curriculum options', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      final cuteThemeLight = AppTheme.buildTheme(
        brightness: Brightness.light,
        styleId: 'cute_sprout',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeTemplateProvider.overrideWith((ref) => FakeActiveTemplateNotifier()),
          ],
          child: MaterialApp(
            theme: cuteThemeLight,
            home: const Scaffold(
              body: TemplateSelectorSheet(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Curriculum Structure'), findsOneWidget);
      expect(find.text('Not Selected'), findsOneWidget);
      expect(find.textContaining('NEP 2020'), findsWidgets);
    });

    testWidgets('SemesterTransitionWizard renders Sprout multi-step layout with zero emojis in headers', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      final cuteThemeLight = AppTheme.buildTheme(
        brightness: Brightness.light,
        styleId: 'cute_sprout',
      );

      final fakeStats = OverallAttendanceStats(
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
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeSemesterProvider.overrideWith((ref) => FakeActiveSemesterNotifier(sampleActiveSem)),
            overallStatsProvider.overrideWithValue(fakeStats),
            subjectsProvider.overrideWith((ref) => FakeSubjectsNotifier(AppDatabase.inMemory(), 'sem-active', ref)),
          ],
          child: MaterialApp(
            theme: cuteThemeLight,
            home: const Scaffold(
              body: SemesterTransitionWizard(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Step 1: Wrap-Up
      expect(find.text('Semester Transition Wizard'), findsOneWidget);
      expect(find.text('Wrap-Up'), findsOneWidget);
      expect(find.text('New Term'), findsOneWidget);
      expect(find.text('Subjects'), findsOneWidget);
      expect(find.text('CLOSING TERM: SEMESTER IV'), findsOneWidget);
      expect(find.text('100.0%'), findsOneWidget);
      expect(find.text('GOAL ACHIEVED'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);

      // Advance to Step 2
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('TERM STRUCTURE TYPE'), findsOneWidget);
      expect(find.text('QUICK NAME PRESETS'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);

      // Advance to Step 3
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Carry Forward Subjects'), findsOneWidget);
      expect(find.text('Start Fresh (Blank)'), findsOneWidget);
      expect(find.text('Archive & Launch New Term'), findsOneWidget);
    });
  });
}
