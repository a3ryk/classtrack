import '../../domain/entities/academic_template.dart';

class ProgrammeTemplates {
  ProgrammeTemplates._();

  /// Default "Not Selected" template
  static final noneTemplate = ProgrammeTemplate(
    id: 'none',
    name: 'Not Selected',
    universityName: '',
    description: 'No specific curriculum structure selected.',
    totalSemesters: 0,
    semesterTemplates: [],
  );

  /// FYUGP (Four-Year Undergraduate Programme under NEP 2020) Template
  static final fyugpTemplate = ProgrammeTemplate(
    id: 'fyugp_nep2020',
    name: 'FYUGP (4-Year UG under NEP 2020)',
    universityName: 'Configurable Indian University (Gauhati, DU, MU, etc.)',
    description: 'NEP 2020 structure with Major, Minor, AEC, MDC, SEC, and VAC slots across 8 semesters.',
    totalSemesters: 8,
    semesterTemplates: [
      SemesterTemplate(
        semesterNumber: 1,
        slots: [
          SlotRequirement(category: 'MAJOR', label: 'Major Course I', defaultCredits: 4),
          SlotRequirement(category: 'MINOR', label: 'Minor Course I', defaultCredits: 4),
          SlotRequirement(category: 'AEC', label: 'Ability Enhancement (AEC I)', defaultCredits: 2),
          SlotRequirement(category: 'MDC', label: 'Multidisciplinary (MDC I)', defaultCredits: 3),
          SlotRequirement(category: 'SEC', label: 'Skill Enhancement (SEC I)', defaultCredits: 3),
          SlotRequirement(category: 'VAC', label: 'Value Added Course (VAC I)', defaultCredits: 2),
        ],
      ),
      SemesterTemplate(
        semesterNumber: 2,
        slots: [
          SlotRequirement(category: 'MAJOR', label: 'Major Course II', defaultCredits: 4),
          SlotRequirement(category: 'MINOR', label: 'Minor Course II', defaultCredits: 4),
          SlotRequirement(category: 'AEC', label: 'Ability Enhancement (AEC II)', defaultCredits: 2),
          SlotRequirement(category: 'MDC', label: 'Multidisciplinary (MDC II)', defaultCredits: 3),
          SlotRequirement(category: 'SEC', label: 'Skill Enhancement (SEC II)', defaultCredits: 3),
          SlotRequirement(category: 'VAC', label: 'Value Added Course (VAC II)', defaultCredits: 2),
        ],
      ),
      SemesterTemplate(
        semesterNumber: 3,
        slots: [
          SlotRequirement(category: 'MAJOR', label: 'Major Course III', defaultCredits: 4),
          SlotRequirement(category: 'MAJOR', label: 'Major Course IV', defaultCredits: 4),
          SlotRequirement(category: 'MINOR', label: 'Minor Course III', defaultCredits: 4),
          SlotRequirement(category: 'AEC', label: 'Ability Enhancement (AEC III)', defaultCredits: 2),
          SlotRequirement(category: 'MDC', label: 'Multidisciplinary (MDC III)', defaultCredits: 3),
          SlotRequirement(category: 'SEC', label: 'Skill Enhancement (SEC III)', defaultCredits: 3),
        ],
      ),
    ],
  );

  /// FYIMP (Five-Year Integrated Master's Programme) Template
  static final fyimpTemplate = ProgrammeTemplate(
    id: 'fyimp_nep2020',
    name: 'FYIMP (5-Year Integrated Master\'s)',
    universityName: 'Configurable Indian University',
    description: 'Integrated Bachelor\'s + Master\'s structure with 10 semesters.',
    totalSemesters: 10,
    semesterTemplates: [
      SemesterTemplate(
        semesterNumber: 1,
        slots: [
          SlotRequirement(category: 'MAJOR', label: 'Core Major I', defaultCredits: 4),
          SlotRequirement(category: 'MAJOR', label: 'Core Major II', defaultCredits: 4),
          SlotRequirement(category: 'MINOR', label: 'Minor Course I', defaultCredits: 3),
          SlotRequirement(category: 'AEC', label: 'AEC Course', defaultCredits: 2),
          SlotRequirement(category: 'SEC', label: 'SEC Course', defaultCredits: 3),
        ],
      ),
    ],
  );

  /// Standard Custom University Template
  static final customTemplate = ProgrammeTemplate(
    id: 'custom_generic',
    name: 'Custom Degree / General College',
    universityName: 'Any University / College',
    description: 'Flexible template for standard B.Tech, B.Sc, B.A, B.Com, or custom degree programmes.',
    totalSemesters: 6,
    semesterTemplates: [
      SemesterTemplate(
        semesterNumber: 1,
        slots: [
          SlotRequirement(category: 'MAJOR', label: 'Subject 1', defaultCredits: 3),
          SlotRequirement(category: 'MAJOR', label: 'Subject 2', defaultCredits: 3),
          SlotRequirement(category: 'MAJOR', label: 'Subject 3', defaultCredits: 3),
          SlotRequirement(category: 'MINOR', label: 'Subject 4', defaultCredits: 3),
          SlotRequirement(category: 'ELECTIVE', label: 'Subject 5', defaultCredits: 3),
        ],
      ),
    ],
  );

  static List<ProgrammeTemplate> getAllTemplates() {
    return [fyugpTemplate, fyimpTemplate, customTemplate];
  }

  static ProgrammeTemplate getById(String? id) {
    if (id == null || id.isEmpty || id == 'none') {
      return noneTemplate;
    }
    return getAllTemplates().firstWhere(
      (t) => t.id == id,
      orElse: () => noneTemplate,
    );
  }
}
