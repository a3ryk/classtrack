import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme_tokens.dart';
import '../../core/utils/date_formatter.dart';
import '../../domain/entities/class_session_entity.dart';
import 'cancellation_reason_dialog.dart';
import 'class_note_dialog.dart';

class ClassInfoSliderSheet extends StatelessWidget {
  final ClassSessionEntity session;

  const ClassInfoSliderSheet({
    super.key,
    required this.session,
  });

  static Future<void> show(BuildContext context, ClassSessionEntity session) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ClassInfoSliderSheet(session: session),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>();
    final isCute = tokens?.isCute ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isCute && tokens != null) {
      return _buildSproutInfoSheet(context, tokens, isDark);
    }
    return _buildClassicInfoSheet(context, isDark);
  }

  Widget _buildClassicInfoSheet(BuildContext context, bool isDark) {
    final hasCancellationReason = session.cancellationReason != null &&
        session.cancellationReason!.trim().isNotEmpty;
    final hasNote = session.notes != null && session.notes!.trim().isNotEmpty;

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
        MediaQuery.of(context).padding.bottom + 20,
      ),
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

          // Header with Subject & Timing
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.subjectName,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${DateFormatter.formatTime12h(session.startTime)} – ${DateFormatter.formatTime12h(session.endTime)}${session.room != null && session.room!.isNotEmpty ? " • Room ${session.room}" : ""}',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _buildClassicOutcomePill(isDark),
            ],
          ),
          const SizedBox(height: 18),

          // Cancellation Reason Card
          if (hasCancellationReason) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cancelledContainerDark : AppColors.cancelledContainerLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? const Color(0xFF4C1D95) : const Color(0xFFDDD6FE),
                  width: 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 14,
                            color: isDark ? AppColors.cancelledVioletDark : AppColors.cancelledVioletText,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'CANCELLATION REASON',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: isDark ? AppColors.cancelledVioletDark : AppColors.cancelledVioletText,
                            ),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          CancellationReasonDialog.show(
                            context,
                            sessionId: session.id,
                            slotId: session.sourceRefId ?? session.id,
                            subjectId: session.subjectComponentId,
                            sessionDate: session.sessionDate,
                            subjectName: session.subjectName,
                            initialReason: session.cancellationReason,
                          );
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Text(
                            'Edit',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.cancelledVioletDark : AppColors.cancelledVioletText,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    session.cancellationReason!,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Class Note Card
          if (hasNote) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                  width: 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.note_alt_outlined,
                            size: 14,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'CLASS NOTE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            ),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          ClassNoteDialog.show(context, session: session);
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Text(
                            'Edit',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.accentIndigoDark : AppColors.accentBlue,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    session.notes!,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Fallback if neither exists
          if (!hasCancellationReason && !hasNote) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No notes or cancellation details recorded for this class.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ),
            ),
          ],

          // Classic Actions Row
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    'Close',
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
                  onPressed: () {
                    Navigator.pop(context);
                    if (session.attendanceOutcome == 'CANCELLED') {
                      CancellationReasonDialog.show(
                        context,
                        sessionId: session.id,
                        slotId: session.sourceRefId ?? session.id,
                        subjectId: session.subjectComponentId,
                        sessionDate: session.sessionDate,
                        subjectName: session.subjectName,
                        initialReason: session.cancellationReason,
                      );
                    } else {
                      ClassNoteDialog.show(context, session: session);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppColors.pillDark : AppColors.primaryLight,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    session.attendanceOutcome == 'CANCELLED' ? 'Edit Reason' : 'Edit Note',
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClassicOutcomePill(bool isDark) {
    Color bg;
    Color border;
    Color text;
    String label;

    switch (session.attendanceOutcome) {
      case 'PRESENT':
        bg = isDark ? AppColors.presentContainerDark : AppColors.presentContainerLight;
        border = isDark ? AppColors.presentGreenDark : AppColors.presentGreen;
        text = isDark ? AppColors.presentGreenDark : AppColors.presentGreenText;
        label = 'Present';
        break;
      case 'ABSENT':
        bg = isDark ? AppColors.absentContainerDark : AppColors.absentContainerLight;
        border = isDark ? AppColors.absentRedDark : AppColors.absentRed;
        text = isDark ? AppColors.absentRedDark : AppColors.absentRedText;
        label = 'Absent';
        break;
      case 'CANCELLED':
        bg = isDark ? AppColors.cancelledContainerDark : AppColors.cancelledContainerLight;
        border = isDark ? AppColors.cancelledVioletDark : AppColors.cancelledViolet;
        text = isDark ? AppColors.cancelledVioletDark : AppColors.cancelledVioletText;
        label = 'Cancelled';
        break;
      default:
        bg = isDark ? AppColors.pillDark : const Color(0xFFF1F5F9);
        border = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);
        text = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
        label = 'Pending';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border.withValues(alpha: 0.5), width: 1.0),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: text,
        ),
      ),
    );
  }

  Widget _buildSproutInfoSheet(BuildContext context, AppThemeTokens tokens, bool isDark) {
    final hasCancellationReason = session.cancellationReason != null &&
        session.cancellationReason!.trim().isNotEmpty;
    final hasNote = session.notes != null && session.notes!.trim().isNotEmpty;

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
        MediaQuery.of(context).padding.bottom + 20,
      ),
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

          // Header with Subject & Timing
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.subjectName,
                      style: GoogleFonts.quicksand(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${session.startTime} – ${session.endTime}${session.room != null && session.room!.isNotEmpty ? " • Room ${session.room}" : ""}',
                      style: GoogleFonts.quicksand(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Outcome Pill
              _buildOutcomePill(tokens, isDark),
            ],
          ),
          const SizedBox(height: 18),

          // Cancellation Reason Card (Lavender tint)
          if (hasCancellationReason) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2E1A47).withValues(alpha: 0.65)
                    : const Color(0xFFF3E8FF),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF7C3AED).withValues(alpha: 0.4)
                      : const Color(0xFFD8B4FE),
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: isDark
                            ? const Color(0xFFC084FC)
                            : const Color(0xFF7C3AED),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Cancellation Reason',
                        style: GoogleFonts.quicksand(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? const Color(0xFFC084FC)
                              : const Color(0xFF7C3AED),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    session.cancellationReason!,
                    style: GoogleFonts.quicksand(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: tokens.textPrimary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Class Note Card (Sage Green tint)
          if (hasNote) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1B382B).withValues(alpha: 0.5)
                    : const Color(0xFFEBF2E8),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF2E5A36).withValues(alpha: 0.6)
                      : const Color(0xFFA7F3A0),
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.edit_note_rounded,
                        size: 18,
                        color: isDark
                            ? const Color(0xFF68D391)
                            : const Color(0xFF2E5A36),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Class Note',
                        style: GoogleFonts.quicksand(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? const Color(0xFF68D391)
                              : const Color(0xFF2E5A36),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    session.notes!,
                    style: GoogleFonts.quicksand(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: tokens.textPrimary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // If neither exists (fallback empty state)
          if (!hasCancellationReason && !hasNote) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No notes or cancellation details recorded for this class.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.quicksand(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: tokens.textSecondary,
                  ),
                ),
              ),
            ),
          ],

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    side: BorderSide(color: tokens.cardBorder, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Close',
                    style: GoogleFonts.quicksand(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: tokens.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (session.attendanceOutcome == 'CANCELLED') {
                      CancellationReasonDialog.show(
                        context,
                        sessionId: session.id,
                        slotId: session.sourceRefId ?? session.id,
                        subjectId: session.subjectComponentId,
                        sessionDate: session.sessionDate,
                        subjectName: session.subjectName,
                        initialReason: session.cancellationReason,
                      );
                    } else {
                      ClassNoteDialog.show(
                        context,
                        session: session,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tokens.primaryAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    session.attendanceOutcome == 'CANCELLED' ? 'Edit Reason' : 'Edit Note',
                    style: GoogleFonts.quicksand(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOutcomePill(AppThemeTokens tokens, bool isDark) {
    Color bg;
    Color border;
    Color text;
    String label;

    switch (session.attendanceOutcome) {
      case 'PRESENT':
        bg = isDark ? const Color(0xFF143320) : const Color(0xFFE8F5E9);
        border = const Color(0xFF2E7D32);
        text = isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32);
        label = 'Present';
        break;
      case 'ABSENT':
        bg = isDark ? const Color(0xFF3B1515) : const Color(0xFFFFEBEE);
        border = const Color(0xFFD32F2F);
        text = isDark ? const Color(0xFFEF9A9A) : const Color(0xFFC62828);
        label = 'Absent';
        break;
      case 'CANCELLED':
        bg = isDark ? const Color(0xFF2E1A47) : const Color(0xFFF3E8FF);
        border = const Color(0xFF7C3AED);
        text = isDark ? const Color(0xFFC084FC) : const Color(0xFF7C3AED);
        label = 'Cancelled';
        break;
      default:
        bg = isDark ? const Color(0xFF1E2D24) : const Color(0xFFF0EFEA);
        border = tokens.cardBorder;
        text = tokens.textSecondary;
        label = 'Pending';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border.withValues(alpha: 0.6), width: 1.2),
      ),
      child: Text(
        label,
        style: GoogleFonts.quicksand(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: text,
        ),
      ),
    );
  }
}
