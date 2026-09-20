import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme_tokens.dart';
import '../../core/utils/date_formatter.dart';
import '../../domain/entities/class_session_entity.dart';
import '../providers/app_state_provider.dart';

class TodayClassCard extends ConsumerWidget {
  final ClassSessionEntity session;
  final ValueChanged<String> onOutcomeChanged;
  final bool isFuture;
  final VoidCallback? onTap;

  const TodayClassCard({
    super.key,
    required this.session,
    required this.onOutcomeChanged,
    this.isFuture = false,
    this.onTap,
  });

  String? _getLiveStatus() {
    try {
      final now = DateTime.now();
      final todayIso = DateFormatter.toIsoDate(now);
      if (session.sessionDate != todayIso) return null;

      final startParts = session.startTime.split(':');
      final endParts = session.endTime.split(':');
      final startMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
      final nowMinutes = now.hour * 60 + now.minute;

      if (nowMinutes >= startMinutes && nowMinutes <= endMinutes) {
        final left = endMinutes - nowMinutes;
        return '🟢 In Progress · ${left == 0 ? "Ending now" : "Ends in ${left}m"}';
      } else if (nowMinutes < startMinutes && startMinutes - nowMinutes <= 60) {
        final mins = startMinutes - nowMinutes;
        return '🕒 Starts in ${mins}m';
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch realtime clock for live in-progress and countdown updates
    ref.watch(realtimeClockProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = Theme.of(context).extension<AppThemeTokens>();
    final isCute = tokens?.isCute ?? false;
    final cardRadius = isCute ? 20.0 : 14.0;
    final isHoliday = session.attendanceOutcome == 'HOLIDAY' || session.status == 'HOLIDAY';
    final liveStatus = (session.attendanceOutcome == 'CANCELLED' || isHoliday) ? null : _getLiveStatus();

    Color stripeColor;
    try {
      final hex = session.colorHex.replaceAll('#', '');
      stripeColor = Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      stripeColor = isCute ? const Color(0xFF7CB342) : AppColors.accentIndigoLight;
    }

    final String subtitleText = [
      '${DateFormatter.formatTime12h(session.startTime)} – ${DateFormatter.formatTime12h(session.endTime)}',
      if (session.room != null && session.room!.isNotEmpty)
        (session.room!.toLowerCase().contains('room') || session.room!.toLowerCase().contains('lab')
            ? session.room!
            : 'Room ${session.room}')
      else if (session.teacherName != null && session.teacherName!.isNotEmpty)
        session.teacherName!
      else
        session.componentType,
    ].join('  •  ');

    final presentIcon = isCute ? Icons.spa_rounded : Icons.check_rounded;
    final absentIcon = isCute ? Icons.cancel_rounded : Icons.close_rounded;
    final cancelledIcon = isCute ? Icons.remove_circle_rounded : Icons.block_rounded;
    final presentColor = isCute ? (tokens?.presentColor ?? AppColors.presentGreen) : AppColors.presentGreen;
    final absentColor = isCute ? (tokens?.absentColor ?? AppColors.absentRed) : AppColors.absentRed;
    final cancelledColor = isCute ? (tokens?.cancelledColor ?? AppColors.cancelledViolet) : AppColors.cancelledViolet;
    final buttonRadius = BorderRadius.circular(isCute ? 999 : 8);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(cardRadius),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(cardRadius),
          border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0), width: 0.8),
        ),
        child: Stack(
          children: [
            // Left vertical indicator bar
            Positioned(
              left: 0,
              top: 14,
              bottom: 14,
              child: Container(
                width: isCute ? 4.5 : 3.5,
                decoration: BoxDecoration(
                  color: isHoliday ? const Color(0xFFD97706) : stripeColor,
                  borderRadius: BorderRadius.horizontal(right: Radius.circular(isCute ? 999 : 4)),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Subject Name & Live Status Badge / Holiday Badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          session.subjectName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            letterSpacing: isCute ? -0.1 : -0.2,
                          ),
                        ),
                      ),
                      if (isHoliday)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          margin: const EdgeInsets.only(left: 6),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF78350F).withValues(alpha: 0.4) : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(isCute ? 999 : 5),
                            border: Border.all(
                              color: isDark ? const Color(0xFFB45309).withValues(alpha: 0.4) : const Color(0xFFFDE68A),
                              width: 0.7,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.beach_access_rounded, size: 11, color: Color(0xFFD97706)),
                              const SizedBox(width: 3),
                              Text(
                                'Holiday',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (liveStatus != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                          margin: const EdgeInsets.only(left: 6),
                          decoration: BoxDecoration(
                            color: liveStatus.startsWith('🟢')
                                ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.5) : const Color(0xFFDCFCE7))
                                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(isCute ? 999 : 5),
                            border: Border.all(
                              color: liveStatus.startsWith('🟢')
                                   ? (isDark ? const Color(0xFF059669).withValues(alpha: 0.4) : const Color(0xFF86EFAC))
                                   : (isDark ? AppColors.borderDark : const Color(0xFFCBD5E1)),
                              width: 0.7,
                            ),
                          ),
                          child: Text(
                            liveStatus,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: liveStatus.startsWith('🟢')
                                  ? (isDark ? const Color(0xFF34D399) : const Color(0xFF15803D))
                                  : (isDark ? AppColors.textSecondaryDark : const Color(0xFF475569)),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),

                  // Time & Location Subtitle
                  Text(
                    subtitleText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Actions / Holiday / Locked notice
                  if (isHoliday)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF78350F).withValues(alpha: 0.25) : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(isCute ? 999 : 8),
                        border: Border.all(
                          color: isDark ? const Color(0xFFB45309).withValues(alpha: 0.4) : const Color(0xFFFDE68A),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.beach_access_rounded,
                            size: 14,
                            color: Color(0xFFD97706),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'College Holiday · Class suspended',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (isFuture)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.pillDark : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(isCute ? 999 : 8),
                        border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0), width: 0.8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_clock_outlined,
                            size: 13,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Upcoming Class · Attendance on class day',
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.15,
                              fontWeight: FontWeight.w500,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: _FigmaActionButton(
                            label: 'Present',
                            icon: presentIcon,
                            isSelected: session.attendanceOutcome == 'PRESENT',
                            activeColor: presentColor,
                            idleBgColor: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.25) : AppColors.presentContainerLight,
                            idleTextColor: isDark ? AppColors.presentGreenDark : AppColors.presentGreenText,
                            borderRadius: buttonRadius,
                            onTap: () => onOutcomeChanged('PRESENT'),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _FigmaActionButton(
                            label: 'Absent',
                            icon: absentIcon,
                            isSelected: session.attendanceOutcome == 'ABSENT',
                            activeColor: absentColor,
                            idleBgColor: isDark ? const Color(0xFF4C0519).withValues(alpha: 0.25) : AppColors.absentContainerLight,
                            idleTextColor: isDark ? const Color(0xFFFB7185) : AppColors.absentRedText,
                            borderRadius: buttonRadius,
                            onTap: () => onOutcomeChanged('ABSENT'),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _FigmaActionButton(
                            label: 'Cancelled',
                            icon: cancelledIcon,
                            isSelected: session.attendanceOutcome == 'CANCELLED',
                            activeColor: cancelledColor,
                            idleBgColor: isDark ? const Color(0xFF2E1065).withValues(alpha: 0.25) : AppColors.cancelledContainerLight,
                            idleTextColor: isDark ? const Color(0xFFA78BFA) : AppColors.cancelledVioletText,
                            borderRadius: buttonRadius,
                            onTap: () => onOutcomeChanged('CANCELLED'),
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
  );
}
}

class _FigmaActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color activeColor;
  final Color idleBgColor;
  final Color idleTextColor;
  final VoidCallback onTap;
  final BorderRadius? borderRadius;

  const _FigmaActionButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.activeColor,
    required this.idleBgColor,
    required this.idleTextColor,
    required this.onTap,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(8);
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: radius,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? activeColor : idleBgColor,
          borderRadius: radius,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected) ...[
              Icon(icon, size: 13, color: Colors.white),
              const SizedBox(width: 3.5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : idleTextColor,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
