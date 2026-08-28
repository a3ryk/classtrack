import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';
import '../../data/templates/programme_templates.dart';
import '../../domain/entities/academic_template.dart';
import '../../domain/entities/attendance_stats.dart';
import '../../domain/entities/class_session_entity.dart';
import '../../domain/entities/semester_entity.dart';
import '../../domain/entities/subject_entity.dart';
import '../../domain/entities/user_profile_entity.dart';
import '../../domain/services/attendance_math.dart';
import '../../domain/services/schedule_engine.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/uuid_generator.dart';
import '../../core/services/notification_service.dart';
import 'backup_provider.dart';
import 'theme_provider.dart';

// ==========================================
// 1. DATABASE PROVIDER
// ==========================================
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.production();
});

// ==========================================
// 2. APP INITIALIZATION & HYDRATION PROVIDER
// ==========================================
final appInitializationProvider = FutureProvider<bool>((ref) async {
  final db = ref.read(databaseProvider);
  await db.seedInitialDataIfEmpty();

  // Hydrate all notifiers
  await ref.read(userProfileProvider.notifier).loadFromDb();
  await ref.read(selectedUniversityProvider.notifier).loadFromDb();
  await ref.read(activeSemesterProvider.notifier).loadFromDb();
  await ref.read(semestersListProvider.notifier).loadFromDb();
  await ref.read(subjectsProvider.notifier).loadFromDb();
  await ref.read(timetableSlotsProvider.notifier).loadFromDb();
  await ref.read(holidaysProvider.notifier).loadFromDb();
  await ref.read(attendanceRecordsProvider.notifier).loadFromDb();
  await ref.read(targetPercentageProvider.notifier).loadFromDb();
  await ref.read(activeTemplateProvider.notifier).loadFromDb();
  await ref.read(betaFeaturesEnabledProvider.notifier).loadFromDb();
  await ref.read(developerModeEnabledProvider.notifier).loadFromDb();
  await ref.read(themeModeProvider.notifier).loadFromDb();
  await ref.read(hasCompletedOnboardingProvider.notifier).loadFromDb();
  await ref.read(isDeveloperUnlockedProvider.notifier).loadFromDb();
  await ref.read(customDevPasscodeHashProvider.notifier).loadFromDb();
  await ref.read(backupProvider.notifier).loadSettingsAndBackups();
  await ref.read(backupProvider.notifier).checkAndRunAutoBackup(db);
  await NotificationService.instance.init();

  return true;
});

// ==========================================
// 3. USER PROFILE PROVIDER
// ==========================================
final userProfileProvider = StateNotifierProvider<UserProfileNotifier, UserProfileEntity>((ref) {
  final db = ref.watch(databaseProvider);
  return UserProfileNotifier(db);
});

class UserProfileNotifier extends StateNotifier<UserProfileEntity> {
  final AppDatabase db;

  UserProfileNotifier(this.db)
      : super(
          const UserProfileEntity(
            studentName: '',
            rollNumber: '',
            enrollmentNumber: '',
            degreeProgramme: '',
            department: '',
          ),
        );

  Future<void> loadFromDb() async {
    final jsonStr = await db.getSetting('user_profile');
    if (!mounted) return;
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final Map<String, dynamic> map = jsonDecode(jsonStr);
        state = UserProfileEntity.fromJson(map);
      } catch (_) {}
    }
  }

  Future<void> updateProfile(UserProfileEntity updated) async {
    state = updated;
    await db.setSetting('user_profile', jsonEncode(updated.toJson()));
  }
}

// ==========================================
// 4. UNIVERSITY / COLLEGE PROVIDER
// ==========================================
class UserUniversityInfo {
  final String state;
  final String universityName;
  final String locationType; // 'CAMPUS' or 'AFFILIATED_COLLEGE'
  final String? collegeName;

  const UserUniversityInfo({
    required this.state,
    required this.universityName,
    required this.locationType,
    this.collegeName,
  });

  Map<String, dynamic> toJson() => {
        'state': state,
        'universityName': universityName,
        'locationType': locationType,
        'collegeName': collegeName,
      };

  factory UserUniversityInfo.fromJson(Map<String, dynamic> json) => UserUniversityInfo(
        state: json['state'] as String? ?? 'Assam',
        universityName: json['universityName'] as String? ?? 'Gauhati University (GU)',
        locationType: json['locationType'] as String? ?? 'CAMPUS',
        collegeName: json['collegeName'] as String?,
      );
}

final selectedUniversityProvider = StateNotifierProvider<SelectedUniversityNotifier, UserUniversityInfo>((ref) {
  final db = ref.watch(databaseProvider);
  return SelectedUniversityNotifier(db);
});

class SelectedUniversityNotifier extends StateNotifier<UserUniversityInfo> {
  final AppDatabase db;

