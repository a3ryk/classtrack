import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:classtrack/core/services/app_update_service.dart';
import 'package:classtrack/core/services/notification_service.dart';
import 'package:classtrack/domain/entities/notification_preferences_entity.dart';
import 'package:classtrack/domain/services/class_notification_scheduler.dart';
import 'package:classtrack/presentation/screens/settings/notification_settings_screen.dart';

void main() {
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

      // Single word title
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Class Reminders'), findsNWidgets(2)); // Header & switch title
      expect(find.text('Remind Before Class'), findsOneWidget);
      expect(find.text('Reminder Timing'), findsOneWidget);
      expect(find.text('Remind When Class Ends'), findsOneWidget);
      expect(find.text('End Reminder Timing'), findsOneWidget);
      expect(find.text('Quick Attendance Buttons'), findsOneWidget);
      expect(find.text('Alerts & Testing'), findsOneWidget);
      expect(find.text('Send Test Notification'), findsOneWidget);

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
    });
  });
}
