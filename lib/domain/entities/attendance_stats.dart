enum SubjectAttendanceStatus {
  safe,
  warning,
  critical,
}

class SubjectAttendanceStats {
  final String subjectId;
  final String subjectName;
  final String? subjectCode;
  final String category;
  final String colorHex;
  final int totalHeld;
  final int totalAttended;
  final int totalAbsent;
  final int totalCancelled;
  final int totalPending;
  final double currentPercentage;
  final double targetPercentage;
  final int marginClassesToMiss;
  final int requiredClassesToAttend;
  final SubjectAttendanceStatus status;

  SubjectAttendanceStats({
    required this.subjectId,
    required this.subjectName,
    this.subjectCode,
    required this.category,
    required this.colorHex,
    required this.totalHeld,
    required this.totalAttended,
    required this.totalAbsent,
    required this.totalCancelled,
    required this.totalPending,
    required this.currentPercentage,
    required this.targetPercentage,
    required this.marginClassesToMiss,
    required this.requiredClassesToAttend,
    required this.status,
  });
}

class OverallAttendanceStats {
  final int totalHeld;
  final int totalAttended;
  final int totalAbsent;
  final int totalCancelled;
  final int totalPending;
  final double overallPercentage;
  final double targetPercentage;
  final int marginClassesToMiss;
  final int requiredClassesToAttend;
  final List<SubjectAttendanceStats> subjectStats;

  OverallAttendanceStats({
    required this.totalHeld,
    required this.totalAttended,
    required this.totalAbsent,
    required this.totalCancelled,
    required this.totalPending,
    required this.overallPercentage,
    required this.targetPercentage,
    required this.marginClassesToMiss,
    required this.requiredClassesToAttend,
    required this.subjectStats,
  });
}
