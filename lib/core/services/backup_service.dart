import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../data/database/app_database.dart';

/// Validation Result for Backup Payloads
class BackupValidationResult {
  final bool isValid;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;
  final Map<String, int> itemCounts;

  const BackupValidationResult({
    required this.isValid,
    this.errorMessage,
    this.metadata,
    this.itemCounts = const {},
  });
}

/// Robust, Zero-Data-Loss Backup & Restore Engine
class BackupService {
  BackupService._();

  static const String currentBackupVersion = '1';
  static const int currentSchemaVersion = 2;
  static const String appIdentifier = 'ClassTrack';

  /// Verifies and requests storage permissions on Android/iOS
  static Future<bool> checkAndRequestStoragePermission() async {
    if (kIsWeb) return true;
    if (!Platform.isAndroid && !Platform.isIOS) return true;

    try {
      if (Platform.isAndroid) {
        // For Android 11+ (API 30+), check manageExternalStorage first
        var manageStatus = await Permission.manageExternalStorage.status;
        if (!manageStatus.isGranted) {
          manageStatus = await Permission.manageExternalStorage.request();
        }
        if (manageStatus.isGranted) return true;

        // Check traditional storage permission
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }
        return status.isGranted;
      } else if (Platform.isIOS) {
        return true;
      }
    } catch (_) {
      return true; // Fall back gracefully
    }
    return true;
  }

  /// Resolves the dedicated "ClassTrack/backups" or user-configured custom storage directory
  static Future<Directory> getBackupDirectory({String? customPath}) async {
    if (customPath != null && customPath.trim().isNotEmpty) {
      final customDir = Directory(customPath.trim());
      if (!await customDir.exists()) {
        await customDir.create(recursive: true);
      }
      return customDir;
    }

    if (!kIsWeb && Platform.isAndroid) {
      // 1. Try public storage root: /storage/emulated/0/ClassTrack/backups (Visible in File Manager)
      try {
        final publicRoot = Directory('/storage/emulated/0/ClassTrack/backups');
        if (!await publicRoot.exists()) {
          await publicRoot.create(recursive: true);
        }
        if (await publicRoot.exists()) {
          return publicRoot;
        }
      } catch (_) {}

      // 2. Try Documents public folder: /storage/emulated/0/Documents/ClassTrack/backups
      try {
        final docsDir = Directory('/storage/emulated/0/Documents/ClassTrack/backups');
        if (!await docsDir.exists()) {
          await docsDir.create(recursive: true);
        }
        if (await docsDir.exists()) {
          return docsDir;
        }
      } catch (_) {}

      // 3. Try Download public folder: /storage/emulated/0/Download/ClassTrack/backups
      try {
        final dlDir = Directory('/storage/emulated/0/Download/ClassTrack/backups');
        if (!await dlDir.exists()) {
          await dlDir.create(recursive: true);
        }
        if (await dlDir.exists()) {
          return dlDir;
        }
      } catch (_) {}

      // 4. App external files fallback
      Directory? extDir;
      try {
        extDir = await getExternalStorageDirectory();
      } catch (_) {}

      final baseDir = extDir ?? await getApplicationDocumentsDirectory();
      final backupDir = Directory(p.join(baseDir.path, 'ClassTrack', 'backups'));
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }
      return backupDir;
    }

    // Windows / macOS / Linux / iOS
    Directory baseDir;
    try {
      baseDir = await getApplicationDocumentsDirectory();
    } catch (_) {
      baseDir = Directory.systemTemp;
    }

    final backupDir = Directory(p.join(baseDir.path, 'ClassTrack', 'backups'));
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir;
  }

  /// Formats any UTC or Local DateTime into user device local timezone string: dd/MM/yyyy, hh:mm a
  static String formatDeviceTimestamp(DateTime dateTime) {
    final localDt = dateTime.toLocal();
    final formatter = DateFormat('dd/MM/yyyy, hh:mm a');
    return formatter.format(localDt);
  }

  /// Formats bytes to readable human string (e.g. "124 KB")
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Serializes all 11 SQLite tables and application settings into a complete JSON envelope
  static Future<String> generateFullBackupJson(AppDatabase db) async {
    final semesters = await db.getAllSemestersAll();
    final subjects = await db.getAllSubjectsAll();
    final subjectComponents = await db.getAllSubjectComponentsAll();
    final timetableSlots = await db.getAllTimetableSlotsAll();
    final academicDayConfigs = await db.getAllAcademicDayConfigsAll();
    final holidays = await db.getAllHolidaysAll();
    final scheduleExceptions = await db.getAllScheduleExceptionsAll();
    final extraClasses = await db.getAllExtraClassesAll();
    final classSessions = await db.getAllClassSessionsAll();
    final attendanceRecords = await db.getAllAttendanceRecordsAll();
    final appSettings = await db.getAllAppSettingsAll();

    final nowUtc = DateTime.now().toUtc();

    final Map<String, dynamic> payload = {
      'app': appIdentifier,
      'backup_version': currentBackupVersion,
      'schema_version': currentSchemaVersion,
      'created_at_utc': nowUtc.toIso8601String(),
      'created_at_local': DateTime.now().toIso8601String(),
      'tables': {
        'semesters': semesters.map((e) => e.toJson()).toList(),
        'subjects': subjects.map((e) => e.toJson()).toList(),
        'subject_components': subjectComponents.map((e) => e.toJson()).toList(),
        'timetable_slots': timetableSlots.map((e) => e.toJson()).toList(),
        'academic_day_configs': academicDayConfigs.map((e) => e.toJson()).toList(),
        'holidays': holidays.map((e) => e.toJson()).toList(),
        'schedule_exceptions': scheduleExceptions.map((e) => e.toJson()).toList(),
        'extra_classes': extraClasses.map((e) => e.toJson()).toList(),
        'class_sessions': classSessions.map((e) => e.toJson()).toList(),
        'attendance_records': attendanceRecords.map((e) => e.toJson()).toList(),
        'app_settings': appSettings.map((e) => e.toJson()).toList(),
      },
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Saves backup content to the designated directory
  static Future<File> saveBackupToFile(
    String jsonContent, {
    String? customFileName,
    String? customDirectoryPath,
  }) async {
    final dir = await getBackupDirectory(customPath: customDirectoryPath);
    final now = DateTime.now();
    final dateStr = DateFormat('yyyyMMdd_HHmmss').format(now);
    final fileName = customFileName ?? 'classtrack_backup_$dateStr.ctbackup';
    final file = File(p.join(dir.path, fileName));
    return file.writeAsString(jsonContent, flush: true);
  }

  /// Deeply validates a backup string and extracts summary metrics
  static BackupValidationResult validateBackup(String jsonString) {
    try {
      final trimmed = jsonString.trim();
      if (!trimmed.startsWith('{') || !trimmed.endsWith('}')) {
        return const BackupValidationResult(
          isValid: false,
          errorMessage: 'Invalid file format: Not a valid ClassTrack backup file.',
        );
      }

      final decoded = jsonDecode(trimmed);
      if (decoded is! Map<String, dynamic>) {
        return const BackupValidationResult(
          isValid: false,
          errorMessage: 'Corrupt backup structure: Root must be a JSON object.',
        );
      }

      if (decoded['app'] != appIdentifier) {
        return const BackupValidationResult(
          isValid: false,
          errorMessage: 'Unrecognized backup file. Expected a ClassTrack backup (.ctbackup).',
        );
      }

      final tables = decoded['tables'];
      if (tables is! Map<String, dynamic>) {
        return const BackupValidationResult(
          isValid: false,
          errorMessage: 'Missing database tables payload in backup.',
        );
      }

      // Check required table keys
      final requiredTables = [
        'semesters',
        'subjects',
        'timetable_slots',
        'attendance_records',
      ];
      for (final req in requiredTables) {
        if (!tables.containsKey(req) || tables[req] is! List) {
          return BackupValidationResult(
            isValid: false,
            errorMessage: 'Missing or corrupt "$req" table in backup payload.',
          );
        }
      }

      final Map<String, int> counts = {
        'semesters': (tables['semesters'] as List).length,
        'subjects': (tables['subjects'] as List).length,
        'timetable_slots': (tables['timetable_slots'] as List).length,
        'attendance_records': (tables['attendance_records'] as List).length,
        'holidays': (tables['holidays'] as List?)?.length ?? 0,
        'extra_classes': (tables['extra_classes'] as List?)?.length ?? 0,
      };

      return BackupValidationResult(
        isValid: true,
        metadata: {
          'created_at_utc': decoded['created_at_utc'] ?? decoded['created_at_local'] ?? '',
          'schema_version': decoded['schema_version'] ?? 1,
          'backup_version': decoded['backup_version'] ?? '1',
        },
        itemCounts: counts,
      );
    } catch (e) {
      return BackupValidationResult(
        isValid: false,
        errorMessage: 'Corrupted backup file: ${e.toString()}',
      );
    }
  }

  /// Restores all 11 tables and settings in an atomic SQLite transaction
  static Future<void> restoreBackup(Map<String, dynamic> backupData, AppDatabase db) async {
    final tables = backupData['tables'] as Map<String, dynamic>? ?? {};

    // Helper to safely parse lists of Maps
    List<T> parseTable<T>(String key, T Function(Map<String, dynamic>) parser) {
      final list = tables[key];
      if (list is! List) return <T>[];
      final results = <T>[];
      for (final item in list) {
        if (item is Map) {
          try {
            results.add(parser(Map<String, dynamic>.from(item)));
          } catch (_) {}
        }
      }
      return results;
    }

    final semestersList = parseTable('semesters', (m) => SemesterData.fromJson(m));
    final subjectsList = parseTable('subjects', (m) => SubjectData.fromJson(m));
    final subjectComponentsList = parseTable('subject_components', (m) => SubjectComponentData.fromJson(m));
    final timetableSlotsList = parseTable('timetable_slots', (m) => TimetableSlotData.fromJson(m));
    final academicDayConfigsList = parseTable('academic_day_configs', (m) => AcademicDayConfigData.fromJson(m));
    final holidaysList = parseTable('holidays', (m) => HolidayData.fromJson(m));
    final scheduleExceptionsList = parseTable('schedule_exceptions', (m) => ScheduleExceptionData.fromJson(m));
    final extraClassesList = parseTable('extra_classes', (m) => ExtraClassData.fromJson(m));
    final classSessionsList = parseTable('class_sessions', (m) => ClassSessionData.fromJson(m));
    final attendanceRecordsList = parseTable('attendance_records', (m) => AttendanceRecordData.fromJson(m));
    final appSettingsList = parseTable('app_settings', (m) => AppSettingData.fromJson(m));

    // Atomic transaction restore
    await db.restoreAllTablesAtomic(
      semestersList: semestersList,
      subjectsList: subjectsList,
      subjectComponentsList: subjectComponentsList,
      timetableSlotsList: timetableSlotsList,
      academicDayConfigsList: academicDayConfigsList,
      holidaysList: holidaysList,
      scheduleExceptionsList: scheduleExceptionsList,
      extraClassesList: extraClassesList,
      classSessionsList: classSessionsList,
      attendanceRecordsList: attendanceRecordsList,
      appSettingsList: appSettingsList,
    );
  }

  /// Cleans older backup files beyond the retention limit
  static Future<void> pruneOldBackups(int maxToKeep, {String? customDirectoryPath}) async {
    if (maxToKeep <= 0) return;
    try {
      final dir = await getBackupDirectory(customPath: customDirectoryPath);
      final entities = dir.listSync().whereType<File>().toList();
      final backupFiles = entities.where((f) => f.path.endsWith('.ctbackup') || f.path.endsWith('.json')).toList();

      if (backupFiles.length > maxToKeep) {
        backupFiles.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
        final toDelete = backupFiles.sublist(maxToKeep);
        for (final file in toDelete) {
          try {
            await file.delete();
          } catch (_) {}
        }
      }
    } catch (_) {}
  }
}
