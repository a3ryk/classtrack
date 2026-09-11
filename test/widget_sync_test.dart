import 'package:flutter_test/flutter_test.dart';
import 'package:classtrack/core/services/widget_sync_service.dart';
import 'package:classtrack/domain/entities/attendance_stats.dart';
import 'package:classtrack/domain/entities/class_session_entity.dart';
import 'package:classtrack/domain/entities/semester_entity.dart';
import 'package:classtrack/domain/entities/widget_settings_entity.dart';
import 'package:classtrack/domain/services/schedule_engine.dart';

void main() {
  group('WidgetSyncService Payload & Edge Case Tests', () {
    final testSemester = SemesterEntity(
      id: 'sem_1',
      name: 'Semester 4',
      academicYear: '2026',
      startDate: DateTime(2026, 8, 1),
      endDate: DateTime(2026, 12, 20),
      isCurrent: true,
    );

    final testStats = OverallAttendanceStats(
      totalHeld: 20,
      totalAttended: 17,
      totalAbsent: 3,
      totalCancelled: 0,
      totalPending: 0,
      overallPercentage: 85.0,
      targetPercentage: 75.0,
      marginClassesToMiss: 2,
      requiredClassesToAttend: 0,
      subjectStats: [
        SubjectAttendanceStats(
          subjectId: 'sub_math',
          subjectName: 'Discrete Mathematics',
          subjectCode: 'CS201',
          category: 'CORE',
          colorHex: '#3B82F6',
          totalHeld: 10,
          totalAttended: 8,
          totalAbsent: 2,
          totalCancelled: 0,
          totalPending: 0,
          currentPercentage: 80.0,
          targetPercentage: 75.0,
          status: SubjectAttendanceStatus.safe,
          marginClassesToMiss: 1,
          requiredClassesToAttend: 0,
        ),
      ],
    );

    test('Edge Case 1: Unset semester produces NO_SEMESTER state with setup prompt', () {
      final payload = WidgetSyncService.computeWidgetPayload(
        now: DateTime(2026, 9, 11, 10, 0),
        activeSemester: SemesterEntity.empty(),
        todaySessions: [],
        tomorrowSessions: [],
        attendanceStats: testStats,
        widgetSettings: const WidgetSettingsEntity(),
        holidays: [],
      );

      expect(payload['next_class_state'], 'NO_SEMESTER');
      expect(payload['next_class_subject'], 'Welcome to Attendly');
      expect(payload['next_class_time'], 'Tap to configure semester');
      expect(payload['next_class_countdown'], 'Setup Required');
    });

    test('Edge Case 2: Declared holiday produces HOLIDAY state with break prompt', () {
      final holidays = [
        HolidayItem(title: 'Diwali Break', startDate: '2026-09-11', endDate: '2026-09-13'),
      ];

      final payload = WidgetSyncService.computeWidgetPayload(
        now: DateTime(2026, 9, 11, 10, 0),
        activeSemester: testSemester,
        todaySessions: [],
        tomorrowSessions: [],
        attendanceStats: testStats,
        widgetSettings: const WidgetSettingsEntity(),
        holidays: holidays,
      );

      expect(payload['next_class_state'], 'HOLIDAY');
      expect(payload['next_class_subject'], 'Diwali Break');
      expect(payload['next_class_time'], 'Declared College Holiday');
    });

    test('Edge Case 3: Zero classes on today produces FREE_DAY state', () {
      final payload = WidgetSyncService.computeWidgetPayload(
        now: DateTime(2026, 9, 11, 10, 0),
        activeSemester: testSemester,
        todaySessions: [],
        tomorrowSessions: [],
        attendanceStats: testStats,
        widgetSettings: const WidgetSettingsEntity(),
        holidays: [],
      );

      expect(payload['next_class_state'], 'FREE_DAY');
      expect(payload['next_class_subject'], 'No Classes Today');
      expect(payload['next_class_countdown'], 'No Lectures');
    });

    test('Edge Case 4: Class in progress produces NOW state with remaining countdown', () {
      final sessions = [
        ClassSessionEntity(
          id: 'sess_1',
          semesterId: 'sem_1',
          subjectComponentId: 'sub_os',
          subjectName: 'Operating Systems',
          category: 'CORE',
          componentType: 'LECTURE',
          colorHex: '#10B981',
          sessionDate: '2026-09-11',
          startTime: '09:30',
          endTime: '10:30',
          sessionSource: 'TIMETABLE_RECURRING',
          status: 'PLANNED',
          room: 'Room 401',
          attendanceOutcome: 'PENDING',
        ),
      ];

      // Time is 10:00 (class is from 09:30 to 10:30, 30 mins left)
      final payload = WidgetSyncService.computeWidgetPayload(
        now: DateTime(2026, 9, 11, 10, 0),
        activeSemester: testSemester,
        todaySessions: sessions,
        tomorrowSessions: [],
        attendanceStats: testStats,
        widgetSettings: const WidgetSettingsEntity(),
        holidays: [],
      );

      expect(payload['next_class_state'], 'NOW');
      expect(payload['next_class_subject'], 'Operating Systems');
      expect(payload['next_class_room'], 'Room 401');
      expect(payload['next_class_countdown'], '30m left');
      expect(payload['next_class_session_id'], 'sess_1');
    });

    test('Edge Case 5: Class upcoming produces NEXT state with minutes until start', () {
      final sessions = [
        ClassSessionEntity(
          id: 'sess_2',
          semesterId: 'sem_1',
          subjectComponentId: 'sub_net',
          subjectName: 'Computer Networks',
          category: 'CORE',
          componentType: 'LECTURE',
          colorHex: '#3B82F6',
          sessionDate: '2026-09-11',
          startTime: '11:15',
          endTime: '12:15',
          sessionSource: 'TIMETABLE_RECURRING',
          status: 'PLANNED',
          room: 'Lab 2',
          attendanceOutcome: 'PENDING',
        ),
      ];

      // Time is 10:30 (45 mins until 11:15)
      final payload = WidgetSyncService.computeWidgetPayload(
        now: DateTime(2026, 9, 11, 10, 30),
        activeSemester: testSemester,
        todaySessions: sessions,
        tomorrowSessions: [],
        attendanceStats: testStats,
        widgetSettings: const WidgetSettingsEntity(),
        holidays: [],
      );

      expect(payload['next_class_state'], 'NEXT');
      expect(payload['next_class_subject'], 'Computer Networks');
      expect(payload['next_class_countdown'], 'Starts in 45m');
      expect(payload['next_class_room'], 'Lab 2');
    });

    test('Edge Case 6: All classes completed switches to tomorrow preview when enabled', () {
      final todaySessions = [
        ClassSessionEntity(
          id: 'sess_1',
          semesterId: 'sem_1',
          subjectComponentId: 'sub_os',
          subjectName: 'Operating Systems',
          category: 'CORE',
          componentType: 'LECTURE',
          colorHex: '#10B981',
          sessionDate: '2026-09-11',
          startTime: '09:00',
          endTime: '10:00',
          sessionSource: 'TIMETABLE_RECURRING',
          status: 'PLANNED',
          attendanceOutcome: 'PRESENT',
        ),
      ];

      final tomorrowSessions = [
        ClassSessionEntity(
          id: 'sess_tomorrow',
          semesterId: 'sem_1',
          subjectComponentId: 'sub_db',
          subjectName: 'Database Systems',
          category: 'CORE',
          componentType: 'LECTURE',
          colorHex: '#8B5CF6',
          sessionDate: '2026-09-12',
          startTime: '09:00',
          endTime: '10:00',
          sessionSource: 'TIMETABLE_RECURRING',
          status: 'PLANNED',
          attendanceOutcome: 'PENDING',
        ),
      ];

      // Time is 16:00 (well after 10:00 AM)
      final payload = WidgetSyncService.computeWidgetPayload(
        now: DateTime(2026, 9, 11, 16, 0),
        activeSemester: testSemester,
        todaySessions: todaySessions,
        tomorrowSessions: tomorrowSessions,
        attendanceStats: testStats,
        widgetSettings: const WidgetSettingsEntity(showTomorrowPreviewWhenDone: true),
        holidays: [],
      );

      expect(payload['next_class_state'], 'COMPLETED');
      expect(payload['next_class_subject'], 'Done for the Day! 🎉');
      expect(payload['next_class_time'], contains('Tomorrow: Database Systems'));
    });

    test('Edge Case 7: Privacy Shield masks attendance percentage and safe bunks', () {
      final payload = WidgetSyncService.computeWidgetPayload(
        now: DateTime(2026, 9, 11, 10, 0),
        activeSemester: testSemester,
        todaySessions: [],
        tomorrowSessions: [],
        attendanceStats: testStats,
        widgetSettings: const WidgetSettingsEntity(privacyMode: true),
        holidays: [],
      );

      expect(payload['gauge_pct_str'], '***%');
      expect(payload['agenda_attendance_pct'], '***%');
      expect(payload['gauge_safe_bunks_str'], 'Privacy Shield Active');
    });

    test('Edge Case 8: Room numbers omitted when showRoomNumber is false', () {
      final sessions = [
        ClassSessionEntity(
          id: 'sess_1',
          semesterId: 'sem_1',
          subjectComponentId: 'sub_os',
          subjectName: 'Operating Systems',
          category: 'CORE',
          componentType: 'LECTURE',
          colorHex: '#10B981',
          sessionDate: '2026-09-11',
          startTime: '09:30',
          endTime: '10:30',
          sessionSource: 'TIMETABLE_RECURRING',
          status: 'PLANNED',
          room: 'Room 401',
          attendanceOutcome: 'PENDING',
        ),
      ];

      final payload = WidgetSyncService.computeWidgetPayload(
        now: DateTime(2026, 9, 11, 10, 0),
        activeSemester: testSemester,
        todaySessions: sessions,
        tomorrowSessions: [],
        attendanceStats: testStats,
        widgetSettings: const WidgetSettingsEntity(showRoomNumber: false),
        holidays: [],
      );

      expect(payload['next_class_room'], '');
    });

    test('Edge Case 9: Custom opacity calculates composite background ARGB correctly', () {
      final payload = WidgetSyncService.computeWidgetPayload(
        now: DateTime(2026, 9, 11, 10, 0),
        activeSemester: testSemester,
        todaySessions: [],
        tomorrowSessions: [],
        attendanceStats: testStats,
        widgetSettings: const WidgetSettingsEntity(
          backgroundOpacity: 0.5,
          themeMode: WidgetThemeMode.amoled,
        ),
        holidays: [],
      );

      final int bgArgb = payload['widget_bg_color'] as int;
      final int alpha = (bgArgb >> 24) & 0xFF;
      // 0.5 * 255 = ~128
      expect(alpha, inInclusiveRange(126, 129));
    });
  });
}
