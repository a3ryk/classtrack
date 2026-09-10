import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../../domain/entities/class_session_entity.dart';
import '../../domain/entities/semester_entity.dart';
import '../../domain/entities/attendance_stats.dart';
import '../../domain/entities/widget_settings_entity.dart';
import '../../domain/services/schedule_engine.dart';

/// Service responsible for serializing schedule & attendance state into
/// Android SharedPreferences and notifying native AppWidgetProvider receivers.
class WidgetSyncService {
  WidgetSyncService._();

  static const String nextClassProviderName = 'NextClassWidgetProvider';
  static const String todayAgendaProviderName = 'TodayAgendaWidgetProvider';
  static const String attendanceGaugeProviderName = 'AttendanceGaugeWidgetProvider';

  /// Pure computation function that produces the entire key-value payload
  /// without invoking any platform channel APIs. 100% unit-testable.
  static Map<String, dynamic> computeWidgetPayload({
    required DateTime now,
    required SemesterEntity activeSemester,
    required List<ClassSessionEntity> todaySessions,
    required List<ClassSessionEntity> tomorrowSessions,
    required OverallAttendanceStats attendanceStats,
    required WidgetSettingsEntity widgetSettings,
    required List<HolidayItem> holidays,
  }) {
    final Map<String, dynamic> payload = {};

    // 1. Resolve Active State & Hero Session
    String nextClassState = 'FREE_DAY';
    String nextClassSubject = 'No Classes Today';
    String nextClassTime = '';
    String nextClassRoom = '';
    String nextClassCountdown = '';
    int nextClassStatusDot = 0xFF94A3B8; // Gray
    String nextClassSessionId = '';

    final isUnsetSemester = activeSemester.isUnset;
    final todayIso = _toIsoDate(now);
    final isHoliday = holidays.any((h) => todayIso.compareTo(h.startDate) >= 0 && todayIso.compareTo(h.endDate) <= 0);

    if (isUnsetSemester) {
      nextClassState = 'NO_SEMESTER';
      nextClassSubject = 'Welcome to ClassTrack';
      nextClassTime = 'Tap to configure semester';
      nextClassCountdown = 'Setup Required';
      nextClassStatusDot = 0xFF3B82F6; // Blue
    } else if (isHoliday) {
      final holiday = holidays.firstWhere((h) => todayIso.compareTo(h.startDate) >= 0 && todayIso.compareTo(h.endDate) <= 0);
      nextClassState = 'HOLIDAY';
      nextClassSubject = holiday.title.isNotEmpty ? holiday.title : 'College Holiday';
      nextClassTime = 'Declared College Holiday';
      nextClassCountdown = 'Relax & enjoy';
      nextClassStatusDot = 0xFFF59E0B; // Amber
    } else if (todaySessions.isEmpty) {
      nextClassState = 'FREE_DAY';
      nextClassSubject = 'No Classes Today';
      nextClassTime = 'Free day • Enjoy your break';
      nextClassCountdown = 'No Lectures';
      nextClassStatusDot = 0xFF10B981; // Green
    } else {
      // Find ongoing or upcoming session
      ClassSessionEntity? ongoingSession;
      ClassSessionEntity? upcomingSession;

      for (final s in todaySessions) {
        if (s.status == 'CANCELLED') continue;

        final startDt = _parseSessionTime(now, s.startTime);
        final endDt = _parseSessionTime(now, s.endTime);

        if (startDt != null && endDt != null) {
          if (!now.isBefore(startDt) && now.isBefore(endDt)) {
            ongoingSession = s;
            break;
          } else if (now.isBefore(startDt)) {
            upcomingSession ??= s;
          }
        }
      }

      if (ongoingSession != null) {
        nextClassState = 'NOW';
        nextClassSubject = ongoingSession.subjectName;
        nextClassSessionId = ongoingSession.id;
        final endDt = _parseSessionTime(now, ongoingSession.endTime)!;
        final minsRemaining = endDt.difference(now).inMinutes;
        nextClassCountdown = minsRemaining > 0 ? '${minsRemaining}m left' : 'Ending now';
        nextClassTime = _formatTimeRange(
          ongoingSession.startTime,
          ongoingSession.endTime,
          widgetSettings.use24HourFormat,
        );
        if (widgetSettings.showRoomNumber && ongoingSession.room != null && ongoingSession.room!.trim().isNotEmpty) {
          nextClassRoom = ongoingSession.room!.trim();
        }
        nextClassStatusDot = 0xFF10B981; // Emerald Pulse
      } else if (upcomingSession != null) {
        nextClassState = 'NEXT';
        nextClassSubject = upcomingSession.subjectName;
        nextClassSessionId = upcomingSession.id;
        final startDt = _parseSessionTime(now, upcomingSession.startTime)!;
        final minsUntil = startDt.difference(now).inMinutes;
        if (minsUntil < 60) {
          nextClassCountdown = minsUntil > 0 ? 'Starts in ${minsUntil}m' : 'Starting now';
        } else {
          final hrs = (minsUntil / 60).toStringAsFixed(1);
          nextClassCountdown = 'Starts in ${hrs}h';
        }
        nextClassTime = _formatTimeRange(
          upcomingSession.startTime,
          upcomingSession.endTime,
          widgetSettings.use24HourFormat,
        );
        if (widgetSettings.showRoomNumber && upcomingSession.room != null && upcomingSession.room!.trim().isNotEmpty) {
          nextClassRoom = upcomingSession.room!.trim();
        }
        nextClassStatusDot = 0xFF3B82F6; // Blue
      } else {
        // All classes today are completed
        nextClassState = 'COMPLETED';
        nextClassSubject = 'Done for the Day! 🎉';
        nextClassStatusDot = 0xFF94A3B8; // Gray

        if (widgetSettings.showTomorrowPreviewWhenDone && tomorrowSessions.isNotEmpty) {
          final firstTomorrow = tomorrowSessions.first;
          final timeStr = _formatSingleTime(firstTomorrow.startTime, widgetSettings.use24HourFormat);
          nextClassTime = 'Tomorrow: ${firstTomorrow.subjectName} at $timeStr';
          nextClassCountdown = 'Tomorrow at $timeStr';
        } else {
          nextClassTime = '${todaySessions.length}/${todaySessions.length} classes completed';
          nextClassCountdown = 'All Attended';
        }
      }
    }

    payload['next_class_state'] = nextClassState;
    payload['next_class_subject'] = nextClassSubject;
    payload['next_class_time'] = nextClassTime;
    payload['next_class_room'] = nextClassRoom;
    payload['next_class_countdown'] = nextClassCountdown;
    payload['next_class_status_dot'] = nextClassStatusDot;
    payload['next_class_session_id'] = nextClassSessionId;

    // 2. Agenda Widget (4x2)
    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dateStr = '${weekdayNames[now.weekday - 1]}, ${monthNames[now.month - 1]} ${now.day}';
    payload['agenda_date_str'] = dateStr;

    final remainingLectures = todaySessions.where((s) {
      if (s.status == 'CANCELLED') return false;
      final endDt = _parseSessionTime(now, s.endTime);
      return endDt != null && now.isBefore(endDt);
    }).length;
    payload['agenda_remaining_count'] = remainingLectures > 0 ? '$remainingLectures left' : 'All done';

    // Format upcoming 3 lectures for Agenda
    final upcomingList = <Map<String, dynamic>>[];
    for (final s in todaySessions) {
      final endDt = _parseSessionTime(now, s.endTime);
      if (endDt != null && now.isBefore(endDt)) {
        upcomingList.add({
          'id': s.id,
          'name': s.subjectName,
          'time': _formatTimeRange(s.startTime, s.endTime, widgetSettings.use24HourFormat),
          'room': widgetSettings.showRoomNumber && s.room != null ? s.room! : '',
          'outcome': s.attendanceOutcome,
          'isCancelled': s.status == 'CANCELLED',
        });
        if (upcomingList.length >= 3) break;
      }
    }
    payload['agenda_upcoming_json'] = jsonEncode(upcomingList);

    // 3. Attendance Gauge Widget (2x2)
    final pctValue = attendanceStats.overallPercentage;
    if (widgetSettings.privacyMode) {
      payload['gauge_pct_str'] = '***%';
      payload['gauge_pct_value'] = 100;
      payload['gauge_safe_bunks_str'] = 'Privacy Shield Active';
      payload['gauge_status_color'] = 0xFF3B82F6; // Blue
      payload['agenda_attendance_pct'] = '***%';
    } else {
      payload['gauge_pct_str'] = '${pctValue.toStringAsFixed(1)}%';
      payload['gauge_pct_value'] = pctValue.round().clamp(0, 100);
      payload['agenda_attendance_pct'] = '${pctValue.toStringAsFixed(1)}%';

      if (pctValue >= attendanceStats.targetPercentage) {
        payload['gauge_safe_bunks_str'] = '🟢 ${attendanceStats.marginClassesToMiss} Safe Bunks';
        payload['gauge_status_color'] = 0xFF10B981; // Green
      } else if (pctValue >= attendanceStats.targetPercentage - 5.0) {
        payload['gauge_safe_bunks_str'] = '🟡 Need ${attendanceStats.requiredClassesToAttend} to recover';
        payload['gauge_status_color'] = 0xFFF59E0B; // Yellow
      } else {
        payload['gauge_safe_bunks_str'] = '🔴 Must attend ${attendanceStats.requiredClassesToAttend}';
        payload['gauge_status_color'] = 0xFFEF4444; // Red
      }
    }

    // Lowest subject spotlight
    if (attendanceStats.subjectStats.isNotEmpty && !widgetSettings.privacyMode) {
      final sortedSubs = List.of(attendanceStats.subjectStats)
        ..sort((a, b) => a.currentPercentage.compareTo(b.currentPercentage));
      final lowest = sortedSubs.first;
      payload['gauge_lowest_subject'] = '${lowest.subjectName}: ${lowest.currentPercentage.toStringAsFixed(0)}%';
    } else {
      payload['gauge_lowest_subject'] = '';
    }

    // 4. Common Theming Keys
    final baseBg = widgetSettings.themeMode.cardBackgroundColorValue;
    final alpha = (widgetSettings.backgroundOpacity * 255).round().clamp(0, 255);
    final compositeBgArgb = (alpha << 24) | (baseBg & 0x00FFFFFF);

    payload['widget_bg_color'] = compositeBgArgb;
    payload['widget_card_bg_color'] = baseBg;
    payload['widget_opacity_int'] = alpha;
    payload['widget_primary_color'] = widgetSettings.themeMode.primaryColorValue;
    payload['widget_opacity'] = widgetSettings.backgroundOpacity;
    payload['widget_theme_mode'] = widgetSettings.themeMode.name;
    payload['widget_direct_marking'] = widgetSettings.directAttendanceMarking;

    return payload;
  }

