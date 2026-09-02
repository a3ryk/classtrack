import '../entities/class_session_entity.dart';
import '../../core/utils/date_formatter.dart';

class HolidayItem {
  final String title;
  final String startDate; // YYYY-MM-DD
  final String endDate;   // YYYY-MM-DD
  HolidayItem({required this.title, required this.startDate, required this.endDate});
}

class AcademicDayConfigItem {
  final int dayOfWeek; // 1..7
  final bool isWeeklyOff;
  AcademicDayConfigItem({required this.dayOfWeek, required this.isWeeklyOff});
}

class TimetableSlotItem {
  final String id;
  final String semesterId;
  final String subjectComponentId;
  final String subjectName;
  final String? subjectCode;
  final String category;
  final String componentType;
  final String colorHex;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final String? room;
  final String? teacherName;
  final String? effectiveFrom;
  final String? effectiveUntil;

  TimetableSlotItem({
    required this.id,
    required this.semesterId,
    required this.subjectComponentId,
    required this.subjectName,
    this.subjectCode,
    required this.category,
    required this.componentType,
    required this.colorHex,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.room,
    this.teacherName,
    this.effectiveFrom,
    this.effectiveUntil,
  });
}

class ScheduleExceptionItem {
  final String timetableSlotId;
  final String exceptionDate; // YYYY-MM-DD
  final String actionType; // CANCELLED, MOVED, SUBSTITUTED
  final String? newStartTime;
  final String? newEndTime;
  final String? substituteComponentId;
  final String? newRoom;

  ScheduleExceptionItem({
    required this.timetableSlotId,
    required this.exceptionDate,
    required this.actionType,
    this.newStartTime,
    this.newEndTime,
    this.substituteComponentId,
    this.newRoom,
  });
}

class ExtraClassItem {
  final String id;
  final String semesterId;
  final String subjectComponentId;
  final String subjectName;
  final String? subjectCode;
  final String category;
  final String componentType;
  final String colorHex;
  final String classDate;
  final String startTime;
  final String endTime;
  final String? room;
  final String? teacherName;

  ExtraClassItem({
    required this.id,
    required this.semesterId,
    required this.subjectComponentId,
    required this.subjectName,
    this.subjectCode,
    required this.category,
    required this.componentType,
    required this.colorHex,
    required this.classDate,
    required this.startTime,
    required this.endTime,
    this.room,
    this.teacherName,
  });
}

