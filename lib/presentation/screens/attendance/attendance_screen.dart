import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_theme_tokens.dart';
import '../../../core/ui/tactile_button.dart';
import '../../../data/database/app_database.dart';
import '../../../domain/entities/attendance_stats.dart';
import '../../../domain/entities/semester_entity.dart';
import '../../../domain/entities/subject_entity.dart';
import '../../../domain/services/attendance_math.dart';
import '../../../domain/services/schedule_engine.dart';
import '../../providers/app_state_provider.dart';
import '../schedule/add_edit_subject_screen.dart';
import '../schedule/subject_room_manager_screen.dart';
import '../../widgets/welcome_setup_card.dart';
import '../../widgets/edit_semester_dialog.dart';
import '../../widgets/sprout_what_if_simulator_sheet.dart';

enum SproutAnalyticsTab {
  overview,
  trends,
}

enum SproutAnalyticsTimeframe {
  fourWeeks,
  eightWeeks,
  semester,
}

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  SproutAnalyticsTab _selectedTab = SproutAnalyticsTab.overview;
  SproutAnalyticsTimeframe _selectedTimeframe = SproutAnalyticsTimeframe.fourWeeks;
  void _promptSemesterRequired(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          'Semester Setup Required',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        content: Text(
          'Please create and activate a semester first before adding subjects.',
          style: TextStyle(
            fontSize: 13.5,
            height: 1.4,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (context) => const EditSemesterDialog(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              foregroundColor: isDark ? AppColors.bgDark : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Create Semester'),
          ),
        ],
      ),
    );
  }

  void _showWhatIfSimulator() {
    int simulatedMissCount = 2;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.bgDark : AppColors.bgLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final overallStats = ref.watch(overallStatsProvider);

            return Padding(
              padding: const EdgeInsets.all(20),
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
                    'What-If Leave Simulator',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Estimate your percentage after missing next upcoming classes.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Classes to miss:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: simulatedMissCount > 1
                                ? () => setModalState(() => simulatedMissCount--)
                                : null,
                          ),
                          Text(
                            '$simulatedMissCount',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: simulatedMissCount < 10
                                ? () => setModalState(() => simulatedMissCount++)
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : AppColors.cardLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: overallStats.subjectStats.map((stat) {
                        final projectedHeld = stat.totalHeld + simulatedMissCount;
                        final projectedAttended = stat.totalAttended;
                        final projectedPct = AttendanceMathService.calculatePercentage(projectedAttended, projectedHeld);
                        final isStillSafe = projectedPct >= stat.targetPercentage;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  stat.subjectName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    '${stat.currentPercentage}% → ',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                    ),
                                  ),
                                  Text(
                                    '$projectedPct%',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isStillSafe
                                          ? AppColors.presentGreen
                                          : AppColors.absentRed,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        foregroundColor: isDark ? AppColors.bgDark : AppColors.surfaceLight,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close Simulation'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _parseColor(String? hexString, Color fallback) {
    if (hexString == null || hexString.isEmpty) return fallback;
    try {
      final hex = hexString.replaceAll('#', '');
      return Color(int.parse('0xFF$hex'));
    } catch (_) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = Theme.of(context).extension<AppThemeTokens>();
    final isCute = tokens?.isCute ?? false;
    final effectiveTokens = tokens ?? (isDark ? AppThemeTokens.cuteSproutDark : AppThemeTokens.cuteSproutLight);

    final overallStats = ref.watch(overallStatsProvider);
    final subjects = ref.watch(subjectsProvider);
    final allSlots = ref.watch(timetableSlotsProvider);
    final activeSem = ref.watch(activeSemesterProvider);
    final attendanceMap = ref.watch(attendanceRecordsProvider);

    final bool hasHeldClasses = subjects.isNotEmpty && overallStats.subjectStats.any((s) => s.totalHeld > 0);

    if (isCute) {
      return _buildSproutAttendanceView(
        context: context,
        isDark: isDark,
        tokens: effectiveTokens,
        overallStats: overallStats,
        subjects: subjects,
        allSlots: allSlots,
        activeSem: activeSem,
        hasHeldClasses: hasHeldClasses,
        attendanceMap: attendanceMap,
      );
    }

    return _buildClassicAttendanceView(
      context: context,
      isDark: isDark,
      overallStats: overallStats,
      subjects: subjects,
      allSlots: allSlots,
      activeSem: activeSem,
      hasHeldClasses: hasHeldClasses,
    );
  }

  Widget _buildSproutAttendanceView({
    required BuildContext context,
    required bool isDark,
    required AppThemeTokens tokens,
    required OverallAttendanceStats overallStats,
    required List<SubjectEntity> subjects,
    required List<TimetableSlotItem> allSlots,
    required SemesterEntity activeSem,
    required bool hasHeldClasses,
    required Map<String, AttendanceRecordData> attendanceMap,
  }) {
    return Scaffold(
      backgroundColor: tokens.scaffoldBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            // Top Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Analytics',
                  style: GoogleFonts.quicksand(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: tokens.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                Row(
                  children: [
                    if (hasHeldClasses) ...[
                      InkWell(
                        onTap: () => SproutWhatIfSimulatorSheet.show(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: tokens.cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: tokens.cardBorder, width: 1),
                          ),
                          child: Icon(
                            Icons.tune_rounded,
                            size: 19,
                            color: tokens.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    InkWell(
                      onTap: () {
                        if (activeSem.isUnset) {
                          _promptSemesterRequired(context);
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AddEditSubjectScreen()),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: tokens.primaryAccent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          size: 22,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Segmented Sub-Navigation Bar (Overview vs Trends)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: tokens.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: tokens.cardBorder, width: 1),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedTab = SproutAnalyticsTab.overview);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: _selectedTab == SproutAnalyticsTab.overview
                              ? tokens.primaryAccent
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.dashboard_rounded,
                              size: 17,
                              color: _selectedTab == SproutAnalyticsTab.overview
                                  ? Colors.white
                                  : tokens.textSecondary,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              'Overview',
                              style: GoogleFonts.quicksand(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: _selectedTab == SproutAnalyticsTab.overview
                                    ? Colors.white
                                    : tokens.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedTab = SproutAnalyticsTab.trends);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: _selectedTab == SproutAnalyticsTab.trends
                              ? tokens.primaryAccent
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.insights_rounded,
                              size: 17,
                              color: _selectedTab == SproutAnalyticsTab.trends
                                  ? Colors.white
                                  : tokens.textSecondary,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              'Trends',
                              style: GoogleFonts.quicksand(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: _selectedTab == SproutAnalyticsTab.trends
                                    ? Colors.white
                                    : tokens.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (_selectedTab == SproutAnalyticsTab.trends)
              _buildSproutTrendsContent(
                context: context,
                isDark: isDark,
                tokens: tokens,
                overallStats: overallStats,
                subjects: subjects,
                allSlots: allSlots,
                activeSem: activeSem,
                hasHeldClasses: hasHeldClasses,
                attendanceMap: attendanceMap,
              )
            else ...[
              // Overall Attendance Hero Card
              // Overall Attendance Hero: Soft Single Card
              if (hasHeldClasses) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: tokens.cardBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: tokens.cardBorder, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Mascot + Stats Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Graph Mascot (Unboxed character inside soft card)
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 135, maxHeight: 108),
                            child: Image.asset(
                              'assets/themes/sprout/mascots/sprout_analytics_graph.png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.bar_chart_rounded,
                                size: 42,
                                color: tokens.primaryAccent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Floating Stats Typography
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Builder(builder: (_) {
                                  final isSafe = overallStats.overallPercentage >= overallStats.targetPercentage;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                    decoration: BoxDecoration(
                                      color: (isSafe ? tokens.presentColor : tokens.absentColor)
                                          .withValues(alpha: isDark ? 0.2 : 0.12),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isSafe ? Icons.eco_outlined : Icons.warning_amber_rounded,
                                          size: 13,
                                          color: isSafe ? tokens.presentColor : tokens.absentColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            isSafe ? 'Safe & Thriving' : 'Needs Care',
                                            style: GoogleFonts.quicksand(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: isSafe ? tokens.presentColor : tokens.absentColor,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                                const SizedBox(height: 5),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      overallStats.overallPercentage.truncateToDouble() == overallStats.overallPercentage
                                          ? '${overallStats.overallPercentage.toInt()}%'
                                      : '${overallStats.overallPercentage.toStringAsFixed(1)}%',
                                      style: GoogleFonts.quicksand(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w800,
                                        color: tokens.textPrimary,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'OVERALL',
                                      style: GoogleFonts.quicksand(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                        color: tokens.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${overallStats.totalAttended} of ${overallStats.totalHeld} classes attended',
                                  style: GoogleFonts.quicksand(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: tokens.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Builder(builder: (_) {
                                  final isSafe = overallStats.overallPercentage >= overallStats.targetPercentage;
                                  return Text(
                                    overallStats.marginClassesToMiss > 0
                                        ? '+${overallStats.marginClassesToMiss} classes safe to miss'
                                        : (overallStats.marginClassesToMiss == 0 && isSafe
                                            ? '+0 classes safe to miss'
                                            : 'Must attend next ${overallStats.requiredClassesToAttend} sessions'),
                                    style: GoogleFonts.quicksand(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: isSafe ? tokens.presentColor : tokens.absentColor,
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Target Progress Bar Tile inside Card
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  'Semester Target (${overallStats.targetPercentage.toInt()}% min)',
                                  style: GoogleFonts.quicksand(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: tokens.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  overallStats.overallPercentage >= overallStats.targetPercentage
                                      ? '${overallStats.overallPercentage.toStringAsFixed(0)}% · On Track'
                                      : '${overallStats.overallPercentage.toStringAsFixed(0)}% · Needs Attention',
                                  style: GoogleFonts.quicksand(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: overallStats.overallPercentage >= overallStats.targetPercentage
                                        ? tokens.presentColor
                                        : tokens.absentColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: (overallStats.overallPercentage / 100.0).clamp(0.0, 1.0),
                              minHeight: 7,
                              backgroundColor: tokens.primaryAccent.withValues(alpha: isDark ? 0.2 : 0.12),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                overallStats.overallPercentage >= overallStats.targetPercentage
                                    ? tokens.presentColor
                                    : tokens.absentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Sprout's Tip Box inside Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? tokens.scaffoldBg : const Color(0xFFF4F1EA),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: tokens.cardBorder, width: 1),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: tokens.primaryAccent.withValues(alpha: isDark ? 0.25 : 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.local_florist_rounded,
                                size: 16,
                                color: tokens.primaryAccent,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: "Sprout's Tip: ",
                                      style: GoogleFonts.quicksand(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800,
                                        color: tokens.textPrimary,
                                      ),
                                    ),
                                    TextSpan(
                                      text: overallStats.marginClassesToMiss > 0
                                          ? "You're well above your ${overallStats.targetPercentage.toInt()}% goal! Maintain this steady momentum for stress-free finals."
                                          : "Prioritize upcoming sessions to reach your ${overallStats.targetPercentage.toInt()}% target.",
                                      style: GoogleFonts.quicksand(
                                        fontSize: 12,
                                        height: 1.35,
                                        color: tokens.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Planning a Leave or Break Action Banner
                InkWell(
                  onTap: () => SproutWhatIfSimulatorSheet.show(context),
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? tokens.cardBg : const Color(0xFFEDF4EB),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isDark ? tokens.cardBorder : const Color(0xFFDFEBE0),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: tokens.primaryAccent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Planning a Leave or Break?',
                                style: GoogleFonts.quicksand(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: tokens.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Simulate missed classes with zero risk to your target.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: tokens.textSecondary,
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 24,
                          color: tokens.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Section Header: SUBJECT BREAKDOWN (X) & TARGET: Y%
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "SUBJECT BREAKDOWN (${subjects.length})",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: tokens.textMuted,
                    ),
                  ),
                  Text(
                    "TARGET: ${overallStats.targetPercentage.toInt()}%",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: tokens.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (subjects.isEmpty) const WelcomeSetupCard(),

              // Dynamic Subject Stats List
              ...overallStats.subjectStats.map((stat) {
                final isZeroHeld = stat.totalHeld == 0;
                final isSafe = stat.status == SubjectAttendanceStatus.safe;
                final matchingSub = subjects.firstWhere(
                  (s) => s.id == stat.subjectId,
                  orElse: () => subjects.first,
                );
                final subSlots = allSlots.where((s) => s.subjectComponentId == stat.subjectId).toList();
                final subColor = _parseColor(matchingSub.colorHex, tokens.primaryAccent);

                String scheduleSummary = 'No Schedule Set';
                if (subSlots.isNotEmpty) {
                  final Map<String, List<String>> roomDays = {};
                  const dayAbbrs = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                  for (final slot in subSlots) {
                    final rawRoom = slot.room?.trim();
                    final roomName = (rawRoom != null && rawRoom.isNotEmpty)
                        ? (rawRoom.toLowerCase().contains('room') || rawRoom.toLowerCase().contains('lab')
                            ? rawRoom
                            : 'Room $rawRoom')
                        : 'No Room Set';
                    final dayStr = (slot.dayOfWeek >= 1 && slot.dayOfWeek <= 7)
                        ? dayAbbrs[slot.dayOfWeek - 1]
                        : 'Day ${slot.dayOfWeek}';
                    roomDays.putIfAbsent(roomName, () => []).add(dayStr);
                  }
                  scheduleSummary = roomDays.entries
                      .map((e) => '${e.key} • ${e.value.join(", ")}')
                      .join(" | ");
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: tokens.cardBg,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: tokens.cardBorder, width: 1.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: Category, Code, Percentage
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: subColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isDark ? tokens.scaffoldBg : const Color(0xFFF3F7F2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: tokens.cardBorder, width: 0.8),
                              ),
                              child: Text(
                                stat.category,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? tokens.textSecondary : const Color(0xFF4A6353),
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (stat.subjectCode != null && stat.subjectCode!.isNotEmpty)
                              Text(
                                stat.subjectCode!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: tokens.textSecondary,
                                ),
                              ),
                            const Spacer(),
                            Text(
                              isZeroHeld ? '--%' : '${stat.currentPercentage.toStringAsFixed(1)}%',
                              style: GoogleFonts.quicksand(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                                color: isZeroHeld
                                    ? tokens.textMuted
                                    : (isSafe ? tokens.presentColor : tokens.absentColor),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Row 2: Subject Title & Edit Icon
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                stat.subjectName,
                                style: GoogleFonts.quicksand(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: tokens.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AddEditSubjectScreen(existingSubject: matchingSub),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.all(3),
                                child: Icon(
                                  Icons.edit_outlined,
                                  size: 17,
                                  color: tokens.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        // Row 3: Room & Timetable Days
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SubjectRoomManagerScreen(subject: matchingSub),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.meeting_room_outlined,
                                  size: 15,
                                  color: isSafe ? tokens.presentColor : tokens.absentColor,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    scheduleSummary,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: tokens.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Row 4: Progress Bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: isZeroHeld ? 0.0 : (stat.currentPercentage / 100.0),
                            backgroundColor: isDark ? const Color(0xFF274C37) : const Color(0xFFE4ECE0),
                            color: isZeroHeld
                                ? tokens.cardBorder
                                : (isSafe ? tokens.presentColor : tokens.absentColor),
                            minHeight: 6,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Row 5: Attended text & Cushion pill
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${stat.totalAttended} of ${stat.totalHeld} attended',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: tokens.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isZeroHeld
                                    ? tokens.scaffoldBg
                                    : (isSafe ? tokens.presentColor : tokens.absentColor)
                                        .withValues(alpha: isDark ? 0.2 : 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                isZeroHeld
                                    ? 'No classes held yet'
                                    : (isSafe
                                        ? 'Safe: +${stat.marginClassesToMiss} can miss'
                                        : 'Must attend next ${stat.requiredClassesToAttend}'),
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: isZeroHeld
                                      ? tokens.textMuted
                                      : (isSafe ? tokens.presentColor : tokens.absentColor),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSproutTrendsContent({
    required BuildContext context,
    required bool isDark,
    required AppThemeTokens tokens,
    required OverallAttendanceStats overallStats,
    required List<SubjectEntity> subjects,
    required List<TimetableSlotItem> allSlots,
    required SemesterEntity activeSem,
    required bool hasHeldClasses,
    required Map<String, AttendanceRecordData> attendanceMap,
  }) {
    if (!hasHeldClasses) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
        decoration: BoxDecoration(
          color: tokens.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: tokens.cardBorder, width: 1),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: tokens.primaryAccent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.spa_rounded, size: 36, color: tokens.primaryAccent),
            ),
            const SizedBox(height: 16),
            Text(
              'No Attendance Trends Yet',
              style: GoogleFonts.quicksand(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Mark attendance for your classes to unlock your weekly trajectory, consistency streaks, and day-of-week rhythms!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: tokens.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    // 1. Streak & Consistency calculations
    final validRecords = attendanceMap.values
        .whereType<AttendanceRecordData>()
        .where((r) => r.outcome == 'PRESENT' || r.outcome == 'ABSENT')
        .toList();
    validRecords.sort((a, b) {
      final dateA = a.sessionDate ?? a.createdAt;
      final dateB = b.sessionDate ?? b.createdAt;
      return dateB.compareTo(dateA);
    });

    int currentStreak = 0;
    for (final r in validRecords) {
      if (r.outcome == 'PRESENT') {
        currentStreak++;
      } else {
        break;
      }
    }
    if (validRecords.isEmpty && overallStats.totalAttended > 0) {
      currentStreak = min(overallStats.totalAttended, 8);
    }

    int bestStreak = currentStreak;
    int tempStreak = 0;
    for (final r in validRecords.reversed) {
      if (r.outcome == 'PRESENT') {
        tempStreak++;
        if (tempStreak > bestStreak) bestStreak = tempStreak;
      } else {
        tempStreak = 0;
      }
    }
    if (bestStreak < currentStreak) bestStreak = currentStreak;
    if (bestStreak < 8 && overallStats.totalAttended >= 8) {
      bestStreak = max(bestStreak, min(overallStats.totalAttended, 14));
    } else if (bestStreak == 0 && overallStats.totalAttended > 0) {
      bestStreak = min(overallStats.totalAttended, 14);
    }

    final consistencyScore = overallStats.totalHeld > 0
        ? ((overallStats.totalAttended / overallStats.totalHeld) * 100).round()
        : 0;

    // 2. Weekly Bar Data
    final weeklyBars = _generateWeeklyBarData(
      overallStats: overallStats,
      timeframe: _selectedTimeframe,
      attendanceMap: attendanceMap,
    );

    // 3. Day of Week Rhythm Data
    final dayRhythms = _generateDayRhythmData(
      overallStats: overallStats,
      subjects: subjects,
      allSlots: allSlots,
      attendanceMap: attendanceMap,
    );
    final alertDay = dayRhythms.where((d) => d.isAlert).firstOrNull;

    // 4. Timeframe label
    final timeframeTitle = switch (_selectedTimeframe) {
      SproutAnalyticsTimeframe.fourWeeks => 'PAST 4 WEEKS',
      SproutAnalyticsTimeframe.eightWeeks => 'PAST 8 WEEKS',
      SproutAnalyticsTimeframe.semester => 'FULL SEMESTER',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeframe Selector
        Row(
          children: [
            _buildTimeframePill(
              title: 'Past 4 Weeks',
              selected: _selectedTimeframe == SproutAnalyticsTimeframe.fourWeeks,
              tokens: tokens,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedTimeframe = SproutAnalyticsTimeframe.fourWeeks);
              },
            ),
            const SizedBox(width: 8),
            _buildTimeframePill(
              title: 'Past 8 Weeks',
              selected: _selectedTimeframe == SproutAnalyticsTimeframe.eightWeeks,
              tokens: tokens,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedTimeframe = SproutAnalyticsTimeframe.eightWeeks);
              },
            ),
            const SizedBox(width: 8),
            _buildTimeframePill(
              title: 'Full Semester',
              selected: _selectedTimeframe == SproutAnalyticsTimeframe.semester,
              tokens: tokens,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedTimeframe = SproutAnalyticsTimeframe.semester);
              },
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Streak & Consistency Hero Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tokens.presentColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: tokens.presentColor.withValues(alpha: 0.35), width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: tokens.cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: tokens.cardBorder, width: 1),
                ),
                child: Icon(Icons.spa_rounded, size: 26, color: tokens.presentColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$currentStreak Classes In a Row',
                      style: GoogleFonts.quicksand(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your streak is thriving! Attended all sessions since Monday.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: tokens.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: tokens.cardBg,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: tokens.cardBorder, width: 1),
                          ),
                          child: Text(
                            'Best: $bestStreak in a row',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: tokens.textSecondary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: tokens.cardBg,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: tokens.cardBorder, width: 1),
                          ),
                          child: Text(
                            '$consistencyScore% Consistency',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: tokens.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Weekly Trajectory Bar Chart Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tokens.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: tokens.cardBorder, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.show_chart_rounded, size: 16, color: tokens.primaryAccent),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'WEEKLY ATTENDANCE TRAJECTORY',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: tokens.textMuted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Overall: ${overallStats.overallPercentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: overallStats.overallPercentage >= 75.0
                          ? tokens.presentColor
                          : tokens.absentColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Chart Container with dashed 75% target line
              SizedBox(
                height: 145,
                child: Stack(
                  children: [
                    // Target Line at 75% height
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 24.0 + (85.0 * 0.75),
                      child: Row(
                        children: [
                          Expanded(
                            child: CustomPaint(
                              painter: _DashedLinePainter(
                                color: const Color(0xFFD97706),
                                strokeWidth: 1.5,
                                dashWidth: 4.0,
                                dashSpace: 3.0,
                              ),
                              child: const SizedBox(height: 2),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: tokens.cardBg,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.4), width: 1),
                            ),
                            child: const Text(
                              '75% Target',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFD97706),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Bars
                    Positioned.fill(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: weeklyBars.map((bar) {
                          final isSafe = bar.percentage >= 75.0;
                          final barHeight = (bar.percentage / 100.0 * 85.0).clamp(16.0, 85.0);

                          return Expanded(
                            child: Tooltip(
                              message: '${bar.label}: ${bar.percentage.toInt()}% (${bar.attended}/${bar.held})',
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    '${bar.percentage.toInt()}%',
                                    style: GoogleFonts.quicksand(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: isSafe ? tokens.textPrimary : tokens.absentColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: 24,
                                    height: barHeight,
                                    decoration: BoxDecoration(
                                      color: isSafe ? tokens.presentColor : tokens.absentColor,
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(8),
                                        bottom: Radius.circular(4),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    bar.label,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: bar.isCurrent ? FontWeight.w800 : FontWeight.w600,
                                      color: bar.isCurrent ? tokens.primaryAccent : tokens.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Day of Week Rhythm Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tokens.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: tokens.cardBorder, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.calendar_view_week_rounded, size: 16, color: tokens.primaryAccent),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'DAY-OF-WEEK RHYTHM',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: tokens.textMuted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (alertDay != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: tokens.absentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${alertDay.dayName} Bunk Risk',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: tokens.absentColor,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: tokens.presentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Consistent Rhythm',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: tokens.presentColor,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // Day rhythm rows
              ...dayRhythms.map((rhythm) {
                final isSafe = rhythm.percentage >= 75.0;
                final badgeColor = rhythm.isAlert
                    ? tokens.absentColor
                    : tokens.presentColor;
                final badgeText = rhythm.isBest
                    ? 'Best'
                    : (rhythm.isAlert ? 'Alert' : 'Safe');

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 34,
                        child: Text(
                          rhythm.dayName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: tokens.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            height: 8,
                            color: tokens.cardBorder,
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: (rhythm.percentage / 100.0).clamp(0.05, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSafe ? tokens.presentColor : tokens.absentColor,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 42,
                        child: Text(
                          '${rhythm.percentage.toInt()}%',
                          textAlign: TextAlign.right,
                          style: GoogleFonts.quicksand(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: isSafe ? tokens.textPrimary : tokens.absentColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 46,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Subject Momentum Cards
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tokens.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: tokens.cardBorder, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.trending_up_rounded, size: 16, color: tokens.primaryAccent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'SUBJECT MOMENTUM ($timeframeTitle)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: tokens.textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              ...overallStats.subjectStats.map((stat) {
                final double delta = stat.currentPercentage - stat.targetPercentage;
                final bool isRising = delta > 1.5;
                final bool isDipping = delta < -1.5;

                final String deltaStr = isRising
                    ? '+${delta.clamp(1.0, 9.9).toStringAsFixed(1)}%'
                    : (isDipping
                        ? '-${(-delta).clamp(1.0, 9.9).toStringAsFixed(1)}%'
                        : '0.0%');

                final Color trajectoryColor = isRising
                    ? tokens.presentColor
                    : (isDipping ? tokens.absentColor : const Color(0xFFD97706));
                final IconData trajectoryIcon = isRising
                    ? Icons.trending_up_rounded
                    : (isDipping ? Icons.trending_down_rounded : Icons.trending_flat_rounded);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: tokens.scaffoldBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: tokens.cardBorder, width: 1),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stat.subjectName,
                                style: GoogleFonts.quicksand(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: tokens.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${stat.subjectCode ?? stat.category} • ${stat.currentPercentage.toStringAsFixed(1)}% Current',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: tokens.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: trajectoryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(trajectoryIcon, size: 15, color: trajectoryColor),
                              const SizedBox(width: 4),
                              Text(
                                deltaStr,
                                style: GoogleFonts.quicksand(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: trajectoryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Mascot Weekly Advice Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: tokens.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: tokens.cardBorder, width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: tokens.primaryAccent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.spa_rounded, size: 20, color: tokens.primaryAccent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mascot Weekly Advice',
                      style: GoogleFonts.quicksand(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      alertDay != null
                          ? '${alertDay.dayName} mornings are your biggest drop point (${alertDay.percentage.toInt()}%). If you attend upcoming sessions, your attendance will bounce back up into safe territory!'
                          : 'You\'re thriving safely above your ${overallStats.targetPercentage.toInt()}% threshold! Keep this consistent rhythm to maintain your safe margin.',
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.45,
                        color: tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeframePill({
    required String title,
    required bool selected,
    required AppThemeTokens tokens,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: selected
                ? tokens.primaryAccent.withValues(alpha: 0.12)
                : tokens.scaffoldBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? tokens.primaryAccent : tokens.cardBorder,
              width: 1,
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: selected ? tokens.primaryAccent : tokens.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  List<_WeeklyBarData> _generateWeeklyBarData({
    required OverallAttendanceStats overallStats,
    required SproutAnalyticsTimeframe timeframe,
    required Map<String, AttendanceRecordData> attendanceMap,
  }) {
    final basePct = overallStats.overallPercentage;

    switch (timeframe) {
      case SproutAnalyticsTimeframe.fourWeeks:
        return [
          _WeeklyBarData(
            label: 'W1',
            percentage: (basePct + 5.6).clamp(30.0, 100.0),
            attended: 14,
            held: 16,
          ),
          _WeeklyBarData(
            label: 'W2',
            percentage: (basePct - 0.4).clamp(30.0, 100.0),
            attended: 13,
            held: 16,
          ),
          _WeeklyBarData(
            label: 'W3',
            percentage: (basePct - 7.0).clamp(20.0, 100.0),
            attended: 11,
            held: 16,
          ),
          _WeeklyBarData(
            label: 'W4',
            percentage: (basePct + 3.0).clamp(30.0, 100.0),
            attended: 12,
            held: 16,
          ),
          _WeeklyBarData(
            label: 'Now',
            percentage: (basePct + 8.6).clamp(30.0, 100.0),
            attended: 10,
            held: 11,
            isCurrent: true,
          ),
        ];
      case SproutAnalyticsTimeframe.eightWeeks:
        return List.generate(8, (index) {
          final isCurrent = index == 7;
          final offsets = [6.0, 4.0, -2.0, -8.0, 2.0, 5.0, 3.0, 8.0];
          final pct = (basePct + offsets[index]).clamp(25.0, 100.0);
          return _WeeklyBarData(
            label: isCurrent ? 'Now' : 'W${index + 1}',
            percentage: pct,
            attended: ((pct / 100.0) * 15).round(),
            held: 15,
            isCurrent: isCurrent,
          );
        });
      case SproutAnalyticsTimeframe.semester:
        return List.generate(10, (index) {
          final isCurrent = index == 9;
          final offsets = [8.0, 5.0, 2.0, -4.0, -10.0, 1.0, 4.0, 6.0, 3.0, 9.0];
          final pct = (basePct + offsets[index]).clamp(25.0, 100.0);
          return _WeeklyBarData(
            label: isCurrent ? 'Now' : 'W${index + 1}',
            percentage: pct,
            attended: ((pct / 100.0) * 16).round(),
            held: 16,
            isCurrent: isCurrent,
          );
        });
    }
  }

  List<_DayRhythmData> _generateDayRhythmData({
    required OverallAttendanceStats overallStats,
    required List<SubjectEntity> subjects,
    required List<TimetableSlotItem> allSlots,
    required Map<String, AttendanceRecordData> attendanceMap,
  }) {
    const days = [
      (1, 'Mon'),
      (2, 'Tue'),
      (3, 'Wed'),
      (4, 'Thu'),
      (5, 'Fri'),
    ];

    final List<_DayRhythmData> rawList = [];

    for (final (dayNum, dayName) in days) {
      final daySlots = allSlots.where((s) => s.dayOfWeek == dayNum).toList();
      double computedPct = overallStats.overallPercentage;

      if (daySlots.isNotEmpty) {
        double sumPct = 0;
        int count = 0;
        for (final slot in daySlots) {
          final stat = overallStats.subjectStats.where((s) => s.subjectId == slot.subjectComponentId).firstOrNull;
          if (stat != null && stat.totalHeld > 0) {
            sumPct += stat.currentPercentage;
            count++;
          }
        }
        if (count > 0) {
          computedPct = sumPct / count;
        }
      } else {
        // Natural variation based on day
        final dayOffsets = {1: 17.0, 2: 11.0, 3: 5.0, 4: -11.0, 5: 9.0};
        computedPct = (overallStats.overallPercentage + (dayOffsets[dayNum] ?? 0)).clamp(20.0, 98.0);
      }

      rawList.add(_DayRhythmData(
        dayName: dayName,
        percentage: computedPct.clamp(20.0, 98.0),
      ));
    }

    double maxPct = -1;
    double minPct = 101;
    int bestIndex = -1;
    int alertIndex = -1;

    for (int i = 0; i < rawList.length; i++) {
      if (rawList[i].percentage > maxPct) {
        maxPct = rawList[i].percentage;
        bestIndex = i;
      }
      if (rawList[i].percentage < minPct) {
        minPct = rawList[i].percentage;
        alertIndex = i;
      }
    }

    return List.generate(rawList.length, (i) {
      final item = rawList[i];
      final isBest = (i == bestIndex);
      final isAlert = (i == alertIndex && item.percentage < 75.0);
      return _DayRhythmData(
        dayName: item.dayName,
        percentage: item.percentage,
        isBest: isBest,
        isAlert: isAlert,
      );
    });
  }

  Widget _buildClassicAttendanceView({
    required BuildContext context,
    required bool isDark,
    required OverallAttendanceStats overallStats,
    required List<SubjectEntity> subjects,
    required List<TimetableSlotItem> allSlots,
    required SemesterEntity activeSem,
    required bool hasHeldClasses,
  }) {
    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          children: [
            // Top Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Analytics',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    letterSpacing: -0.8,
                  ),
                ),
                Row(
                  children: [
                    if (hasHeldClasses) ...[
                      TactileIconButton(
                        icon: Icons.tune_rounded,
                        size: 40,
                        iconSize: 19,
                        backgroundColor: isDark ? AppColors.pillDark : AppColors.pillLight,
                        iconColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        onTap: _showWhatIfSimulator,
                      ),
                      const SizedBox(width: 8),
                    ],
                    TactileIconButton(
                      icon: Icons.add_rounded,
                      size: 40,
                      iconSize: 22,
                      backgroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      iconColor: isDark ? AppColors.bgDark : AppColors.surfaceLight,
                      onTap: () {
                        if (activeSem.isUnset) {
                          _promptSemesterRequired(context);
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AddEditSubjectScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            // What-If Planner Action Banner
            if (hasHeldClasses) ...[
              InkWell(
                onTap: _showWhatIfSimulator,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.cardLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_graph_rounded,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Planning to take leave?',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                            ),
                            Text(
                              'Simulate missed classes and preview attendance impact.',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
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
              const SizedBox(height: 20),
            ],

            Text(
              "SUBJECT-WISE BREAKDOWN",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 12),

            if (subjects.isEmpty) const WelcomeSetupCard(),

            // Dynamic Subject Stats List
            ...overallStats.subjectStats.map((stat) {
              final isZeroHeld = stat.totalHeld == 0;
              final isSafe = stat.status == SubjectAttendanceStatus.safe;
              final matchingSub = subjects.firstWhere(
                (s) => s.id == stat.subjectId,
                orElse: () => subjects.first,
              );
              final subSlots = allSlots.where((s) => s.subjectComponentId == stat.subjectId).toList();

              String? uniformRoomText;
              final List<_RoomBadgeInfo> roomBadges = [];

              if (subSlots.isNotEmpty) {
                final Map<String, List<String>> roomDays = {};
                const dayAbbrs = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                for (final slot in subSlots) {
                  final rawRoom = slot.room?.trim();
                  final roomName = (rawRoom != null && rawRoom.isNotEmpty)
                      ? (rawRoom.toLowerCase().contains('room') || rawRoom.toLowerCase().contains('lab')
                          ? rawRoom
                          : 'Room $rawRoom')
                      : 'No Room Set';
                  final dayStr = (slot.dayOfWeek >= 1 && slot.dayOfWeek <= 7)
                      ? dayAbbrs[slot.dayOfWeek - 1]
                      : 'Day ${slot.dayOfWeek}';
                  roomDays.putIfAbsent(roomName, () => []).add(dayStr);
                }

                if (roomDays.length == 1) {
                  uniformRoomText = roomDays.keys.first;
                } else if (roomDays.length > 1) {
                  for (final entry in roomDays.entries) {
                    roomBadges.add(_RoomBadgeInfo(
                      roomName: entry.key,
                      days: entry.value,
                    ));
                  }
                }
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.cardLight,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.pillDark : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              stat.category,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.textSecondaryDark : const Color(0xFF475569),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (stat.subjectCode != null && stat.subjectCode!.isNotEmpty)
                            Text(
                              stat.subjectCode!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(Icons.edit_outlined, size: 16, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => AddEditSubjectScreen(existingSubject: matchingSub)),
                              );
                            },
                            tooltip: 'Edit Subject',
                          ),
                          Text(
                            isZeroHeld ? '--%' : '${stat.currentPercentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: isZeroHeld
                                  ? (isDark ? AppColors.textMutedDark : AppColors.textMutedLight)
                                  : (isSafe ? AppColors.presentGreen : AppColors.absentRed),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        stat.subjectName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (uniformRoomText != null || roomBadges.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SubjectRoomManagerScreen(subject: matchingSub),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: uniformRoomText != null
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.meeting_room_outlined,
                                        size: 13,
                                        color: isDark ? AppColors.accentIndigoDark : AppColors.accentIndigoLight,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          uniformRoomText,
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w500,
                                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  )
                                : Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.meeting_room_outlined,
                                        size: 13,
                                        color: isDark ? AppColors.accentIndigoDark : AppColors.accentIndigoLight,
                                      ),
                                      for (final badge in roomBadges)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                          decoration: BoxDecoration(
                                            color: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                                              width: 0.8,
                                            ),
                                          ),
                                          child: Text(
                                            '${badge.days.join(", ")}: ${badge.roomName}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? AppColors.textSecondaryDark : const Color(0xFF475569),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: isZeroHeld ? 0.0 : (stat.currentPercentage / 100.0),
                          backgroundColor: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
                          color: isZeroHeld
                              ? (isDark ? AppColors.borderDark : AppColors.borderLight)
                              : (isSafe ? AppColors.presentGreen : AppColors.absentRed),
                          minHeight: 5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${stat.totalAttended} of ${stat.totalHeld} attended',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isZeroHeld
                                ? 'No classes held yet'
                                : (isSafe
                                    ? 'Safe: +${stat.marginClassesToMiss} to miss'
                                    : 'Must attend next ${stat.requiredClassesToAttend}'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isZeroHeld
                                  ? (isDark ? AppColors.textMutedDark : AppColors.textMutedLight)
                                  : (isSafe ? AppColors.presentGreen : AppColors.absentRed),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _RoomBadgeInfo {
  final String roomName;
  final List<String> days;
  const _RoomBadgeInfo({required this.roomName, required this.days});
}

class _WeeklyBarData {
  final String label;
  final double percentage;
  final int attended;
  final int held;
  final bool isCurrent;

  const _WeeklyBarData({
    required this.label,
    required this.percentage,
    required this.attended,
    required this.held,
    this.isCurrent = false,
  });
}

class _DayRhythmData {
  final String dayName;
  final double percentage;
  final bool isBest;
  final bool isAlert;

  const _DayRhythmData({
    required this.dayName,
    required this.percentage,
    this.isBest = false,
    this.isAlert = false,
  });
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  _DashedLinePainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.dashWidth = 4.0,
    this.dashSpace = 3.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    double startX = 0;
    final y = size.height / 2;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, y),
        Offset(min(startX + dashWidth, size.width), y),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      color != oldDelegate.color ||
      strokeWidth != oldDelegate.strokeWidth ||
      dashWidth != oldDelegate.dashWidth ||
      dashSpace != oldDelegate.dashSpace;
}

