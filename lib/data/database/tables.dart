import 'package:drift/drift.dart';

/// Database Table Definitions for Classtrack (Offline-First Architecture)

@DataClassName('SemesterData')
class Semesters extends Table {
  TextColumn get id => text()(); // UUIDv4
  TextColumn get name => text()(); // e.g., "Semester III (2026)"
  TextColumn get startDate => text()(); // YYYY-MM-DD
  TextColumn get endDate => text()(); // YYYY-MM-DD
  RealColumn get defaultTargetPct => real().withDefault(const Constant(75.0))();
  TextColumn get status => text().withDefault(const Constant('ACTIVE'))(); // UPCOMING, ACTIVE, COMPLETED, ARCHIVED
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  TextColumn get deletedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SubjectData')
class Subjects extends Table {
  TextColumn get id => text()();
  TextColumn get semesterId => text().references(Semesters, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  TextColumn get code => text().nullable()();
  TextColumn get category => text().withDefault(const Constant('MAJOR'))(); // MAJOR, MINOR, AEC, MDC, SEC, VAC, ELECTIVE
  IntColumn get credits => integer().withDefault(const Constant(3))();
  RealColumn get targetAttendancePct => real().withDefault(const Constant(75.0))();
  IntColumn get baselineHeld => integer().withDefault(const Constant(0))(); // Mid-semester onboarding baseline held
  IntColumn get baselineAttended => integer().withDefault(const Constant(0))(); // Mid-semester onboarding baseline attended
  TextColumn get colorHex => text().withDefault(const Constant('#4F46E5'))();
  TextColumn get notes => text().nullable()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  TextColumn get deletedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SubjectComponentData')
class SubjectComponents extends Table {
  TextColumn get id => text()();
  TextColumn get subjectId => text().references(Subjects, #id, onDelete: KeyAction.cascade)();
  TextColumn get componentType => text().withDefault(const Constant('LECTURE'))(); // LECTURE, PRACTICAL, TUTORIAL, LAB
  BoolColumn get trackSeparately => boolean().withDefault(const Constant(false))();
  RealColumn get weight => real().withDefault(const Constant(1.0))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  TextColumn get deletedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TimetableSlotData')
class TimetableSlots extends Table {
  TextColumn get id => text()();
  TextColumn get semesterId => text().references(Semesters, #id, onDelete: KeyAction.cascade)();
  TextColumn get subjectComponentId => text().references(SubjectComponents, #id, onDelete: KeyAction.cascade)();
  IntColumn get dayOfWeek => integer()(); // 1 = Monday, 7 = Sunday
  TextColumn get startTime => text()(); // HH:mm
  TextColumn get endTime => text()(); // HH:mm
  TextColumn get room => text().nullable()();
  TextColumn get teacherName => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get effectiveFrom => text().nullable()(); // YYYY-MM-DD
  TextColumn get effectiveUntil => text().nullable()(); // YYYY-MM-DD
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  TextColumn get deletedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AcademicDayConfigData')
class AcademicDayConfigs extends Table {
  TextColumn get id => text()();
  TextColumn get semesterId => text().references(Semesters, #id, onDelete: KeyAction.cascade)();
  IntColumn get dayOfWeek => integer()(); // 1..7
  BoolColumn get isWeeklyOff => boolean().withDefault(const Constant(false))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('HolidayData')
class Holidays extends Table {
  TextColumn get id => text()();
  TextColumn get semesterId => text().references(Semesters, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  TextColumn get startDate => text()(); // YYYY-MM-DD
  TextColumn get endDate => text()(); // YYYY-MM-DD
  TextColumn get category => text().withDefault(const Constant('HOLIDAY'))(); // HOLIDAY, EXAM, SEMESTER_BREAK, EVENT
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  TextColumn get deletedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ScheduleExceptionData')
class ScheduleExceptions extends Table {
  TextColumn get id => text()();
  TextColumn get timetableSlotId => text().references(TimetableSlots, #id, onDelete: KeyAction.cascade)();
  TextColumn get exceptionDate => text()(); // YYYY-MM-DD
  TextColumn get actionType => text()(); // CANCELLED, MOVED, SUBSTITUTED
  TextColumn get newStartTime => text().nullable()();
  TextColumn get newEndTime => text().nullable()();
  TextColumn get substituteComponentId => text().nullable()();
  TextColumn get newRoom => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ExtraClassData')
class ExtraClasses extends Table {
  TextColumn get id => text()();
  TextColumn get semesterId => text().references(Semesters, #id, onDelete: KeyAction.cascade)();
  TextColumn get subjectComponentId => text().references(SubjectComponents, #id, onDelete: KeyAction.cascade)();
  TextColumn get classDate => text()(); // YYYY-MM-DD
  TextColumn get startTime => text()();
  TextColumn get endTime => text()();
  TextColumn get room => text().nullable()();
  TextColumn get teacherName => text().nullable()();
  TextColumn get reason => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  TextColumn get deletedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ClassSessionData')
class ClassSessions extends Table {
  TextColumn get id => text()();
  TextColumn get semesterId => text().references(Semesters, #id, onDelete: KeyAction.cascade)();
  TextColumn get subjectComponentId => text().references(SubjectComponents, #id, onDelete: KeyAction.cascade)();
  TextColumn get sessionDate => text()(); // YYYY-MM-DD
  TextColumn get startTime => text()();
  TextColumn get endTime => text()();
  TextColumn get sessionSource => text()(); // TIMETABLE, EXTRA, MANUAL
  TextColumn get sourceRefId => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('PLANNED'))(); // PLANNED, HELD, CANCELLED, NO_CLASS_DAY
  TextColumn get room => text().nullable()();
  TextColumn get teacherName => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  TextColumn get deletedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AttendanceRecordData')
class AttendanceRecords extends Table {
  TextColumn get id => text()();
  TextColumn get classSessionId => text()(); // e.g. session_${slotId}_${dateIso} or extra_${extraId}_${dateIso}
  TextColumn get slotId => text().nullable()();
  TextColumn get subjectId => text().nullable()();
  TextColumn get sessionDate => text().nullable()(); // YYYY-MM-DD
  TextColumn get outcome => text().withDefault(const Constant('PENDING'))(); // PRESENT, ABSENT, CANCELLED, PENDING
  TextColumn get markedAt => text().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get syncVersion => integer().withDefault(const Constant(1))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  TextColumn get deletedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AppSettingData')
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