  SelectedUniversityNotifier(this.db)
      : super(
          const UserUniversityInfo(
            state: '',
            universityName: '',
            locationType: 'CAMPUS',
          ),
        );

  Future<void> loadFromDb() async {
    final jsonStr = await db.getSetting('user_university');
    if (!mounted) return;
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final Map<String, dynamic> map = jsonDecode(jsonStr);
        state = UserUniversityInfo.fromJson(map);
      } catch (_) {}
    }
  }

  Future<void> updateUniversity({
    required String stateName,
    required String universityName,
    required String locationType,
    String? collegeName,
  }) async {
    final updated = UserUniversityInfo(
      state: stateName,
      universityName: universityName,
      locationType: locationType,
      collegeName: collegeName,
    );
    state = updated;
    await db.setSetting('user_university', jsonEncode(updated.toJson()));
  }
}

// ==========================================
// 5. HOLIDAYS & VACATIONS PROVIDER
// ==========================================
final holidaysProvider = StateNotifierProvider<HolidaysNotifier, List<HolidayItem>>((ref) {
  final db = ref.watch(databaseProvider);
  final activeSem = ref.watch(activeSemesterProvider);
  return HolidaysNotifier(db, activeSem.id);
});

class HolidaysNotifier extends StateNotifier<List<HolidayItem>> {
  final AppDatabase db;
  final String semesterId;

  HolidaysNotifier(this.db, this.semesterId) : super([]) {
    loadFromDb();
  }

  Future<void> loadFromDb() async {
    final rows = await db.getHolidays(semesterId);
    if (!mounted) return;
    state = rows.map((r) => HolidayItem(title: r.title, startDate: r.startDate, endDate: r.endDate)).toList();
  }

  Future<void> addHoliday(HolidayItem holiday) async {
    state = [...state, holiday];
    final nowIso = DateTime.now().toIso8601String();
    await db.saveHoliday(
      HolidayData(
        id: UuidGenerator.generate(),
        semesterId: semesterId,
        title: holiday.title,
        startDate: holiday.startDate,
        endDate: holiday.endDate,
        category: 'HOLIDAY',
        createdAt: nowIso,
        updatedAt: nowIso,
      ),
    );
  }

  Future<void> removeHoliday(String title) async {
    final target = state.firstWhere((h) => h.title == title, orElse: () => HolidayItem(title: '', startDate: '', endDate: ''));
    state = state.where((h) => h.title != title).toList();
    if (target.title.isNotEmpty) {
      final rows = await db.getHolidays(semesterId);
      final match = rows.where((r) => r.title == title).toList();
      for (final m in match) {
        await db.deleteHoliday(m.id);
      }
    }
  }
}

// ==========================================
// 6. SEMESTER PROVIDERS
// ==========================================
final activeSemesterProvider = StateNotifierProvider<ActiveSemesterNotifier, SemesterEntity>((ref) {
  final db = ref.watch(databaseProvider);
  return ActiveSemesterNotifier(db);
});

class ActiveSemesterNotifier extends StateNotifier<SemesterEntity> {
  final AppDatabase db;

  ActiveSemesterNotifier(this.db) : super(SemesterEntity.empty());

  Future<void> loadFromDb() async {
    final active = await db.getActiveSemester();
    if (!mounted) return;
    if (active != null) {
      state = _mapSemesterData(active);
    } else {
      state = SemesterEntity.empty();
    }
  }

  Future<void> updateSemester(SemesterEntity semester) async {
    state = semester;
    final nowIso = DateTime.now().toIso8601String();
    await db.saveSemester(
      SemesterData(
        id: semester.id,
        name: semester.name,
        startDate: DateFormatter.toIsoDate(semester.startDate),
        endDate: semester.endDate != null ? DateFormatter.toIsoDate(semester.endDate!) : DateFormatter.toIsoDate(DateTime(2026, 12, 31)),
        defaultTargetPct: 75.0,
        status: 'ACTIVE',
        createdAt: nowIso,
        updatedAt: nowIso,
      ),
    );
  }

  static SemesterEntity _mapSemesterData(SemesterData d) {
    DateTime start = DateTime(2026, 8, 1);
    DateTime? end = DateTime(2026, 12, 20);
    try {
      start = DateTime.parse(d.startDate);
      end = DateTime.parse(d.endDate);
    } catch (_) {}

    return SemesterEntity(
      id: d.id,
      name: d.name,
      academicYear: '2026',
      startDate: start,
      endDate: end,
      isCurrent: d.status == 'ACTIVE',
    );
  }
}

final semestersListProvider = StateNotifierProvider<SemestersListNotifier, List<SemesterEntity>>((ref) {
  final db = ref.watch(databaseProvider);
  return SemestersListNotifier(db);
});

