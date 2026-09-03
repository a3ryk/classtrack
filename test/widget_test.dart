import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:classtrack/main.dart';
import 'package:classtrack/data/database/app_database.dart';
import 'package:classtrack/domain/services/attendance_math.dart';
import 'package:classtrack/domain/services/schedule_engine.dart';
import 'package:classtrack/domain/entities/semester_entity.dart';
import 'package:classtrack/presentation/providers/app_state_provider.dart';
import 'package:classtrack/core/services/app_update_service.dart';
import 'package:classtrack/core/services/backup_service.dart';
import 'package:classtrack/data/templates/programme_templates.dart';
import 'package:classtrack/presentation/providers/backup_provider.dart';
import 'package:classtrack/presentation/providers/theme_provider.dart';
import 'package:classtrack/presentation/widgets/walkthrough/welcome_onboarding_dialog.dart';
import 'package:classtrack/presentation/screens/settings/developer_tools_screen.dart';
import 'package:classtrack/presentation/screens/settings/about_screen.dart';
import 'package:classtrack/presentation/screens/settings/update_screen.dart';
import 'package:classtrack/core/services/developer_auth_service.dart';
import 'package:classtrack/core/services/notification_service.dart';
import 'package:drift/drift.dart' show Value;
import 'package:classtrack/core/constants/app_release_notes.dart';
import 'package:classtrack/core/ui/tactile_button.dart';
import 'package:classtrack/presentation/widgets/developer_passcode_dialog.dart';
import 'package:classtrack/domain/entities/class_session_entity.dart';
import 'package:classtrack/domain/entities/subject_entity.dart';
import 'package:classtrack/presentation/screens/schedule/reschedule_session_screen.dart';
import 'package:classtrack/presentation/screens/schedule/subject_room_manager_screen.dart';

