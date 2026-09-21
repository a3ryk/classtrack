import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme_tokens.dart';
import '../providers/app_state_provider.dart';

class CancellationReasonDialog extends ConsumerStatefulWidget {
  final String sessionId;
  final String slotId;
  final String subjectId;
  final String sessionDate;
  final String subjectName;
  final String? initialReason;

  const CancellationReasonDialog({
    super.key,
    required this.sessionId,
    required this.slotId,
    required this.subjectId,
    required this.sessionDate,
    required this.subjectName,
    this.initialReason,
  });

  static Future<void> show(
    BuildContext context, {
    required String sessionId,
    required String slotId,
    required String subjectId,
    required String sessionDate,
    required String subjectName,
    String? initialReason,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CancellationReasonDialog(
        sessionId: sessionId,
        slotId: slotId,
        subjectId: subjectId,
        sessionDate: sessionDate,
        subjectName: subjectName,
        initialReason: initialReason,
      ),
    );
  }

  @override
  ConsumerState<CancellationReasonDialog> createState() => _CancellationReasonDialogState();
}

class _CancellationReasonDialogState extends ConsumerState<CancellationReasonDialog> {
  late TextEditingController _detailController;
  String? _selectedPreset;

  static const List<Map<String, String>> _presets = [
    {'title': 'Professor on Leave', 'emoji': '👨‍🏫'},
    {'title': 'College Event / Fest', 'emoji': '🎉'},
    {'title': 'Rain / Weather Holiday', 'emoji': '🌧️'},
    {'title': 'Official Holiday', 'emoji': '🏛️'},
    {'title': 'Rescheduled / Postponed', 'emoji': '🔄'},
    {'title': 'Other', 'emoji': '✏️'},
  ];

  @override
  void initState() {
    super.initState();
    _detailController = TextEditingController();

    if (widget.initialReason != null && widget.initialReason!.trim().isNotEmpty) {
      final initial = widget.initialReason!.trim();
      final matchingPreset = _presets.firstWhere(
        (p) => initial.startsWith(p['title']!),
        orElse: () => const {'title': '', 'emoji': ''},
      );
      if (matchingPreset['title']!.isNotEmpty) {
        _selectedPreset = matchingPreset['title'];
        final prefix = matchingPreset['title']!;
        if (initial.length > prefix.length) {
          final remainder = initial.substring(prefix.length).replaceAll(RegExp(r'^[\s:\-–—]+'), '');
          _detailController.text = remainder;
        }
      } else {
        _selectedPreset = 'Other';
        _detailController.text = initial;
      }
    } else {
      _selectedPreset = 'Professor on Leave';
    }
  }

  @override
  void dispose() {
    _detailController.dispose();
    super.dispose();
  }

  void _save({bool skip = false}) {
    String? reason;
    if (!skip) {
      final customDetail = _detailController.text.trim();
      if (_selectedPreset != null && _selectedPreset!.isNotEmpty) {
        if (_selectedPreset == 'Other') {
          reason = customDetail.isNotEmpty ? customDetail : 'Other Reason';
        } else {
          reason = customDetail.isNotEmpty
              ? '$_selectedPreset: $customDetail'
              : _selectedPreset;
        }
      } else if (customDetail.isNotEmpty) {
        reason = customDetail;
      }
    }

    ref.read(attendanceRecordsProvider.notifier).markAttendance(
      sessionId: widget.sessionId,
      slotId: widget.slotId,
      subjectId: widget.subjectId,
      sessionDate: widget.sessionDate,
      outcome: 'CANCELLED',
      cancellationReason: reason,
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>();
    final isCute = tokens?.isCute ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isCute && tokens != null) {
      return _buildSproutDialog(context, tokens, isDark);
    }
    return _buildClassicDialog(context, isDark);
  }

