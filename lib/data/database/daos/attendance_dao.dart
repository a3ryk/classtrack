import '../app_database.dart';

class AttendanceRepository {
  final AppDatabase db;
  AttendanceRepository(this.db);

  Future<void> markAttendance({
    required String id,
    required String classSessionId,
    required String outcome,
    String? notes,
  }) async {
    final nowIso = DateTime.now().toIso8601String();
    await db.saveAttendanceRecord(
      AttendanceRecordData(
        id: id,
        classSessionId: classSessionId,
        outcome: outcome,
        markedAt: nowIso,
        notes: notes,
        syncVersion: 1,
        createdAt: nowIso,
        updatedAt: nowIso,
      ),
    );
  }

  Stream<List<AttendanceRecordData>> watchAttendance() {
    return db.watchAttendanceRecords();
  }
}
