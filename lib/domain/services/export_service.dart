import 'dart:convert';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../entities/academic_template.dart';
import '../entities/attendance_stats.dart';
import '../entities/class_session_entity.dart';
import '../entities/semester_entity.dart';
import '../entities/user_profile_entity.dart';
import '../../core/services/notification_service.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/database/app_database.dart';
import '../../domain/services/schedule_engine.dart';
import '../../presentation/providers/app_state_provider.dart';

typedef ProgressCallback = void Function(double progress, String statusMessage);

class ExportService {
  ExportService._();

  /// Gathers all class sessions and marked attendance records across a full date range
  static Future<List<ClassSessionEntity>> collectDateRangeSessions({
    required AppDatabase db,
    required SemesterEntity semester,
    required DateTime startDate,
    required DateTime endDate,
    ProgressCallback? onProgress,
  }) async {
    final holidays = (await db.getHolidays(semester.id))
        .map((h) => HolidayItem(title: h.title, startDate: h.startDate, endDate: h.endDate))
        .toList();

    final dayConfigs = (await db.getAcademicDayConfigs(semester.id))
        .map((c) => AcademicDayConfigItem(dayOfWeek: c.dayOfWeek, isWeeklyOff: c.isWeeklyOff))
        .toList();

    final dbSlots = await db.getTimetableSlots(semester.id);
    final allSubjects = await db.getAllSubjects(semester.id);
    final subjectMap = {for (final s in allSubjects) s.id: s};

    final slots = dbSlots.map((slotData) {
      final sub = subjectMap[slotData.subjectComponentId];
      final rawNotes = (slotData.notes ?? '').toUpperCase();
      String compType = 'LECTURE';
      if (rawNotes.contains('PRACTICAL') || rawNotes.contains('LAB')) {
        compType = 'PRACTICAL';
      } else if (rawNotes.contains('TUTORIAL')) {
        compType = 'TUTORIAL';
      } else if (rawNotes.contains('SEMINAR')) {
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

    final exceptions = (await db.getScheduleExceptions()).map((e) => ScheduleExceptionItem(
      timetableSlotId: e.timetableSlotId,
      exceptionDate: e.exceptionDate,
      actionType: e.actionType,
      newStartTime: e.newStartTime,
      newEndTime: e.newEndTime,
      substituteComponentId: e.substituteComponentId,
      newRoom: e.newRoom,
    )).toList();

    final extraClasses = (await db.getExtraClasses(semester.id)).map((e) {
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

    final allRecords = await db.getAllAttendanceRecords();
    final outcomesMap = <String, String>{};
    for (final r in allRecords) {
      outcomesMap[r.classSessionId] = r.outcome;
    }

    final totalDays = endDate.difference(startDate).inDays + 1;
    final List<ClassSessionEntity> allSessions = [];

    for (int i = 0; i < totalDays; i++) {
      final currentDate = startDate.add(Duration(days: i));
      final daySessions = ScheduleResolutionEngine.resolveScheduleForDate(
        targetDate: currentDate,
        semesterId: semester.id,
        semesterStartDate: semester.startDate,
        semesterEndDate: semester.endDate,
        holidays: holidays,
        dayConfigs: dayConfigs,
        timetableSlots: slots,
        exceptions: exceptions,
        extraClasses: extraClasses,
        existingOutcomes: outcomesMap,
      );

      allSessions.addAll(daySessions);

      final progress = (i + 1) / totalDays;
      if (i % 15 == 0 || i == totalDays - 1) {
        onProgress?.call(progress * 0.7, 'Processing ${DateFormatter.formatDateIndian(currentDate)} ($i/$totalDays days)...');
        await NotificationService.instance.showExportProgressNotification(
          progressPercent: (progress * 70).toInt(),
          message: 'Gathering records for $totalDays days...',
        );
      }
    }

    return allSessions;
  }

  /// Generates a professional multi-sheet Excel (.xlsx) workbook with full date-wise register
  static Future<String> generateExcelReport({
    required OverallAttendanceStats overallStats,
    required SemesterEntity semester,
    required UserProfileEntity profile,
    required UserUniversityInfo university,
    required ProgrammeTemplate courseStructure,
    required List<ClassSessionEntity> sessions,
    ProgressCallback? onProgress,
  }) async {
    onProgress?.call(0.75, 'Generating Excel workbook...');
    final excel = Excel.createExcel();

    // Sheet 1: Executive Summary & Profile Header
    final Sheet summarySheet = excel['Summary'];
    excel.setDefaultSheet('Summary');

    summarySheet.appendRow([TextCellValue('CLASSTRACK ATTENDANCE REPORT')]);
    summarySheet.appendRow([TextCellValue('Student Name:'), TextCellValue(profile.studentName.isNotEmpty ? profile.studentName : 'Not Set')]);
    summarySheet.appendRow([TextCellValue('Roll Number:'), TextCellValue(profile.rollNumber.isNotEmpty ? profile.rollNumber : 'Not Set')]);
    summarySheet.appendRow([TextCellValue('Enrollment Reg No:'), TextCellValue(profile.enrollmentNumber.isNotEmpty ? profile.enrollmentNumber : 'Not Set')]);
    summarySheet.appendRow([TextCellValue('Degree / Programme:'), TextCellValue(profile.degreeProgramme.isNotEmpty ? profile.degreeProgramme : 'Not Set')]);
    summarySheet.appendRow([TextCellValue('Department / School:'), TextCellValue(profile.department.isNotEmpty ? profile.department : 'Not Set')]);
    summarySheet.appendRow([TextCellValue('Course Structure:'), TextCellValue(courseStructure.name)]);
    summarySheet.appendRow([TextCellValue('University:'), TextCellValue(university.universityName)]);
    if (university.locationType == 'AFFILIATED_COLLEGE' && university.collegeName != null) {
      summarySheet.appendRow([TextCellValue('College:'), TextCellValue(university.collegeName!)]);
    }
    summarySheet.appendRow([TextCellValue('State:'), TextCellValue(university.state)]);
    summarySheet.appendRow([TextCellValue('Semester / Term:'), TextCellValue('${semester.name} (${semester.termType.displayName})')]);
    summarySheet.appendRow([TextCellValue('Generated At:'), TextCellValue(DateFormatter.formatDateIndian(DateTime.now()))]);
    summarySheet.appendRow([]);
    summarySheet.appendRow([TextCellValue('OVERALL METRICS')]);
    summarySheet.appendRow([TextCellValue('Total Classes Held'), IntCellValue(overallStats.totalHeld)]);
    summarySheet.appendRow([TextCellValue('Total Classes Attended'), IntCellValue(overallStats.totalAttended)]);
    summarySheet.appendRow([TextCellValue('Total Classes Absent'), IntCellValue(overallStats.totalAbsent)]);
    summarySheet.appendRow([TextCellValue('Overall Attendance %'), DoubleCellValue(overallStats.overallPercentage)]);
    summarySheet.appendRow([TextCellValue('Target Requirement %'), DoubleCellValue(overallStats.targetPercentage)]);

    // Sheet 2: Subject Breakdown
    final Sheet subjectSheet = excel['Subjects'];
    subjectSheet.appendRow([
      TextCellValue('Category'),
      TextCellValue('Code'),
      TextCellValue('Subject Name'),
      TextCellValue('Held'),
      TextCellValue('Attended'),
      TextCellValue('Absent'),
      TextCellValue('Attendance %'),
      TextCellValue('Target %'),
      TextCellValue('Status Margin'),
    ]);

    for (final s in overallStats.subjectStats) {
      subjectSheet.appendRow([
        TextCellValue(s.category),
        TextCellValue(s.subjectCode ?? '-'),
        TextCellValue(s.subjectName),
        IntCellValue(s.totalHeld),
        IntCellValue(s.totalAttended),
        IntCellValue(s.totalAbsent),
        DoubleCellValue(s.currentPercentage),
        DoubleCellValue(s.targetPercentage),
        TextCellValue(s.status == SubjectAttendanceStatus.safe
            ? 'Safe (+${s.marginClassesToMiss} to miss)'
            : 'Critical (Must attend next ${s.requiredClassesToAttend})'),
      ]);
    }

    // Sheet 3: Date-Wise Attendance Register
    final Sheet registerSheet = excel['Daily Attendance Register'];
    registerSheet.appendRow([
      TextCellValue('Date (DD/MM/YYYY)'),
      TextCellValue('Time Slot'),
      TextCellValue('Category'),
      TextCellValue('Subject Code'),
      TextCellValue('Subject Name'),
      TextCellValue('Type'),
      TextCellValue('Room'),
      TextCellValue('Attendance Status'),
    ]);

    final sortedSessions = List<ClassSessionEntity>.from(sessions)
      ..sort((a, b) => a.sessionDate.compareTo(b.sessionDate));

    for (final session in sortedSessions) {
      registerSheet.appendRow([
        TextCellValue(DateFormatter.formatIsoToIndian(session.sessionDate)),
        TextCellValue('${session.startTime} - ${session.endTime}'),
        TextCellValue(session.category),
        TextCellValue(session.subjectCode ?? '-'),
        TextCellValue(session.subjectName),
        TextCellValue(session.componentType),
        TextCellValue(session.room ?? '-'),
        TextCellValue(session.attendanceOutcome),
      ]);
    }

    onProgress?.call(0.9, 'Saving Excel spreadsheet...');
    final bytes = excel.save();
    if (bytes == null) throw Exception('Failed to encode Excel file.');

    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/classtrack_${semester.name.replaceAll(" ", "_")}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    onProgress?.call(1.0, 'Export complete!');
    await NotificationService.instance.showExportCompleteNotification(
      filePath: filePath,
      title: '✅ Attendance Export Ready',
      body: 'Generated ${sortedSessions.length} date-wise records in Excel format.',
    );

    return filePath;
  }

  /// Generates an official printable PDF report with zero text overflow and full multi-page register
  static Future<String> generatePdfReport({
    required OverallAttendanceStats overallStats,
    required SemesterEntity semester,
    required UserProfileEntity profile,
    required UserUniversityInfo university,
    required ProgrammeTemplate courseStructure,
    required List<ClassSessionEntity> sessions,
    ProgressCallback? onProgress,
  }) async {
    onProgress?.call(0.75, 'Formatting PDF pages & tables...');
    final pdf = pw.Document();

    final sortedSessions = List<ClassSessionEntity>.from(sessions)
      ..sort((a, b) => a.sessionDate.compareTo(b.sessionDate));

    // Page 1: Executive Summary & Subject Breakdown
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('CLASSTRACK ATTENDANCE REPORT', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 2),
                      pw.Text('${semester.name} (${semester.academicYear})', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: pw.BoxDecoration(
                      color: (overallStats.overallPercentage >= overallStats.targetPercentage) ? PdfColors.green50 : PdfColors.red50,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                      border: pw.Border.all(
                        color: (overallStats.overallPercentage >= overallStats.targetPercentage) ? PdfColors.green300 : PdfColors.red300,
                        width: 0.8,
                      ),
                    ),
                    child: pw.Text(
                      '${overallStats.overallPercentage}% Overall',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: (overallStats.overallPercentage >= overallStats.targetPercentage) ? PdfColors.green900 : PdfColors.red900,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),

              // Student Info Card
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300, width: 0.6),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  color: PdfColors.grey50,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Student: ${profile.studentName.isNotEmpty ? profile.studentName : "Not Configured"}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                        pw.Text('Roll: ${profile.rollNumber.isNotEmpty ? profile.rollNumber : "N/A"} | Reg: ${profile.enrollmentNumber.isNotEmpty ? profile.enrollmentNumber : "N/A"}', style: const pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('Institution: ${university.universityName} (${university.state})', style: const pw.TextStyle(fontSize: 9)),
                    if (university.locationType == 'AFFILIATED_COLLEGE' && university.collegeName != null) ...[
                      pw.SizedBox(height: 2),
                      pw.Text('College: ${university.collegeName}', style: const pw.TextStyle(fontSize: 9)),
                    ],
                    pw.SizedBox(height: 2),
                    pw.Text('Structure: ${courseStructure.name}${profile.degreeProgramme.isNotEmpty ? " • ${profile.degreeProgramme}" : ""}', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              // Overview Numbers
              pw.Row(
                children: [
                  _pdfMetricBox('Classes Held', '${overallStats.totalHeld}'),
                  pw.SizedBox(width: 8),
                  _pdfMetricBox('Attended', '${overallStats.totalAttended}', color: PdfColors.green700),
                  pw.SizedBox(width: 8),
                  _pdfMetricBox('Absent', '${overallStats.totalAbsent}', color: PdfColors.red700),
                  pw.SizedBox(width: 8),
                  _pdfMetricBox('Target', '${overallStats.targetPercentage}%'),
                ],
              ),
              pw.SizedBox(height: 16),

              pw.Text('SUBJECT BREAKDOWN SUMMARY', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),

              pw.TableHelper.fromTextArray(
                headers: ['Category', 'Subject', 'Held', 'Attended', '%', 'Margin Status'],
                columnWidths: {
                  0: const pw.FixedColumnWidth(55),
                  1: const pw.FlexColumnWidth(2.5),
                  2: const pw.FixedColumnWidth(40),
                  3: const pw.FixedColumnWidth(45),
                  4: const pw.FixedColumnWidth(45),
                  5: const pw.FlexColumnWidth(2),
                },
                headerStyle: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                cellStyle: const pw.TextStyle(fontSize: 8),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                data: overallStats.subjectStats.map((s) {
                  return [
                    s.category,
                    s.subjectName,
                    '${s.totalHeld}',
                    '${s.totalAttended}',
                    '${s.currentPercentage}%',
                    s.status == SubjectAttendanceStatus.safe ? 'Safe (+${s.marginClassesToMiss})' : 'Must attend ${s.requiredClassesToAttend}',
                  ];
                }).toList(),
              ),

              pw.Spacer(),
              pw.Divider(color: PdfColors.grey300, thickness: 0.5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Generated by ClassTrack App', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  pw.Text('Page 1 of Register', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  pw.Text(DateFormatter.formatDateIndian(DateTime.now()), style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Page 2+: Multi-page Date-Wise Attendance Register
    if (sortedSessions.isNotEmpty) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          header: (pw.Context context) {
            return pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 8),
              margin: const pw.EdgeInsets.only(bottom: 8),
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('DATE-WISE ATTENDANCE REGISTER', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text('${profile.studentName} (Roll: ${profile.rollNumber})', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                ],
              ),
            );
          },
          footer: (pw.Context context) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(top: 8),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('ClassTrack Attendance Register', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                ],
              ),
            );
          },
          build: (pw.Context context) {
            return [
              pw.TableHelper.fromTextArray(
                headers: ['Date (DD/MM/YYYY)', 'Time', 'Subject', 'Type', 'Room', 'Status'],
                columnWidths: {
                  0: const pw.FixedColumnWidth(75),
                  1: const pw.FixedColumnWidth(65),
                  2: const pw.FlexColumnWidth(2.5),
                  3: const pw.FixedColumnWidth(55),
                  4: const pw.FixedColumnWidth(45),
                  5: const pw.FixedColumnWidth(60),
                },
                headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                cellStyle: const pw.TextStyle(fontSize: 7.5),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3.5),
                data: sortedSessions.map((s) {
                  return [
                    DateFormatter.formatIsoToIndian(s.sessionDate),
                    '${s.startTime}-${s.endTime}',
                    s.subjectName,
                    s.componentType,
                    s.room ?? '-',
                    s.attendanceOutcome,
                  ];
                }).toList(),
              ),
            ];
          },
        ),
      );
    }

