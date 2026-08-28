import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/app_update_service.dart';
import '../../../core/services/developer_auth_service.dart';
import '../../../core/ui/app_toast.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/uuid_generator.dart';
import '../../../data/database/app_database.dart';
import '../../providers/app_state_provider.dart';
import '../onboarding/welcome_onboarding_screen.dart';
import 'update_screen.dart';

class DeveloperToolsScreen extends ConsumerStatefulWidget {
  const DeveloperToolsScreen({super.key});

  @override
  ConsumerState<DeveloperToolsScreen> createState() => _DeveloperToolsScreenState();
}

class _DeveloperToolsScreenState extends ConsumerState<DeveloperToolsScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final groupBg = isDark ? AppColors.cardDark : Colors.white;
    final groupBorder = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);
    final dividerColor = isDark ? AppColors.borderDark : const Color(0xFFF1F5F9);

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF8FAFC),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Text(
          'Developer Tools',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            letterSpacing: -0.4,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                // 1. ONBOARDING & TOUR
                _buildSectionHeader('Onboarding & User Walkthrough', isDark),
                Container(
                  decoration: BoxDecoration(
                    color: groupBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: groupBorder, width: 0.8),
                  ),
                  child: Column(
                    children: [
                      _buildTile(
                        title: 'Launch Welcome Onboarding Screen',
                        subtitle: 'Opens the full-screen first-time welcome page',
                        isDark: isDark,
                        icon: Icons.waving_hand_rounded,
                        iconColor: AppColors.accentIndigoLight,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (screenCtx) => const WelcomeOnboardingScreen(),
                            ),
                          );
                        },
                      ),
                      Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                      _buildTile(
                        title: 'Start Interactive App Tour',
                        subtitle: 'Triggers the 5-step guided spotlight tour',
                        isDark: isDark,
                        icon: Icons.explore_rounded,
                        iconColor: AppColors.presentGreen,
                        onTap: () {
                          Navigator.of(context).pop();
                          ref.read(activeTourProvider.notifier).state = true;
                        },
                      ),
                      Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                      _buildTile(
                        title: 'Reset Onboarding Status',
                        subtitle: 'Sets has_completed_onboarding = false in SQLite',
                        isDark: isDark,
                        icon: Icons.restart_alt_rounded,
                        iconColor: Colors.amber,
                        onTap: () async {
                          await ref.read(hasCompletedOnboardingProvider.notifier).setCompleted(false);
                          if (context.mounted) {
                            AppToast.success(context, 'Onboarding state reset! Restart app to see welcome flow.');
                          }
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 2. ATTENDANCE SCENARIO GENERATORS
                _buildSectionHeader('Attendance Scenario Generators', isDark),
                Container(
                  decoration: BoxDecoration(
                    color: groupBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: groupBorder, width: 0.8),
                  ),
                  child: Column(
                    children: [
                      _buildTile(
                        title: 'Populate Standard Timetable Data',
                        subtitle: 'Seeds sample subjects and recurring weekly slots',
                        isDark: isDark,
                        icon: Icons.playlist_add_rounded,
                        iconColor: AppColors.accentBlue,
                        onTap: () async {
                          setState(() => _isLoading = true);
                          final activeSem = ref.read(activeSemesterProvider);
                          final semId = activeSem.id;
                          final db = ref.read(databaseProvider);
                          await db.populateDemoData(semId);
                          await ref.read(subjectsProvider.notifier).loadFromDb();
                          await ref.read(timetableSlotsProvider.notifier).loadFromDb();
                          await ref.read(attendanceRecordsProvider.notifier).loadFromDb();
                          setState(() => _isLoading = false);
                          if (context.mounted) {
                            AppToast.success(context, 'Sample timetable populated in SQLite!');
                          }
                        },
                      ),
                      Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                      _buildTile(
                        title: 'Simulate "At-Risk" Attendance (~64%)',
                        subtitle: 'Seeds past sessions with low attendance to test warning badges',
                        isDark: isDark,
                        icon: Icons.warning_amber_rounded,
                        iconColor: AppColors.absentRed,
                        onTap: () async => _seedAttendanceScenario(attended: 7, total: 11),
                      ),
                      Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                      _buildTile(
                        title: 'Simulate "Safe" Attendance (~90%)',
                        subtitle: 'Seeds past sessions with high attendance to test spare margins',
                        isDark: isDark,
                        icon: Icons.verified_rounded,
                        iconColor: AppColors.presentGreen,
                        onTap: () async => _seedAttendanceScenario(attended: 18, total: 20),
                      ),
                      Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                      _buildTile(
                        title: 'Clear All Schedule & Logs',
                        subtitle: 'Purges all slots, sessions, and attendance records',
                        isDark: isDark,
                        titleColor: AppColors.absentRed,
                        icon: Icons.delete_sweep_outlined,
                        iconColor: AppColors.absentRed,
                        onTap: () => _confirmClearAllData(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 3. SCHEDULE ENGINE EDGE-CASE STRESS
                _buildSectionHeader('Schedule Engine Edge-Case Stress Tools', isDark),
                Container(
                  decoration: BoxDecoration(
                    color: groupBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: groupBorder, width: 0.8),
                  ),
                  child: Column(
                    children: [
                      _buildTile(
                        title: 'Seed 5-Day College Holiday Break',
                        subtitle: 'Tests Level 1 schedule suppression during holidays',
                        isDark: isDark,
                        icon: Icons.beach_access_rounded,
                        iconColor: Colors.orange,
                        onTap: () async {
                          final db = ref.read(databaseProvider);
                          final activeSem = ref.read(activeSemesterProvider);
                          final semId = activeSem.id;
                          final now = DateTime.now();
                          final start = DateFormatter.toIsoDate(now);
                          final end = DateFormatter.toIsoDate(now.add(const Duration(days: 4)));
                          final nowIso = now.toIso8601String();

                          await db.saveHoliday(HolidayData(
                            id: UuidGenerator.generate(),
                            semesterId: semId,
                            title: 'Mid-Term Festival Break',
                            startDate: start,
                            endDate: end,
                            category: 'SEMESTER_BREAK',
                            createdAt: nowIso,
                            updatedAt: nowIso,
                            deletedAt: null,
                          ));
                          await ref.read(holidaysProvider.notifier).loadFromDb();
                          if (context.mounted) {
                            AppToast.success(context, '5-Day holiday break seeded ($start to $end)!');
                          }
                        },
                      ),
                      Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                      _buildTile(
                        title: 'Seed Sunday Class Slot (Day 7)',
                        subtitle: 'Verifies Sunday-first timetable resolution',
                        isDark: isDark,
                        icon: Icons.weekend_rounded,
                        iconColor: AppColors.accentIndigoLight,
                        onTap: () async {
                          final subjects = ref.read(subjectsProvider);
                          if (subjects.isEmpty) {
                            AppToast.error(context, 'Please populate sample timetable first!');
                            return;
                          }
                          final sub = subjects.first;
                          final activeSem = ref.read(activeSemesterProvider);
                          final semId = activeSem.id;
                          final db = ref.read(databaseProvider);
                          final nowIso = DateTime.now().toIso8601String();

                          await db.saveTimetableSlot(TimetableSlotData(
                            id: UuidGenerator.generate(),
                            semesterId: semId,
                            subjectComponentId: sub.components.isNotEmpty ? sub.components.first.id : UuidGenerator.generate(),
                            dayOfWeek: 7, // Sunday
                            startTime: '10:00',
                            endTime: '11:00',
                            room: 'Audi-1',
                            effectiveFrom: null,
                            effectiveUntil: null,
                            createdAt: nowIso,
                            updatedAt: nowIso,
                          ));
                          await ref.read(timetableSlotsProvider.notifier).loadFromDb();
                          if (context.mounted) {
                            AppToast.success(context, 'Sunday class slot seeded at 10:00 AM!');
                          }
                        },
                      ),
                      Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                      _buildTile(
                        title: 'Seed Extra Lecture for Today',
                        subtitle: 'Tests Level 5 priority Extra Class resolution',
                        isDark: isDark,
                        icon: Icons.add_alarm_rounded,
                        iconColor: Colors.purple,
                        onTap: () async {
                          final subjects = ref.read(subjectsProvider);
                          if (subjects.isEmpty) {
                            AppToast.error(context, 'Please populate sample timetable first!');
                            return;
                          }
                          final sub = subjects.first;
                          final activeSem = ref.read(activeSemesterProvider);
                          final semId = activeSem.id;
                          final db = ref.read(databaseProvider);
                          final now = DateTime.now();
                          final nowIso = now.toIso8601String();

                          await db.saveExtraClass(ExtraClassData(
                            id: UuidGenerator.generate(),
                            semesterId: semId,
                            subjectComponentId: sub.components.isNotEmpty ? sub.components.first.id : UuidGenerator.generate(),
                            classDate: DateFormatter.toIsoDate(now),
                            startTime: '14:00',
                            endTime: '15:30',
                            room: 'Main Auditorium',
                            createdAt: nowIso,
                            updatedAt: nowIso,
                            deletedAt: null,
                          ));
                          await ref.read(timetableSlotsProvider.notifier).loadFromDb();
                          if (context.mounted) {
                            AppToast.success(context, 'Extra workshop lecture seeded for today at 2:00 PM!');
                          }
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 4. SQLITE DATABASE DIAGNOSTICS & EXPORT
                _buildSectionHeader('SQLite Database & Storage', isDark),
                Container(
                  decoration: BoxDecoration(
                    color: groupBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: groupBorder, width: 0.8),
                  ),
                  child: Column(
                    children: [
                      _buildTile(
                        title: 'Inspect Live Table Row Counts',
                        subtitle: 'View active records across all 11 SQLite tables',
                        isDark: isDark,
                        icon: Icons.table_chart_outlined,
                        iconColor: AppColors.accentBlue,
                        onTap: () => _showTableCountsDialog(context, isDark),
                      ),
                      Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                      _buildTile(
                        title: 'Export Raw .sqlite Database File',
                        subtitle: 'Share SQLite file to inspect in DB Browser on PC',
                        isDark: isDark,
                        icon: Icons.file_download_outlined,
                        iconColor: AppColors.presentGreen,
                        onTap: () => _exportRawDatabaseFile(context),
                      ),
                      Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                      _buildTile(
                        title: 'Copy Database File Path',
                        subtitle: 'Copies local SQLite absolute storage path',
                        isDark: isDark,
                        icon: Icons.copy_rounded,
                        iconColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        onTap: () async {
                          final dir = await getApplicationDocumentsDirectory();
                          final path = p.join(dir.path, 'classtrack_db.sqlite');
                          await Clipboard.setData(ClipboardData(text: path));
                          if (context.mounted) {
                            AppToast.success(context, 'Database path copied to clipboard!');
                          }
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 5. UI & FEEDBACK DIAGNOSTICS
                _buildSectionHeader('UI & Feedback Diagnostics', isDark),
                Container(
                  decoration: BoxDecoration(
                    color: groupBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: groupBorder, width: 0.8),
                  ),
                  child: Column(
                    children: [
                      _buildTile(
                        title: 'Trigger Success Toast',
                        isDark: isDark,
                        icon: Icons.check_circle_outline_rounded,
                        iconColor: AppColors.presentGreen,
                        onTap: () => AppToast.success(context, 'Test Success: Operation completed smoothly!'),
                      ),
                      Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                      _buildTile(
                        title: 'Trigger Error Toast',
                        isDark: isDark,
                        icon: Icons.error_outline_rounded,
                        iconColor: AppColors.absentRed,
                        onTap: () => AppToast.error(context, 'Test Error: Something went wrong!'),
                      ),
                      Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                      _buildTile(
                        title: 'Trigger Info Toast with Undo Action',
                        isDark: isDark,
                        icon: Icons.info_outline_rounded,
                        iconColor: AppColors.accentIndigoLight,
                        onTap: () {
                          AppToast.show(
                            context,
                            'Marked Present for Mathematics',
                            type: ToastType.info,
                            actionLabel: 'UNDO',
                            onAction: () => AppToast.success(context, 'Action undone!'),
                          );
                        },
                      ),
                      Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                      _buildTile(
                        title: 'Trigger Haptic Feedback Click',
                        subtitle: 'Tests hardware vibration motor',
                        isDark: isDark,
                        icon: Icons.vibration_rounded,
                        iconColor: Colors.teal,
                        onTap: () async {
                          await HapticFeedback.lightImpact();
                          if (context.mounted) {
                            AppToast.info(context, 'Haptic feedback triggered');
                          }
                        },
                      ),
                      Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                      _buildTile(
                        title: 'Simulate Normal Update Available',
                        subtitle: 'Tests reference update modal with "Not now" & changelog',
                        isDark: isDark,
                        icon: Icons.system_update_alt_rounded,
                        iconColor: AppColors.accentBlue,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (ctx) => const UpdateScreen(
                                releaseInfo: AppReleaseInfo(
                                  latestVersion: '0.20.4',
                                  buildNumber: 24,
                                  minSupportedVersion: '0.19.0',
                                  releaseDate: '25/08/2026',
                                  releaseTitle: 'ClassTrack v0.20.4',
                                  changelog: [
                                    '✨ Added 1-tap batch timetable setup for recurring days',
                                    '✨ Real-time dynamic attendance impact forecast on Today tab',
                                    '🧩 Fixed some dates being wrongly shown as Today or closer in time',
                                    '🧩 Improved SQLite WAL compression on app resume',
                                  ],
                                  downloadUrl: 'https://github.com/classtrack/classtrack/releases',
                                  releasePageUrl: 'https://github.com/classtrack/classtrack/releases/tag/v0.20.4',
                                  isMandatory: false,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                      _buildTile(
                        title: 'Simulate Mandatory Update Available',
                        subtitle: 'Tests critical update with hidden "Not now" and back-button lock',
                        isDark: isDark,
                        icon: Icons.error_outline_rounded,
                        iconColor: AppColors.absentRed,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (ctx) => const UpdateScreen(
                                releaseInfo: AppReleaseInfo(
                                  latestVersion: '1.0.0',
                                  buildNumber: 30,
                                  minSupportedVersion: '1.0.0',
                                  releaseDate: '25/08/2026',
                                  releaseTitle: 'ClassTrack v1.0.0 Major Release',
                                  changelog: [
                                    '⚠️ Critical database schema migration required to prevent data loss',
                                    '🧩 Complete security and encryption overhaul for offline storage',
                                  ],
                                  downloadUrl: 'https://github.com/classtrack/classtrack/releases',
                                  releasePageUrl: 'https://github.com/classtrack/classtrack/releases/tag/v1.0.0',
                                  isMandatory: true,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 6. DEVELOPER SECURITY & ACCESS
                _buildSectionHeader('Developer Security & Access', isDark),
                Container(
                  decoration: BoxDecoration(
                    color: groupBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: groupBorder, width: 0.8),
                  ),
                  child: Column(
                    children: [
                      _buildTile(
                        title: 'Change Developer Passcode',
                        subtitle: 'Set a custom 4-digit secret PIN',
                        isDark: isDark,
                        icon: Icons.pin_outlined,
                        iconColor: AppColors.accentIndigoLight,
                        onTap: () => _showChangePasscodeDialog(context, isDark),
                      ),
                      Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                      _buildTile(
                        title: 'View Developer Unlock QR Badge',
                        subtitle: 'Share cryptographic unlock token with team',
                        isDark: isDark,
                        icon: Icons.qr_code_2_rounded,
                        iconColor: AppColors.accentBlue,
                        onTap: () => _showDeveloperQrDialog(context, isDark),
                      ),
                      Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                      _buildTile(
                        title: 'Lock & Re-hide Developer Mode',
                        subtitle: 'Revokes developer access until 7-tap & PIN unlock',
                        isDark: isDark,
                        titleColor: AppColors.absentRed,
                        icon: Icons.lock_outline_rounded,
                        iconColor: AppColors.absentRed,
                        onTap: () async {
                          await ref.read(isDeveloperUnlockedProvider.notifier).setUnlocked(false);
                          await ref.read(developerModeEnabledProvider.notifier).toggle(false);
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            AppToast.info(context, 'Developer Mode locked and concealed.');
                          }
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildTile({
    required String title,
    String? subtitle,
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: titleColor ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _seedAttendanceScenario({required int attended, required int total}) async {
    setState(() => _isLoading = true);
    try {
      final db = ref.read(databaseProvider);
      final activeSem = ref.read(activeSemesterProvider);
      final semId = activeSem.id;

      var subjects = ref.read(subjectsProvider);
      if (subjects.isEmpty) {
        await db.populateDemoData(semId);
        await ref.read(subjectsProvider.notifier).loadFromDb();
        subjects = ref.read(subjectsProvider);
      }

      final sub = subjects.first;
      final now = DateTime.now();

      for (int i = 1; i <= total; i++) {
        final date = now.subtract(Duration(days: i));
        final dateIso = DateFormatter.toIsoDate(date);
        final sessionId = 'scenario_session_${sub.id}_$dateIso';
        final isAttended = i <= attended;
        final dateIsoTimestamp = date.toIso8601String();

        await db.saveAttendanceRecord(AttendanceRecordData(
          id: UuidGenerator.generate(),
          classSessionId: sessionId,
          slotId: null,
          subjectId: sub.id,
          sessionDate: dateIso,
          outcome: isAttended ? 'PRESENT' : 'ABSENT',
          markedAt: dateIsoTimestamp,
          syncVersion: 1,
          createdAt: dateIsoTimestamp,
          updatedAt: dateIsoTimestamp,
          deletedAt: null,
        ));
      }

      await ref.read(attendanceRecordsProvider.notifier).loadFromDb();
      setState(() => _isLoading = false);
      if (mounted) {
        AppToast.success(context, 'Seeded scenario: $attended attended / $total total (${((attended / total) * 100).toStringAsFixed(1)}%)');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) AppToast.error(context, 'Scenario generation failed: $e');
    }
  }

  Future<void> _exportRawDatabaseFile(BuildContext context) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final dbPath = p.join(dir.path, 'classtrack_db.sqlite');
      final file = File(dbPath);

      if (!await file.exists()) {
        if (context.mounted) AppToast.error(context, 'SQLite database file not found.');
        return;
      }

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'ClassTrack SQLite Database Backup (${DateFormatter.formatDateIndian(DateTime.now())})',
        ),
      );
    } catch (e) {
      if (context.mounted) AppToast.error(context, 'Export failed: $e');
    }
  }

  Future<void> _showTableCountsDialog(BuildContext context, bool isDark) async {
    final db = ref.read(databaseProvider);
    final sems = await db.getAllSemestersAll();
    final subs = await db.getAllSubjectsAll();
    final comps = await db.getAllSubjectComponentsAll();
    final slots = await db.getAllTimetableSlotsAll();
    final hols = await db.getAllHolidaysAll();
    final extras = await db.getAllExtraClassesAll();
    final sessions = await db.getAllClassSessionsAll();
    final records = await db.getAllAttendanceRecordsAll();
    final settings = await db.getAllAppSettingsAll();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          'SQLite Table Row Counts',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCountRow('Semesters', sems.length, isDark),
            _buildCountRow('Subjects', subs.length, isDark),
            _buildCountRow('Subject Components', comps.length, isDark),
            _buildCountRow('Timetable Slots', slots.length, isDark),
            _buildCountRow('Holidays', hols.length, isDark),
            _buildCountRow('Extra Classes', extras.length, isDark),
            _buildCountRow('Class Sessions', sessions.length, isDark),
            _buildCountRow('Attendance Records', records.length, isDark),
            _buildCountRow('App Settings', settings.length, isDark),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildCountRow(String tableName, int count, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            tableName,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
            decoration: BoxDecoration(
              color: isDark ? AppColors.pillDark : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmClearAllData() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text('This will delete all subjects, timetable slots, and attendance logs. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              setState(() => _isLoading = true);
              await ref.read(subjectsProvider.notifier).clearAllData();
              await ref.read(timetableSlotsProvider.notifier).loadFromDb();
              await ref.read(attendanceRecordsProvider.notifier).loadFromDb();
              setState(() => _isLoading = false);
              if (mounted) AppToast.info(context, 'All schedule data cleared.');
            },
            child: const Text('Clear All', style: TextStyle(color: AppColors.absentRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showChangePasscodeDialog(BuildContext context, bool isDark) {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0), width: 0.8),
        ),
        title: Text(
          'Change Developer Passcode',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter a new 4-digit numeric PIN.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New 4-Digit PIN',
                counterText: '',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: confirmController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm New PIN',
                counterText: '',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final pin = pinController.text.trim();
              final confirm = confirmController.text.trim();

              if (pin.length != 4 || !RegExp(r'^\d{4}$').hasMatch(pin)) {
                AppToast.error(context, 'Passcode must be exactly 4 digits');
                return;
              }
              if (pin != confirm) {
                AppToast.error(context, 'Passcodes do not match');
                return;
              }

              final hash = DeveloperAuthService.hashPasscode(pin);
              await ref.read(customDevPasscodeHashProvider.notifier).setHash(hash);
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (context.mounted) {
                AppToast.success(context, 'Developer passcode updated successfully!');
              }
            },
            child: const Text('Save PIN', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDeveloperQrDialog(BuildContext context, bool isDark) {
    final customHash = ref.read(customDevPasscodeHashProvider);
    final payload = DeveloperAuthService.generateQrPayload(customHash);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0), width: 0.8),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Developer Unlock QR Badge',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Scan this QR code from the developer login dialog to unlock instantly.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFCBD5E1), width: 0.8),
                  ),
                  child: SizedBox(
                    width: 180,
                    height: 180,
                    child: QrImageView(
                      data: payload,
                      version: QrVersions.auto,
                      size: 180.0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  payload,
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: payload));
                        if (ctx.mounted) {
                          AppToast.success(context, 'Unlock link copied to clipboard!');
                        }
                      },
                      child: const Text('Copy Link'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