  /// Syncs all home screen widgets with current state.
  /// Wrapped in safe try/catch to ensure platform failures never crash the app.
  static Future<bool> syncAll({
    required DateTime now,
    required SemesterEntity activeSemester,
    required List<ClassSessionEntity> todaySessions,
    required List<ClassSessionEntity> tomorrowSessions,
    required OverallAttendanceStats attendanceStats,
    required WidgetSettingsEntity widgetSettings,
    required List<HolidayItem> holidays,
  }) async {
    try {
      final payload = computeWidgetPayload(
        now: now,
        activeSemester: activeSemester,
        todaySessions: todaySessions,
        tomorrowSessions: tomorrowSessions,
        attendanceStats: attendanceStats,
        widgetSettings: widgetSettings,
        holidays: holidays,
      );

      for (final entry in payload.entries) {
        final key = entry.key;
        final val = entry.value;
        if (val is String) {
          await HomeWidget.saveWidgetData<String>(key, val);
        } else if (val is int) {
          await HomeWidget.saveWidgetData<int>(key, val);
        } else if (val is double) {
          await HomeWidget.saveWidgetData<double>(key, val);
        } else if (val is bool) {
          await HomeWidget.saveWidgetData<bool>(key, val);
        }
      }

      await HomeWidget.updateWidget(
        name: nextClassProviderName,
        androidName: 'widgets.$nextClassProviderName',
        qualifiedAndroidName: 'com.classtrack.app.widgets.$nextClassProviderName',
      );
      await HomeWidget.updateWidget(
        name: todayAgendaProviderName,
        androidName: 'widgets.$todayAgendaProviderName',
        qualifiedAndroidName: 'com.classtrack.app.widgets.$todayAgendaProviderName',
      );
      await HomeWidget.updateWidget(
        name: attendanceGaugeProviderName,
        androidName: 'widgets.$attendanceGaugeProviderName',
        qualifiedAndroidName: 'com.classtrack.app.widgets.$attendanceGaugeProviderName',
      );

      return true;
    } catch (e) {
      debugPrint('[WidgetSyncService] Sync failed safely: $e');
      return false;
    }
  }

  // --- Internal Time Helpers ---
  static DateTime? _parseSessionTime(DateTime date, String hhMm) {
    try {
      final parts = hhMm.split(':');
      if (parts.length < 2) return null;
      return DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(parts[0].trim()),
        int.parse(parts[1].trim()),
      );
    } catch (_) {
      return null;
    }
  }

  static String _formatTimeRange(String startHhMm, String endHhMm, bool use24h) {
    final startStr = _formatSingleTime(startHhMm, use24h);
    final endStr = _formatSingleTime(endHhMm, use24h);
    return '$startStr - $endStr';
  }

  static String _formatSingleTime(String hhMm, bool use24h) {
    try {
      final parts = hhMm.split(':');
      final hour = int.parse(parts[0].trim());
      final minute = int.parse(parts[1].trim());

      if (use24h) {
        final hStr = hour.toString().padLeft(2, '0');
        final mStr = minute.toString().padLeft(2, '0');
        return '$hStr:$mStr';
      }

      final period = hour >= 12 ? 'PM' : 'AM';
      final h12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      final mStr = minute.toString().padLeft(2, '0');
      return '$h12:$mStr $period';
    } catch (_) {
      return hhMm;
    }
  }

  static String _toIsoDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