    onProgress?.call(0.9, 'Saving PDF document...');
    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/classtrack_report_${semester.name.replaceAll(" ", "_")}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    onProgress?.call(1.0, 'Export complete!');
    await NotificationService.instance.showExportCompleteNotification(
      filePath: filePath,
      title: '✅ PDF Report Ready',
      body: 'Generated printable PDF with ${sortedSessions.length} date-wise records.',
    );

    return filePath;
  }

  static pw.Widget _pdfMetricBox(String label, String value, {PdfColor? color}) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
            pw.SizedBox(height: 2),
            pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: color ?? PdfColors.black)),
          ],
        ),
      ),
    );
  }

  /// Exports full relational DB snapshot as JSON string
  static Future<String> exportJsonBackup({
    required UserProfileEntity profile,
    required UserUniversityInfo university,
    required SemesterEntity semester,
    required ProgrammeTemplate courseStructure,
    required List<dynamic> subjects,
    required List<ClassSessionEntity> sessions,
    ProgressCallback? onProgress,
  }) async {
    onProgress?.call(0.5, 'Serializing backup payload...');
    final payload = {
      'schemaVersion': 1,
      'appVersion': '1.0.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'profile': profile.toJson(),
      'courseStructure': {
        'id': courseStructure.id,
        'name': courseStructure.name,
        'totalSemesters': courseStructure.totalSemesters,
      },
      'university': {
        'state': university.state,
        'universityName': university.universityName,
        'locationType': university.locationType,
        'collegeName': university.collegeName,
      },
      'activeSemester': {
        'id': semester.id,
        'name': semester.name,
        'academicYear': semester.academicYear,
        'startDate': DateFormatter.toIsoDate(semester.startDate),
        'endDate': semester.endDate != null ? DateFormatter.toIsoDate(semester.endDate!) : null,
        'termType': semester.termType.name,
      },
      'subjectsCount': subjects.length,
      'sessionsCount': sessions.length,
      'dateWiseRegister': sessions.map((s) => {
        'date': s.sessionDate,
        'time': '${s.startTime}-${s.endTime}',
        'subject': s.subjectName,
        'category': s.category,
        'status': s.attendanceOutcome,
      }).toList(),
    };

    onProgress?.call(0.8, 'Writing JSON file...');
    final jsonStr = const JsonEncoder.withIndent('  ').convert(payload);
    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/classtrack_backup_${DateTime.now().millisecondsSinceEpoch}.json';
    final file = File(filePath);
    await file.writeAsString(jsonStr);

    onProgress?.call(1.0, 'JSON export ready!');
    await NotificationService.instance.showExportCompleteNotification(
      filePath: filePath,
      title: '✅ JSON Backup Ready',
      body: 'ClassTrack JSON backup file is ready to share.',
    );

    return filePath;
  }

  /// Shares a file via native share dialog
  static Future<void> shareFile(String filePath, String mimeType) async {
    await SharePlus.instance.share(ShareParams(files: [XFile(filePath)]));
  }
}
