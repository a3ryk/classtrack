import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/ui/tactile_button.dart';
import '../../../domain/entities/attendance_stats.dart';
import '../../../domain/services/attendance_math.dart';
import '../../providers/app_state_provider.dart';
import '../../widgets/add_subject_dialog.dart';
import '../../widgets/welcome_setup_card.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overallStats = ref.watch(overallStatsProvider);
    final subjects = ref.watch(subjectsProvider);

    final bool hasHeldClasses = subjects.isNotEmpty && overallStats.subjectStats.any((s) => s.totalHeld > 0);

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
                        showDialog(context: context, builder: (context) => const AddSubjectDialog());
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
                              showDialog(
                                context: context,
                                builder: (context) => AddSubjectDialog(existingSubject: matchingSub),
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
                          Text(
                            '${stat.totalAttended} of ${stat.totalHeld} attended',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
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
