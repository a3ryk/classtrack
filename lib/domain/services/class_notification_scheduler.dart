import 'dart:convert';
import '../../core/services/notification_service.dart';
import '../entities/class_session_entity.dart';
import '../entities/notification_preferences_entity.dart';

class ClassNotificationScheduler {
  final NotificationService notificationService;

  ClassNotificationScheduler({NotificationService? notificationService})
      : notificationService = notificationService ?? NotificationService.instance;

  static int generateNotificationId(String key) {
    return (key.hashCode & 0x7FFFFFFF) % 1000000000;
  }

  static DateTime? parseSessionDateTime(String dateStr, String timeStr) {
    try {
      final dateParts = dateStr.split('-').map(int.parse).toList();
      final timeParts = timeStr.split(':').map(int.parse).toList();
      return DateTime(dateParts[0], dateParts[1], dateParts[2], timeParts[0], timeParts[1]);
    } catch (_) {
      return null;
    }
  }

  /// Schedules start and/or end reminders for upcoming class sessions based on user preferences.
  Future<void> scheduleSessions({
    required List<ClassSessionEntity> sessions,
    required NotificationPreferencesEntity preferences,
  }) async {
    if (!preferences.enabled) {
      await cancelAll();
      return;
    }

    final now = DateTime.now();

    for (final session in sessions) {
      // Don't notify for cancelled classes or holiday / no class days
      if (session.status == 'CANCELLED' ||
          session.status == 'NO_CLASS_DAY' ||
          session.attendanceOutcome == 'CANCELLED') {
        continue;
      }

      final startDt = parseSessionDateTime(session.sessionDate, session.startTime);
      final endDt = parseSessionDateTime(session.sessionDate, session.endTime);

      if (startDt == null || endDt == null) continue;

      final sessionPayload = jsonEncode({
        'sessionId': session.id,
        'slotId': session.sourceRefId ?? session.id,
        'subjectId': session.subjectComponentId,
        'sessionDate': session.sessionDate,
        'subjectName': session.subjectName,
      });

      final hasRoom = session.room != null && session.room!.trim().isNotEmpty;
      final roomText = hasRoom ? 'Room ${session.room!.trim()}' : 'Scheduled';

      // 1. Class Start Reminder
      if (preferences.enableClassStart) {
        final startNotificationTime = startDt.subtract(
          Duration(minutes: preferences.startLeadMinutes),
        );

        if (startNotificationTime.isAfter(now)) {
          final int startId = generateNotificationId('${session.id}_start');
          final String title = session.subjectName;
          final String body = preferences.startLeadMinutes == 0
              ? 'Class starting now • $roomText'
              : 'Class starts in ${preferences.startLeadMinutes} min • $roomText';

          await notificationService.scheduleClassNotification(
            id: startId,
            title: title,
            body: body,
            scheduledTime: startNotificationTime,
            payload: sessionPayload,
            withQuickActions: preferences.enableQuickActions,
            sound: preferences.sound,
            vibrate: preferences.vibrate,
          );
        }
      }

      // 2. Class End Attendance Reminder
      if (preferences.enableClassEnd) {
        final endNotificationTime = endDt.subtract(
          Duration(minutes: preferences.endLeadMinutes),
        );

        if (endNotificationTime.isAfter(now)) {
          final int endId = generateNotificationId('${session.id}_end');
          final String title = 'Mark Attendance: ${session.subjectName}';
          final String body = preferences.endLeadMinutes == 0
              ? 'Class ended • Tap an action to record attendance'
              : 'Class ending in ${preferences.endLeadMinutes} min • Tap an action to record attendance';

          await notificationService.scheduleClassNotification(
            id: endId,
            title: title,
            body: body,
            scheduledTime: endNotificationTime,
            payload: sessionPayload,
            withQuickActions: preferences.enableQuickActions,
            sound: preferences.sound,
            vibrate: preferences.vibrate,
          );
        }
      }
    }
  }

  Future<void> cancelAll() async {
    await notificationService.cancelAllNotifications();
  }
}
