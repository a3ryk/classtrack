import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

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

  /// Sanitizes text ensuring zero em-dashes or en-dashes
  static String sanitizeText(String input) {
    return input.replaceAll('—', '-').replaceAll('–', '-');
  }

  Future<void> init() async {
    if (_isInitialized) return;

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
      await _notificationsPlugin.initialize(settings: initSettings);

      if (Platform.isAndroid) {
        // Request notification and storage permissions on launch
        try {
          await [
            Permission.notification,
            Permission.storage,
          ].request();
        } catch (_) {}

        final androidImpl = _notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        await androidImpl?.requestNotificationsPermission();

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
      }

      _isInitialized = true;
    } catch (_) {
      // Graceful fallback for platforms without native notification permissions
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
