import 'package:flutter_test/flutter_test.dart';
import 'package:classtrack/domain/entities/semester_entity.dart';
import 'package:classtrack/domain/services/semester_sequencer.dart';

void main() {
  group('SemesterSequencer.suggestNextTermName', () {
    test('increments Roman numerals properly', () {
      expect(
        SemesterSequencer.suggestNextTermName(currentName: 'Semester I', termType: TermType.semester),
        equals('Semester II'),
      );
      expect(
        SemesterSequencer.suggestNextTermName(currentName: 'Semester III', termType: TermType.semester),
        equals('Semester IV'),
      );
      expect(
        SemesterSequencer.suggestNextTermName(currentName: 'Semester IV', termType: TermType.semester),
        equals('Semester V'),
      );
      expect(
        SemesterSequencer.suggestNextTermName(currentName: 'Semester VII', termType: TermType.semester),
        equals('Semester VIII'),
      );
      expect(
        SemesterSequencer.suggestNextTermName(currentName: 'Sem II', termType: TermType.semester),
        equals('Sem III'),
      );
    });

    test('increments Arabic numerals properly', () {
      expect(
        SemesterSequencer.suggestNextTermName(currentName: 'Semester 1', termType: TermType.semester),
        equals('Semester 2'),
      );
      expect(
        SemesterSequencer.suggestNextTermName(currentName: 'Sem 3', termType: TermType.semester),
        equals('Sem 4'),
      );
      expect(
        SemesterSequencer.suggestNextTermName(currentName: 'Module 4', termType: TermType.custom),
        equals('Module 5'),
      );
    });

    test('progresses Year presets', () {
      expect(
        SemesterSequencer.suggestNextTermName(currentName: '1st Year', termType: TermType.yearly),
        equals('2nd Year'),
      );
      expect(
        SemesterSequencer.suggestNextTermName(currentName: '2nd Year', termType: TermType.yearly),
        equals('3rd Year'),
      );
      expect(
        SemesterSequencer.suggestNextTermName(currentName: '4th Year', termType: TermType.yearly),
        equals('5th Year'),
      );
    });

    test('progresses Trimester presets', () {
      expect(
        SemesterSequencer.suggestNextTermName(
          currentName: 'Term 1 (Trimester I)',
          termType: TermType.trimester,
        ),
        equals('Term 2 (Trimester II)'),
      );
      expect(
        SemesterSequencer.suggestNextTermName(
          currentName: 'Term 2 (Trimester II)',
          termType: TermType.trimester,
        ),
        equals('Term 3 (Trimester III)'),
      );
    });

    test('progresses Fall and Spring seasonal terms', () {
      expect(
        SemesterSequencer.suggestNextTermName(currentName: 'Fall 2025', termType: TermType.semester),
        equals('Spring 2026'),
      );
      expect(
        SemesterSequencer.suggestNextTermName(currentName: 'Spring 2026', termType: TermType.semester),
        equals('Fall 2026'),
      );
    });

    test('fallback works when empty or unrecognized', () {
      expect(
        SemesterSequencer.suggestNextTermName(currentName: '', termType: TermType.semester),
        equals('Semester II'),
      );
      expect(
        SemesterSequencer.suggestNextTermName(currentName: '', termType: TermType.yearly),
        equals('2nd Year'),
      );
    });
  });

  group('SemesterSequencer.suggestNextAcademicYear', () {
    test('increments academic year range when cross year threshold', () {
      final currentEnd = DateTime(2026, 5, 30);
      final nextStart = DateTime(2026, 8, 1);
      final result = SemesterSequencer.suggestNextAcademicYear(
        currentAcademicYear: '2025-2026',
        currentEndDate: currentEnd,
        nextStartDate: nextStart,
      );
      expect(result, equals('2026-2027'));
    });

    test('keeps same academic year range if within same academic year', () {
      final currentEnd = DateTime(2025, 12, 15);
      final nextStart = DateTime(2026, 1, 10);
      final result = SemesterSequencer.suggestNextAcademicYear(
        currentAcademicYear: '2025-2026',
        currentEndDate: currentEnd,
        nextStartDate: nextStart,
      );
      expect(result, equals('2025-2026'));
    });
  });
}
