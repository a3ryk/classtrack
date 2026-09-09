import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../data/database/app_database.dart';

/// Top-level background notification response handler
/// Executed by OS BroadcastReceiver when app is in background or completely terminated
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) async {
  WidgetsFlutterBinding.ensureInitialized();
  await _processNotificationAction(response);
}

/// Foreground or app-launch notification response handler
@pragma('vm:entry-point')
void notificationTapForeground(NotificationResponse response) async {
  WidgetsFlutterBinding.ensureInitialized();
  await _processNotificationAction(response);
}

@pragma('vm:entry-point')
Future<void> _processNotificationAction(NotificationResponse response) async {
  final actionId = response.actionId;
  final payloadStr = response.payload;
  if (actionId == null || payloadStr == null || payloadStr.isEmpty) return;

  try {
    final Map<String, dynamic> data = jsonDecode(payloadStr) as Map<String, dynamic>;
    final bool isTest = data['isTest'] == true || data['sessionId'] == 'test_sample_session';
    final String? sessionId = data['sessionId'] as String?;
    final String? slotId = data['slotId'] as String?;
    final String? subjectId = data['subjectId'] as String?;
    final String? sessionDate = data['sessionDate'] as String?;

    if (sessionId == null || sessionId.isEmpty) return;

    String? outcome;
    if (actionId == NotificationService.actionPresent) {
      outcome = 'PRESENT';
    } else if (actionId == NotificationService.actionAbsent) {
      outcome = 'ABSENT';
    } else if (actionId == NotificationService.actionCancelled) {
      outcome = 'CANCELLED';
    }

    if (outcome != null) {
      if (isTest) {
        // NON-DESTRUCTIVE SIMULATION: Do NOT write to real database!
        final sendPort = IsolateNameServer.lookupPortByName(NotificationService.isolateActionPortName);
        if (sendPort != null) {
          sendPort.send(jsonEncode({'isTest': true, 'action': outcome}));
        } else {
          NotificationService.onTestNotificationAction.add(outcome);
        }
        if (response.id != null) {
          await NotificationService.instance.cancelNotification(response.id!);
        }
        return;
      }

      final db = AppDatabase.production();
      final nowIso = DateTime.now().toIso8601String();
      final record = AttendanceRecordData(
        id: sessionId,
        classSessionId: sessionId,
        slotId: slotId,
        subjectId: subjectId,
        sessionDate: sessionDate,
        outcome: outcome,
        markedAt: nowIso,
        notes: 'Marked via notification action ($outcome)',
        syncVersion: 1,
        createdAt: nowIso,
        updatedAt: nowIso,
      );
      await db.saveAttendanceRecord(record);
      await db.close();

      // Broadcast cross-isolate to running UI isolate if active, or locally in same isolate
      final sendPort = IsolateNameServer.lookupPortByName(NotificationService.isolateActionPortName);
      if (sendPort != null) {
        sendPort.send(jsonEncode(record.toJson()));
      } else {
        NotificationService.onAttendanceActionMarked.add(record);
      }

      // Dismiss the notification from tray
      if (response.id != null) {
        await NotificationService.instance.cancelNotification(response.id!);
      }

      // Cancel BOTH start and end reminders for this session
      final startReminderId = ('${sessionId}_start'.hashCode & 0x7FFFFFFF) % 1000000000;
      final endReminderId = ('${sessionId}_end'.hashCode & 0x7FFFFFFF) % 1000000000;
      await NotificationService.instance.cancelNotification(startReminderId);
      await NotificationService.instance.cancelNotification(endReminderId);
    }
  } catch (e) {
    debugPrint('Error handling notification background action: $e');
  }
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  /// Broadcast stream notifying running listeners whenever an attendance action is recorded from a notification
  static final StreamController<AttendanceRecordData> onAttendanceActionMarked =
      StreamController<AttendanceRecordData>.broadcast();

  /// Broadcast stream for test notification simulation events (non-destructive feedback)
  static final StreamController<String> onTestNotificationAction =
      StreamController<String>.broadcast();

  static const String isolateActionPortName = 'classtrack_notification_action_port';
  ReceivePort? _actionReceivePort;

  /// Sets up cross-isolate communication so actions executed in background isolates
  /// are cleanly forwarded to the main UI isolate's StreamController.
  void setupIsolateCommunication() {
    try {
      IsolateNameServer.removePortNameMapping(isolateActionPortName);
      final port = ReceivePort();
      final registered = IsolateNameServer.registerPortWithName(port.sendPort, isolateActionPortName);
      if (registered) {
        _actionReceivePort?.close();
        _actionReceivePort = port;
        port.listen((dynamic message) {
          if (message is String) {
            try {
              final data = jsonDecode(message) as Map<String, dynamic>;
              if (data['isTest'] == true) {
                final action = data['action'] as String? ?? 'PRESENT';
                onTestNotificationAction.add(action);
                return;
              }
              final record = AttendanceRecordData.fromJson(data);
              onAttendanceActionMarked.add(record);
            } catch (e) {
              debugPrint('NotificationService: Failed to parse action message from isolate: $e');
            }
          }
        });
      }
    } catch (e) {
      debugPrint('NotificationService: Failed to setup isolate communication: $e');
    }
  }

  /// Visible for testing: allows direct simulation of notification response action
  @visibleForTesting
  static Future<void> handleNotificationAction(NotificationResponse response) async {
    await _processNotificationAction(response);
  }

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  static const int exportProgressNotificationId = 1001;
  static const int exportCompleteNotificationId = 1002;
  static const int backupNotificationId = 1003;
  static const int generalNotificationId = 1004;
  static const int updateNotificationId = 1005;

  static const String exportChannelId = 'classtrack_exports';
  static const String exportChannelName = 'Export & Reports';

  static const String backupChannelId = 'classtrack_backups';
  static const String backupChannelName = 'Backups & Sync';

  static const String generalChannelId = 'classtrack_general';
  static const String generalChannelName = 'ClassTrack Alerts';

  static const String updateChannelId = 'classtrack_updates';
  static const String updateChannelName = 'App Updates';

  static const String classRemindersChannelId = 'classtrack_class_reminders';
  static const String classRemindersChannelName = 'Class Reminders & Attendance';

  // Dedicated sound & vibration channels for Android 8+
  static const String channelRemindersAll = 'classtrack_reminders_all';
  static const String channelRemindersSoundOnly = 'classtrack_reminders_sound';
  static const String channelRemindersVibrateOnly = 'classtrack_reminders_vibrate';
  static const String channelRemindersSilent = 'classtrack_reminders_silent';

  /// Resolves the exact system notification channel based on user sound & vibrate preferences
  static String resolveChannelId({required bool sound, required bool vibrate}) {
    if (sound && vibrate) return channelRemindersAll;
    if (sound && !vibrate) return channelRemindersSoundOnly;
    if (!sound && vibrate) return channelRemindersVibrateOnly;
    return channelRemindersSilent;
  }

  // Notification Action IDs
  static const String actionPresent = 'ATTENDANCE_PRESENT';
  static const String actionAbsent = 'ATTENDANCE_ABSENT';
  static const String actionCancelled = 'ATTENDANCE_CANCELLED';

  /// Sanitizes text ensuring zero em-dashes or en-dashes
  static String sanitizeText(String input) {
    return input.replaceAll('—', '-').replaceAll('–', '-');
  }

  /// Checks and requests runtime notification permission (POST_NOTIFICATIONS on Android 13+)
  static Future<bool> checkAndRequestNotificationPermission() async {
    if (kIsWeb) return true;
    if (!Platform.isAndroid && !Platform.isIOS) return true;

    try {
      if (Platform.isAndroid || Platform.isIOS) {
        var status = await Permission.notification.status;
        if (!status.isGranted) {
          status = await Permission.notification.request();
        }
        return status.isGranted;
      }
    } catch (_) {
      return true;
    }
    return true;
  }

  /// Checks whether exact alarms can be scheduled on Android 12+
  Future<bool> canScheduleExactAlarms() async {
    if (!Platform.isAndroid) return true;
    try {
      final androidImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      return await androidImpl?.canScheduleExactNotifications() ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Requests exact alarms permission from the OS
  Future<void> requestExactAlarmsPermission() async {
    if (!Platform.isAndroid) return;
    try {
      final androidImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.requestExactAlarmsPermission();
    } catch (_) {}
  }

  void _initTimezones() {
    try {
      tz.initializeTimeZones();
      final now = DateTime.now();

      // 1. Try matching by system timezone name if recognized
      try {
        final loc = tz.getLocation(now.timeZoneName);
        tz.setLocalLocation(loc);
        return;
      } catch (_) {}

      // 2. Match by current device offset
      final offsetMs = now.timeZoneOffset.inMilliseconds;
      for (final loc in tz.timeZoneDatabase.locations.values) {
        if (loc.currentTimeZone.offset == offsetMs) {
          tz.setLocalLocation(loc);
          return;
        }
      }
    } catch (e) {
      debugPrint('Timezone initialization note: $e');
    }
  }

  Future<void> init() async {
    setupIsolateCommunication();
    if (_isInitialized) return;

    _initTimezones();

    const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
    );

    try {
      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: notificationTapForeground,
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );

      if (Platform.isAndroid) {
        try {
          await [
            Permission.notification,
            Permission.storage,
          ].request();
        } catch (_) {}

        final androidImpl = _notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        await androidImpl?.requestNotificationsPermission();
        await androidImpl?.requestExactAlarmsPermission();

        // 1. Export Channel
        await androidImpl?.createNotificationChannel(const AndroidNotificationChannel(
          exportChannelId,
          exportChannelName,
          description: 'Notifications for data exports and reports',
          importance: Importance.high,
          playSound: true,
        ));

        // 2. Backup Channel
        await androidImpl?.createNotificationChannel(const AndroidNotificationChannel(
          backupChannelId,
          backupChannelName,
          description: 'Notifications for backups and data restoration',
          importance: Importance.high,
          playSound: true,
        ));

        // 3. General Channel
        await androidImpl?.createNotificationChannel(const AndroidNotificationChannel(
          generalChannelId,
          generalChannelName,
          description: 'General academic and timetable alerts',
          importance: Importance.high,
          playSound: true,
        ));

        // 4. Update Channel
        await androidImpl?.createNotificationChannel(const AndroidNotificationChannel(
          updateChannelId,
          updateChannelName,
          description: 'Notifications for in-app updates',
          importance: Importance.high,
          playSound: true,
        ));

        // 5. Class Reminders Channels (Sound & Vibrate matrix for Android 8+)
        await androidImpl?.createNotificationChannel(const AndroidNotificationChannel(
          channelRemindersAll,
          'Class Reminders (Sound & Vibrate)',
          description: 'Notifications with sound and vibration',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ));

        await androidImpl?.createNotificationChannel(const AndroidNotificationChannel(
          channelRemindersSoundOnly,
          'Class Reminders (Sound Only)',
          description: 'Notifications with sound only',
          importance: Importance.high,
          playSound: true,
          enableVibration: false,
        ));

        await androidImpl?.createNotificationChannel(const AndroidNotificationChannel(
          channelRemindersVibrateOnly,
          'Class Reminders (Vibrate Only)',
          description: 'Notifications with vibration only',
          importance: Importance.high,
          playSound: false,
          enableVibration: true,
        ));

        await androidImpl?.createNotificationChannel(const AndroidNotificationChannel(
          channelRemindersSilent,
          'Class Reminders (Silent)',
          description: 'Silent notifications without sound or vibration',
          importance: Importance.low,
          playSound: false,
          enableVibration: false,
        ));
      }

      _isInitialized = true;
    } catch (_) {
      // Graceful fallback for platforms without native notification permissions
    }
  }

  /// Schedules a future class notification using exact alarm
  Future<void> scheduleClassNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String payload,
    bool withQuickActions = true,
    bool sound = true,
    bool vibrate = true,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await init();

    if (scheduledTime.isBefore(DateTime.now())) return;

    try {
      final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);
      final actions = withQuickActions
          ? const [
              AndroidNotificationAction(
                actionPresent,
                'Present',
                showsUserInterface: false,
                cancelNotification: true,
              ),
              AndroidNotificationAction(
                actionAbsent,
                'Absent',
                showsUserInterface: false,
                cancelNotification: true,
              ),
              AndroidNotificationAction(
                actionCancelled,
                'Cancelled',
                showsUserInterface: false,
                cancelNotification: true,
              ),
            ]
          : const <AndroidNotificationAction>[];

      final channelId = resolveChannelId(sound: sound, vibrate: vibrate);
      final androidDetails = AndroidNotificationDetails(
        channelId,
        classRemindersChannelName,
        channelDescription: 'Class reminders and quick attendance actions',
        importance: (sound || vibrate) ? Importance.high : Importance.low,
        priority: (sound || vibrate) ? Priority.high : Priority.low,
        playSound: sound,
        enableVibration: vibrate,
        vibrationPattern: vibrate ? null : Int64List.fromList([0]),
        actions: actions,
        autoCancel: true,
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
        groupKey: 'classtrack_reminders_group',
        groupAlertBehavior: GroupAlertBehavior.children,
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      final canExact = await canScheduleExactAlarms();
      final scheduleMode = canExact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;

      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: sanitizeText(title),
        body: sanitizeText(body),
        scheduledDate: tzTime,
        notificationDetails: details,
        androidScheduleMode: scheduleMode,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Failed to schedule class notification: $e');
    }
  }

  /// Shows an instant notification (e.g. for testing from Notification Settings)
  Future<void> showImmediateClassNotification({
    required int id,
    required String title,
    required String body,
    required String payload,
    bool withQuickActions = true,
    bool sound = true,
    bool vibrate = true,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await init();

    if (Platform.isAndroid) {
      try {
        final status = await Permission.notification.status;
        if (!status.isGranted) {
          await Permission.notification.request();
        }
      } catch (_) {}
    }

    try {
      final actions = withQuickActions
          ? const [
              AndroidNotificationAction(
                actionPresent,
                'Present',
                showsUserInterface: false,
                cancelNotification: true,
              ),
              AndroidNotificationAction(
                actionAbsent,
                'Absent',
                showsUserInterface: false,
                cancelNotification: true,
              ),
              AndroidNotificationAction(
                actionCancelled,
                'Cancelled',
                showsUserInterface: false,
                cancelNotification: true,
              ),
            ]
          : const <AndroidNotificationAction>[];

      final channelId = resolveChannelId(sound: sound, vibrate: vibrate);
      final androidDetails = AndroidNotificationDetails(
        channelId,
        classRemindersChannelName,
        channelDescription: 'Class reminders and quick attendance actions',
        importance: (sound || vibrate) ? Importance.high : Importance.low,
        priority: (sound || vibrate) ? Priority.high : Priority.low,
        playSound: sound,
        enableVibration: vibrate,
        vibrationPattern: vibrate ? null : Int64List.fromList([0]),
        actions: actions,
        autoCancel: true,
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
        groupKey: 'classtrack_reminders_group',
        groupAlertBehavior: GroupAlertBehavior.children,
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      await _notificationsPlugin.show(
        id: id,
        title: sanitizeText(title),
        body: sanitizeText(body),
        notificationDetails: details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Failed to show immediate class notification: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    try {
      await _notificationsPlugin.cancel(id: id);
    } catch (_) {}
  }

  Future<void> cancelAllNotifications() async {
    try {
      await _notificationsPlugin.cancelAll();
    } catch (_) {}
  }

  /// Returns all currently scheduled pending notification requests from Android AlarmManager
  Future<List<PendingNotificationRequest>> getPendingNotificationRequests() async {
    try {
      return await _notificationsPlugin.pendingNotificationRequests();
    } catch (_) {
      return [];
    }
  }

  /// Cancels only pending class reminder alarms scheduled in AlarmManager,
  /// preserving active tray notifications and static system alerts (export, backup, update)
  Future<void> cancelAllPendingClassReminders() async {
    try {
      final pending = await _notificationsPlugin.pendingNotificationRequests();
      for (final req in pending) {
        final isClassReminder = req.id > 10005 || (req.payload != null && req.payload!.contains('sessionId'));
        if (isClassReminder) {
          await _notificationsPlugin.cancel(id: req.id);
        }
      }
    } catch (e) {
      debugPrint('Failed to cancel pending class reminders: $e');
    }
  }

  Future<void> showExportProgressNotification({
    required int progressPercent,
    required String message,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await init();

    final androidDetails = AndroidNotificationDetails(
      exportChannelId,
      exportChannelName,
      channelDescription: 'Notifications for long-running data exports',
      importance: Importance.low,
      priority: Priority.low,
      showProgress: true,
      maxProgress: 100,
      progress: progressPercent,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
    );

    final details = NotificationDetails(android: androidDetails);

    try {
      await _notificationsPlugin.show(
        id: exportProgressNotificationId,
        title: sanitizeText('Exporting Attendance Data ($progressPercent%)'),
        body: sanitizeText(message),
        notificationDetails: details,
      );
    } catch (_) {}
  }

  Future<void> showExportCompleteNotification({
    required String filePath,
    required String title,
    required String body,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await init();

    try {
      await _notificationsPlugin.cancel(id: exportProgressNotificationId);

      const androidDetails = AndroidNotificationDetails(
        exportChannelId,
        exportChannelName,
        channelDescription: 'Notifications for completed data exports',
        importance: Importance.high,
        priority: Priority.high,
        autoCancel: true,
      );

      const details = NotificationDetails(android: androidDetails);

      await _notificationsPlugin.show(
        id: exportCompleteNotificationId,
        title: sanitizeText(title),
        body: sanitizeText(body),
        notificationDetails: details,
      );
    } catch (_) {}
  }

  Future<void> showBackupNotification({
    required String title,
    required String body,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await init();

    try {
      const androidDetails = AndroidNotificationDetails(
        backupChannelId,
        backupChannelName,
        channelDescription: 'Notifications for backups and data restoration',
        importance: Importance.high,
        priority: Priority.high,
        autoCancel: true,
      );

      const details = NotificationDetails(android: androidDetails);

      await _notificationsPlugin.show(
        id: backupNotificationId,
        title: sanitizeText(title),
        body: sanitizeText(body),
        notificationDetails: details,
      );
    } catch (_) {}
  }

  Future<void> showGeneralNotification({
    required String title,
    required String body,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await init();

    try {
      const androidDetails = AndroidNotificationDetails(
        generalChannelId,
        generalChannelName,
        channelDescription: 'General academic and timetable alerts',
        importance: Importance.high,
        priority: Priority.high,
        autoCancel: true,
      );

      const details = NotificationDetails(android: androidDetails);

      await _notificationsPlugin.show(
        id: generalNotificationId,
        title: sanitizeText(title),
        body: sanitizeText(body),
        notificationDetails: details,
      );
    } catch (_) {}
  }

  Future<void> cancelExportNotifications() async {
    try {
      await _notificationsPlugin.cancel(id: exportProgressNotificationId);
    } catch (_) {}
  }
}