class SemestersListNotifier extends StateNotifier<List<SemesterEntity>> {
  final AppDatabase db;

  SemestersListNotifier(this.db) : super([]);

  Future<void> loadFromDb() async {
    final list = await db.getAllSemesters();
    if (!mounted) return;
    if (list.isNotEmpty) {
      state = list.map((d) => ActiveSemesterNotifier._mapSemesterData(d)).toList();
    }
  }

  Future<void> addSemester(SemesterEntity semester) async {
    state = [...state, semester];
    final nowIso = DateTime.now().toIso8601String();
    await db.saveSemester(
      SemesterData(
        id: semester.id,
        name: semester.name,
        startDate: DateFormatter.toIsoDate(semester.startDate),
        endDate: semester.endDate != null ? DateFormatter.toIsoDate(semester.endDate!) : DateFormatter.toIsoDate(DateTime(2026, 12, 31)),
        defaultTargetPct: 75.0,
        status: semester.isCurrent ? 'ACTIVE' : 'ARCHIVED',
        createdAt: nowIso,
        updatedAt: nowIso,
      ),
    );
  }

  Future<void> updateSemesterInList(SemesterEntity updated) async {
    state = [
      for (final s in state)
        if (s.id == updated.id) updated else s
    ];
    final nowIso = DateTime.now().toIso8601String();
    await db.saveSemester(
      SemesterData(
        id: updated.id,
        name: updated.name,
        startDate: DateFormatter.toIsoDate(updated.startDate),
        endDate: updated.endDate != null ? DateFormatter.toIsoDate(updated.endDate!) : DateFormatter.toIsoDate(DateTime(2026, 12, 31)),
        defaultTargetPct: 75.0,
        status: updated.isCurrent ? 'ACTIVE' : 'ARCHIVED',
        createdAt: nowIso,
        updatedAt: nowIso,
      ),
    );
  }

  Future<void> deleteSemester(String semesterId) async {
    state = state.where((s) => s.id != semesterId).toList();
    await db.deleteSemester(semesterId);
  }
}

// ==========================================
// 7. ACADEMIC TEMPLATE PROVIDER
// ==========================================
final activeTemplateProvider = StateNotifierProvider<ActiveTemplateNotifier, ProgrammeTemplate>((ref) {
  final db = ref.watch(databaseProvider);
  return ActiveTemplateNotifier(db);
});

class ActiveTemplateNotifier extends StateNotifier<ProgrammeTemplate> {
  final AppDatabase db;

  ActiveTemplateNotifier(this.db) : super(ProgrammeTemplates.noneTemplate);

  Future<void> loadFromDb() async {
    final templateId = await db.getSetting('academic_template_id');
    if (!mounted) return;
    state = ProgrammeTemplates.getById(templateId);
  }

  Future<void> selectTemplate(ProgrammeTemplate template) async {
    state = template;
    await db.setSetting('academic_template_id', template.id);
  }

  Future<void> clearTemplate() async {
    state = ProgrammeTemplates.noneTemplate;
    await db.setSetting('academic_template_id', 'none');
  }
}

// ==========================================
// 8. TARGET PERCENTAGE & FLAGS PROVIDERS
// ==========================================
final targetPercentageProvider = StateNotifierProvider<TargetPercentageNotifier, double>((ref) {
  final db = ref.watch(databaseProvider);
  return TargetPercentageNotifier(db);
});

class TargetPercentageNotifier extends StateNotifier<double> {
  final AppDatabase db;
  TargetPercentageNotifier(this.db) : super(75.0);

  Future<void> loadFromDb() async {
    final val = await db.getSetting('target_percentage');
    if (!mounted) return;
    if (val != null) {
      state = double.tryParse(val) ?? 75.0;
    }
  }

  Future<void> setTarget(double target) async {
    state = target;
    await db.setSetting('target_percentage', target.toString());
  }
}

final betaFeaturesEnabledProvider = StateNotifierProvider<BetaFeaturesNotifier, bool>((ref) {
  final db = ref.watch(databaseProvider);
  return BetaFeaturesNotifier(db);
});

class BetaFeaturesNotifier extends StateNotifier<bool> {
  final AppDatabase db;
  BetaFeaturesNotifier(this.db) : super(false);

  Future<void> loadFromDb() async {
    final val = await db.getSetting('beta_features_enabled');
    if (!mounted) return;
    if (val != null) {
      state = val == 'true';
    }
  }

  Future<void> toggle(bool value) async {
    state = value;
    await db.setSetting('beta_features_enabled', value.toString());
  }
}

final developerModeEnabledProvider = StateNotifierProvider<DeveloperModeNotifier, bool>((ref) {
  final db = ref.watch(databaseProvider);
  return DeveloperModeNotifier(db);
});

