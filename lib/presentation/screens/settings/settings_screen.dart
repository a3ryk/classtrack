import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/ui/app_toast.dart';
import '../../../core/ui/theme_transition_wrapper.dart';
import '../../../domain/entities/academic_template.dart';
import '../../../domain/entities/attendance_stats.dart';
import '../../../domain/entities/semester_entity.dart';
import '../../../domain/entities/subject_entity.dart';
import '../../../domain/entities/user_profile_entity.dart';
import '../../../domain/services/export_service.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/app_update_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/target_percentage_dialog.dart';
import '../profile/profile_screen.dart';
import 'about_screen.dart';
import 'backup_restore_screen.dart';
import 'developer_tools_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userProfile = ref.watch(userProfileProvider);
    final userUni = ref.watch(selectedUniversityProvider);
    final activeSemester = ref.watch(activeSemesterProvider);
    final targetPct = ref.watch(targetPercentageProvider);
    final overallStats = ref.watch(overallStatsProvider);
    final activeTemplate = ref.watch(activeTemplateProvider);
    final betaMode = ref.watch(betaFeaturesEnabledProvider);
    final developerMode = ref.watch(developerModeEnabledProvider);
    final isDeveloperUnlocked = ref.watch(isDeveloperUnlockedProvider);
    final updateState = ref.watch(appUpdateProvider);
    final currentThemeMode = ref.watch(themeModeProvider);

    final String initials = userProfile.studentName.trim().isNotEmpty
        ? userProfile.studentName.trim().split(' ').map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').take(2).join()
        : 'ST';

    final Color groupBg = isDark ? AppColors.cardDark : Colors.white;
    final Color groupBorder = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);
    final Color dividerColor = isDark ? AppColors.borderDark.withValues(alpha: 0.6) : const Color(0xFFF1F5F9);

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF8FAFC),
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 80,
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: [
              const SizedBox(width: 16),
              const Icon(Icons.chevron_left_rounded, size: 22, color: AppColors.accentBlue),
              const Text(
                'Back',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentBlue,
                ),
              ),
            ],
          ),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. ACCOUNT / PROFILE
          _buildSectionHeader('Account', isDark),
          RepaintBoundary(
            child: Container(
              decoration: BoxDecoration(
                color: groupBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: groupBorder, width: 0.8),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfileScreen()),
                    );
                  },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initials,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userProfile.studentName.isNotEmpty ? userProfile.studentName : 'Student Profile',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              userProfile.degreeProgramme.isNotEmpty
                                  ? userProfile.degreeProgramme + (userProfile.rollNumber.isNotEmpty ? ' • ${userProfile.rollNumber}' : '')
                                  : (userUni.universityName.isNotEmpty
                                      ? userUni.universityName
                                      : 'Tap to configure student identity'),
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

          // 2. APPEARANCE
          _buildSectionHeader('Appearance', isDark),
          _buildSegmentedThemeControl(
            currentMode: currentThemeMode,
            isDark: isDark,
            groupBorder: groupBorder,
            context: context,
          ),

          const SizedBox(height: 20),

          // 3. GENERAL PREFERENCES
          _buildSectionHeader('Preferences', isDark),
          RepaintBoundary(
            child: Container(
              decoration: BoxDecoration(
                color: groupBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: groupBorder, width: 0.8),
              ),
              child: Column(
                children: [
                  _buildTile(
                    title: 'Notifications',
                    isDark: isDark,
                    trailing: Switch(
                      value: _notificationsEnabled,
                      activeThumbColor: AppColors.presentGreen,
                      onChanged: (val) {
                        setState(() {
                          _notificationsEnabled = val;
                        });
                        AppToast.info(context, 'Notifications ${val ? "enabled" : "disabled"}');
                      },
                    ),
                  ),
                  Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                  _buildTile(
                    title: 'Attendance Target',
                    isDark: isDark,
                    trailing: _buildChevronValue('${targetPct.toStringAsFixed(1)}%', isDark),
                    onTap: () => TargetPercentageSheet.show(context),
                  ),
                  Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                  _buildTile(
                    title: 'Export Attendance Report',
                    isDark: isDark,
                    trailing: _buildChevronIcon(isDark),
                    onTap: () => _showExportSheet(context, overallStats, activeSemester, userProfile, userUni, activeTemplate, isDark),
                  ),
                  Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                  _buildTile(
                    title: 'Backup & Restore',
                    isDark: isDark,
                    trailing: _buildChevronIcon(isDark),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const BackupRestoreScreen()),
                      );
                    },
                  ),
                  Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                  _buildTile(
                    title: 'Language',
                    isDark: isDark,
                    trailing: _buildChevronValue('English', isDark),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 4. EXPERIMENTAL & DEVELOPER
          _buildSectionHeader('Developer & Experimental', isDark),
          RepaintBoundary(
            child: Container(
              decoration: BoxDecoration(
                color: groupBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: groupBorder, width: 0.8),
              ),
              child: Column(
                children: [
                  _buildTile(
                    title: 'Beta Features',
                    subtitle: 'Early access to experimental features',
                    isDark: isDark,
                    trailing: Switch(
                      value: betaMode,
                      activeThumbColor: AppColors.presentGreen,
                      onChanged: (val) {
                        ref.read(betaFeaturesEnabledProvider.notifier).toggle(val);
                        AppToast.info(context, 'Beta features ${val ? "enabled" : "disabled"}');
                      },
                    ),
                  ),
                  if (isDeveloperUnlocked) ...[
                    Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                    _buildTile(
                      title: 'Developer Options',
                      subtitle: 'Advanced database & testing tools',
                      isDark: isDark,
                      trailing: Switch(
                        value: developerMode,
                        activeThumbColor: AppColors.presentGreen,
                        onChanged: (val) {
                          ref.read(developerModeEnabledProvider.notifier).toggle(val);
                        },
                      ),
                    ),
                    if (developerMode) ...[
                      Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                      _buildTile(
                        title: 'Developer Tools',
                        subtitle: 'Testing utilities, scenario simulators & diagnostics',
                        isDark: isDark,
                        trailing: _buildChevronIcon(isDark),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const DeveloperToolsScreen()),
                          );
                        },
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 5. SUPPORT & ABOUT
          _buildSectionHeader('Support & About', isDark),
          RepaintBoundary(
            child: Container(
              decoration: BoxDecoration(
                color: groupBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: groupBorder, width: 0.8),
              ),
              child: Column(
                children: [
                  _buildTile(
                    title: 'Take Guided App Tour',
                    subtitle: 'Replay the interactive app walkthrough',
                    isDark: isDark,
                    trailing: _buildChevronIcon(isDark),
                    onTap: () {
                      Navigator.of(context).pop();
                      ref.read(activeTourProvider.notifier).state = true;
                    },
                  ),
                  Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                  _buildTile(
                    title: 'About',
                    subtitle: 'Version ${updateState.currentVersion}, updates, links & legal',
                    isDark: isDark,
                    trailing: _buildChevronIcon(isDark),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AboutScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
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
        ),
      ),
    );
  }

  Widget _buildTile({
    required String title,
    String? subtitle,
    required bool isDark,
    Widget? trailing,
    Color? titleColor,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
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
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChevronValue(String value, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
        ),
        const SizedBox(width: 4),
        _buildChevronIcon(isDark),
      ],
    );
  }

  Widget _buildChevronIcon(bool isDark) {
    return Icon(
      Icons.chevron_right_rounded,
      size: 18,
      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
    );
  }

  void _showExportSheet(
    BuildContext context,
    OverallAttendanceStats overallStats,
    SemesterEntity activeSemester,
    UserProfileEntity userProfile,
    UserUniversityInfo userUni,
    ProgrammeTemplate activeTemplate,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final subjects = ref.read(subjectsProvider);
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Export Attendance Report',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Exports all date-wise sessions across ${activeSemester.name}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 18),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.presentGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.table_chart_rounded, color: AppColors.presentGreen, size: 22),
                ),
                title: const Text('Excel Spreadsheet (.xlsx)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Full multi-sheet workbook with summary & daily register', style: TextStyle(fontSize: 11)),
                onTap: () {
                  Navigator.pop(context);
                  _runExportWithProgress(
                    format: 'EXCEL',
                    overallStats: overallStats,
                    activeSemester: activeSemester,
                    userProfile: userProfile,
                    userUni: userUni,
                    activeTemplate: activeTemplate,
                    subjects: subjects,
                  );
                },
              ),
              Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.absentRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.absentRed, size: 22),
                ),
                title: const Text('PDF Document (.pdf)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Printable official report with wrap protection & date tables', style: TextStyle(fontSize: 11)),
                onTap: () {
                  Navigator.pop(context);
                  _runExportWithProgress(
                    format: 'PDF',
                    overallStats: overallStats,
                    activeSemester: activeSemester,
                    userProfile: userProfile,
                    userUni: userUni,
                    activeTemplate: activeTemplate,
                    subjects: subjects,
                  );
                },
              ),
              Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.code_rounded, color: AppColors.accentBlue, size: 22),
                ),
                title: const Text('Raw JSON (.json)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Machine-readable backup of your entire attendance data', style: TextStyle(fontSize: 11)),
                onTap: () {
                  Navigator.pop(context);
                  _runExportWithProgress(
                    format: 'JSON',
                    overallStats: overallStats,
                    activeSemester: activeSemester,
                    userProfile: userProfile,
                    userUni: userUni,
                    activeTemplate: activeTemplate,
                    subjects: subjects,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _runExportWithProgress({
    required String format,
    required OverallAttendanceStats overallStats,
    required SemesterEntity activeSemester,
    required UserProfileEntity userProfile,
    required UserUniversityInfo userUni,
    required ProgrammeTemplate activeTemplate,
    required List<SubjectEntity> subjects,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    double currentProgress = 0.05;
    String currentStatus = 'Initializing export...';
    StateSetter? dialogStateSetter;

    // Show Progress Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            dialogStateSetter = setDialogState;
            return AlertDialog(
              backgroundColor: isDark ? AppColors.cardDark : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              content: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 64,
                          height: 64,
                          child: CircularProgressIndicator(
                            value: currentProgress,
                            strokeWidth: 5,
                            backgroundColor: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              format == 'PDF'
                                  ? AppColors.absentRed
                                  : (format == 'EXCEL' ? AppColors.presentGreen : AppColors.accentIndigoLight),
                            ),
                          ),
                        ),
                        Text(
                          '${(currentProgress * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Exporting $format Report',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      currentStatus,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, size: 16, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Please do not clear the app from background. We will notify you once done.',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    try {
      final db = ref.read(databaseProvider);
      final startDate = activeSemester.startDate;
      final endDate = activeSemester.endDate ?? DateTime.now();

      final sessions = await ExportService.collectDateRangeSessions(
        db: db,
        semester: activeSemester,
        startDate: startDate,
        endDate: endDate,
        onProgress: (p, msg) {
          currentProgress = p;
          currentStatus = msg;
          dialogStateSetter?.call(() {});
        },
      );

      String filePath;
      String mimeType;

      if (format == 'EXCEL') {
        mimeType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
        filePath = await ExportService.generateExcelReport(
          overallStats: overallStats,
          semester: activeSemester,
          profile: userProfile,
          university: userUni,
          courseStructure: activeTemplate,
          sessions: sessions,
          onProgress: (p, msg) {
            currentProgress = p;
            currentStatus = msg;
            dialogStateSetter?.call(() {});
          },
        );
      } else if (format == 'PDF') {
        mimeType = 'application/pdf';
        filePath = await ExportService.generatePdfReport(
          overallStats: overallStats,
          semester: activeSemester,
          profile: userProfile,
          university: userUni,
          courseStructure: activeTemplate,
          sessions: sessions,
          onProgress: (p, msg) {
            currentProgress = p;
            currentStatus = msg;
            dialogStateSetter?.call(() {});
          },
        );
      } else {
        mimeType = 'application/json';
        filePath = await ExportService.exportJsonBackup(
          profile: userProfile,
          university: userUni,
          semester: activeSemester,
          courseStructure: activeTemplate,
          subjects: subjects,
          sessions: sessions,
          onProgress: (p, msg) {
            currentProgress = p;
            currentStatus = msg;
            dialogStateSetter?.call(() {});
          },
        );
      }

      if (mounted) {
        Navigator.pop(context); // Close progress modal
        await ExportService.shareFile(filePath, mimeType);
        if (mounted) {
          AppToast.success(context, '$format report exported successfully!');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close progress modal
        AppToast.error(context, 'Export failed: $e');
      }
    }
  }

  Widget _buildSegmentedThemeControl({
    required ThemeMode currentMode,
    required bool isDark,
    required Color groupBorder,
    required BuildContext context,
  }) {
    // 3 options: System (index 0), Light (index 1), Dark (index 2)
    final double targetAlignmentX = currentMode == ThemeMode.system
        ? -1.0
        : (currentMode == ThemeMode.light ? 0.0 : 1.0);

    final activePillBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final activeText = isDark ? Colors.white : const Color(0xFF0F172A);
    final inactiveText = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return RepaintBoundary(
      child: Container(
        height: 42,
        padding: const EdgeInsets.all(3.5),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0B0F17) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: groupBorder, width: 0.8),
        ),
        child: Stack(
          children: [
            // Smoothly gliding active capsule pill
            AnimatedAlign(
              alignment: Alignment(targetAlignmentX, 0.0),
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              child: FractionallySizedBox(
                widthFactor: 1 / 3,
                heightFactor: 1.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: activePillBg,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Tap targets and labels row
            Row(
              children: [
                _buildThemeSegment(
                  title: 'System',
                  mode: ThemeMode.system,
                  currentMode: currentMode,
                  activeText: activeText,
                  inactiveText: inactiveText,
                  context: context,
                ),
                _buildThemeSegment(
                  title: 'Light',
                  mode: ThemeMode.light,
                  currentMode: currentMode,
                  activeText: activeText,
                  inactiveText: inactiveText,
                  context: context,
                ),
                _buildThemeSegment(
                  title: 'Dark',
                  mode: ThemeMode.dark,
                  currentMode: currentMode,
                  activeText: activeText,
                  inactiveText: inactiveText,
                  context: context,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSegment({
    required String title,
    required ThemeMode mode,
    required ThemeMode currentMode,
    required Color activeText,
    required Color inactiveText,
    required BuildContext context,
  }) {
    final isSelected = mode == currentMode;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (details) {
          if (mode != currentMode) {
            ThemeTransition.switchTheme(
              context,
              ref,
              mode,
              origin: details.globalPosition,
            );
          }
        },
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? activeText : inactiveText,
            ),
            child: Text(title),
          ),
        ),
      ),
    );
  }
}
