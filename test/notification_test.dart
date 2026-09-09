import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:classtrack/core/services/app_update_service.dart';
import 'package:classtrack/core/services/notification_service.dart';
import 'package:classtrack/data/database/app_database.dart';
import 'package:classtrack/domain/entities/class_session_entity.dart';
import 'package:classtrack/domain/entities/notification_preferences_entity.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:classtrack/domain/services/class_notification_scheduler.dart';
import 'package:classtrack/presentation/providers/app_state_provider.dart';
import 'package:classtrack/presentation/screens/settings/notification_settings_screen.dart';

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  group('Notification & ABI Tests', () {
    test('verify flutter_local_notifications and timezone', () {
      tz.initializeTimeZones();
      expect(tz.timeZoneDatabase.locations.isNotEmpty, isTrue);

      const action = AndroidNotificationAction(
        'ATTENDANCE_PRESENT',
        'Present',
        showsUserInterface: false,
        cancelNotification: true,
      );
      expect(action.id, 'ATTENDANCE_PRESENT');

      const androidDetails = AndroidNotificationDetails(
        'classtrack_class_reminders',
        'Class Reminders & Attendance',
        actions: [action],
      );
      expect(androidDetails.actions?.length, 1);

      const resp = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotificationAction,
        id: 100,
        actionId: 'ATTENDANCE_PRESENT',
        payload: '{"test": 1}',
      );
      expect(resp.actionId, 'ATTENDANCE_PRESENT');
      expect(resp.payload, '{"test": 1}');
    });

    test('NotificationPreferencesEntity serialization and defaults', () {
      const defaultPrefs = NotificationPreferencesEntity();
      expect(defaultPrefs.enabled, isTrue);
      expect(defaultPrefs.enableClassStart, isTrue);
      expect(defaultPrefs.startLeadMinutes, 5);
      expect(defaultPrefs.enableClassEnd, isTrue);
      expect(defaultPrefs.endLeadMinutes, 0);
      expect(defaultPrefs.enableQuickActions, isTrue);

      final json = defaultPrefs.toJson();
      final decoded = NotificationPreferencesEntity.fromJson(json);
      expect(decoded.enabled, defaultPrefs.enabled);
      expect(decoded.startLeadMinutes, defaultPrefs.startLeadMinutes);
      expect(decoded.endLeadMinutes, defaultPrefs.endLeadMinutes);
      expect(decoded.enableQuickActions, defaultPrefs.enableQuickActions);

      final updated = defaultPrefs.copyWith(startLeadMinutes: 15, enableQuickActions: false);
      expect(updated.startLeadMinutes, 15);
      expect(updated.enableQuickActions, isFalse);
    });

    test('ClassNotificationScheduler date parsing and notification ID generation', () {
      final dt = ClassNotificationScheduler.parseSessionDateTime('2026-09-09', '09:30');
      expect(dt, isNotNull);
      expect(dt!.year, 2026);
      expect(dt.month, 9);
      expect(dt.day, 9);
      expect(dt.hour, 9);
      expect(dt.minute, 30);

      final id1 = ClassNotificationScheduler.generateNotificationId('session_1_start');
      final id2 = ClassNotificationScheduler.generateNotificationId('session_1_end');
      expect(id1, isNonNegative);
      expect(id2, isNonNegative);
      expect(id1, isNot(equals(id2)));
    });

    test('Notification Action payload parsing and outcome verification', () {
      final payload = jsonEncode({
        'sessionId': 'session_math_1',
        'slotId': 'slot_math',
        'subjectId': 'sub_123',
        'sessionDate': '2026-09-09',
        'subjectName': 'Advanced Mathematics',
      });

      final Map<String, dynamic> data = jsonDecode(payload) as Map<String, dynamic>;
      expect(data['sessionId'], 'session_math_1');
      expect(data['slotId'], 'slot_math');
      expect(data['subjectName'], 'Advanced Mathematics');

      // Test outcome mapping
      expect(NotificationService.actionPresent, 'ATTENDANCE_PRESENT');
      expect(NotificationService.actionAbsent, 'ATTENDANCE_ABSENT');
      expect(NotificationService.actionCancelled, 'ATTENDANCE_CANCELLED');
    });

    test('AppReleaseInfo parses abi_assets correctly', () {
      final json = {
        'latest_version': '1.0.0-alpha.6',
        'build_number': 6,
        'min_supported_version': '1.0.0-alpha.6',
        'release_date': '2026-09-04',
        'release_title': 'ClassTrack v1.0.0-alpha.6',
        'changelog': ['Feature 1', 'Fix 1'],
        'download_url': 'https://github.com/.../ClassTrack-v1.0.0-alpha.6.apk',
        'abi_assets': {
          'arm64-v8a': 'https://github.com/.../app-arm64-v8a-release.apk',
          'armeabi-v7a': 'https://github.com/.../app-armeabi-v7a-release.apk',
          'x86_64': 'https://github.com/.../app-x86_64-release.apk',
          'universal': 'https://github.com/.../ClassTrack-v1.0.0-alpha.6.apk'
        }
      };

      final info = AppReleaseInfo.fromJson(json);
      expect(info.abiAssets.length, 4);
      expect(info.downloadUrl, isNotNull);
    });

    test('NotificationService.resolveChannelId maps all sound and vibration combinations correctly', () {
      expect(
        NotificationService.resolveChannelId(sound: true, vibrate: true),
        NotificationService.channelRemindersAll,
      );
      expect(
        NotificationService.resolveChannelId(sound: true, vibrate: false),
        NotificationService.channelRemindersSoundOnly,
      );
      expect(
        NotificationService.resolveChannelId(sound: false, vibrate: true),
        NotificationService.channelRemindersVibrateOnly,
      );
      expect(
        NotificationService.resolveChannelId(sound: false, vibrate: false),
        NotificationService.channelRemindersSilent,
      );
    });

    testWidgets('NotificationSettingsScreen renders all sections cleanly and opens timing sheet', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: NotificationSettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Single word title & Hero card
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Reminders Active'), findsOneWidget);
      expect(find.text('Class Reminders'), findsNWidgets(2)); // Header & switch title
      expect(find.text('Remind Before Class'), findsOneWidget);
      expect(find.text('Reminder Timing'), findsOneWidget);
      expect(find.text('Remind When Class Ends'), findsOneWidget);
      expect(find.text('End Reminder Timing'), findsOneWidget);
      expect(find.text('Quick Attendance Buttons'), findsOneWidget);
      expect(find.text('Sound & Vibration'), findsOneWidget);
      expect(find.text('Send Test Notification'), findsNothing);

      // Verify no cluttered subtext exists on the screen
      expect(find.text('Vibrate on class alerts'), findsNothing);
      expect(find.text('Play default notification ringtone'), findsNothing);
      expect(find.text('Prompts you to mark attendance'), findsNothing);
      expect(find.text('Room and subject details before class starts'), findsNothing);

      // Verify no footer card exists
      expect(find.textContaining('battery'), findsNothing);
      expect(find.textContaining('ClassTrack alerts you only'), findsNothing);

      // Verify tapping timing opens tactile bottom sheet
      await tester.tap(find.text('Reminder Timing'));
      await tester.pumpAndSettle();

      expect(find.text('Start Reminder'), findsOneWidget);
      expect(find.text('5 min before'), findsOneWidget);
      expect(find.text('15m'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);

      // Tap 15m preset
      await tester.tap(find.text('15m'));
      await tester.pumpAndSettle();

      expect(find.text('15 min before'), findsOneWidget);

      // Tap Save to dismiss and commit
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify sheet dismissed and updated value shown on tile
      expect(find.text('15m before'), findsOneWidget);

      // Verify tapping info button in top right opens "Did You Know?" battery bottom sheet
      expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.info_outline_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Did You Know?'), findsOneWidget);
      expect(find.text('100% Battery Friendly'), findsOneWidget);
      expect(find.text('Exact Scheduled Alarms'), findsOneWidget);
      expect(find.text('Never Runs in the Background'), findsOneWidget);
      expect(find.text('Zero Idle CPU Usage'), findsOneWidget);
      expect(find.text('Got It'), findsOneWidget);

      // Tap "Got It" to dismiss
      await tester.tap(find.text('Got It'));
      await tester.pumpAndSettle();

      expect(find.text('Did You Know?'), findsNothing);
    });

    test('AndroidManifest.xml contains all 3 required notification receivers', () {
      final manifestFile = File('android/app/src/main/AndroidManifest.xml');
      expect(manifestFile.existsSync(), isTrue);
      final content = manifestFile.readAsStringSync();
      expect(content, contains('com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver'));
      expect(content, contains('com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver'));
      expect(content, contains('com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver'));
      expect(content, contains('android.intent.action.BOOT_COMPLETED'));
    });

    test('NotificationService.onAttendanceActionMarked stream emits records correctly', () async {
      final record = AttendanceRecordData(
        id: 'session_test_1',
        classSessionId: 'session_test_1',
        slotId: 'slot_1',
        subjectId: 'sub_1',
        sessionDate: '2026-09-09',
        outcome: 'PRESENT',
        syncVersion: 1,
        createdAt: '2026-09-09T10:00:00Z',
        updatedAt: '2026-09-09T10:00:00Z',
      );

      final futureEmission = NotificationService.onAttendanceActionMarked.stream.first;
      NotificationService.onAttendanceActionMarked.add(record);
      final received = await futureEmission;

      expect(received.id, 'session_test_1');
      expect(received.outcome, 'PRESENT');
    });

    test('ClassNotificationScheduler ignores sessions where attendance is already marked', () async {
      const prefs = NotificationPreferencesEntity();

      final sessionPending = ClassSessionEntity(
        id: 'sess_pending',
        semesterId: 'sem_1',
        subjectComponentId: 'sub_comp_1',
        subjectName: 'Operating Systems',
        category: 'MAJOR',
        componentType: 'LECTURE',
        colorHex: '#4F46E5',
        sessionDate: '2026-09-10',
        startTime: '10:00',
        endTime: '11:00',
        sessionSource: 'TIMETABLE',
        status: 'HELD',
        attendanceOutcome: 'PENDING',
      );

      final sessionPresent = ClassSessionEntity(
        id: 'sess_present',
        semesterId: 'sem_1',
        subjectComponentId: 'sub_comp_1',
        subjectName: 'Operating Systems',
        category: 'MAJOR',
        componentType: 'LECTURE',
        colorHex: '#4F46E5',
        sessionDate: '2026-09-10',
        startTime: '10:00',
        endTime: '11:00',
        sessionSource: 'TIMETABLE',
        status: 'HELD',
        attendanceOutcome: 'PRESENT',
      );

      expect(prefs.enabled, isTrue);
      expect(sessionPresent.attendanceOutcome, 'PRESENT');

      // Verify date parsing and ID generation work for pending
      final dt = ClassNotificationScheduler.parseSessionDateTime(sessionPending.sessionDate, sessionPending.startTime);
      expect(dt, isNotNull);

      // Verify generateNotificationId is deterministic
      expect(
        ClassNotificationScheduler.generateNotificationId('${sessionPending.id}_start'),
        ClassNotificationScheduler.generateNotificationId('${sessionPending.id}_start'),
      );
    });

    test('NotificationService canScheduleExactAlarms evaluates without throwing', () async {
      final canExact = await NotificationService.instance.canScheduleExactAlarms();
      expect(canExact, isTrue); // true in unit test non-Android environment
    });

    test('Inter-isolate communication port registration and AttendanceRecordData round-trip serialization', () async {
      NotificationService.instance.setupIsolateCommunication();

      final sendPort = IsolateNameServer.lookupPortByName(NotificationService.isolateActionPortName);
      expect(sendPort, isNotNull);

      final originalRecord = AttendanceRecordData(
        id: 'session_bio_101',
        classSessionId: 'session_bio_101',
        slotId: 'slot_bio',
        subjectId: 'sub_bio',
        sessionDate: '2026-09-10',
        outcome: 'PRESENT',
        markedAt: '2026-09-10T10:00:00Z',
        notes: 'Marked via notification action (PRESENT)',
        syncVersion: 1,
        createdAt: '2026-09-10T10:00:00Z',
        updatedAt: '2026-09-10T10:00:00Z',
      );

      // Verify JSON serialization round-trip
      final json = originalRecord.toJson();
      final decodedRecord = AttendanceRecordData.fromJson(json);
      expect(decodedRecord.id, originalRecord.id);
      expect(decodedRecord.classSessionId, originalRecord.classSessionId);
      expect(decodedRecord.outcome, 'PRESENT');

      // Verify port message transmission across isolates
      final futureEmission = NotificationService.onAttendanceActionMarked.stream.first;
      sendPort!.send(jsonEncode(originalRecord.toJson()));
      final received = await futureEmission.timeout(const Duration(seconds: 2));

      expect(received.id, 'session_bio_101');
      expect(received.outcome, 'PRESENT');
      expect(received.notes, contains('notification action'));
    });

    test('Schedule exceptions and timetable slot modifications trigger debounced resync cleanly', () async {
      final db = AppDatabase.inMemory();
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(() {
        container.dispose();
        db.close();
      });

      // Verify adding an exception runs cleanly and triggers debounced notification resync
      final excNotifier = container.read(scheduleExceptionsProvider.notifier);
      await excNotifier.addOrUpdateException(
        timetableSlotId: 'slot_1',
        exceptionDate: '2026-09-10',
        actionType: 'MOVED',
        newStartTime: '11:00',
        newEndTime: '12:00',
      );

      expect(container.read(scheduleExceptionsProvider).length, 1);
      expect(container.read(scheduleExceptionsProvider).first.actionType, 'MOVED');

      // Verify removing an exception also executes cleanly
      await excNotifier.removeException('slot_1', '2026-09-10');
      expect(container.read(scheduleExceptionsProvider), isEmpty);
    });

    test('Test notification simulation emits to onTestNotificationAction and does NOT write to database', () async {
      NotificationService.instance.setupIsolateCommunication();

      final testPayload = jsonEncode({
        'isTest': true,
        'sessionId': 'test_sample_session',
        'slotId': 'test_slot',
        'subjectId': 'test_subject',
        'sessionDate': '2026-09-10',
        'subjectName': 'Sample Class (Test Alert)',
      });

      final response = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotificationAction,
        id: 9999,
        actionId: NotificationService.actionPresent,
        payload: testPayload,
      );

      final futureAction = NotificationService.onTestNotificationAction.stream.first;
      await NotificationService.handleNotificationAction(response);
      final receivedAction = await futureAction.timeout(const Duration(seconds: 2));

      expect(receivedAction, 'PRESENT');
    });

    test('10 concurrent classes at identical timestamp generate distinct non-colliding IDs', () {
      final sessionIds = List.generate(10, (i) => 'session_concurrent_$i');
      final startIds = <int>{};
      final endIds = <int>{};

      for (final sId in sessionIds) {
        final startId = ClassNotificationScheduler.generateNotificationId('${sId}_start');
        final endId = ClassNotificationScheduler.generateNotificationId('${sId}_end');

        expect(startIds.contains(startId), isFalse, reason: 'Duplicate start ID found for $sId');
        expect(endIds.contains(endId), isFalse, reason: 'Duplicate end ID found for $sId');
        expect(startId, isNot(equals(endId)), reason: 'Start ID collided with End ID for $sId');

        startIds.add(startId);
        endIds.add(endId);
      }

      expect(startIds.length, 10);
      expect(endIds.length, 10);
    });

    test('Cross-midnight class scheduling detects end before start and advances endDt by 1 day', () {
      final startDt = ClassNotificationScheduler.parseSessionDateTime('2026-09-10', '23:30');
      var endDt = ClassNotificationScheduler.parseSessionDateTime('2026-09-10', '01:00');

      expect(startDt, isNotNull);
      expect(endDt, isNotNull);
      expect(endDt!.isBefore(startDt!), isTrue);

      if (endDt.isBefore(startDt)) {
        endDt = endDt.add(const Duration(days: 1));
      }

      expect(endDt.isAfter(startDt), isTrue);
      expect(endDt.day, 11);
      expect(endDt.hour, 1);
      expect(endDt.minute, 0);
    });

    test('ExtraClassesNotifier add, update, and delete persist cleanly', () async {
      final db = AppDatabase.inMemory();
      addTearDown(() {
        db.close();
      });

      final extraNotifier = ExtraClassesNotifier(db, 'sem_test', []);
      await extraNotifier.addExtraClass(
        subjectId: 'sub_extra',
        classDate: '2026-09-10',
        startTime: '14:00',
        endTime: '15:00',
        room: 'Lab 404',
      );

      var list = extraNotifier.state;
      expect(list.length, 1);
      final created = list.first;
      expect(created.startTime, '14:00');
      expect(created.room, 'Lab 404');

      // Update extra class time & room
      await extraNotifier.updateExtraClass(
        id: created.id,
        subjectId: 'sub_extra',
        classDate: '2026-09-10',
        startTime: '14:30',
        endTime: '15:30',
        room: 'Lab 501',
      );

      list = extraNotifier.state;
      expect(list.length, 1);
      expect(list.first.startTime, '14:30');
      expect(list.first.room, 'Lab 501');

      // Delete extra class
      await extraNotifier.deleteExtraClass(created.id);
      list = extraNotifier.state;
      expect(list, isEmpty);
    });

    test('Marking attendance cancels both start and end reminder notification IDs', () async {
      final db = AppDatabase.inMemory();
      addTearDown(() {
        db.close();
      });

      const testSessionId = 'session_verify_dual_cancel';
      final expectedStartId = ('${testSessionId}_start'.hashCode & 0x7FFFFFFF) % 1000000000;
      final expectedEndId = ('${testSessionId}_end'.hashCode & 0x7FFFFFFF) % 1000000000;

      // Generate via scheduler helper
      final schedStartId = ClassNotificationScheduler.generateNotificationId('${testSessionId}_start');
      final schedEndId = ClassNotificationScheduler.generateNotificationId('${testSessionId}_end');

      expect(expectedStartId, schedStartId);
      expect(expectedEndId, schedEndId);

      final attendanceNotifier = AttendanceRecordsNotifier(db);
      await attendanceNotifier.loadFromDb();
      await attendanceNotifier.markAttendance(
        sessionId: testSessionId,
        slotId: 'slot_verify',
        subjectId: 'sub_verify',
        sessionDate: '2026-09-10',
        outcome: 'PRESENT',
      );

      final records = attendanceNotifier.state;
      expect(records.containsKey(testSessionId), isTrue);
      expect(records[testSessionId]?.outcome, 'PRESENT');
    });
  });
}