class DeveloperModeNotifier extends StateNotifier<bool> {
  final AppDatabase db;
  DeveloperModeNotifier(this.db) : super(false);

  Future<void> loadFromDb() async {
    final val = await db.getSetting('developer_mode_enabled');
    if (!mounted) return;
    if (val != null) {
      state = val == 'true';
    }
  }

  Future<void> toggle(bool value) async {
    state = value;
    await db.setSetting('developer_mode_enabled', value.toString());
  }
}

// ==========================================
// 8.5. REAL-TIME TICKER PROVIDER (15-second live pulse)
// ==========================================
final realtimeClockProvider = StreamProvider<DateTime>((ref) {
  return Stream.periodic(const Duration(seconds: 15), (_) => DateTime.now());
});

// ==========================================
// 9. DYNAMIC SUBJECTS PROVIDER (SQLite Persisted)
// ==========================================
final subjectsProvider = StateNotifierProvider<SubjectsNotifier, List<SubjectEntity>>((ref) {
  final db = ref.watch(databaseProvider);
  final activeSem = ref.watch(activeSemesterProvider);
  return SubjectsNotifier(db, activeSem.id, ref);
});

class SubjectsNotifier extends StateNotifier<List<SubjectEntity>> {
  final AppDatabase db;
  final String semesterId;
  final Ref ref;

  SubjectsNotifier(this.db, this.semesterId, this.ref) : super([]) {
    loadFromDb();
  }

  Future<void> loadFromDb() async {
    final list = await db.getAllSubjects(semesterId);
    if (!mounted) return;
    state = list.map((d) => _mapSubjectData(d)).toList();
  }

  Future<void> addSubject(SubjectEntity subject) async {
    state = [...state, subject];
    final nowIso = DateTime.now().toIso8601String();
    await db.saveSubject(
      SubjectData(
        id: subject.id,
        semesterId: semesterId,
        name: subject.name,
        code: subject.code,
        category: subject.category,
        credits: subject.credits,
        targetAttendancePct: subject.targetAttendancePct,
        baselineHeld: subject.baselineHeld,
        baselineAttended: subject.baselineAttended,
        colorHex: subject.colorHex,
        isArchived: subject.isArchived,
        createdAt: nowIso,
        updatedAt: nowIso,
      ),
    );
    ref.read(timetableSlotsProvider.notifier).loadFromDb(state);
  }

  Future<void> updateSubject(SubjectEntity updated) async {
    state = [
      for (final s in state)
        if (s.id == updated.id) updated else s
    ];
    final nowIso = DateTime.now().toIso8601String();
    await db.saveSubject(
      SubjectData(
        id: updated.id,
        semesterId: semesterId,
        name: updated.name,
        code: updated.code,
        category: updated.category,
        credits: updated.credits,
        targetAttendancePct: updated.targetAttendancePct,
        baselineHeld: updated.baselineHeld,
        baselineAttended: updated.baselineAttended,
        colorHex: updated.colorHex,
        isArchived: updated.isArchived,
        createdAt: nowIso,
        updatedAt: nowIso,
      ),
    );
    ref.read(timetableSlotsProvider.notifier).loadFromDb(state);
  }

  Future<void> deleteSubject(String subjectId, {bool deleteSlots = true}) async {
    state = state.where((s) => s.id != subjectId).toList();
    await db.deleteSubject(subjectId);
    await ref.read(timetableSlotsProvider.notifier).loadFromDb(state);
    await ref.read(attendanceRecordsProvider.notifier).loadFromDb();
  }

  Future<void> populateDemoData() async {
    await db.populateDemoData(semesterId);
    await loadFromDb();
    await ref.read(timetableSlotsProvider.notifier).loadFromDb();
    await ref.read(attendanceRecordsProvider.notifier).loadFromDb();
  }

  Future<void> clearAllData() async {
    state = [];
    await db.clearAllScheduleData();
    await ref.read(timetableSlotsProvider.notifier).loadFromDb([]);
    await ref.read(attendanceRecordsProvider.notifier).loadFromDb();
  }

  static SubjectEntity _mapSubjectData(SubjectData d) {
    return SubjectEntity(
      id: d.id,
      semesterId: d.semesterId,
      name: d.name,
      code: d.code,
      category: d.category,
      credits: d.credits,
      targetAttendancePct: d.targetAttendancePct,
      baselineHeld: d.baselineHeld,
      baselineAttended: d.baselineAttended,
      colorHex: d.colorHex,
      isArchived: d.isArchived,
      components: [],
    );
  }
}

// ==========================================
// 10. TIMETABLE SLOTS PROVIDER (SQLite Persisted)
// ==========================================
final timetableSlotsProvider = StateNotifierProvider<TimetableSlotsNotifier, List<TimetableSlotItem>>((ref) {
  final db = ref.watch(databaseProvider);
  final activeSem = ref.watch(activeSemesterProvider);
  final subjects = ref.watch(subjectsProvider);
  return TimetableSlotsNotifier(db, activeSem.id, subjects);
});