void main() {
  group('AttendanceMathService Tests', () {
    test('Calculates attendance percentage correctly', () {
      expect(AttendanceMathService.calculatePercentage(27, 32), equals(84.4));
      expect(AttendanceMathService.calculatePercentage(0, 0), equals(100.0));
      expect(AttendanceMathService.calculatePercentage(15, 20), equals(75.0));
    });

    test('Calculates margin classes student can miss correctly', () {
      final canMiss = AttendanceMathService.calculateClassesCanMiss(
        attended: 27,
        held: 32,
        targetPct: 75.0,
      );
      expect(canMiss, equals(4));
    });

    test('Calculates required classes student must attend when below target', () {
      final mustAttend = AttendanceMathService.calculateClassesMustAttend(
        attended: 14,
        held: 20,
        targetPct: 75.0,
      );
      expect(mustAttend, equals(4));
    });
  });

  group('ScheduleResolutionEngine Tests', () {
    test('Level 1 Holiday suppresses recurring timetable slots', () {
      final mondayDate = DateTime(2026, 8, 24); // Monday
      final resolved = ScheduleResolutionEngine.resolveScheduleForDate(
        targetDate: mondayDate,
        semesterId: 'sem_1',
        holidays: [
          HolidayItem(title: 'Semester Break', startDate: '2026-08-20', endDate: '2026-08-25')
        ],
        dayConfigs: [],
        timetableSlots: [
          TimetableSlotItem(
            id: 'slot_1',
            semesterId: 'sem_1',
            subjectComponentId: 'comp_1',
            subjectName: 'Foundations of LIS',
            category: 'MAJOR',
            componentType: 'LECTURE',
            colorHex: '#4F46E5',
            dayOfWeek: 1, // Monday
            startTime: '09:00',
            endTime: '10:00',
          ),
        ],
        exceptions: [],
        extraClasses: [],
      );

      expect(resolved.isEmpty, isTrue);
    });

    test('Strict Date Isolation: Marking outcome for Monday Aug 24 does not mark Monday Aug 31', () {
      final slot = TimetableSlotItem(
        id: 'slot_1',
        semesterId: 'sem_1',
        subjectComponentId: 'comp_1',
        subjectName: 'Foundations of LIS',
        category: 'MAJOR',
        componentType: 'LECTURE',
        colorHex: '#4F46E5',
        dayOfWeek: 1, // Monday
        startTime: '09:00',
        endTime: '10:00',
      );

      // Outcome map has an outcome strictly for session_slot_1_2026-08-24
      final outcomesMap = {
        'session_slot_1_2026-08-24': 'PRESENT',
      };

      // 1. Resolve for Aug 24
      final resolvedAug24 = ScheduleResolutionEngine.resolveScheduleForDate(
        targetDate: DateTime(2026, 8, 24),
        semesterId: 'sem_1',
        holidays: [],
        dayConfigs: [],
        timetableSlots: [slot],
        exceptions: [],
        extraClasses: [],
        existingOutcomes: outcomesMap,
      );

      expect(resolvedAug24.length, equals(1));
      expect(resolvedAug24.first.attendanceOutcome, equals('PRESENT'));

      // 2. Resolve for Aug 31 (following Monday)
      final resolvedAug31 = ScheduleResolutionEngine.resolveScheduleForDate(
        targetDate: DateTime(2026, 8, 31),
        semesterId: 'sem_1',
        holidays: [],
        dayConfigs: [],
        timetableSlots: [slot],
        exceptions: [],
        extraClasses: [],
        existingOutcomes: outcomesMap,
      );

      expect(resolvedAug31.length, equals(1));
      expect(resolvedAug31.first.attendanceOutcome, equals('PENDING')); // Strict date isolation preserved!
    });

    test('Level 5 Extra Class resolves correctly even on custom dates', () {
      final mondayDate = DateTime(2026, 8, 24);
      final resolved = ScheduleResolutionEngine.resolveScheduleForDate(
        targetDate: mondayDate,
        semesterId: 'sem_1',
        holidays: [],
        dayConfigs: [],
        timetableSlots: [],
        exceptions: [],
        extraClasses: [
          ExtraClassItem(
            id: 'extra_1',
            semesterId: 'sem_1',
            subjectComponentId: 'comp_1',
            subjectName: 'Special Lecture LIS',
            category: 'MAJOR',
            componentType: 'LECTURE',
            colorHex: '#4F46E5',
            classDate: '2026-08-24',
            startTime: '14:00',
            endTime: '15:00',
          ),
        ],
      );

      expect(resolved.length, equals(1));
      expect(resolved.first.subjectName, equals('Special Lecture LIS'));
      expect(resolved.first.sessionSource, equals('EXTRA'));
    });

    test('Sunday classes resolve correctly when scheduled on Day 7', () {
      final sundayDate = DateTime(2026, 8, 23); // Sunday
      final resolved = ScheduleResolutionEngine.resolveScheduleForDate(
        targetDate: sundayDate,
        semesterId: 'sem_1',
        holidays: [],
        dayConfigs: [],
        timetableSlots: [
          TimetableSlotItem(
            id: 'slot_sun',
            semesterId: 'sem_1',
            subjectComponentId: 'comp_sun',
            subjectName: 'Weekend Workshop',
            category: 'ELECTIVE',
            componentType: 'SEMINAR',
            colorHex: '#10B981',
            dayOfWeek: 7, // Sunday
            startTime: '10:00',
            endTime: '12:00',
          ),
        ],
        exceptions: [],
        extraClasses: [],
      );

      expect(resolved.length, equals(1));
      expect(resolved.first.subjectName, equals('Weekend Workshop'));
      expect(resolved.first.startTime, equals('10:00'));
    });

    test('Effective date range filters timetable slots correctly', () {
      final slotWithRange = TimetableSlotItem(
        id: 'slot_range',
        semesterId: 'sem_1',
        subjectComponentId: 'comp_1',
        subjectName: 'Module 1 LIS',
        category: 'MAJOR',
        componentType: 'LECTURE',
        colorHex: '#4F46E5',
        dayOfWeek: 1, // Monday
        startTime: '09:00',
        endTime: '10:00',
        effectiveFrom: '2026-08-01',
        effectiveUntil: '2026-08-25',
      );

      // Before range: July 27, 2026 (Monday) -> Should NOT resolve
      final beforeRange = ScheduleResolutionEngine.resolveScheduleForDate(
        targetDate: DateTime(2026, 7, 27),
        semesterId: 'sem_1',
        holidays: [],
        dayConfigs: [],
        timetableSlots: [slotWithRange],
        exceptions: [],
        extraClasses: [],
      );
      expect(beforeRange.isEmpty, isTrue);

      // In range: August 24, 2026 (Monday) -> Should resolve
      final inRange = ScheduleResolutionEngine.resolveScheduleForDate(
        targetDate: DateTime(2026, 8, 24),
        semesterId: 'sem_1',
        holidays: [],
        dayConfigs: [],
        timetableSlots: [slotWithRange],
        exceptions: [],
        extraClasses: [],
      );
      expect(inRange.length, equals(1));

      // After range: August 31, 2026 (Monday) -> Should NOT resolve
      final afterRange = ScheduleResolutionEngine.resolveScheduleForDate(
        targetDate: DateTime(2026, 8, 31),
        semesterId: 'sem_1',
        holidays: [],
        dayConfigs: [],
        timetableSlots: [slotWithRange],
        exceptions: [],
        extraClasses: [],
      );
      expect(afterRange.isEmpty, isTrue);
    });

    test('SQLite AppDatabase persists and retrieves effectiveFrom and effectiveUntil', () async {
      final db = AppDatabase.inMemory();
      await db.seedInitialDataIfEmpty();

      final slot = TimetableSlotData(
        id: 'slot_custom_1',
        semesterId: 'sem_1',
        subjectComponentId: 'sub_lis_1',
        dayOfWeek: 1, // Monday
        startTime: '10:00',
        endTime: '11:00',
        effectiveFrom: '2026-09-01',
        effectiveUntil: '2026-10-31',
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      await db.saveTimetableSlot(slot);

      final slots = await db.getTimetableSlots('sem_1');
      final fetched = slots.firstWhere((s) => s.id == 'slot_custom_1');

      expect(fetched.effectiveFrom, equals('2026-09-01'));
      expect(fetched.effectiveUntil, equals('2026-10-31'));

      await db.close();
    });

    test('Active Term classes strictly respect semester start and end boundaries', () {
      final activeTermSlot = TimetableSlotItem(
        id: 'slot_active_term',
        semesterId: 'sem_5',
        subjectComponentId: 'sub_net',
        subjectName: 'Computer Networks',
        category: 'MAJOR',
        componentType: 'LECTURE',
        colorHex: '#4F46E5',
        dayOfWeek: 1, // Monday
        startTime: '09:00',
        endTime: '10:00',
        effectiveFrom: null, // Active Term
        effectiveUntil: null,
      );

      final semesterStart = DateTime(2026, 8, 1);
      final semesterEnd = DateTime(2026, 12, 20);

      // 1. Before semester starts: July 27, 2026 (Monday) -> 0 classes
      final beforeSem = ScheduleResolutionEngine.resolveScheduleForDate(
        targetDate: DateTime(2026, 7, 27),
        semesterId: 'sem_5',
        semesterStartDate: semesterStart,
        semesterEndDate: semesterEnd,
        holidays: [],
        dayConfigs: [],
        timetableSlots: [activeTermSlot],
        exceptions: [],
        extraClasses: [],
      );
      expect(beforeSem.isEmpty, isTrue);

      // 2. During semester: August 24, 2026 (Monday) -> 1 class
      final duringSem = ScheduleResolutionEngine.resolveScheduleForDate(
        targetDate: DateTime(2026, 8, 24),
        semesterId: 'sem_5',
        semesterStartDate: semesterStart,
        semesterEndDate: semesterEnd,
        holidays: [],
        dayConfigs: [],
        timetableSlots: [activeTermSlot],
        exceptions: [],
        extraClasses: [],
      );
      expect(duringSem.length, equals(1));
      expect(duringSem.first.subjectName, equals('Computer Networks'));

      // 3. After semester ends: December 28, 2026 (Monday) -> 0 classes
      final afterSem = ScheduleResolutionEngine.resolveScheduleForDate(
        targetDate: DateTime(2026, 12, 28),
        semesterId: 'sem_5',
        semesterStartDate: semesterStart,
        semesterEndDate: semesterEnd,
        holidays: [],
        dayConfigs: [],
        timetableSlots: [activeTermSlot],
        exceptions: [],
        extraClasses: [],
      );
      expect(afterSem.isEmpty, isTrue);
    });

    test('Sunday-first week offset calculation aligns Sunday to 0', () {
      final sunday = DateTime(2026, 8, 23); // Sunday (weekday = 7)
      final monday = DateTime(2026, 8, 24); // Monday (weekday = 1)
      final saturday = DateTime(2026, 8, 29); // Saturday (weekday = 6)

      expect(sunday.weekday % 7, equals(0));
      expect(monday.weekday % 7, equals(1));
      expect(saturday.weekday % 7, equals(6));

      final weekStart = sunday.subtract(Duration(days: sunday.weekday % 7));
      expect(weekStart.day, equals(23)); // Starts on Sunday!
    });

    test('SemestersListNotifier updates and deletes semesters in state and DB', () async {
      final db = AppDatabase.inMemory();
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
      );
      final notifier = container.read(semestersListProvider.notifier);

      final sem1 = SemesterEntity(
        id: 'sem_test_1',
        name: 'Semester I',
        academicYear: '2026',
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 12, 20),
        isCurrent: true,
      );
      final sem2 = SemesterEntity(
        id: 'sem_test_2',
        name: 'Semester II',
        academicYear: '2027',
        startDate: DateTime(2027, 1, 15),
        endDate: DateTime(2027, 5, 30),
        isCurrent: false,
      );

      await notifier.addSemester(sem1);
      await notifier.addSemester(sem2);
      expect(container.read(semestersListProvider).length, equals(2));

      // Update sem1
      final updatedSem1 = sem1.copyWith(name: 'Updated Semester 1st');
      await notifier.updateSemesterInList(updatedSem1);
      expect(container.read(semestersListProvider).first.name, equals('Updated Semester 1st'));

      // Delete sem2
      await notifier.deleteSemester('sem_test_2');
      expect(container.read(semestersListProvider).length, equals(1));
      expect(container.read(semestersListProvider).first.id, equals('sem_test_1'));

      container.dispose();
      await db.close();
    });
  });

  group('AppUpdateService Tests', () {
    test('Semver comparison accurately detects version differences', () {
      expect(AppUpdateService.compareSemver('1.0.0', '1.0.0'), equals(0));
      expect(AppUpdateService.compareSemver('1.0.0', '1.0.1'), equals(1)); // remote is newer
      expect(AppUpdateService.compareSemver('1.0.1', '1.0.0'), equals(-1)); // remote is older
      expect(AppUpdateService.compareSemver('1.0.0', '1.1.0'), equals(1));
      expect(AppUpdateService.compareSemver('1.9.0', '2.0.0'), equals(1));
      expect(AppUpdateService.compareSemver('2.1.0-beta', '2.1.0'), equals(1));
      expect(AppUpdateService.compareSemver('2.1.0', '2.1.0'), equals(0));
    });

    test('isUpdateAvailable checks both semver and build numbers', () {
      expect(
        AppUpdateService.isUpdateAvailable(currentVersion: '1.0.0', remoteVersion: '1.1.0'),
        isTrue,
      );
      expect(
        AppUpdateService.isUpdateAvailable(currentVersion: '1.1.0', remoteVersion: '1.0.0'),
        isFalse,
      );
      expect(
        AppUpdateService.isUpdateAvailable(
          currentVersion: '1.0.0',
          remoteVersion: '1.0.0',
          currentBuild: 1,
          remoteBuild: 2,
        ),
        isTrue,
      );
    });

    test('isMandatoryUpdate correctly forces update when version is below minimum', () {
      expect(
        AppUpdateService.isMandatoryUpdate(
          currentVersion: '1.0.0',
          minSupportedVersion: '1.1.0',
        ),
        isTrue,
      );
      expect(
        AppUpdateService.isMandatoryUpdate(
          currentVersion: '1.2.0',
          minSupportedVersion: '1.1.0',
        ),
        isFalse,
      );
      expect(
        AppUpdateService.isMandatoryUpdate(
          currentVersion: '1.2.0',
          minSupportedVersion: '1.1.0',
          isMandatoryFlag: true,
        ),
        isTrue,
      );
    });

    test('AppReleaseInfo parses JSON manifests safely', () {
      final json = {
        'latest_version': '1.2.0',
        'build_number': 5,
        'min_supported_version': '1.0.0',
        'release_date': '2026-08-25',
        'release_title': 'ClassTrack 1.2.0 Feature Release',
        'changelog': [
          '✨ Modern bottom navigation bar',
          '⚡ Strict multi-day batch class scheduler',
        ],
        'download_url': 'https://example.com/classtrack.apk',
        'is_mandatory': false,
      };

      final info = AppReleaseInfo.fromJson(json);
      expect(info.latestVersion, equals('1.2.0'));
      expect(info.buildNumber, equals(5));
      expect(info.changelog.length, equals(2));
      expect(info.downloadUrl, equals('https://example.com/classtrack.apk'));
      expect(info.isMandatory, isFalse);
    });

    test('AppReleaseInfo resolves appropriate APK asset when split-per-abi assets exist', () {
      final githubReleaseJson = {
        'tag_name': 'v1.0.0-alpha.5',
        'body': '✨ Multi-room support',
        'published_at': '2026-09-03T12:00:00Z',
        'assets': [
          {
            'name': 'app-armeabi-v7a-release.apk',
            'browser_download_url': 'https://github.com/a3ryk/classtrack/releases/download/v1.0.0-alpha.5/app-armeabi-v7a-release.apk',
          },
          {
            'name': 'app-arm64-v8a-release.apk',
            'browser_download_url': 'https://github.com/a3ryk/classtrack/releases/download/v1.0.0-alpha.5/app-arm64-v8a-release.apk',
          },
          {
            'name': 'app-x86_64-release.apk',
            'browser_download_url': 'https://github.com/a3ryk/classtrack/releases/download/v1.0.0-alpha.5/app-x86_64-release.apk',
          },
        ],
      };

      final info = AppReleaseInfo.fromGithubReleaseJson(githubReleaseJson);
      expect(info.latestVersion, equals('1.0.0-alpha.5'));
      expect(info.downloadUrl, isNotNull);
      expect(info.downloadUrl!.endsWith('.apk'), isTrue);
    });
  });

  group('BackupService Tests', () {
    test('generateFullBackupJson captures all tables and settings', () async {
      final db = AppDatabase.inMemory();
      final nowIso = DateTime.now().toIso8601String();
      await db.saveSemester(
        SemesterData(
          id: 'sem_1',
          name: 'Demo Semester',
          startDate: '2026-08-01',
          endDate: '2026-12-31',
          defaultTargetPct: 75.0,
          status: 'ACTIVE',
          createdAt: nowIso,
          updatedAt: nowIso,
        ),
      );
      await db.populateDemoData('sem_1');
      await db.setSetting('user_profile', '{"studentName":"John Doe","rollNumber":"CS-42"}');
      await db.setSetting('target_percentage', '80.0');

      final jsonStr = await BackupService.generateFullBackupJson(db);
      expect(jsonStr.isNotEmpty, isTrue);

      final validation = BackupService.validateBackup(jsonStr);
      expect(validation.isValid, isTrue);
      expect(validation.itemCounts['semesters']! >= 1, isTrue);
      expect(validation.itemCounts['subjects']! >= 3, isTrue);
      expect(validation.itemCounts['timetable_slots']! >= 5, isTrue);

      await db.close();
    });

    test('validateBackup rejects invalid or non-ClassTrack JSON', () {
      expect(BackupService.validateBackup('not json').isValid, isFalse);
      expect(BackupService.validateBackup('{"app": "AnotherApp"}').isValid, isFalse);
      expect(BackupService.validateBackup('{"app": "ClassTrack"}').isValid, isFalse); // missing tables
      expect(BackupService.validateBackup('{"app": "ClassTrack", "tables": {}}').isValid, isFalse); // missing required tables
      expect(BackupService.validateBackup('%PDF-1.4 binary garbage').isValid, isFalse);
    });

    test('ThemeModeNotifier persists theme selection to SQLite AppSettings', () async {
      final db = AppDatabase.inMemory();
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
      );

      final notifier = container.read(themeModeProvider.notifier);
      await notifier.setThemeMode(ThemeMode.dark);

      final saved = await db.getSetting('theme_mode');
      expect(saved, equals('dark'));

      await notifier.setThemeMode(ThemeMode.light);
      final savedLight = await db.getSetting('theme_mode');
      expect(savedLight, equals('light'));

      container.dispose();
      await db.close();
    });

    test('ActiveTemplateNotifier defaults to Not Selected, persists to SQLite, and reloads across instances', () async {
      final db = AppDatabase.inMemory();
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
      );

      // Default state is Not Selected
      final initialTemplate = container.read(activeTemplateProvider);
      expect(initialTemplate.id, equals('none'));
      expect(initialTemplate.name, equals('Not Selected'));

      // Select FYUGP template
      await container.read(activeTemplateProvider.notifier).selectTemplate(ProgrammeTemplates.fyugpTemplate);
      expect(container.read(activeTemplateProvider).id, equals('fyugp_nep2020'));

      // Check SQLite setting was written
      final savedId = await db.getSetting('academic_template_id');
      expect(savedId, equals('fyugp_nep2020'));

      // Simulate hot restart / new container
      final container2 = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
      );
      await container2.read(activeTemplateProvider.notifier).loadFromDb();
      expect(container2.read(activeTemplateProvider).id, equals('fyugp_nep2020'));
      expect(container2.read(activeTemplateProvider).name.contains('FYUGP'), isTrue);

      // Clear template back to none
      await container2.read(activeTemplateProvider.notifier).clearTemplate();
      expect(container2.read(activeTemplateProvider).id, equals('none'));
      expect(container2.read(activeTemplateProvider).name, equals('Not Selected'));
      expect(await db.getSetting('academic_template_id'), equals('none'));

      container.dispose();
      container2.dispose();
      await db.close();
    });

    test('restoreBackup restores all 11 tables and settings atomically', () async {
      final db = AppDatabase.inMemory();
      final nowIso = DateTime.now().toIso8601String();
      await db.saveSemester(
        SemesterData(
          id: 'sem_1',
          name: 'Original Semester',
          startDate: '2026-08-01',
          endDate: '2026-12-31',
          defaultTargetPct: 75.0,
          status: 'ACTIVE',
          createdAt: nowIso,
          updatedAt: nowIso,
        ),
      );
      await db.populateDemoData('sem_1');
      await db.setSetting('user_profile', '{"studentName":"Original Student"}');

      // 1. Generate snapshot
      final backupJson = await BackupService.generateFullBackupJson(db);

      // 2. Modify database
      await db.saveSemester(
        SemesterData(
          id: 'sem_modified',
          name: 'Modified Semester',
          startDate: '2026-09-01',
          endDate: '2026-12-31',
          defaultTargetPct: 75.0,
          status: 'ACTIVE',
          createdAt: nowIso,
          updatedAt: nowIso,
        ),
      );
      await db.setSetting('user_profile', '{"studentName":"Modified Student"}');

      // 3. Restore snapshot
      final decoded = jsonDecode(backupJson) as Map<String, dynamic>;
      await BackupService.restoreBackup(decoded, db);

      // 4. Assert original state restored
      final restoredSemesters = await db.getAllSemestersAll();
      expect(restoredSemesters.any((s) => s.id == 'sem_modified'), isFalse);
      expect(restoredSemesters.any((s) => s.id == 'sem_1'), isTrue);

      final restoredProfile = await db.getSetting('user_profile');
      expect(restoredProfile!.contains('Original Student'), isTrue);

      await db.close();
    });

    test('formatDeviceTimestamp formats local date and time without timezone bugs', () {
      final utcTime = DateTime.utc(2026, 8, 25, 12, 30);
      final formatted = BackupService.formatDeviceTimestamp(utcTime);
      expect(formatted.contains('25/08/2026'), isTrue);
      expect(formatted.contains(':'), isTrue);
    });

    test('formatFileSize produces human-readable size labels', () {
      expect(BackupService.formatFileSize(500), equals('500 B'));
      expect(BackupService.formatFileSize(1500), equals('1.5 KB'));
      expect(BackupService.formatFileSize(2048 * 1024), equals('2.0 MB'));
    });

    test('AutoBackupFrequency durations are accurate', () {
      expect(AutoBackupFrequency.every6Hours.duration.inHours, equals(6));
      expect(AutoBackupFrequency.daily.duration.inDays, equals(1));
      expect(AutoBackupFrequency.weekly.duration.inDays, equals(7));
      expect(AutoBackupFrequency.monthly.duration.inDays, equals(30));
    });
  });

  testWidgets('ClasstrackApp smoke test renders tabs with SQLite persistence', (WidgetTester tester) async {
    final db = AppDatabase.inMemory();
    await db.seedInitialDataIfEmpty();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          appInitializationProvider.overrideWith((ref) => Future.value(true)),
        ],
        child: const ClasstrackApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify main navigation items exist
    expect(find.text('Today'), findsWidgets);
    expect(find.text('Analytics'), findsWidgets);
    expect(find.text('Timetable'), findsWidgets);
    expect(find.text('Calendar'), findsWidgets);

    await db.close();
  });

  group('Onboarding & Walkthrough Tests', () {
    test('HasCompletedOnboardingNotifier persists state in SQLite', () async {
      final db = AppDatabase.inMemory();
      final notifier = HasCompletedOnboardingNotifier(db);

      await notifier.loadFromDb();
      expect(notifier.state, isFalse);

      await notifier.setCompleted(true);
      expect(notifier.state, isTrue);

      final val = await db.getSetting('has_completed_onboarding');
      expect(val, equals('true'));

      await db.close();
    });

    testWidgets('WelcomeOnboardingDialog renders options and triggers callbacks', (WidgetTester tester) async {
      bool tourStarted = false;
      bool enterDirectly = false;
      bool backupTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => WelcomeOnboardingDialog(
                      onStartTour: () => tourStarted = true,
                      onEnterDirectly: () => enterDirectly = true,
                      onRestoreBackup: () => backupTriggered = true,
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome to ClassTrack'), findsOneWidget);
      expect(find.text("I'm New Here"), findsOneWidget);
      expect(find.text("I'm Familiar"), findsOneWidget);
      expect(find.text('Have a backup file? Restore from .ctbackup'), findsOneWidget);

      await tester.tap(find.text("I'm New Here"));
      await tester.pumpAndSettle();
      expect(tourStarted, isTrue);
      expect(enterDirectly, isFalse);
      expect(backupTriggered, isFalse);
    });

    testWidgets('DeveloperToolsScreen renders all 5 testing tool sections', (WidgetTester tester) async {
      final db = AppDatabase.inMemory();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
          ],
          child: const MaterialApp(
            home: DeveloperToolsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Developer Tools'), findsOneWidget);
      expect(find.text('Onboarding & User Walkthrough'), findsOneWidget);
      expect(find.text('Attendance Scenario Generators'), findsOneWidget);
      expect(find.text('Launch Welcome Onboarding Screen'), findsOneWidget);
      expect(find.text('Start Interactive App Tour'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('SQLite Database & Storage'), 200);
      expect(find.text('SQLite Database & Storage'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('UI & Feedback Diagnostics'), 200);
      expect(find.text('UI & Feedback Diagnostics'), findsOneWidget);

      await db.close();
    });

    test('DeveloperAuthService validates default and custom passcodes', () {
      expect(DeveloperAuthService.verifyPasscode('8080', null), isTrue);
      expect(DeveloperAuthService.verifyPasscode('0000', null), isFalse);

      final customHash = DeveloperAuthService.hashPasscode('1234');
      expect(DeveloperAuthService.verifyPasscode('1234', customHash), isTrue);
      expect(DeveloperAuthService.verifyPasscode('8080', customHash), isFalse);
    });

    test('DeveloperAuthService validates and parses QR payloads strictly', () {
      final validPayload = DeveloperAuthService.generateQrPayload(null);
      expect(DeveloperAuthService.verifyQrPayload(validPayload, null), isTrue);
      expect(DeveloperAuthService.verifyQrPayload('https://evil.com', null), isFalse);
      expect(DeveloperAuthService.verifyQrPayload('classtrack://dev-unlock?hash=short', null), isFalse);
    });

    test('DeveloperRateLimiter locks out after 5 consecutive failures', () {
      DeveloperRateLimiter.reset();
      expect(DeveloperRateLimiter.isLockedOut, isFalse);

      for (int i = 0; i < 5; i++) {
        DeveloperRateLimiter.recordFailure();
      }

      expect(DeveloperRateLimiter.isLockedOut, isTrue);
      expect(DeveloperRateLimiter.remainingLockoutSeconds, greaterThan(0));

      DeveloperRateLimiter.reset();
      expect(DeveloperRateLimiter.isLockedOut, isFalse);
    });

    testWidgets('DeveloperPasscodeDialog unlocks on correct 4-digit PIN', (WidgetTester tester) async {
      bool unlocked = false;
      final db = AppDatabase.inMemory();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => DeveloperPasscodeDialog(
                        onUnlocked: () => unlocked = true,
                      ),
                    );
                  },
                  child: const Text('Open Passcode Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Passcode Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Developer Access'), findsOneWidget);

      // Tap 8 -> 0 -> 8 -> 0
      await tester.tap(find.text('8'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('0'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('8'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('0'));
      await tester.pumpAndSettle();

      expect(unlocked, isTrue);
      await db.close();
    });

    testWidgets('AboutScreen renders clean unsectioned list and handles 7-tap on Version tile', (WidgetTester tester) async {
      final db = AppDatabase.inMemory();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
          ],
          child: const MaterialApp(
            home: AboutScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('About'), findsOneWidget);
      expect(find.text('Version'), findsOneWidget);
      expect(find.text('Check for updates'), findsOneWidget);
      expect(find.text('What\'s new'), findsOneWidget);
      expect(find.text('Open source licenses'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);

      // Tap Version tile 7 times
      for (int i = 0; i < 7; i++) {
        await tester.tap(find.text('Version'));
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pumpAndSettle();

      // Developer PIN dialog should appear
      expect(find.text('Developer Access'), findsOneWidget);

      await db.close();
    });

    testWidgets('UpdateScreen renders uniform Download button and handles custom warnings', (WidgetTester tester) async {
      // 1. Regular update
      await tester.pumpWidget(
        const MaterialApp(
          home: UpdateScreen(
            releaseInfo: AppReleaseInfo(
              latestVersion: '1.2.0',
              buildNumber: 5,
              minSupportedVersion: '1.0.0',
              releaseDate: '25/08/2026',
              releaseTitle: 'ClassTrack v1.2.0',
              changelog: [
                '✨ New features',
                '🧩 Fixed issues',
              ],
              isMandatory: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('New version available!'), findsOneWidget);
      expect(find.text('v1.2.0 • Released 25/08/2026'), findsOneWidget);
      expect(find.text('✨ Features'), findsOneWidget);
      expect(find.text('🧩 Fixes'), findsOneWidget);
      expect(find.text('View complete release notes on GitHub'), findsOneWidget);
      expect(find.text('Update Now'), findsOneWidget);
      expect(find.text('Not now'), findsOneWidget);

      // 2. Mandatory update with custom warning
      await tester.pumpWidget(
        const MaterialApp(
          home: UpdateScreen(
            releaseInfo: AppReleaseInfo(
              latestVersion: '2.0.0',
              buildNumber: 10,
              minSupportedVersion: '2.0.0',
              releaseDate: '25/08/2026',
              releaseTitle: 'Critical Update',
              changelog: ['🧩 Critical fix'],
              isMandatory: true,
              warningMessage: 'Custom database migration required.',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Update Now'), findsOneWidget);
      expect(find.text('Custom database migration required.'), findsOneWidget);
      expect(find.text('Not now'), findsNothing); // Hidden for mandatory update
    });

    testWidgets('TactileIconButton renders and triggers onTap callback', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TactileIconButton(
              icon: Icons.settings_outlined,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

      await tester.tap(find.byType(TactileIconButton));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    test('Initial ActiveSemesterNotifier starts unset when DB is empty', () async {
      final db = AppDatabase.inMemory();
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
      );

      final initialSem = container.read(activeSemesterProvider);
      expect(initialSem.isUnset, isTrue);
      expect(initialSem.name, equals('No Semester'));

      container.dispose();
      await db.close();
    });

    test('Resolved schedule displays recurring Wednesday slots for Wednesday 26 Aug 2026', () {
      final wednesdayDate = DateTime(2026, 8, 26); // Wednesday (weekday 3)
      final resolved = ScheduleResolutionEngine.resolveScheduleForDate(
        targetDate: wednesdayDate,
        semesterId: 'sem_fall_2026',
        semesterStartDate: DateTime(2026, 8, 1),
        semesterEndDate: DateTime(2026, 12, 31),
        holidays: [],
        dayConfigs: [],
        timetableSlots: [
          TimetableSlotItem(
            id: 'slot_wed',
            semesterId: 'sem_fall_2026',
            subjectComponentId: 'sub_algo',
            subjectName: 'Algorithms & Data Structures',
            category: 'MAJOR',
            componentType: 'LECTURE',
            colorHex: '#4F46E5',
            dayOfWeek: 3, // Wednesday
            startTime: '10:00',
            endTime: '11:00',
          ),
        ],
        exceptions: [],
        extraClasses: [],
      );

      expect(resolved.length, equals(1));
      expect(resolved.first.subjectName, equals('Algorithms & Data Structures'));
      expect(resolved.first.startTime, equals('10:00'));
    });

    test('ScheduleResolutionEngine Tests Date-Specific MOVED exception overrides slot time for that date only', () {
      final wedDate = DateTime(2026, 8, 26);
      final resolved = ScheduleResolutionEngine.resolveScheduleForDate(
        targetDate: wedDate,
        semesterId: 'sem_fall_2026',
        semesterStartDate: DateTime(2026, 8, 1),
        semesterEndDate: DateTime(2026, 12, 31),
        holidays: [],
        dayConfigs: [],
        timetableSlots: [
          TimetableSlotItem(
            id: 'slot_wed',
            semesterId: 'sem_fall_2026',
            subjectComponentId: 'sub_algo',
            subjectName: 'Algorithms & Data Structures',
            category: 'MAJOR',
            componentType: 'LECTURE',
            colorHex: '#4F46E5',
            dayOfWeek: 3,
            startTime: '10:00',
            endTime: '11:00',
          ),
        ],
        exceptions: [
          ScheduleExceptionItem(
            timetableSlotId: 'slot_wed',
            exceptionDate: '2026-08-26',
            actionType: 'MOVED',
            newStartTime: '14:00',
            newEndTime: '15:30',
            newRoom: 'Lab 402',
          ),
        ],
        extraClasses: [],
      );

      expect(resolved.length, equals(1));
      expect(resolved.first.startTime, equals('14:00'));
      expect(resolved.first.endTime, equals('15:30'));
      expect(resolved.first.room, equals('Lab 402'));
    });

    test('ScheduleResolutionEngine Tests Date-Specific CANCELLED exception excludes session for that date only', () {
      final wedDate = DateTime(2026, 8, 26);
      final resolved = ScheduleResolutionEngine.resolveScheduleForDate(
        targetDate: wedDate,
        semesterId: 'sem_fall_2026',
        semesterStartDate: DateTime(2026, 8, 1),
        semesterEndDate: DateTime(2026, 12, 31),
        holidays: [],
        dayConfigs: [],
        timetableSlots: [
          TimetableSlotItem(
            id: 'slot_wed',
            semesterId: 'sem_fall_2026',
            subjectComponentId: 'sub_algo',
            subjectName: 'Algorithms & Data Structures',
            category: 'MAJOR',
            componentType: 'LECTURE',
            colorHex: '#4F46E5',
            dayOfWeek: 3,
            startTime: '10:00',
            endTime: '11:00',
          ),
        ],
        exceptions: [
          ScheduleExceptionItem(
            timetableSlotId: 'slot_wed',
            exceptionDate: '2026-08-26',
            actionType: 'CANCELLED',
          ),
        ],
        extraClasses: [],
      );

      expect(resolved.isEmpty, isTrue);
    });

    test('QR Protocol Tests Compresses and decompresses timetable payload accurately with Gzip', () {
      final payloadMap = {
        'v': 2,
        'sem': 'Semester 5',
        'subs': [
          {'id': 'sub_1', 'name': 'Quantum Physics', 'code': 'PHY301', 'cat': 'MAJOR', 'col': '#4F46E5'},
        ],
        'slots': [
          {'subId': 'sub_1', 'day': 1, 'start': '09:00', 'end': '10:00', 'type': 'LECTURE', 'room': 'LH-1'},
        ],
      };

      final jsonStr = jsonEncode(payloadMap);
      final bytes = utf8.encode(jsonStr);
      final compressed = gzip.encode(bytes);
      final encoded = 'CT2:${base64Url.encode(compressed)}';

      expect(encoded.startsWith('CT2:'), isTrue);

      final code = encoded.substring(4);
      final decompressedBytes = gzip.decode(base64Url.decode(code));
      final decodedMap = jsonDecode(utf8.decode(decompressedBytes)) as Map<String, dynamic>;

      expect(decodedMap['sem'], equals('Semester 5'));
      expect((decodedMap['subs'] as List).length, equals(1));
      expect((decodedMap['subs'] as List).first['name'], equals('Quantum Physics'));
    });

    test('Notification Text Sanitization: Replaces em-dashes and en-dashes with standard hyphens', () {
      const input = 'ClassTrack Backup — Snapshot saved – 25 KB';
      final sanitized = NotificationService.sanitizeText(input);
      expect(sanitized, equals('ClassTrack Backup - Snapshot saved - 25 KB'));
      expect(sanitized.contains('—'), isFalse);
      expect(sanitized.contains('–'), isFalse);
    });

    test('AppUpdateService Semver Comparison: Identifies newer releases accurately', () {
      expect(AppUpdateService.compareSemver('1.0.0', '1.0.1'), equals(1));
      expect(AppUpdateService.compareSemver('1.0.0', '1.1.0'), equals(1));
      expect(AppUpdateService.compareSemver('1.0.0', '2.0.0'), equals(1));
      expect(AppUpdateService.compareSemver('1.1.0', '1.1.0'), equals(0));
      expect(AppUpdateService.compareSemver('1.1.0', '1.0.9'), equals(-1));
    });

    test('AppReleaseInfo JSON Deserialization: Parses release manifest correctly', () {
      final json = {
        'latest_version': '1.2.0',
        'build_number': 15,
        'min_supported_version': '1.0.0',
        'release_date': '2026-08-28',
        'release_title': 'ClassTrack v1.2.0',
        'changelog': [
          '✨ In-App updates',
          '🧩 Notification fixes',
        ],
        'download_url': 'https://example.com/app.apk',
        'is_mandatory': false,
      };

      final info = AppReleaseInfo.fromJson(json);
      expect(info.latestVersion, equals('1.2.0'));
      expect(info.buildNumber, equals(15));
      expect(info.minSupportedVersion, equals('1.0.0'));
      expect(info.changelog.length, equals(2));
      expect(info.isMandatory, isFalse);
    });

    test('AppReleaseInfo JSON Deserialization: Parses plain warning_message without emojis', () {
      final json = {
        'latest_version': '1.0.0-alpha.3',
        'build_number': 3,
        'min_supported_version': '1.0.0-alpha.1',
        'warning_message': 'Database schema upgrade is required for all users.',
        'changelog': ['Feature 1'],
      };

      final info = AppReleaseInfo.fromJson(json);
      expect(info.warningMessage, equals('Database schema upgrade is required for all users.'));
      expect(info.isMandatory, isFalse);
    });

    test('AppReleaseInfo GitHub Markdown Parsing: Extracts MIN_VERSION and MANDATORY tags', () {
      final githubJson = {
        'tag_name': 'v1.0.0-alpha.4',
        'name': 'ClassTrack v1.0.0-alpha.4',
        'published_at': '2026-09-03T00:00:00Z',
        'body': 'MIN_VERSION: 1.0.0-alpha.3\nMANDATORY: Breaking timetable sync changes.\n- Added full screens\n- Fixed performance',
        'assets': [
          {'name': 'classtrack.apk', 'browser_download_url': 'https://github.com/apk/app.apk'},
        ],
      };

      final info = AppReleaseInfo.fromGithubReleaseJson(githubJson);
      expect(info.latestVersion, equals('1.0.0-alpha.4'));
      expect(info.minSupportedVersion, equals('1.0.0-alpha.3'));
      expect(info.isMandatory, isTrue);
      expect(info.warningMessage, equals('Breaking timetable sync changes.'));
      expect(info.downloadUrl, equals('https://github.com/apk/app.apk'));
      expect(info.changelog.length, equals(2));
    });

    test('AppReleaseInfo GitHub Alert Parsing: Parses > [!WARNING] alerts properly', () {
      final githubJson = {
        'tag_name': 'v1.0.0-alpha.4',
        'name': 'ClassTrack v1.0.0-alpha.4',
        'body': '> [!WARNING] Critical update required.\n- Performance improvements\n<!-- MIN_VERSION: 1.0.0-alpha.4 -->',
      };

      final info = AppReleaseInfo.fromGithubReleaseJson(githubJson);
      expect(info.isMandatory, isTrue);
      expect(info.warningMessage, equals('Critical update required.'));
      expect(info.minSupportedVersion, equals('1.0.0-alpha.4'));
    });

    test('AppReleaseNotes Registry: Returns release notes for installed version offline', () {
      final v3 = AppReleaseNotes.getForVersion('1.0.0-alpha.3');
      expect(v3.latestVersion, equals('1.0.0-alpha.3'));
      expect(v3.changelog.isNotEmpty, isTrue);

      final v2 = AppReleaseNotes.getForVersion('1.0.0-alpha.2');
      expect(v2.latestVersion, equals('1.0.0-alpha.2'));
      expect(v2.changelog.isNotEmpty, isTrue);
    });

    test('AppUpdateService Mandatory Threshold: Correctly locks only older versions', () {
      // Installed version alpha.1 is older than minSupportedVersion alpha.3 -> Must force update
      expect(
        AppUpdateService.isMandatoryUpdate(
          currentVersion: '1.0.0-alpha.1',
          minSupportedVersion: '1.0.0-alpha.3',
        ),
        isTrue,
      );

      // Installed version alpha.3 meets minSupportedVersion alpha.3 -> Not forced
      expect(
        AppUpdateService.isMandatoryUpdate(
          currentVersion: '1.0.0-alpha.3',
          minSupportedVersion: '1.0.0-alpha.3',
        ),
        isFalse,
      );
    });

    test('Timetable Slot Room Persistence: Editing and removing room updates SQLite correctly', () async {
      final db = AppDatabase.inMemory();
      final nowIso = DateTime.now().toIso8601String();

      // 1. Insert initial slot with Room 101
      final slot1 = TimetableSlotData(
        id: 'slot_test_room',
        semesterId: 'sem_test',
        subjectComponentId: 'sub_test',
        dayOfWeek: 1,
        startTime: '09:00',
        endTime: '10:00',
        room: 'Room 101',
        createdAt: nowIso,
        updatedAt: nowIso,
      );
      await db.saveTimetableSlot(slot1);

      var saved = await db.getTimetableSlots('sem_test');
      expect(saved.first.room, equals('Room 101'));

      // 2. Edit room to Lab B
      final slotEdited = slot1.copyWith(room: const Value('Lab B'));
      await db.saveTimetableSlot(slotEdited);

      saved = await db.getTimetableSlots('sem_test');
      expect(saved.first.room, equals('Lab B'));

      // 3. Remove/Clear room to null
      final slotCleared = slot1.copyWith(room: const Value(null));
      await db.saveTimetableSlot(slotCleared);

      saved = await db.getTimetableSlots('sem_test');
      expect(saved.first.room, isNull);

      await db.close();
    });

    test('ScheduleResolutionEngine: Resolves MOVED exception room correctly including clearing room', () {
      final baseSlot = TimetableSlotItem(
        id: 'slot_1',
        semesterId: 'sem_1',
        subjectComponentId: 'sub_1',
        subjectName: 'Physics',
        dayOfWeek: 1, // Monday
        startTime: '09:00',
        endTime: '10:00',
        room: 'Room 101',
        category: 'MAJOR',
        componentType: 'LECTURE',
        colorHex: '#4F46E5',
      );

      // 1. Without exception -> uses slot.room (Room 101)
      final regular = ScheduleResolutionEngine.resolveScheduleForDate(
        targetDate: DateTime(2026, 8, 24), // Monday
        timetableSlots: [baseSlot],
        exceptions: [],
        extraClasses: [],
        holidays: [],
        dayConfigs: const [],
        existingOutcomes: {},
        semesterId: 'sem_1',
      );
      expect(regular.first.room, equals('Room 101'));

      // 2. With MOVED exception changing room to 'Auditorium'
      final movedWithRoom = ScheduleResolutionEngine.resolveScheduleForDate(
        targetDate: DateTime(2026, 8, 24),
        timetableSlots: [baseSlot],
        exceptions: [
          ScheduleExceptionItem(
            timetableSlotId: 'slot_1',
            exceptionDate: '2026-08-24',
            actionType: 'MOVED',
            newStartTime: '10:00',
            newEndTime: '11:00',
            newRoom: 'Auditorium',
          ),
        ],
        extraClasses: [],
        holidays: [],
        dayConfigs: const [],
        existingOutcomes: {},
        semesterId: 'sem_1',
      );
      expect(movedWithRoom.first.room, equals('Auditorium'));

      // 3. With MOVED exception clearing room (newRoom is empty string "")
      final movedClearedRoom = ScheduleResolutionEngine.resolveScheduleForDate(
        targetDate: DateTime(2026, 8, 24),
        timetableSlots: [baseSlot],
        exceptions: [
          ScheduleExceptionItem(
            timetableSlotId: 'slot_1',
            exceptionDate: '2026-08-24',
            actionType: 'MOVED',
            newStartTime: '10:00',
            newEndTime: '11:00',
            newRoom: '',
          ),
        ],
        extraClasses: [],
        holidays: [],
        dayConfigs: const [],
        existingOutcomes: {},
        semesterId: 'sem_1',
      );
      expect(movedClearedRoom.first.room, isNull);
    });

    test('AppUpdateService Hybrid Fetcher: Returns local bundled notes immediately', () async {
      final info = await AppUpdateService.fetchReleaseNotesForVersion(versionStr: '1.0.0-alpha.4');
      expect(info.latestVersion, equals('1.0.0-alpha.4'));
      expect(info.changelog.isNotEmpty, isTrue);
    });

    test('Auto-Backup Engine: isAutoBackupDue evaluates frequency durations accurately', () async {
      final db = AppDatabase.inMemory();
      final container = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
      ]);
      final notifier = container.read(backupProvider.notifier);

      // 1. When auto backup is disabled -> never due
      notifier.state = notifier.state.copyWith(
        isAutoBackupEnabled: false,
        lastBackupTimestamp: DateTime.now().subtract(const Duration(days: 10)),
      );
      expect(notifier.isAutoBackupDue(), isFalse);

      // 2. When auto backup is enabled but never run (last is null) -> due immediately
      notifier.state = notifier.state.copyWith(
        isAutoBackupEnabled: true,
        lastBackupTimestamp: null,
      );
      expect(notifier.isAutoBackupDue(), isTrue);

      // 3. Every 6 Hours: 4 hours ago -> false, 7 hours ago -> true
      notifier.state = notifier.state.copyWith(
        isAutoBackupEnabled: true,
        frequency: AutoBackupFrequency.every6Hours,
        lastBackupTimestamp: DateTime.now().subtract(const Duration(hours: 4)),
      );
      expect(notifier.isAutoBackupDue(), isFalse);

      notifier.state = notifier.state.copyWith(
        lastBackupTimestamp: DateTime.now().subtract(const Duration(hours: 7)),
      );
      expect(notifier.isAutoBackupDue(), isTrue);

      // 4. Daily: 12 hours ago -> false, 25 hours ago -> true
      notifier.state = notifier.state.copyWith(
        frequency: AutoBackupFrequency.daily,
        lastBackupTimestamp: DateTime.now().subtract(const Duration(hours: 12)),
      );
      expect(notifier.isAutoBackupDue(), isFalse);

      notifier.state = notifier.state.copyWith(
        lastBackupTimestamp: DateTime.now().subtract(const Duration(hours: 25)),
      );
      expect(notifier.isAutoBackupDue(), isTrue);

      // 5. Clock Reversal / Time Traveler Edge Case (clock moved back so last is in future) -> due immediately
      notifier.state = notifier.state.copyWith(
        lastBackupTimestamp: DateTime.now().add(const Duration(hours: 2)),
      );
      expect(notifier.isAutoBackupDue(), isTrue);

      container.dispose();
      await db.close();
    });

    test('ScheduleResolutionEngine: Multi-room weekly schedule resolves correct rooms per day', () {
      final slots = [
        // Mon (Day 1): Room 101 (Lecture)
        TimetableSlotItem(
          id: 'slot_mon',
          semesterId: 'sem_1',
          subjectComponentId: 'sub_physics',
          subjectName: 'Physics',
          category: 'MAJOR',
          componentType: 'LECTURE',
          colorHex: '#4F46E5',
          dayOfWeek: 1,
          startTime: '09:00',
          endTime: '10:00',
          room: 'Room 101',
        ),
        // Tue (Day 2): Physics Lab B (Practical)
        TimetableSlotItem(
          id: 'slot_tue',
          semesterId: 'sem_1',
          subjectComponentId: 'sub_physics',
          subjectName: 'Physics',
          category: 'MAJOR',
          componentType: 'PRACTICAL',
          colorHex: '#4F46E5',
          dayOfWeek: 2,
          startTime: '14:00',
          endTime: '16:00',
          room: 'Physics Lab B',
        ),
      ];

      // Monday Aug 24, 2026
      final monResolved = ScheduleResolutionEngine.resolveScheduleForDate(
        targetDate: DateTime(2026, 8, 24),
        semesterId: 'sem_1',
        holidays: [],
        dayConfigs: const [],
        timetableSlots: slots,
        exceptions: [],
        extraClasses: [],
      );
      expect(monResolved.length, equals(1));
      expect(monResolved.first.room, equals('Room 101'));
      expect(monResolved.first.componentType, equals('LECTURE'));

      // Tuesday Aug 25, 2026
      final tueResolved = ScheduleResolutionEngine.resolveScheduleForDate(
        targetDate: DateTime(2026, 8, 25),
        semesterId: 'sem_1',
        holidays: [],
        dayConfigs: const [],
        timetableSlots: slots,
        exceptions: [],
        extraClasses: [],
      );
      expect(tueResolved.length, equals(1));
      expect(tueResolved.first.room, equals('Physics Lab B'));
      expect(tueResolved.first.componentType, equals('PRACTICAL'));
    });

    test('ScheduleResolutionEngine: Single-date exception preserves default room when newRoom is null', () {
      final slots = [
        TimetableSlotItem(
          id: 'slot_math',
          semesterId: 'sem_1',
          subjectComponentId: 'sub_math',
          subjectName: 'Math',
          category: 'MAJOR',
          componentType: 'LECTURE',
          colorHex: '#4F46E5',
          dayOfWeek: 1,
          startTime: '09:00',
          endTime: '10:00',
          room: 'Room 204',
        ),
      ];

      // Moved time only (newRoom is null) -> should preserve Room 204
      final exceptions = [
        ScheduleExceptionItem(
          timetableSlotId: 'slot_math',
          exceptionDate: '2026-08-24',
          actionType: 'MOVED',
          newStartTime: '10:30',
          newEndTime: '11:30',
          newRoom: null,
        ),
      ];

      final resolved = ScheduleResolutionEngine.resolveScheduleForDate(
        targetDate: DateTime(2026, 8, 24),
        semesterId: 'sem_1',
        holidays: [],
        dayConfigs: const [],
        timetableSlots: slots,
        exceptions: exceptions,
        extraClasses: [],
      );
      expect(resolved.length, equals(1));
      expect(resolved.first.startTime, equals('10:30'));
      expect(resolved.first.room, equals('Room 204'));
    });

    test('TimetableSlotsNotifier: updateRoomForSubject updates all slots for that subject in SQLite', () async {
      final db = AppDatabase.inMemory();
      final nowIso = DateTime.now().toIso8601String();
      await db.saveSemester(
        SemesterData(
          id: 'sem_1',
          name: 'Semester 1',
          startDate: '2026-08-01',
          endDate: '2026-12-31',
          defaultTargetPct: 75.0,
          status: 'ACTIVE',
          createdAt: nowIso,
          updatedAt: nowIso,
        ),
      );

      await db.saveSubject(
        SubjectData(
          id: 'sub_cs',
          semesterId: 'sem_1',
          name: 'Computer Science',
          code: 'CS101',
          category: 'MAJOR',
          credits: 4,
          targetAttendancePct: 75.0,
          baselineHeld: 0,
          baselineAttended: 0,
          isArchived: false,
          colorHex: '#4F46E5',
          createdAt: nowIso,
          updatedAt: nowIso,
        ),
      );

      // Add Mon and Wed slots with Room 101
      await db.saveTimetableSlot(
        TimetableSlotData(
          id: 'slot_1',
          semesterId: 'sem_1',
          subjectComponentId: 'sub_cs',
          dayOfWeek: 1,
          startTime: '09:00',
          endTime: '10:00',
          room: 'Room 101',
          createdAt: nowIso,
          updatedAt: nowIso,
        ),
      );
      await db.saveTimetableSlot(
        TimetableSlotData(
          id: 'slot_2',
          semesterId: 'sem_1',
          subjectComponentId: 'sub_cs',
          dayOfWeek: 3,
          startTime: '11:00',
          endTime: '12:00',
          room: 'Room 101',
          createdAt: nowIso,
          updatedAt: nowIso,
        ),
      );

      final notifier = TimetableSlotsNotifier(db, 'sem_1', []);
      await notifier.loadFromDb();
      expect(notifier.state.length, equals(2));

      // Bulk update room for subject to Room 405
      await notifier.updateRoomForSubject(subjectId: 'sub_cs', newRoom: 'Room 405');

      final updatedSlots = await db.getTimetableSlots('sem_1');
      expect(updatedSlots.length, equals(2));
      expect(updatedSlots.every((s) => s.room == 'Room 405'), isTrue);

      notifier.dispose();
      await db.close();
    });

    testWidgets('RescheduleSessionScreen renders hero card and room input', (tester) async {
      final db = AppDatabase.inMemory();
      final session = ClassSessionEntity(
        id: 'session_1',
        sourceRefId: 'slot_1',
        semesterId: 'sem_1',
        subjectComponentId: 'sub_1',
        subjectName: 'Computer Architecture',
        category: 'MAJOR',
        componentType: 'LECTURE',
        colorHex: '#4F46E5',
        sessionDate: '2026-08-26',
        sessionSource: 'TIMETABLE_RECURRING',
        status: 'PLANNED',
        attendanceOutcome: 'PENDING',
        startTime: '09:00',
        endTime: '10:00',
        room: 'Room 302',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
          ],
          child: MaterialApp(
            home: RescheduleSessionScreen(
              session: session,
              dateIso: '2026-08-26',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Computer Architecture'), findsWidgets);
      expect(find.text('Room 302'), findsWidgets);
      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.text('Cancel class for this date'), findsOneWidget);

      // Button is locked/disabled initially (no changes)
      var saveButton = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Save Changes'));
      expect(saveButton.onPressed, isNull);

      // Make a change
      await tester.enterText(find.byType(TextField), 'Room 404');
      await tester.pumpAndSettle();

      // Button becomes unlocked/enabled
      saveButton = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Save Changes'));
      expect(saveButton.onPressed, isNotNull);

      await db.close();
    });

    testWidgets('SubjectRoomManagerScreen renders bulk and daily room inputs', (tester) async {
      final db = AppDatabase.inMemory();
      final nowIso = DateTime.now().toIso8601String();
      await db.saveSemester(
        SemesterData(
          id: 'sem_1',
          name: 'Semester 1',
          startDate: '2026-08-01',
          endDate: '2026-12-31',
          defaultTargetPct: 75.0,
          status: 'ACTIVE',
          createdAt: nowIso,
          updatedAt: nowIso,
        ),
      );
      await db.saveTimetableSlot(
        TimetableSlotData(
          id: 'slot_1',
          semesterId: 'sem_1',
          subjectComponentId: 'sub_1',
          dayOfWeek: 1,
          startTime: '09:00',
          endTime: '10:00',
          room: 'Room 101',
          createdAt: nowIso,
          updatedAt: nowIso,
        ),
      );
      await db.saveTimetableSlot(
        TimetableSlotData(
          id: 'slot_2',
          semesterId: 'sem_1',
          subjectComponentId: 'sub_1',
          dayOfWeek: 3,
          startTime: '11:00',
          endTime: '12:00',
          room: 'Room 102',
          createdAt: nowIso,
          updatedAt: nowIso,
        ),
      );

      final subject = SubjectEntity(
        id: 'sub_1',
        semesterId: 'sem_1',
        name: 'Database Systems',
        category: 'MAJOR',
        credits: 4,
        targetAttendancePct: 75.0,
        baselineHeld: 0,
        baselineAttended: 0,
        isArchived: false,
        colorHex: '#10B981',
        components: [],
      );

      final notifier = TimetableSlotsNotifier(db, 'sem_1', [subject]);
      await notifier.loadFromDb();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            timetableSlotsProvider.overrideWith((ref) => notifier),
          ],
          child: MaterialApp(
            home: SubjectRoomManagerScreen(
              subject: subject,
              initialRoom: 'Room 101',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Database Systems'), findsWidgets);
      expect(find.text('Room & Location Manager'), findsOneWidget);
      expect(find.text('Save Room Changes'), findsOneWidget);

      // Save button is initially locked/disabled (no changes yet)
      var saveRoomBtn = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Save Room Changes'));
      expect(saveRoomBtn.onPressed, isNull);

      // Apply a change
      await tester.enterText(find.widgetWithText(TextField, 'e.g. Room 405 or Lecture Hall A'), 'Room 500');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Apply'));
      await tester.pumpAndSettle();

      // Save button is now enabled
      saveRoomBtn = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Save Room Changes'));
      expect(saveRoomBtn.onPressed, isNotNull);

      await db.close();
    });
  });
}