/// 5-Level Schedule Resolution Engine
class ScheduleResolutionEngine {
  /// Resolves exact ClassSessions for a date [targetDate]
  static List<ClassSessionEntity> resolveScheduleForDate({
    required DateTime targetDate,
    required String semesterId,
    DateTime? semesterStartDate,
    DateTime? semesterEndDate,
    required List<HolidayItem> holidays,
    required List<AcademicDayConfigItem> dayConfigs,
    required List<TimetableSlotItem> timetableSlots,
    required List<ScheduleExceptionItem> exceptions,
    required List<ExtraClassItem> extraClasses,
    Map<String, String> existingOutcomes = const {}, // sessionKey -> outcome
  }) {
    final String dateString = DateFormatter.toIsoDate(targetDate);
    final int dayOfWeek = DateFormatter.getDayOfWeek(targetDate);

    // LEVEL 1: Holiday Check
    final isHoliday = holidays.any((h) => _isDateInRange(dateString, h.startDate, h.endDate));
    if (isHoliday) {
      // Suppress normal timetable slots. Only explicit ExtraClasses scheduled for today are included.
      return _resolveExtraClasses(extraClasses, dateString, semesterId, existingOutcomes);
    }

    // LEVEL 2 & 3: Process Timetable Slots & Apply Exceptions
    final List<ClassSessionEntity> resolved = [];
    final matchingSlots = timetableSlots.where((s) {
      if (s.dayOfWeek != dayOfWeek) return false;

      // Active Term (semester bounded) vs Custom Date Range Bounding
      final effectiveStart = (s.effectiveFrom != null && s.effectiveFrom!.isNotEmpty)
          ? s.effectiveFrom
          : (semesterStartDate != null ? DateFormatter.toIsoDate(semesterStartDate) : null);
      final effectiveEnd = (s.effectiveUntil != null && s.effectiveUntil!.isNotEmpty)
          ? s.effectiveUntil
          : (semesterEndDate != null ? DateFormatter.toIsoDate(semesterEndDate) : null);

      if (effectiveStart != null && dateString.compareTo(effectiveStart) < 0) return false;
      if (effectiveEnd != null && dateString.compareTo(effectiveEnd) > 0) return false;

      return true;
    }).toList();

    for (final slot in matchingSlots) {
      final exception = exceptions.firstWhere(
        (e) => e.timetableSlotId == slot.id && e.exceptionDate == dateString,
        orElse: () => ScheduleExceptionItem(timetableSlotId: '', exceptionDate: '', actionType: 'NONE'),
      );

      if (exception.actionType == 'CANCELLED') {
        // Slot is cancelled for today.
        continue;
      }

      final String startTime = exception.actionType == 'MOVED' && exception.newStartTime != null
          ? exception.newStartTime!
          : slot.startTime;
      final String endTime = exception.actionType == 'MOVED' && exception.newEndTime != null
          ? exception.newEndTime!
          : slot.endTime;
      final String? room = exception.actionType == 'MOVED'
          ? (exception.newRoom != null && exception.newRoom!.isNotEmpty ? exception.newRoom : null)
          : slot.room;

      final sessionId = 'session_${slot.id}_$dateString';
      final outcome = existingOutcomes[sessionId] ?? 'PENDING';

      resolved.add(ClassSessionEntity(
        id: sessionId,
        semesterId: semesterId,
        subjectComponentId: slot.subjectComponentId,
        subjectName: slot.subjectName,
        subjectCode: slot.subjectCode,
        category: slot.category,
        componentType: slot.componentType,
        colorHex: slot.colorHex,
        sessionDate: dateString,
        startTime: startTime,
        endTime: endTime,
        sessionSource: 'TIMETABLE',
        sourceRefId: slot.id,
        status: 'HELD',
        room: room,
        teacherName: slot.teacherName,
        attendanceOutcome: outcome,
        effectiveFrom: slot.effectiveFrom,
        effectiveUntil: slot.effectiveUntil,
      ));
    }

    // LEVEL 5: Append Extra Classes
    resolved.addAll(_resolveExtraClasses(extraClasses, dateString, semesterId, existingOutcomes));

    // Sort chronologically by start time
    resolved.sort((a, b) => a.startTime.compareTo(b.startTime));
    return resolved;
  }

  static List<ClassSessionEntity> _resolveExtraClasses(
    List<ExtraClassItem> extraClasses,
    String dateString,
    String semesterId,
    Map<String, String> existingOutcomes,
  ) {
    final matchingExtra = extraClasses.where((e) => e.classDate == dateString).toList();
    return matchingExtra.map((extra) {
      final sessionId = 'extra_${extra.id}_$dateString';
      final outcome = existingOutcomes[sessionId] ?? 'PENDING';
      return ClassSessionEntity(
        id: sessionId,
        semesterId: semesterId,
        subjectComponentId: extra.subjectComponentId,
        subjectName: extra.subjectName,
        subjectCode: extra.subjectCode,
        category: extra.category,
        componentType: extra.componentType,
        colorHex: extra.colorHex,
        sessionDate: dateString,
        startTime: extra.startTime,
        endTime: extra.endTime,
        sessionSource: 'EXTRA',
        sourceRefId: extra.id,
        status: 'HELD',
        room: extra.room,
        teacherName: extra.teacherName,
        attendanceOutcome: outcome,
      );
    }).toList();
  }

  static bool _isDateInRange(String target, String start, String end) {
    return target.compareTo(start) >= 0 && target.compareTo(end) <= 0;
  }
}