class TimetableSlotsNotifier extends StateNotifier<List<TimetableSlotItem>> {
  final AppDatabase db;
  final String semesterId;
  final List<SubjectEntity> subjects;

  TimetableSlotsNotifier(this.db, this.semesterId, this.subjects) : super([]) {
    loadFromDb();
  }

  Future<void> loadFromDb([List<SubjectEntity>? updatedSubjects]) async {
    final list = await db.getTimetableSlots(semesterId);
    if (!mounted) return;
    final List<SubjectEntity> liveSubjects = updatedSubjects ??
        (await db.getAllSubjects(semesterId)).map((d) => SubjectsNotifier._mapSubjectData(d)).toList();
    final subjectMap = {for (final s in liveSubjects) s.id: s};

    state = list.map((slotData) {
      final sub = subjectMap[slotData.subjectComponentId];
      final rawNotes = (slotData.notes ?? '').toUpperCase();
      String compType = 'LECTURE';
      if (rawNotes.contains('PRACTICAL') || rawNotes.contains('LAB')) {
        compType = 'PRACTICAL';
      } else if (rawNotes.contains('TUTORIAL')) {
        compType = 'TUTORIAL';
      } else if (rawNotes.contains('SEMINAR') || rawNotes.contains('WORKSHOP')) {
        compType = 'SEMINAR';
      }

      return TimetableSlotItem(
        id: slotData.id,
        semesterId: slotData.semesterId,
        subjectComponentId: slotData.subjectComponentId,
        subjectName: sub?.name ?? 'Deleted Subject',
        subjectCode: sub?.code,
        category: sub?.category ?? 'MAJOR',
        componentType: compType,
        colorHex: sub?.colorHex ?? '#4F46E5',
        dayOfWeek: slotData.dayOfWeek,
        startTime: slotData.startTime,
        endTime: slotData.endTime,
        room: slotData.room,
        teacherName: slotData.teacherName,
        effectiveFrom: slotData.effectiveFrom,
        effectiveUntil: slotData.effectiveUntil,
      );
    }).toList();
  }

  Future<void> addSlot(TimetableSlotData slotData) async {
    await db.saveTimetableSlot(slotData);
    await loadFromDb();
  }

  Future<void> addBatchSlots(List<TimetableSlotData> slotList) async {
    await db.saveTimetableSlotsBatch(slotList);
    await loadFromDb();
  }

  Future<void> updateSingleSlot(TimetableSlotData slotData) async {
    await db.saveTimetableSlot(slotData);
    await loadFromDb();
  }

  Future<void> updateSlotsForSubject({
    required String subjectId,
    String? newStartTime,
    String? newEndTime,
    String? newRoom,
    String? newTeacher,
    String? newComponentType,
  }) async {
    final existingSlots = await db.getTimetableSlots(semesterId);
    final subjectSlots = existingSlots.where((s) => s.subjectComponentId == subjectId).toList();

    for (final slot in subjectSlots) {
      final updated = slot.copyWith(
        startTime: newStartTime ?? slot.startTime,
        endTime: newEndTime ?? slot.endTime,
        room: newRoom != null ? Value(newRoom) : Value(slot.room),
        teacherName: newTeacher != null ? Value(newTeacher) : Value(slot.teacherName),
        notes: newComponentType != null ? Value(newComponentType) : Value(slot.notes),
        updatedAt: DateTime.now().toIso8601String(),
      );
      await db.saveTimetableSlot(updated);
    }
    await loadFromDb();
  }

  Future<void> deleteSlotsForSubject(String subjectId) async {
    final existingSlots = await db.getTimetableSlots(semesterId);
    final subjectSlots = existingSlots.where((s) => s.subjectComponentId == subjectId).toList();
    for (final slot in subjectSlots) {
      await db.deleteTimetableSlot(slot.id);
    }
    await loadFromDb();
  }

  Future<void> deleteSlot(String slotId) async {
    await db.deleteTimetableSlot(slotId);
    state = state.where((s) => s.id != slotId).toList();
  }
}

// ==========================================
// 10.5. SCHEDULE EXCEPTIONS & EXTRA CLASSES PROVIDERS
// ==========================================
final scheduleExceptionsProvider = StateNotifierProvider<ScheduleExceptionsNotifier, List<ScheduleExceptionItem>>((ref) {
  final db = ref.watch(databaseProvider);
  return ScheduleExceptionsNotifier(db);
});

class ScheduleExceptionsNotifier extends StateNotifier<List<ScheduleExceptionItem>> {
  final AppDatabase db;
  ScheduleExceptionsNotifier(this.db) : super([]) {
    loadFromDb();
  }