  Widget _buildClassicDialog(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title & Subject Info
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.cancelledContainerDark
                        : AppColors.cancelledContainerLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? const Color(0xFF4C1D95) : const Color(0xFFDDD6FE),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.event_busy_rounded,
                    size: 20,
                    color: isDark ? AppColors.cancelledVioletDark : AppColors.cancelledVioletText,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Class Cancelled',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.subjectName,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Section Label
            Text(
              'WHY WAS THIS CLASS CANCELLED?',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
            const SizedBox(height: 10),

            // Preset Reason Chips (Clean classic styling, no emoji)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presets.map((preset) {
                final isSelected = _selectedPreset == preset['title'];
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedPreset = preset['title'];
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? const Color(0xFF2E1065) : const Color(0xFFEDE9FE))
                          : (isDark ? AppColors.pillDark : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? (isDark ? const Color(0xFF8B5CF6) : const Color(0xFF7C3AED))
                            : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                        width: isSelected ? 1.3 : 1.0,
                      ),
                    ),
                    child: Text(
                      preset['title']!,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? (isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED))
                            : (isDark ? AppColors.textPrimaryDark : const Color(0xFF334155)),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Additional details input
            Text(
              'ADDITIONAL DETAILS (OPTIONAL)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _detailController,
              maxLines: 2,
              maxLength: 200,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
              decoration: InputDecoration(
                hintText: 'e.g. Announced on WhatsApp: practical postponed to Friday...',
                hintStyle: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
                filled: true,
                fillColor: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0), width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0), width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: isDark ? const Color(0xFF8B5CF6) : const Color(0xFF7C3AED), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _save(skip: true),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      'Skip Reason',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _save(skip: false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF7C3AED) : AppColors.cancelledViolet,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text(
                      'Save Reason',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSproutDialog(BuildContext context, AppThemeTokens tokens, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: tokens.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: tokens.cardBorder, width: 1.5),
          left: BorderSide(color: tokens.cardBorder, width: 1.5),
          right: BorderSide(color: tokens.cardBorder, width: 1.5),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
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
            const SizedBox(height: 16),

            // Title & Subject Info
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2E1A47)
                        : const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF7C3AED) : const Color(0xFFD8B4FE),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.cancel_schedule_send_rounded,
                    size: 20,
                    color: Color(0xFF7C3AED),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Class Cancelled',
                        style: GoogleFonts.quicksand(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: tokens.textPrimary,
                        ),
                      ),
                      Text(
                        widget.subjectName,
                        style: GoogleFonts.quicksand(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: tokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Section Label
            Text(
              'Why was this class cancelled?',
              style: GoogleFonts.quicksand(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: 10),

            // Preset Reason Chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presets.map((preset) {
                final isSelected = _selectedPreset == preset['title'];
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedPreset = preset['title'];
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? const Color(0xFF7C3AED).withValues(alpha: 0.3) : const Color(0xFFF3E8FF))
                          : (isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFFFAF7F2)),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF7C3AED)
                            : tokens.cardBorder,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(preset['emoji']!, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(
                          preset['title']!,
                          style: GoogleFonts.quicksand(
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected
                                ? (isDark ? const Color(0xFFC084FC) : const Color(0xFF7C3AED))
                                : tokens.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Additional details input
            Text(
              'Additional Details (Optional)',
              style: GoogleFonts.quicksand(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: tokens.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _detailController,
              maxLines: 2,
              maxLength: 200,
              style: GoogleFonts.quicksand(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: tokens.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'e.g. Announced on WhatsApp: practical postponed to Friday...',
                hintStyle: GoogleFonts.quicksand(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: tokens.textSecondary.withValues(alpha: 0.6),
                ),
                filled: true,
                fillColor: isDark
                    ? Colors.black.withValues(alpha: 0.25)
                    : const Color(0xFFFAF7F2),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: tokens.cardBorder, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: tokens.cardBorder, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _save(skip: true),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: BorderSide(color: tokens.cardBorder, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Skip Reason',
                      style: GoogleFonts.quicksand(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: tokens.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _save(skip: false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Save Reason',
                      style: GoogleFonts.quicksand(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
