import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/services/attendance_formula_engine.dart';
import '../../providers/formula_provider.dart';

class FormulaSettingsScreen extends ConsumerWidget {
  const FormulaSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final config = ref.watch(formulaConfigProvider);
    final notifier = ref.read(formulaConfigProvider.notifier);

    // Live Sandbox Calculation
    final samplePct = AttendanceFormulaEngine.calculatePercentage(
      attended: 27,
      held: 32,
      dutyLeave: 2,
      cancelled: 1,
      config: config,
    );
    final sampleMargin = AttendanceFormulaEngine.calculateClassesCanMiss(
      attended: 27,
      held: 32,
      dutyLeave: 2,
      cancelled: 1,
      targetPct: 75.0,
      config: config,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Formula & Calculation'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Live Formula Sandbox Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calculate_outlined, size: 18, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                    const SizedBox(width: 8),
                    Text(
                      'LIVE FORMULA SANDBOX PREVIEW',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sample: 27 Attended / 32 Held (+2 OD Leave)',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Formula Result: $samplePct%',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.presentGreenDark : AppColors.presentGreenLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.presentContainerDark : AppColors.presentContainerLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Safe: +$sampleMargin to miss',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.presentGreenDark : AppColors.presentGreenLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Formula Rules & Toggles
          Text(
            "CREDIT RULES & ADJUSTMENTS",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Credit Official Duty (OD) & Medical Leave', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  subtitle: const Text('Approved leave added to Attended count', style: TextStyle(fontSize: 11)),
                  value: config.includeDutyLeaveInPresent,
                  onChanged: (val) => notifier.toggleDutyLeave(val),
                ),
                Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),
                SwitchListTile(
                  title: const Text('Credit Teacher-Cancelled Classes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  subtitle: const Text('Cancelled sessions credited as Attended', style: TextStyle(fontSize: 11)),
                  value: config.creditCancelledAsPresent,
                  onChanged: (val) => notifier.toggleCreditCancelled(val),
                ),
                Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),
                ListTile(
                  title: const Text('Institutional Grace Classes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  subtitle: Text('${config.graceClassesCount} grace point classes added', style: const TextStyle(fontSize: 11)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
                        onPressed: config.graceClassesCount > 0 ? () => notifier.setGraceClasses(config.graceClassesCount - 1) : null,
                      ),
                      Text('${config.graceClassesCount}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                        onPressed: () => notifier.setGraceClasses(config.graceClassesCount + 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Category Specific Attendance Target Thresholds
          Text(
            "CATEGORY TARGET REQUIREMENTS",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Column(
              children: config.categoryTargets.entries.map((entry) {
                final category = entry.key;
                final target = entry.value;

                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$category Requirement:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                        ),
                        Text(
                          '${target.toStringAsFixed(1)}%',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                        ),
                      ],
                    ),
                    Slider(
                      value: target,
                      min: 50.0,
                      max: 95.0,
                      divisions: 45,
                      activeColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      inactiveColor: isDark ? AppColors.borderDark : AppColors.borderLight,
                      label: '${target.toStringAsFixed(1)}%',
                      onChanged: (val) => notifier.setCategoryTarget(category, val),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
