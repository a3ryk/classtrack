class SlotRequirement {
  final String category; // MAJOR, MINOR, AEC, MDC, SEC, VAC, ELECTIVE
  final String label;
  final int defaultCredits;
  final bool isRequired;

  SlotRequirement({
    required this.category,
    required this.label,
    this.defaultCredits = 3,
    this.isRequired = true,
  });
}

class SemesterTemplate {
  final int semesterNumber;
  final List<SlotRequirement> slots;

  SemesterTemplate({
    required this.semesterNumber,
    required this.slots,
  });
}

class ProgrammeTemplate {
  final String id;
  final String name;
  final String universityName;
  final String description;
  final int totalSemesters;
  final List<SemesterTemplate> semesterTemplates;

  ProgrammeTemplate({
    required this.id,
    required this.name,
    required this.universityName,
    required this.description,
    required this.totalSemesters,
    required this.semesterTemplates,
  });
}