  Future<void> loadFromDb() async {
    final list = await db.getScheduleExceptions();
    if (!mounted) return;
    state = list.map((e) => ScheduleExceptionItem(
      timetableSlotId: e.timetableSlotId,
      exceptionDate: e.exceptionDate,
      actionType: e.actionType,
      newStartTime: e.newStartTime,
      newEndTime: e.newEndTime,
      substituteComponentId: e.substituteComponentId,
      newRoom: e.newRoom,
    )).toList();
  }

  Future<void> addOrUpdateException({
    required String timetableSlotId,
    required String exceptionDate,
    required String actionType,
    String? newStartTime,
    String? newEndTime,
    String? newRoom,
    String? notes,
  }) async {
    final nowIso = DateTime.now().toIso8601String();
    final exception = ScheduleExceptionData(
      id: 'exc_${timetableSlotId}_$exceptionDate',
      timetableSlotId: timetableSlotId,
      exceptionDate: exceptionDate,
      actionType: actionType,
      newStartTime: newStartTime,
      newEndTime: newEndTime,
      substituteComponentId: null,
      newRoom: newRoom,
      notes: notes,
      createdAt: nowIso,
      updatedAt: nowIso,
    );
    await db.saveScheduleException(exception);
    await loadFromDb();
  }

  Future<void> removeException(String timetableSlotId, String exceptionDate) async {
    await db.deleteScheduleExceptionForSlotAndDate(timetableSlotId, exceptionDate);
    await loadFromDb();
  }
}

final extraClassesProvider = StateNotifierProvider<ExtraClassesNotifier, List<ExtraClassItem>>((ref) {
  final db = ref.watch(databaseProvider);
  final activeSem = ref.watch(activeSemesterProvider);
  final subjects = ref.watch(subjectsProvider);
  return ExtraClassesNotifier(db, activeSem.id, subjects);
});

class ExtraClassesNotifier extends StateNotifier<List<ExtraClassItem>> {
  final AppDatabase db;
  final String semesterId;
  final List<SubjectEntity> subjects;

  ExtraClassesNotifier(this.db, this.semesterId, this.subjects) : super([]) {
    loadFromDb();
  }

  Future<void> loadFromDb() async {
    final list = await db.getExtraClasses(semesterId);
    if (!mounted) return;
    final subjectMap = {for (final s in subjects) s.id: s};

    state = list.map((e) {
      final sub = subjectMap[e.subjectComponentId];
      return ExtraClassItem(
        id: e.id,
        semesterId: e.semesterId,
        subjectComponentId: e.subjectComponentId,
        subjectName: sub?.name ?? 'Extra Class',
        subjectCode: sub?.code,
        category: sub?.category ?? 'MAJOR',
        componentType: 'LECTURE',
        colorHex: sub?.colorHex ?? '#4F46E5',
        classDate: e.classDate,
        startTime: e.startTime,
        endTime: e.endTime,
        room: e.room,
        teacherName: e.teacherName,
      );
    }).toList();
  }

  Future<void> addExtraClass({
    required String subjectId,
    required String classDate,
    required String startTime,
    required String endTime,
    String? room,
    String? teacherName,
    String? reason,
  }) async {
    final nowIso = DateTime.now().toIso8601String();
    final extra = ExtraClassData(
      id: 'extra_${DateTime.now().millisecondsSinceEpoch}',
      semesterId: semesterId,
      subjectComponentId: subjectId,
      classDate: classDate,
      startTime: startTime,
      endTime: endTime,
      room: room,
      teacherName: teacherName,
      reason: reason,
      createdAt: nowIso,
      updatedAt: nowIso,
    );
    await db.saveExtraClass(extra);
    await loadFromDb();
  }

  Future<void> deleteExtraClass(String id) async {
    await db.deleteExtraClass(id);
    await loadFromDb();
  }
}

// ==========================================
// 11. ATTENDANCE RECORDS PROVIDER (SQLite Persisted)
// ==========================================
final attendanceRecordsProvider = StateNotifierProvider<AttendanceRecordsNotifier, Map<String, AttendanceRecordData>>((ref) {
  final db = ref.watch(databaseProvider);
  return AttendanceRecordsNotifier(db);
});

class AttendanceRecordsNotifier extends StateNotifier<Map<String, AttendanceRecordData>> {
  final AppDatabase db;

  AttendanceRecordsNotifier(this.db) : super({});

  Future<void> loadFromDb() async {
    final records = await db.getAllAttendanceRecords();
    if (!mounted) return;
    final map = <String, AttendanceRecordData>{};
    for (final r in records) {
      map[r.classSessionId] = r;
    }
    state = map;
  }

