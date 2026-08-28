class ClassSessionEntity {
  final String id;
  final String semesterId;
  final String subjectComponentId;
  final String subjectName;
  final String? subjectCode;
  final String category;
  final String componentType;
  final String colorHex;
  final String sessionDate; // YYYY-MM-DD
  final int? dayOfWeek; // 1 = Mon, 2 = Tue, ..., 7 = Sun
  final String startTime; // HH:mm
  final String endTime; // HH:mm
  final String sessionSource; // TIMETABLE_RECURRING, DATE_RANGE, MULTI_DATE, SINGLE_DATE
  final String? sourceRefId;
  final String status; // PLANNED, HELD, CANCELLED, NO_CLASS_DAY
  final String? room;
  final String? teacherName;
  final String attendanceOutcome; // PRESENT, ABSENT, CANCELLED, PENDING
  final String? markedAt;

  // Date Boundaries & Multi-Date Fields
  final String? effectiveFrom; // YYYY-MM-DD
  final String? effectiveUntil; // YYYY-MM-DD (Optional)
  final List<String>? specificDates; // List of ISO YYYY-MM-DD date strings

  ClassSessionEntity({
    required this.id,
    required this.semesterId,
    required this.subjectComponentId,
    required this.subjectName,
    this.subjectCode,
    required this.category,
    required this.componentType,
    required this.colorHex,
    required this.sessionDate,
    this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.sessionSource,
    this.sourceRefId,
    required this.status,
    this.room,
    this.teacherName,
    required this.attendanceOutcome,
    this.markedAt,
    this.effectiveFrom,
    this.effectiveUntil,
    this.specificDates,
  });

  ClassSessionEntity copyWith({
    String? attendanceOutcome,
    String? markedAt,
    String? status,
    int? dayOfWeek,
    String? effectiveFrom,
    String? effectiveUntil,
    List<String>? specificDates,
  }) {
    return ClassSessionEntity(
      id: id,
      semesterId: semesterId,
      subjectComponentId: subjectComponentId,
      subjectName: subjectName,
      subjectCode: subjectCode,
      category: category,
      componentType: componentType,
      colorHex: colorHex,
      sessionDate: sessionDate,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime,
      endTime: endTime,
      sessionSource: sessionSource,
      sourceRefId: sourceRefId,
      status: status ?? this.status,
      room: room,
      teacherName: teacherName,
      attendanceOutcome: attendanceOutcome ?? this.attendanceOutcome,
      markedAt: markedAt ?? this.markedAt,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      effectiveUntil: effectiveUntil ?? this.effectiveUntil,
      specificDates: specificDates ?? this.specificDates,
    );
  }
}
