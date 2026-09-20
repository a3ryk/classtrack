import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_theme_tokens.dart';
import '../../domain/services/attendance_math.dart';
import '../providers/app_state_provider.dart';

enum WhatIfMode {
  miss,
  attend,
}

class SproutWhatIfSimulatorSheet extends ConsumerStatefulWidget {
  const SproutWhatIfSimulatorSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SproutWhatIfSimulatorSheet(),
    );
  }

  @override
  ConsumerState<SproutWhatIfSimulatorSheet> createState() => _SproutWhatIfSimulatorSheetState();
}

class _SproutWhatIfSimulatorSheetState extends ConsumerState<SproutWhatIfSimulatorSheet> {
  WhatIfMode _mode = WhatIfMode.miss;
  int _sessionCount = 2;

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
    final tokens = Theme.of(context).extension<AppThemeTokens>() ??
        (isDark ? AppThemeTokens.cuteSproutDark : AppThemeTokens.cuteSproutLight);

    final overallStats = ref.watch(overallStatsProvider);
    final isMiss = _mode == WhatIfMode.miss;

    // Calculate projected overall stats
    int sumHeld = 0;
    int sumAttended = 0;

    for (final stat in overallStats.subjectStats) {
      final newHeld = stat.totalHeld + _sessionCount;
      final newAttended = isMiss ? stat.totalAttended : (stat.totalAttended + _sessionCount);
      sumHeld += newHeld;
      sumAttended += newAttended;
    }

