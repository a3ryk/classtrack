import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../core/utils/uuid_generator.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Semesters,
  Subjects,
  SubjectComponents,
  TimetableSlots,
  AcademicDayConfigs,
  Holidays,
  ScheduleExceptions,
  ExtraClasses,
  ClassSessions,
  AttendanceRecords,
  AppSettings,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(timetableSlots, timetableSlots.effectiveFrom);
            await m.addColumn(timetableSlots, timetableSlots.effectiveUntil);
          }
        },
      );

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'classtrack_db.sqlite'));

      // Enable Write-Ahead Logging (WAL) mode for maximum performance and multi-thread concurrency
      return NativeDatabase.createInBackground(
        file,
        isolateSetup: () async {
          // Pragmas for performance
        },
      );
    });
  }

  factory AppDatabase.production() => AppDatabase(_openConnection());

  factory AppDatabase.inMemory() => AppDatabase(NativeDatabase.memory());

  // ==========================================
  // SEMESTERS CRUD
  // ==========================================

  Future<List<SemesterData>> getAllSemesters() {
    return (select(semesters)..where((t) => t.deletedAt.isNull())).get();
  }

  Future<SemesterData?> getActiveSemester() async {
    return (select(semesters)..where((t) => t.status.equals('ACTIVE') & t.deletedAt.isNull())).getSingleOrNull();
  }

  Future<void> saveSemester(SemesterData semester) {
    return into(semesters).insertOnConflictUpdate(semester);
  }

  Future<void> setActiveSemester(String semesterId) async {
    await transaction(() async {
      // Set all to ARCHIVED or COMPLETED
      await (update(semesters)..where((t) => t.status.equals('ACTIVE'))).write(
        const SemestersCompanion(status: Value('ARCHIVED')),
      );
      // Set chosen to ACTIVE
      await (update(semesters)..where((t) => t.id.equals(semesterId))).write(
        const SemestersCompanion(status: Value('ACTIVE')),
      );
    });
  }

  Future<void> deleteSemester(String semesterId) {
    return (update(semesters)..where((t) => t.id.equals(semesterId))).write(
      SemestersCompanion(deletedAt: Value(DateTime.now().toIso8601String())),
    );
  }

  // ==========================================
  // SUBJECTS & COMPONENTS CRUD
  // ==========================================

  Future<List<SubjectData>> getAllSubjects(String semesterId) {
    return (select(subjects)
          ..where((t) => t.semesterId.equals(semesterId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
        .get();
  }

  Future<void> saveSubject(SubjectData subject) {
    return into(subjects).insertOnConflictUpdate(subject);
  }

  Future<void> deleteSubject(String subjectId) async {
    final nowIso = DateTime.now().toIso8601String();
    await (update(subjects)..where((t) => t.id.equals(subjectId))).write(
      SubjectsCompanion(deletedAt: Value(nowIso)),
    );
    await (update(timetableSlots)..where((t) => t.subjectComponentId.equals(subjectId))).write(
      TimetableSlotsCompanion(deletedAt: Value(nowIso)),
    );
  }

  Future<List<SubjectComponentData>> getSubjectComponents(String subjectId) {
    return (select(subjectComponents)..where((t) => t.subjectId.equals(subjectId) & t.deletedAt.isNull())).get();
  }

  Future<void> saveSubjectComponent(SubjectComponentData component) {
    return into(subjectComponents).insertOnConflictUpdate(component);
  }

  // ==========================================
  // TIMETABLE SLOTS CRUD
  // ==========================================

  Future<List<TimetableSlotData>> getTimetableSlots(String semesterId) {
    return (select(timetableSlots)
          ..where((t) => t.semesterId.equals(semesterId) & t.deletedAt.isNull())
          ..orderBy([
            (t) => OrderingTerm(expression: t.dayOfWeek),
            (t) => OrderingTerm(expression: t.startTime),
          ]))
        .get();
  }

  Future<void> saveTimetableSlot(TimetableSlotData slot) {
    return into(timetableSlots).insertOnConflictUpdate(slot);
  }

  Future<void> saveTimetableSlotsBatch(List<TimetableSlotData> slotList) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(timetableSlots, slotList);
    });
  }

  Future<void> deleteTimetableSlot(String slotId) {
    return (update(timetableSlots)..where((t) => t.id.equals(slotId))).write(
      TimetableSlotsCompanion(deletedAt: Value(DateTime.now().toIso8601String())),
    );
  }

  Future<void> clearAllScheduleData() async {
    final nowIso = DateTime.now().toIso8601String();
    await (update(subjects)).write(SubjectsCompanion(deletedAt: Value(nowIso)));
    await (update(timetableSlots)).write(TimetableSlotsCompanion(deletedAt: Value(nowIso)));
    await (update(attendanceRecords)).write(AttendanceRecordsCompanion(deletedAt: Value(nowIso)));
    await (update(extraClasses)).write(ExtraClassesCompanion(deletedAt: Value(nowIso)));
  }

  // ==========================================
  // ATTENDANCE RECORDS CRUD
  // ==========================================

  Future<List<AttendanceRecordData>> getAllAttendanceRecords() {
    return (select(attendanceRecords)..where((t) => t.deletedAt.isNull())).get();
  }

  Future<List<AttendanceRecordData>> getAttendanceForDate(String sessionDate) {
    return (select(attendanceRecords)
          ..where((t) => t.sessionDate.equals(sessionDate) & t.deletedAt.isNull()))
        .get();
  }

  Future<AttendanceRecordData?> getAttendanceForSession(String classSessionId) {
    return (select(attendanceRecords)
          ..where((t) => t.classSessionId.equals(classSessionId) & t.deletedAt.isNull()))
        .getSingleOrNull();
  }

  Future<void> saveAttendanceRecord(AttendanceRecordData record) {
    return into(attendanceRecords).insertOnConflictUpdate(record);
  }

  Stream<List<AttendanceRecordData>> watchAttendanceRecords() {
    return (select(attendanceRecords)..where((t) => t.deletedAt.isNull())).watch();
  }

  // ==========================================
  // HOLIDAYS & ACADEMIC DAY CONFIGS
  // ==========================================

  Future<List<HolidayData>> getHolidays(String semesterId) {
    return (select(holidays)..where((t) => t.semesterId.equals(semesterId) & t.deletedAt.isNull())).get();
  }

  Future<void> saveHoliday(HolidayData holiday) {
    return into(holidays).insertOnConflictUpdate(holiday);
  }

  Future<void> deleteHoliday(String id) {
    return (update(holidays)..where((t) => t.id.equals(id))).write(
      HolidaysCompanion(deletedAt: Value(DateTime.now().toIso8601String())),
    );
  }

  Future<List<AcademicDayConfigData>> getAcademicDayConfigs(String semesterId) {
    return (select(academicDayConfigs)..where((t) => t.semesterId.equals(semesterId))).get();
  }

  Future<void> saveAcademicDayConfig(AcademicDayConfigData config) {
    return into(academicDayConfigs).insertOnConflictUpdate(config);
  }

  // ==========================================
  // EXTRA CLASSES
  // ==========================================

  Future<List<ExtraClassData>> getExtraClasses(String semesterId) {
    return (select(extraClasses)..where((t) => t.semesterId.equals(semesterId) & t.deletedAt.isNull())).get();
  }

  Future<void> saveExtraClass(ExtraClassData extraClass) {
    return into(extraClasses).insertOnConflictUpdate(extraClass);
  }

  Future<void> deleteExtraClass(String id) {
    return (update(extraClasses)..where((t) => t.id.equals(id))).write(
      ExtraClassesCompanion(deletedAt: Value(DateTime.now().toIso8601String())),
    );
  }

  // ==========================================
  // SCHEDULE EXCEPTIONS (SINGLE DATE EDITS & CANCELLATIONS)
  // ==========================================

  Future<List<ScheduleExceptionData>> getScheduleExceptions() {
    return select(scheduleExceptions).get();
  }

  Future<void> saveScheduleException(ScheduleExceptionData exception) {
    return into(scheduleExceptions).insertOnConflictUpdate(exception);
  }

  Future<void> deleteScheduleException(String id) {
    return (delete(scheduleExceptions)..where((t) => t.id.equals(id))).go();
  }

  Future<void> deleteScheduleExceptionForSlotAndDate(String slotId, String exceptionDate) {
    return (delete(scheduleExceptions)
          ..where((t) => t.timetableSlotId.equals(slotId) & t.exceptionDate.equals(exceptionDate)))
        .go();
  }

  // ==========================================
  // APP SETTINGS (KEY-VALUE PAIRS)
  // ==========================================

  Future<String?> getSetting(String key) async {
    final result = await (select(appSettings)..where((t) => t.key.equals(key))).getSingleOrNull();
    return result?.value;
  }

  Future<void> setSetting(String key, String value) {
    return into(appSettings).insertOnConflictUpdate(AppSettingData(key: key, value: value));
  }

  Future<Map<String, String>> getAllSettings() async {
    final list = await select(appSettings).get();
    return {for (final item in list) item.key: item.value};
  }

  // ==========================================
  // INITIAL DATABASE SEEDER & HELPERS
  // ==========================================

  Future<void> seedInitialDataIfEmpty() async {
    // Initial launch: Start with clean database, no fake semesters.
    // User will be guided to set up profile and create their active semester.
  }

  Future<void> populateDemoData(String targetSemesterId) async {
    final nowIso = DateTime.now().toIso8601String();
    final sub1Id = UuidGenerator.generate();
    final sub2Id = UuidGenerator.generate();
    final sub3Id = UuidGenerator.generate();

    await saveSubject(
      SubjectData(
        id: sub1Id,
        semesterId: targetSemesterId,
        name: 'Foundations of Computer Science',
        code: 'CS-101',
        category: 'MAJOR',
        credits: 4,
        targetAttendancePct: 75.0,
        baselineHeld: 0,
        baselineAttended: 0,
        colorHex: '#4F46E5',
        isArchived: false,
        createdAt: nowIso,
        updatedAt: nowIso,
      ),
    );

    await saveSubject(
      SubjectData(
        id: sub2Id,
        semesterId: targetSemesterId,
        name: 'Digital Logic & Architecture',
        code: 'CS-102',
        category: 'MINOR',
        credits: 4,
        targetAttendancePct: 75.0,
        baselineHeld: 0,
        baselineAttended: 0,
        colorHex: '#0284C7',
        isArchived: false,
        createdAt: nowIso,
        updatedAt: nowIso,
      ),
    );

    await saveSubject(
      SubjectData(
        id: sub3Id,
        semesterId: targetSemesterId,
        name: 'Environmental Studies',
        code: 'VAC-101',
        category: 'VAC',
        credits: 2,
        targetAttendancePct: 75.0,
        baselineHeld: 0,
        baselineAttended: 0,
        colorHex: '#E11D48',
        isArchived: false,
        createdAt: nowIso,
        updatedAt: nowIso,
      ),
    );

    // Mon, Wed, Fri for Major (Days 1, 3, 5)
    for (final day in [1, 3, 5]) {
      await saveTimetableSlot(
        TimetableSlotData(
          id: UuidGenerator.generate(),
          semesterId: targetSemesterId,
          subjectComponentId: sub1Id,
          dayOfWeek: day,
          startTime: '09:00',
          endTime: '10:00',
          room: 'Room 101',
          teacherName: 'Prof. R. Sharma',
          createdAt: nowIso,
          updatedAt: nowIso,
        ),
      );
    }

    // Tue, Thu for Minor (Days 2, 4)
    for (final day in [2, 4]) {
      await saveTimetableSlot(
        TimetableSlotData(
          id: UuidGenerator.generate(),
          semesterId: targetSemesterId,
          subjectComponentId: sub2Id,
          dayOfWeek: day,
          startTime: '10:15',
          endTime: '11:15',
          room: 'Lab B',
          teacherName: 'Dr. S. Roy',
          createdAt: nowIso,
          updatedAt: nowIso,
        ),
      );
    }
  }

  Future<void> copySubjectsToSemester(String fromSemId, String toSemId) async {
    final nowIso = DateTime.now().toIso8601String();
    final sourceSubjects = await getAllSubjects(fromSemId);
    for (final s in sourceSubjects) {
      await saveSubject(
        SubjectData(
          id: UuidGenerator.generate(),
          semesterId: toSemId,
          name: s.name,
          code: s.code,
          category: s.category,
          credits: s.credits,
          targetAttendancePct: s.targetAttendancePct,
          baselineHeld: 0,
          baselineAttended: 0,
          colorHex: s.colorHex,
          isArchived: false,
          createdAt: nowIso,
          updatedAt: nowIso,
        ),
      );
    }
  }

  // ==========================================
  // FULL BACKUP & RESTORE ATOMIC OPERATIONS
  // ==========================================

  Future<List<SemesterData>> getAllSemestersAll() => select(semesters).get();
  Future<List<SubjectData>> getAllSubjectsAll() => select(subjects).get();
  Future<List<SubjectComponentData>> getAllSubjectComponentsAll() => select(subjectComponents).get();
  Future<List<TimetableSlotData>> getAllTimetableSlotsAll() => select(timetableSlots).get();
  Future<List<AcademicDayConfigData>> getAllAcademicDayConfigsAll() => select(academicDayConfigs).get();
  Future<List<HolidayData>> getAllHolidaysAll() => select(holidays).get();
  Future<List<ScheduleExceptionData>> getAllScheduleExceptionsAll() => select(scheduleExceptions).get();
  Future<List<ExtraClassData>> getAllExtraClassesAll() => select(extraClasses).get();
  Future<List<ClassSessionData>> getAllClassSessionsAll() => select(classSessions).get();
  Future<List<AttendanceRecordData>> getAllAttendanceRecordsAll() => select(attendanceRecords).get();
  Future<List<AppSettingData>> getAllAppSettingsAll() => select(appSettings).get();

  Future<void> restoreAllTablesAtomic({
    required List<SemesterData> semestersList,
    required List<SubjectData> subjectsList,
    required List<SubjectComponentData> subjectComponentsList,
    required List<TimetableSlotData> timetableSlotsList,
    required List<AcademicDayConfigData> academicDayConfigsList,
    required List<HolidayData> holidaysList,
    required List<ScheduleExceptionData> scheduleExceptionsList,
    required List<ExtraClassData> extraClassesList,
    required List<ClassSessionData> classSessionsList,
    required List<AttendanceRecordData> attendanceRecordsList,
    required List<AppSettingData> appSettingsList,
  }) async {
    await transaction(() async {
      // Clear tables in reverse dependency order
      await delete(attendanceRecords).go();
      await delete(classSessions).go();
      await delete(extraClasses).go();
      await delete(scheduleExceptions).go();
      await delete(holidays).go();
      await delete(academicDayConfigs).go();
      await delete(timetableSlots).go();
      await delete(subjectComponents).go();
      await delete(subjects).go();
      await delete(semesters).go();
      await delete(appSettings).go();

      // Insert all in topological dependency order
      await batch((b) {
        if (semestersList.isNotEmpty) b.insertAll(semesters, semestersList);
        if (subjectsList.isNotEmpty) b.insertAll(subjects, subjectsList);
        if (subjectComponentsList.isNotEmpty) b.insertAll(subjectComponents, subjectComponentsList);
        if (timetableSlotsList.isNotEmpty) b.insertAll(timetableSlots, timetableSlotsList);
        if (academicDayConfigsList.isNotEmpty) b.insertAll(academicDayConfigs, academicDayConfigsList);
        if (holidaysList.isNotEmpty) b.insertAll(holidays, holidaysList);
        if (scheduleExceptionsList.isNotEmpty) b.insertAll(scheduleExceptions, scheduleExceptionsList);
        if (extraClassesList.isNotEmpty) b.insertAll(extraClasses, extraClassesList);
        if (classSessionsList.isNotEmpty) b.insertAll(classSessions, classSessionsList);
        if (attendanceRecordsList.isNotEmpty) b.insertAll(attendanceRecords, attendanceRecordsList);
        if (appSettingsList.isNotEmpty) b.insertAll(appSettings, appSettingsList);
      });
    });
  }
}