  Future<void> markAttendance({
    required String sessionId,
    required String slotId,
    required String subjectId,
    required String sessionDate,
    required String outcome,
    String? notes,
  }) async {
    final nowIso = DateTime.now().toIso8601String();
    final record = AttendanceRecordData(
      id: sessionId,
      classSessionId: sessionId,
      slotId: slotId,
      subjectId: subjectId,
      sessionDate: sessionDate,
      outcome: outcome,
      markedAt: nowIso,
      notes: notes,
      syncVersion: 1,
      createdAt: nowIso,
      updatedAt: nowIso,
    );

    // Update in-memory map reactively
    state = {
      ...state,
      sessionId: record,
    };

    // Save to SQLite
    await db.saveAttendanceRecord(record);
  }
}

// ==========================================
// 12. RESOLVED DAILY SCHEDULE PROVIDER (Single Source of Truth)
// ==========================================
final resolvedDayScheduleProvider = Provider.family<List<ClassSessionEntity>, DateTime>((ref, targetDate) {
  final activeSem = ref.watch(activeSemesterProvider);
  if (activeSem.isUnset) {
    return const [];
  }
  final allSemesters = ref.watch(semestersListProvider);
  final holidays = ref.watch(holidaysProvider);
  final timetableSlots = ref.watch(timetableSlotsProvider);
  final attendanceMap = ref.watch(attendanceRecordsProvider);

  // Match targetDate against all semesters if present
  SemesterEntity effectiveSem = activeSem;
  if (allSemesters.isNotEmpty) {
    final matched = allSemesters.where((s) {
      if (s.isUnset) return false;
      final isAfterStart = targetDate.isAfter(s.startDate) || DateFormatter.toIsoDate(targetDate) == DateFormatter.toIsoDate(s.startDate);
      final isBeforeEnd = s.endDate == null || targetDate.isBefore(s.endDate!) || DateFormatter.toIsoDate(targetDate) == DateFormatter.toIsoDate(s.endDate!);
      return isAfterStart && isBeforeEnd;
    }).toList();
    if (matched.isNotEmpty) {
      effectiveSem = matched.first;
    }
  }

  final outcomesMap = <String, String>{};
  for (final entry in attendanceMap.entries) {
    outcomesMap[entry.key] = entry.value.outcome;
  }

  final exceptions = ref.watch(scheduleExceptionsProvider);
  final extraClasses = ref.watch(extraClassesProvider);

  return ScheduleResolutionEngine.resolveScheduleForDate(
    targetDate: targetDate,
    semesterId: effectiveSem.id,
    semesterStartDate: effectiveSem.startDate,
    semesterEndDate: effectiveSem.endDate,
    holidays: holidays,
    dayConfigs: [],
    timetableSlots: timetableSlots,
    exceptions: exceptions,
    extraClasses: extraClasses,
    existingOutcomes: outcomesMap,
  );
});

// Legacy shim for components still watching dailySessionsProvider
final dailySessionsProvider = StateNotifierProvider<DailySessionsNotifier, List<ClassSessionEntity>>((ref) {
  return DailySessionsNotifier(ref);
});

class DailySessionsNotifier extends StateNotifier<List<ClassSessionEntity>> {
  final Ref ref;

  DailySessionsNotifier(this.ref) : super([]) {
    // Sync with resolved today schedule
    final todaySessions = ref.watch(resolvedDayScheduleProvider(DateTime.now()));
    state = todaySessions;
  }

  void updateOutcome(String sessionId, String outcome) {
    // Handled by attendanceRecordsProvider
  }

  void addExtraClass(ClassSessionEntity session) {}
  void deleteSlot(String sessionId) {}
  void populateDemoData([List<SubjectEntity>? inputSubjects]) {}
  void clearAllData() {}
}

