import '../entities/semester_entity.dart';

/// Intelligent sequential term naming and academic year progression service.
class SemesterSequencer {
  SemesterSequencer._();

  static const List<String> romanNumerals = [
    'I',
    'II',
    'III',
    'IV',
    'V',
    'VI',
    'VII',
    'VIII',
    'IX',
    'X',
    'XI',
    'XII',
  ];

  static const List<String> yearPresets = [
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year',
    '5th Year',
  ];

  static const List<String> trimesterPresets = [
    'Term 1 (Trimester I)',
    'Term 2 (Trimester II)',
    'Term 3 (Trimester III)',
    'Term 4 (Trimester IV)',
    'Term 5 (Trimester V)',
    'Term 6 (Trimester VI)',
    'Term 7 (Trimester VII)',
    'Term 8 (Trimester VIII)',
    'Term 9 (Trimester IX)',
  ];

  /// Suggests the next sequential term name based on current term's name and type.
  static String suggestNextTermName({
    required String currentName,
    required TermType termType,
  }) {
    final trimmed = currentName.trim();
    if (trimmed.isEmpty) {
      return _getDefaultPresetForType(termType);
    }

    // 1. Trimester preset matching (e.g. 'Term 1 (Trimester I)' -> 'Term 2 (Trimester II)')
    final trimesterIdx = trimesterPresets.indexWhere((p) => p.toLowerCase() == trimmed.toLowerCase());
    if (trimesterIdx >= 0) {
      if (trimesterIdx + 1 < trimesterPresets.length) {
        return trimesterPresets[trimesterIdx + 1];
      }
      return 'Term  (Trimester )';
    }

    // 2. Year preset matching (e.g. '1st Year' -> '2nd Year')
    final yearIdx = yearPresets.indexWhere((p) => p.toLowerCase() == trimmed.toLowerCase());
    if (yearIdx >= 0) {
      if (yearIdx + 1 < yearPresets.length) {
        return yearPresets[yearIdx + 1];
      }
      return '${yearIdx + 2}th Year';
    }

    // 3. Fall / Spring seasonal sequence (e.g. 'Fall 2025' -> 'Spring 2026')
    final seasonalRegex = RegExp(r'^(Fall|Autumn|Spring|Summer|Winter)\s*(\d{4})?$', caseSensitive: false);
    final seasonalMatch = seasonalRegex.firstMatch(trimmed);
    if (seasonalMatch != null) {
      final season = seasonalMatch.group(1)!.toLowerCase();
      final yearStr = seasonalMatch.group(2);
      final year = yearStr != null ? int.tryParse(yearStr) : null;

      if (season == 'fall' || season == 'autumn') {
        final nextYear = year != null ? year + 1 : null;
        return nextYear != null ? 'Spring $nextYear' : 'Spring';
      } else if (season == 'spring') {
        return year != null ? 'Fall $year' : 'Fall';
      } else if (season == 'summer') {
        return year != null ? 'Fall $year' : 'Fall';
      } else if (season == 'winter') {
        final nextYear = year != null ? year + 1 : null;
        return nextYear != null ? 'Spring $nextYear' : 'Spring';
      }
    }

    // 4. Roman Numeral matching (e.g. 'Semester III' -> 'Semester IV', 'Sem II' -> 'Sem III')
    for (int i = 0; i < romanNumerals.length; i++) {
      final roman = romanNumerals[i];
      final romanRegex = RegExp('^(.*\\b)($roman)\$', caseSensitive: true);
      final match = romanRegex.firstMatch(trimmed);
      if (match != null) {
        final prefix = match.group(1)!;
        if (i + 1 < romanNumerals.length) {
          final nextRoman = romanNumerals[i + 1];
          return '$prefix$nextRoman';
        }
      }
    }

    // 5. Arabic Numeral at the end (e.g. 'Semester 3' -> 'Semester 4', 'Sem 1' -> 'Sem 2', 'Module 4' -> 'Module 5')
    final arabicRegex = RegExp(r'^(.*?)(\d+)$');
    final arabicMatch = arabicRegex.firstMatch(trimmed);
    if (arabicMatch != null) {
      final prefix = arabicMatch.group(1)!;
      final num = int.tryParse(arabicMatch.group(2)!);
      if (num != null) {
        return '$prefix${num + 1}';
      }
    }

    // 6. If name matches known default, advance by default
    if (trimmed.toLowerCase() == 'semester i' || trimmed.toLowerCase() == 'semester 1') {
      return 'Semester II';
    }

    // 7. Fallback: Return default preset for the selected term type
    return _getDefaultPresetForType(termType);
  }

  /// Suggests the next academic year (e.g. '2025-2026' -> '2026-2027' or '2026').
  static String suggestNextAcademicYear({
    required String currentAcademicYear,
    required DateTime currentEndDate,
    required DateTime nextStartDate,
  }) {
    final trimmed = currentAcademicYear.trim();
    final rangeRegex = RegExp(r'^(\d{4})[-/](\d{2,4})$');
    final rangeMatch = rangeRegex.firstMatch(trimmed);
    if (rangeMatch != null) {
      final startYear = int.tryParse(rangeMatch.group(1)!);
      final endYearRaw = rangeMatch.group(2)!;
      final endYear = endYearRaw.length == 2
          ? (startYear != null ? (startYear - (startYear % 100) + int.parse(endYearRaw)) : null)
          : int.tryParse(endYearRaw);

      if (startYear != null && endYear != null) {
        if (nextStartDate.year >= endYear && nextStartDate.month >= 6) {
          return '${startYear + 1}-${endYear + 1}';
        }
        return currentAcademicYear;
      }
    }

    final singleYear = int.tryParse(trimmed);
    if (singleYear != null) {
      if (nextStartDate.year > singleYear) {
        return '';
      }
      return currentAcademicYear;
    }

    return '-';
  }

  static String _getDefaultPresetForType(TermType type) {
    switch (type) {
      case TermType.yearly:
        return '2nd Year';
      case TermType.trimester:
        return 'Term 2 (Trimester II)';
      case TermType.semester:
      case TermType.custom:
        return 'Semester II';
    }
  }
}
