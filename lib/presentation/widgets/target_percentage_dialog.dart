import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme_tokens.dart';
import '../../core/ui/app_toast.dart';
import '../providers/app_state_provider.dart';

/// Modern Modal Bottom Sheet for Attendance Target Setting
class TargetPercentageSheet extends ConsumerStatefulWidget {
  const TargetPercentageSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TargetPercentageSheet(),
    );
  }

  @override
  ConsumerState<TargetPercentageSheet> createState() => _TargetPercentageSheetState();
}

class _TargetPercentageSheetState extends ConsumerState<TargetPercentageSheet> {
  late double _selectedTarget;

  @override
  void initState() {
    super.initState();
    _selectedTarget = ref.read(targetPercentageProvider);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (tokens?.isCute == true) {
      return _buildSproutTargetSheet(context, tokens!, isDark);
    }
    return _buildClassicTargetSheet(context, isDark);
  }

  Widget _buildClassicTargetSheet(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
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

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Attendance Target',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, size: 20, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Target percentage used to calculate margin-to-miss and required classes.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 20),

          // Big Percentage Indicator + Preset Pills
          Center(
            child: Text(
              '${_selectedTarget.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Quick Preset Pills (65%, 75%, 80%, 85%)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [65.0, 75.0, 80.0, 85.0].map((preset) {
              final isSel = (_selectedTarget - preset).abs() < 0.1;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  onTap: () => setState(() => _selectedTarget = preset),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSel
                          ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                          : (isDark ? AppColors.pillDark : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${preset.toInt()}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                        color: isSel
                            ? (isDark ? AppColors.bgDark : AppColors.surfaceLight)
                            : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Slider
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              activeTrackColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              inactiveTrackColor: isDark ? AppColors.pillDark : const Color(0xFFE2E8F0),
              thumbColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: _selectedTarget,
              min: 50.0,
              max: 95.0,
              divisions: 45,
              onChanged: (val) => setState(() => _selectedTarget = val),
            ),
          ),
          const SizedBox(height: 16),

          // Save Action
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                foregroundColor: isDark ? AppColors.bgDark : AppColors.surfaceLight,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              onPressed: () {
                ref.read(targetPercentageProvider.notifier).setTarget(_selectedTarget);
                Navigator.pop(context);
                AppToast.success(context, 'Attendance target set to ${_selectedTarget.toStringAsFixed(1)}%');
              },
              child: const Text('Save Target', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSproutTargetSheet(BuildContext context, AppThemeTokens tokens, bool isDark) {
    final sheetBg = isDark ? const Color(0xFF1B3626) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF274C37) : const Color(0xFFE4ECE0);

    String statusLabel = 'STANDARD TARGET';
    if (_selectedTarget >= 85.0) {
      statusLabel = 'HONORS TARGET';
    } else if (_selectedTarget >= 80.0) {
      statusLabel = 'HIGH TARGET';
    } else if (_selectedTarget >= 75.0) {
      statusLabel = 'BALANCED TARGET';
    }

    return Container(
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
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF274C37) : const Color(0xFFD4DEC7),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Attendance Target',
                style: GoogleFonts.quicksand(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: tokens.textPrimary,
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
          const SizedBox(height: 4),
          Text(
            'Target percentage used to calculate margin-to-miss and required classes.',
            style: GoogleFonts.quicksand(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // Big Percentage Indicator + Dynamic Tag
          Center(
            child: Column(
              children: [
                Text(
                  '${_selectedTarget.toStringAsFixed(1)}%',
                  style: GoogleFonts.quicksand(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF163424) : const Color(0xFFEAF8E7),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isDark ? const Color(0xFF2C5B45) : const Color(0xFFD7F0D6),
                      width: 1.0,
                    ),
                  ),
                  child: Text(
                    statusLabel,
                    style: GoogleFonts.quicksand(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: isDark ? const Color(0xFF8BC34A) : const Color(0xFF1E6B3F),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Quick Preset Pills (65%, 75%, 80%, 85%, 90%)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [65.0, 75.0, 80.0, 85.0, 90.0].map((preset) {
              final isSel = (_selectedTarget - preset).abs() < 0.1;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedTarget = preset);
                  },
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSel
                          ? tokens.primaryAccent
                          : (isDark ? const Color(0xFF163424) : const Color(0xFFF0F6EE)),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isSel
                            ? tokens.primaryAccent
                            : (isDark ? const Color(0xFF274C37) : const Color(0xFFE4ECE0)),
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      '${preset.toInt()}%',
                      style: GoogleFonts.quicksand(
                        fontSize: 12,
                        fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                        color: isSel
                            ? (isDark ? const Color(0xFF0F2618) : Colors.white)
                            : tokens.textPrimary,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Continuous Slider with Steppers Row
          Row(
            children: [
              IconButton(
                icon: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF163424) : const Color(0xFFF0F6EE),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: cardBorder, width: 0.8),
                  ),
                  child: Icon(Icons.remove_rounded, size: 18, color: tokens.textPrimary),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: _selectedTarget > 50.0
                    ? () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedTarget = (_selectedTarget - 1.0).clamp(50.0, 95.0);
                        });
                      }
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 6,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                    activeTrackColor: tokens.primaryAccent,
                    inactiveTrackColor: isDark ? const Color(0xFF274C37) : const Color(0xFFE2EAE0),
                    thumbColor: tokens.primaryAccent,
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                  ),
                  child: Slider(
                    value: _selectedTarget,
                    min: 50.0,
                    max: 95.0,
                    divisions: 90,
                    onChanged: (val) {
                      setState(() => _selectedTarget = (val * 2).round() / 2);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF163424) : const Color(0xFFF0F6EE),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: cardBorder, width: 0.8),
                  ),
                  child: Icon(Icons.add_rounded, size: 18, color: tokens.textPrimary),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: _selectedTarget < 95.0
                    ? () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedTarget = (_selectedTarget + 1.0).clamp(50.0, 95.0);
                        });
                      }
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Save Action
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: tokens.primaryAccent,
                foregroundColor: isDark ? const Color(0xFF0F2618) : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                ref.read(targetPercentageProvider.notifier).setTarget(_selectedTarget);
                Navigator.pop(context);
                AppToast.success(context, 'Attendance target set to ${_selectedTarget.toStringAsFixed(1)}%');
              },
              child: Text(
                'Save Target',
                style: GoogleFonts.quicksand(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