    final double projectedOverallPct = AttendanceMathService.calculatePercentage(sumAttended, sumHeld);
    final double overallDelta = projectedOverallPct - overallStats.overallPercentage;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: tokens.scaffoldBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle & Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: tokens.cardBorder,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: tokens.primaryAccent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.auto_graph_rounded,
                                size: 20,
                                color: tokens.primaryAccent,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'What-If Simulator',
                                style: GoogleFonts.quicksand(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                  color: tokens.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: tokens.textMuted, size: 22),
                        onPressed: () => Navigator.of(context).pop(),
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Scrollable Content
            Flexible(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  // Mode Selector Tabs (Miss vs Attend)
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
                              setState(() => _mode = WhatIfMode.miss);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                              decoration: BoxDecoration(
                                color: isMiss
                                    ? tokens.absentColor.withValues(alpha: isDark ? 0.25 : 0.12)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: isMiss
                                    ? Border.all(color: tokens.absentColor.withValues(alpha: 0.4), width: 1.2)
                                    : null,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.event_busy_rounded,
                                      size: 16,
                                      color: isMiss ? tokens.absentColor : tokens.textMuted,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Miss Classes',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isMiss ? FontWeight.w700 : FontWeight.w500,
                                        color: isMiss ? tokens.absentColor : tokens.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _mode = WhatIfMode.attend);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                              decoration: BoxDecoration(
                                color: !isMiss
                                    ? tokens.presentColor.withValues(alpha: isDark ? 0.25 : 0.12)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: !isMiss
                                    ? Border.all(color: tokens.presentColor.withValues(alpha: 0.4), width: 1.2)
                                    : null,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.event_available_rounded,
                                      size: 16,
                                      color: !isMiss ? tokens.presentColor : tokens.textMuted,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Attend Classes',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: !isMiss ? FontWeight.w700 : FontWeight.w500,
                                        color: !isMiss ? tokens.presentColor : tokens.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Session Stepper Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: tokens.cardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: tokens.cardBorder, width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isMiss ? 'Upcoming Classes to Miss' : 'Extra Classes to Attend',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: tokens.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isMiss
                                    ? 'Project leave across all scheduled subjects'
                                    : 'Project recovery from attending next sessions',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: tokens.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          children: [
                            _buildStepperButton(
                              icon: Icons.remove_rounded,
                              enabled: _sessionCount > 1,
                              onTap: () {
                                if (_sessionCount > 1) {
                                  HapticFeedback.lightImpact();
                                  setState(() => _sessionCount--);
                                }
                              },
                              tokens: tokens,
                              isDark: isDark,
                            ),
                            Container(
                              constraints: const BoxConstraints(minWidth: 42),
                              alignment: Alignment.center,
                              child: Text(
                                '$_sessionCount',
                                style: GoogleFonts.quicksand(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: tokens.textPrimary,
                                ),
                              ),
                            ),
                            _buildStepperButton(
                              icon: Icons.add_rounded,
                              enabled: _sessionCount < 15,
                              onTap: () {
                                if (_sessionCount < 15) {
                                  HapticFeedback.lightImpact();
                                  setState(() => _sessionCount++);
                                }
                              },
                              tokens: tokens,
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Overall Impact Hero Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isMiss
                          ? tokens.absentColor.withValues(alpha: isDark ? 0.16 : 0.08)
                          : tokens.presentColor.withValues(alpha: isDark ? 0.16 : 0.08),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isMiss
                            ? tokens.absentColor.withValues(alpha: 0.3)
                            : tokens.presentColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isMiss
                                ? tokens.absentColor.withValues(alpha: 0.2)
                                : tokens.presentColor.withValues(alpha: 0.2),
                          ),
                          child: Icon(
                            isMiss ? Icons.trending_down_rounded : Icons.trending_up_rounded,
                            color: isMiss ? tokens.absentColor : tokens.presentColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Overall Projected Attendance',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: tokens.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      '${overallStats.overallPercentage.toStringAsFixed(1)}%',
                                      style: GoogleFonts.quicksand(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: tokens.textSecondary,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 6),
                                      child: Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 14,
                                        color: tokens.textMuted,
                                      ),
                                    ),
                                    Text(
                                      '${projectedOverallPct.toStringAsFixed(1)}%',
                                      style: GoogleFonts.quicksand(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: isMiss
                                            ? (projectedOverallPct >= overallStats.targetPercentage
                                                ? tokens.textPrimary
                                                : tokens.absentColor)
                                            : tokens.presentColor,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isMiss
                                            ? tokens.absentColor.withValues(alpha: 0.18)
                                            : tokens.presentColor.withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${overallDelta >= 0 ? "+" : ""}${overallDelta.toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: isMiss ? tokens.absentColor : tokens.presentColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'SUBJECT-BY-SUBJECT PROJECTION',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: tokens.textMuted,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Subject Projections
                  ...overallStats.subjectStats.map((stat) {
                    final newHeld = stat.totalHeld + _sessionCount;
                    final newAttended = isMiss ? stat.totalAttended : (stat.totalAttended + _sessionCount);
                    final projectedPct = AttendanceMathService.calculatePercentage(newAttended, newHeld);
                    final isSafe = projectedPct >= stat.targetPercentage;
                    final delta = projectedPct - stat.currentPercentage;
                    final subColor = _parseColor(stat.colorHex, tokens.primaryAccent);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: tokens.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: tokens.cardBorder, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                              Expanded(
                                child: Text(
                                  stat.subjectName,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: tokens.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    '${stat.currentPercentage.toStringAsFixed(1)}%',
                                    style: GoogleFonts.quicksand(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: tokens.textMuted,
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 16,
                                    color: tokens.textMuted,
                                  ),
                                  Text(
                                    '${projectedPct.toStringAsFixed(1)}%',
                                    style: GoogleFonts.quicksand(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                      color: isSafe ? tokens.presentColor : tokens.absentColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: (projectedPct / 100.0).clamp(0.0, 1.0),
                              backgroundColor: tokens.cardBorder,
                              color: isSafe ? tokens.presentColor : tokens.absentColor,
                              minHeight: 4.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (isSafe ? tokens.presentColor : tokens.absentColor)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isSafe ? 'Target Met (>=${stat.targetPercentage.toInt()}%)' : 'Below Target',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: isSafe ? tokens.presentColor : tokens.absentColor,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(
                                    delta >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                                    size: 13,
                                    color: delta >= 0 ? tokens.presentColor : tokens.absentColor,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${delta >= 0 ? "+" : ""}${delta.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: delta >= 0 ? tokens.presentColor : tokens.absentColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Bottom CTA
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              decoration: BoxDecoration(
                color: tokens.cardBg,
                border: Border(top: BorderSide(color: tokens.cardBorder, width: 1)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tokens.primaryAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Done Simulating',
                    style: GoogleFonts.quicksand(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepperButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
    required AppThemeTokens tokens,
    required bool isDark,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: enabled
              ? (isDark ? tokens.cardBorder : tokens.scaffoldBg)
              : (isDark ? Colors.transparent : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled ? tokens.cardBorder : tokens.cardBorder.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? tokens.textPrimary : tokens.textMuted,
        ),
      ),
    );
  }
}
