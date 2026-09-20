import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme_tokens.dart';
import '../../core/ui/app_toast.dart';
import '../../core/utils/date_formatter.dart';
import '../../domain/entities/semester_entity.dart';
import '../providers/app_state_provider.dart';

/// Modal bottom sheet displaying read-only final performance metrics and report card for an archived semester.
class ArchivedSemesterReportSheet extends ConsumerWidget {
  final SemesterEntity semester;

  const ArchivedSemesterReportSheet({
    super.key,
    required this.semester,
  });

  static Future<void> show(BuildContext context, SemesterEntity semester) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ArchivedSemesterReportSheet(semester: semester),
    );
  }

  void _confirmReactivation(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).extension<AppThemeTokens>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (tokens?.isCute == true) {
      _showSproutReactivateDialog(context, ref, tokens!, isDark);
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          'Reactivate ${semester.name}?',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This will set "${semester.name}" as your active operational semester. Your Today schedule, timetable view, and notification alarms will switch to this term.',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              foregroundColor: isDark ? AppColors.bgDark : AppColors.surfaceLight,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(activeSemesterProvider.notifier).updateSemester(semester);
              await ref.read(semestersListProvider.notifier).loadFromDb();
              if (context.mounted) {
                Navigator.pop(context);
                AppToast.success(context, 'Switched active term to ${semester.name}');
              }
            },
            child: const Text('Reactivate Term'),
          ),
        ],
      ),
    );
  }

  void _showSproutReactivateDialog(
    BuildContext context,
    WidgetRef ref,
    AppThemeTokens tokens,
    bool isDark,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF193223) : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: isDark ? const Color(0xFF284F37) : const Color(0xFFE4ECE0)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF234631) : const Color(0xFFEDF5E9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.history_rounded,
                size: 18,
                color: tokens.primaryAccent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Reactivate ${semester.name}?',
                style: GoogleFonts.quicksand(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: tokens.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'This will set "${semester.name}" as your active operational semester. Today schedule and timetable views will switch to this term.',
          style: GoogleFonts.quicksand(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: tokens.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.quicksand(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: tokens.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: tokens.primaryAccent,
              foregroundColor: isDark ? const Color(0xFF102016) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(activeSemesterProvider.notifier).updateSemester(semester);
              await ref.read(semestersListProvider.notifier).loadFromDb();
              if (context.mounted) {
                Navigator.pop(context);
                AppToast.success(context, 'Switched active term to ${semester.name}');
              }
            },
            child: Text(
              'Reactivate Term',
              style: GoogleFonts.quicksand(
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).extension<AppThemeTokens>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statsAsync = ref.watch(archivedSemesterStatsProvider(semester.id));

    if (tokens?.isCute == true) {
      return _buildSproutArchivedReportSheet(context, ref, tokens!, isDark, statsAsync);
    }
    return _buildClassicArchivedReportSheet(context, ref, isDark, statsAsync);
  }

  Widget _buildClassicArchivedReportSheet(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    AsyncValue statsAsync,
  ) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            semester.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              letterSpacing: -0.4,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.pillDark : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'ARCHIVED',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${semester.termType.displayName} · ${DateFormatter.formatDateIndian(semester.startDate)} to ${semester.endDate != null ? DateFormatter.formatDateIndian(semester.endDate!) : "Continuous"}',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Body: Loading / Error / Data
          Flexible(
            child: statsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Failed to load archived metrics: $err',
                    style: const TextStyle(color: AppColors.absentRed, fontSize: 12),
                  ),
                ),
              ),
              data: (stats) {
                final isZeroHeld = stats.totalHeld == 0;
                final pct = stats.overallPercentage;
                final isSafe = pct >= stats.targetPercentage;

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Overall Metric Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.pillDark : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'FINAL ATTENDANCE',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.6,
                                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text(
                                          isZeroHeld ? 'N/A' : '${pct.toStringAsFixed(1)}%',
                                          style: TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w900,
                                            color: isZeroHeld
                                                ? (isDark ? AppColors.textMutedDark : AppColors.textMutedLight)
                                                : (isSafe
                                                    ? (isDark ? AppColors.presentGreenDark : AppColors.presentGreenText)
                                                    : (isDark ? AppColors.absentRedDark : AppColors.absentRed)),
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Target: ${stats.targetPercentage.toInt()}%',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isZeroHeld
                                        ? (isDark ? AppColors.pillDark : const Color(0xFFE2E8F0))
                                        : (isSafe
                                            ? (isDark ? AppColors.presentContainerDark : AppColors.presentContainerLight)
                                            : (isDark ? AppColors.absentContainerDark : AppColors.absentContainerLight)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isZeroHeld
                                        ? 'NO RECORDS'
                                        : (isSafe ? 'TARGET MET' : 'BELOW TARGET'),
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                      color: isZeroHeld
                                          ? (isDark ? AppColors.textMutedDark : AppColors.textMutedLight)
                                          : (isSafe
                                              ? (isDark ? AppColors.presentGreenDark : AppColors.presentGreenText)
                                              : (isDark ? AppColors.absentRedDark : AppColors.absentRed)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            // Metrics Grid
                            Row(
                              children: [
                                _buildMetricChip(context, 'Held', '${stats.totalHeld}', isDark),
                                const SizedBox(width: 6),
                                _buildMetricChip(context, 'Attended', '${stats.totalAttended}', isDark),
                                const SizedBox(width: 6),
                                _buildMetricChip(context, 'Missed', '${stats.totalHeld - stats.totalAttended}', isDark),
                                const SizedBox(width: 6),
                                _buildMetricChip(context, 'Cancelled', '${stats.totalCancelled}', isDark),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Subjects Section Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'SUBJECT PERFORMANCE (${stats.subjectStats.length})',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Subject Breakdown List
                      if (stats.subjectStats.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          alignment: Alignment.center,
                          child: Text(
                            'No subjects registered for this semester',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: stats.subjectStats.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (context, idx) {
                            final sub = stats.subjectStats[idx];
                            final subSafe = sub.currentPercentage >= sub.targetPercentage;
                            final Color dotColor = _parseColorHex(sub.colorHex);

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.pillDark : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Subject color indicator
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: dotColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          sub.subjectName,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${sub.totalAttended}/${sub.totalHeld} attended',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Percentage Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: sub.totalHeld == 0
                                          ? (isDark ? AppColors.pillDark : const Color(0xFFE2E8F0))
                                          : (subSafe
                                              ? (isDark ? AppColors.presentContainerDark : AppColors.presentContainerLight)
                                              : (isDark ? AppColors.absentContainerDark : AppColors.absentContainerLight)),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      sub.totalHeld == 0 ? '--%' : '${sub.currentPercentage.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: sub.totalHeld == 0
                                            ? (isDark ? AppColors.textMutedDark : AppColors.textMutedLight)
                                            : (subSafe
                                                ? (isDark ? AppColors.presentGreenDark : AppColors.presentGreenText)
                                                : (isDark ? AppColors.absentRedDark : AppColors.absentRed)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Bottom Action: Reactivate Term Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.history_rounded, size: 16),
              label: const Text(
                'Reactivate as Operational Term',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                side: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => _confirmReactivation(context, ref),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip(BuildContext context, String label, String value, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColorHex(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('0xFF$clean'));
    } catch (_) {
      return AppColors.accentIndigoLight;
    }
  }

  Widget _buildSproutArchivedReportSheet(
    BuildContext context,
    WidgetRef ref,
    AppThemeTokens tokens,
    bool isDark,
    AsyncValue statsAsync,
  ) {
    final sheetBg = isDark ? const Color(0xFF193223) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF284F37) : const Color(0xFFE4ECE0);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: cardBorder, width: 1.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF284F37) : const Color(0xFFD4DEC7),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            semester.name,
                            style: GoogleFonts.quicksand(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: tokens.textPrimary,
                              letterSpacing: -0.3,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF203D2B) : const Color(0xFFF0F4EC),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'ARCHIVED',
                            style: GoogleFonts.quicksand(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: tokens.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${semester.termType.displayName} · ${DateFormatter.formatDateIndian(semester.startDate)} to ${semester.endDate != null ? DateFormatter.formatDateIndian(semester.endDate!) : "Continuous"}',
                      style: GoogleFonts.quicksand(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: tokens.textSecondary,
                ),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Body: Loading / Error / Data
          Flexible(
            child: statsAsync.when(
              loading: () => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: CircularProgressIndicator(strokeWidth: 2, color: tokens.primaryAccent),
                ),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Failed to load archived metrics: $err',
                    style: GoogleFonts.quicksand(color: isDark ? const Color(0xFFEF6A66) : const Color(0xFFD9534F), fontSize: 12),
                  ),
                ),
              ),
              data: (stats) {
                final isZeroHeld = stats.totalHeld == 0;
                final pct = stats.overallPercentage;
                final isSafe = pct >= stats.targetPercentage;

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Overall Metric Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF203F2C) : const Color(0xFFF8FAF5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: cardBorder,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'FINAL ATTENDANCE',
                                        style: GoogleFonts.quicksand(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.8,
                                          color: tokens.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Wrap(
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        spacing: 8,
                                        runSpacing: 2,
                                        children: [
                                          Text(
                                            isZeroHeld ? 'N/A' : '${pct.toStringAsFixed(1)}%',
                                            style: GoogleFonts.quicksand(
                                              fontSize: 28,
                                              fontWeight: FontWeight.w800,
                                              color: isZeroHeld
                                                  ? tokens.textSecondary
                                                  : (isSafe
                                                      ? tokens.primaryAccent
                                                      : (isDark ? const Color(0xFFEF6A66) : const Color(0xFFD9534F))),
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                          Text(
                                            'Target: ${stats.targetPercentage.toInt()}%',
                                            style: GoogleFonts.quicksand(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: tokens.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isZeroHeld
                                        ? (isDark ? const Color(0xFF203D2B) : const Color(0xFFF0F4EC))
                                        : (isSafe
                                            ? (isDark ? const Color(0xFF234631) : const Color(0xFFEDF5E9))
                                            : (isDark ? const Color(0xFF381E1E) : const Color(0xFFFDF2F2))),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isZeroHeld
                                        ? 'NO RECORDS'
                                        : (isSafe ? 'TARGET MET' : 'BELOW TARGET'),
                                    style: GoogleFonts.quicksand(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                      color: isZeroHeld
                                          ? tokens.textSecondary
                                          : (isSafe
                                              ? tokens.primaryAccent
                                              : (isDark ? const Color(0xFFEF6A66) : const Color(0xFFD9534F))),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            // Metrics Grid
                            Row(
                              children: [
                                _buildSproutMetricChip(context, 'Held', '${stats.totalHeld}', tokens, isDark),
                                const SizedBox(width: 6),
                                _buildSproutMetricChip(context, 'Attended', '${stats.totalAttended}', tokens, isDark),
                                const SizedBox(width: 6),
                                _buildSproutMetricChip(context, 'Missed', '${stats.totalHeld - stats.totalAttended}', tokens, isDark),
                                const SizedBox(width: 6),
                                _buildSproutMetricChip(context, 'Cancelled', '${stats.totalCancelled}', tokens, isDark),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Subjects Section Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'SUBJECT PERFORMANCE (${stats.subjectStats.length})',
                            style: GoogleFonts.quicksand(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: tokens.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Subject Breakdown List
                      if (stats.subjectStats.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          alignment: Alignment.center,
                          child: Text(
                            'No subjects registered for this semester',
                            style: GoogleFonts.quicksand(
                              fontSize: 12,
                              color: tokens.textSecondary,
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: stats.subjectStats.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (context, idx) {
                            final sub = stats.subjectStats[idx];
                            final subSafe = sub.currentPercentage >= sub.targetPercentage;
                            final Color dotColor = _parseColorHex(sub.colorHex);

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF203F2C) : const Color(0xFFF8FAF5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: cardBorder,
                                  width: 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Subject color indicator
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: dotColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          sub.subjectName,
                                          style: GoogleFonts.quicksand(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: tokens.textPrimary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${sub.totalAttended}/${sub.totalHeld} attended',
                                          style: GoogleFonts.quicksand(
                                            fontSize: 11,
                                            color: tokens.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Percentage Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: sub.totalHeld == 0
                                          ? (isDark ? const Color(0xFF203D2B) : const Color(0xFFF0F4EC))
                                          : (subSafe
                                              ? (isDark ? const Color(0xFF234631) : const Color(0xFFEDF5E9))
                                              : (isDark ? const Color(0xFF381E1E) : const Color(0xFFFDF2F2))),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      sub.totalHeld == 0 ? '--%' : '${sub.currentPercentage.toStringAsFixed(1)}%',
                                      style: GoogleFonts.quicksand(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: sub.totalHeld == 0
                                            ? tokens.textSecondary
                                            : (subSafe
                                                ? tokens.primaryAccent
                                                : (isDark ? const Color(0xFFEF6A66) : const Color(0xFFD9534F))),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Bottom Action: Reactivate Term Button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.history_rounded, size: 16),
              label: Text(
                'Reactivate as Operational Term',
                style: GoogleFonts.quicksand(fontSize: 13, fontWeight: FontWeight.w800),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: tokens.textPrimary,
                side: BorderSide(color: cardBorder, width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => _confirmReactivation(context, ref),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSproutMetricChip(BuildContext context, String label, String value, AppThemeTokens tokens, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF193223) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isDark ? const Color(0xFF284F37) : const Color(0xFFE4ECE0)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.quicksand(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: tokens.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.quicksand(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: tokens.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