// ==========================================
// 13. OVERALL ATTENDANCE STATS CALCULATOR
// ==========================================
final overallStatsProvider = Provider<OverallAttendanceStats>((ref) {
  final subjects = ref.watch(subjectsProvider);
  final attendanceMap = ref.watch(attendanceRecordsProvider);
  final targetPct = ref.watch(targetPercentageProvider);

  int globalHeld = 0;
  int globalAttended = 0;
  int globalAbsent = 0;
  int globalCancelled = 0;
  int globalPending = 0;

  final List<SubjectAttendanceStats> subjectStatsList = [];

  for (final sub in subjects) {
    // Find all attendance records belonging to this subject
    final records = attendanceMap.values.where((r) => r.subjectId == sub.id).toList();

    final int present = records.where((r) => r.outcome == 'PRESENT').length;
    final int absent = records.where((r) => r.outcome == 'ABSENT').length;
    final int cancelled = records.where((r) => r.outcome == 'CANCELLED').length;
    final int pending = records.where((r) => r.outcome == 'PENDING').length;

    final int totalHeld = sub.baselineHeld + present + absent;
    final int totalAttended = sub.baselineAttended + present;

    final double pct = AttendanceMathService.calculatePercentage(totalAttended, totalHeld);
    final int marginToMiss = AttendanceMathService.calculateClassesCanMiss(
      attended: totalAttended,
      held: totalHeld,
      targetPct: targetPct,
    );
    final int mustAttend = AttendanceMathService.calculateClassesMustAttend(
      attended: totalAttended,
      held: totalHeld,
      targetPct: targetPct,
    );

    SubjectAttendanceStatus status;
    if (pct >= targetPct) {
      status = SubjectAttendanceStatus.safe;
    } else if (pct >= targetPct - 10.0) {
      status = SubjectAttendanceStatus.warning;
    } else {
      status = SubjectAttendanceStatus.critical;
    }

    globalHeld += totalHeld;
    globalAttended += totalAttended;
    globalAbsent += absent;
    globalCancelled += cancelled;
    globalPending += pending;

    subjectStatsList.add(
      SubjectAttendanceStats(
        subjectId: sub.id,
        subjectName: sub.name,
        subjectCode: sub.code,
        category: sub.category,
        colorHex: sub.colorHex,
        totalHeld: totalHeld,
        totalAttended: totalAttended,
        totalAbsent: absent,
        totalCancelled: cancelled,
        totalPending: pending,
        currentPercentage: pct,
        targetPercentage: targetPct,
        status: status,
        marginClassesToMiss: marginToMiss,
        requiredClassesToAttend: mustAttend,
      ),
    );
  }

  final double overallPct = AttendanceMathService.calculatePercentage(globalAttended, globalHeld);
  final int overallMarginToMiss = AttendanceMathService.calculateClassesCanMiss(
    attended: globalAttended,
    held: globalHeld,
    targetPct: targetPct,
  );
  final int overallMustAttend = AttendanceMathService.calculateClassesMustAttend(
    attended: globalAttended,
    held: globalHeld,
    targetPct: targetPct,
  );

  return OverallAttendanceStats(
    totalHeld: globalHeld,
    totalAttended: globalAttended,
    totalAbsent: globalAbsent,
    totalCancelled: globalCancelled,
    totalPending: globalPending,
    overallPercentage: overallPct,
    targetPercentage: targetPct,
    marginClassesToMiss: overallMarginToMiss,
    requiredClassesToAttend: overallMustAttend,
    subjectStats: subjectStatsList,
  );
});

// ==========================================
// ONBOARDING STATUS PROVIDER
// ==========================================
final hasCompletedOnboardingProvider = StateNotifierProvider<HasCompletedOnboardingNotifier, bool>((ref) {
  final db = ref.watch(databaseProvider);
  return HasCompletedOnboardingNotifier(db);
});

class HasCompletedOnboardingNotifier extends StateNotifier<bool> {
  final AppDatabase db;

  HasCompletedOnboardingNotifier(this.db) : super(true);

  Future<void> loadFromDb() async {
    final val = await db.getSetting('has_completed_onboarding');
    state = val == 'true';
  }

  Future<void> setCompleted(bool completed) async {
    state = completed;
    await db.setSetting('has_completed_onboarding', completed.toString());
  }
}

final activeTourProvider = StateProvider<bool>((ref) => false);

// ==========================================
// DEVELOPER SECURITY & UNLOCK STATUS PROVIDERS
// ==========================================
final isDeveloperUnlockedProvider = StateNotifierProvider<IsDeveloperUnlockedNotifier, bool>((ref) {
  final db = ref.watch(databaseProvider);
  return IsDeveloperUnlockedNotifier(db);
});

class IsDeveloperUnlockedNotifier extends StateNotifier<bool> {
  final AppDatabase db;

  IsDeveloperUnlockedNotifier(this.db) : super(false);

  Future<void> loadFromDb() async {
    final val = await db.getSetting('is_developer_unlocked');
    state = val == 'true';
  }

  Future<void> setUnlocked(bool unlocked) async {
    state = unlocked;
    await db.setSetting('is_developer_unlocked', unlocked.toString());
  }
}

final customDevPasscodeHashProvider = StateNotifierProvider<CustomDevPasscodeHashNotifier, String?>((ref) {
  final db = ref.watch(databaseProvider);
  return CustomDevPasscodeHashNotifier(db);
});

class CustomDevPasscodeHashNotifier extends StateNotifier<String?> {
  final AppDatabase db;

  CustomDevPasscodeHashNotifier(this.db) : super(null);

  Future<void> loadFromDb() async {
    final val = await db.getSetting('custom_dev_passcode_hash');
    state = (val != null && val.isNotEmpty) ? val : null;
  }

  Future<void> setHash(String? hash) async {
    state = hash;
    await db.setSetting('custom_dev_passcode_hash', hash ?? '');
  }
}



