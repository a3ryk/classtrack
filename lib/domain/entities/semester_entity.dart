enum TermType {
  semester,
  yearly,
  trimester,
  custom,
}

extension TermTypeExtension on TermType {
  String get displayName {
    switch (this) {
      case TermType.semester:
        return 'Semester';
      case TermType.yearly:
        return 'Annual';
      case TermType.trimester:
        return 'Trimester';
      case TermType.custom:
        return 'Custom';
    }
  }
}

class SemesterEntity {
  final String id;
  final String name; // e.g. "Semester III" or "1st Year"
  final String academicYear; // e.g. "2026" or "2025-2026"
  final TermType termType;
  final DateTime startDate;
  final DateTime? endDate; // Optional for open-ended terms
  final bool isCurrent;
  final bool isArchived;

  SemesterEntity({
    required this.id,
    required this.name,
    required this.academicYear,
    this.termType = TermType.semester,
    required this.startDate,
    this.endDate,
    this.isCurrent = true,
    this.isArchived = false,
  });

  SemesterEntity copyWith({
    String? name,
    String? academicYear,
    TermType? termType,
    DateTime? startDate,
    DateTime? endDate,
    bool? isCurrent,
    bool? isArchived,
  }) {
    return SemesterEntity(
      id: id,
      name: name ?? this.name,
      academicYear: academicYear ?? this.academicYear,
      termType: termType ?? this.termType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isCurrent: isCurrent ?? this.isCurrent,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  bool get isUnset => id.isEmpty;

  factory SemesterEntity.empty() {
    final now = DateTime.now();
    return SemesterEntity(
      id: '',
      name: 'No Semester',
      academicYear: '${now.year}',
      startDate: DateTime(now.year, now.month, 1),
      endDate: DateTime(now.year, now.month + 5, 0),
      isCurrent: false,
      isArchived: false,
    );
  }
}
