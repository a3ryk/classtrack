class SubjectEntity {
  final String id;
  final String semesterId;
  final String name;
  final String? code;
  final String category; // MAJOR, MINOR, AEC, MDC, SEC, VAC, ELECTIVE
  final int credits;
  final double targetAttendancePct;
  final int baselineHeld;
  final int baselineAttended;
  final String colorHex;
  final String? notes;
  final bool isArchived;
  final List<SubjectComponentEntity> components;

  SubjectEntity({
    required this.id,
    required this.semesterId,
    required this.name,
    this.code,
    required this.category,
    required this.credits,
    required this.targetAttendancePct,
    required this.baselineHeld,
    required this.baselineAttended,
    required this.colorHex,
    this.notes,
    required this.isArchived,
    required this.components,
  });
}

class SubjectComponentEntity {
  final String id;
  final String subjectId;
  final String componentType; // LECTURE, PRACTICAL, TUTORIAL, LAB
  final bool trackSeparately;
  final double weight;

  SubjectComponentEntity({
    required this.id,
    required this.subjectId,
    required this.componentType,
    required this.trackSeparately,
    required this.weight,
  });
}
