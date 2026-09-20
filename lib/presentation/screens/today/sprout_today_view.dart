import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_theme_tokens.dart';
import '../../../core/theme/app_theme_registry.dart';
import '../../../core/ui/app_toast.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/entities/attendance_stats.dart';
import '../../../domain/entities/class_session_entity.dart';
import '../../../domain/services/schedule_engine.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/app_theme_style_provider.dart';
import '../../widgets/declare_holiday_dialog.dart';
import '../../widgets/mascot_peek_overlay.dart';

/// Sprout Mascot Dashboard view for the Today screen
class SproutTodayView extends ConsumerWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback onGoToToday;
  final VoidCallback onPickDate;
  final void Function(ClassSessionEntity session, String dateIso) onSessionTap;

  const SproutTodayView({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
    required this.onGoToToday,
    required this.onPickDate,
    required this.onSessionTap,
  });

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 12) return 'Good morning,';
    if (hour >= 12 && hour < 17) return 'Good afternoon,';
    if (hour >= 17 && hour < 22) return 'Good evening,';
    return 'Good night,';
  }

  String _getTimeMascot(ThemeDefinition themeDef) {
    final hour = DateTime.now().hour;
    if (hour >= 17 && hour < 22) {
      return themeDef.assets.eveningMascot ?? 'assets/themes/sprout/mascots/sprout_home_evening.png';
    }
    if (hour >= 22 || hour < 4) {
      return themeDef.assets.nightMascot ?? 'assets/themes/sprout/mascots/sprout_home_night.png';
    }
    return themeDef.assets.todayMascot.isNotEmpty
        ? themeDef.assets.todayMascot
        : 'assets/themes/sprout/mascots/sprout_home_wave.png';
  }

  ClassSessionEntity? _findNextOrOngoingSession(List<ClassSessionEntity> sessions, String todayIso) {
    if (sessions.isEmpty) return null;
    final now = DateTime.now();
    final nowIso = DateFormatter.toIsoDate(now);
    if (todayIso != nowIso) {
      return sessions.first;
    }

    final nowMinutes = now.hour * 60 + now.minute;
    for (final s in sessions) {
      try {
        final endParts = s.endTime.split(':');
        final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
        if (endMinutes >= nowMinutes && s.attendanceOutcome != 'CANCELLED' && s.attendanceOutcome != 'HOLIDAY') {
          return s;
        }
      } catch (_) {}
    }
    return sessions.first;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = Theme.of(context).extension<AppThemeTokens>() ??
        (isDark ? AppThemeTokens.cuteSproutDark : AppThemeTokens.cuteSproutLight);

    final String selectedDateIso = DateFormatter.toIsoDate(selectedDate);
    final sessions = ref.watch(resolvedDayScheduleProvider(selectedDate));
    final holidays = ref.watch(holidaysProvider);
    final profile = ref.watch(userProfileProvider);
    final overallStats = ref.watch(overallStatsProvider);
    final themeStyle = ref.watch(appThemeStyleProvider);
    final themeDef = AppThemeRegistry.getTheme(themeStyle);

    final isToday = DateUtils.dateOnly(selectedDate) == DateUtils.dateOnly(DateTime.now());
    final isHoliday = holidays.any((h) => selectedDateIso.compareTo(h.startDate) >= 0 && selectedDateIso.compareTo(h.endDate) <= 0);
    final HolidayItem? currentHoliday = holidays.where((h) => selectedDateIso.compareTo(h.startDate) >= 0 && selectedDateIso.compareTo(h.endDate) <= 0).firstOrNull;

    final studentName = profile.studentName.trim().isNotEmpty
        ? profile.studentName.trim().split(' ').first
        : 'Friend';

    final nextSession = _findNextOrOngoingSession(sessions, selectedDateIso);

    return ColoredBox(
      color: tokens.scaffoldBg,
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Action Strip: [Date Chip] [Today Pill] ... [Holiday]
              _buildTopActionStrip(context, ref, isDark, isToday, isHoliday, selectedDateIso, tokens),

              const SizedBox(height: 16),

              // Header: Greeting + Subtitle on Left, 3D Mascot on Right
              _buildHeaderGreeting(context, studentName, isDark, tokens, themeDef),

              const SizedBox(height: 20),

              // Overall Attendance Care Card
              _buildOverallAttendanceCareCard(context, overallStats, isDark, tokens),

              const SizedBox(height: 24),

              // Schedule Section: Next Class (Hero Card Only on Today)
              if (isHoliday)
                _buildHolidayBanner(context, currentHoliday, isDark, tokens, themeDef)
              else if (sessions.isEmpty)
                _buildEmptyClassesCard(context, isDark, tokens, themeDef)
              else if (isToday) ...[
                // Next Class Hero Section only (per design specification)
                if (nextSession != null) ...[
                  _buildSectionHeader('Next Class', isDark, tokens),
                  const SizedBox(height: 10),
                  _buildNextClassHeroCard(context, ref, nextSession, selectedDateIso, isDark, tokens),
                ] else ...[
                  _buildEmptyClassesCard(context, isDark, tokens, themeDef),
                ],
              ] else ...[
                // All Sessions when viewing another Date
                _buildSectionHeader(
                  DateFormat('EEEE, MMM d').format(selectedDate),
                  isDark,
                  tokens,
                  count: sessions.length,
                ),
                const SizedBox(height: 10),
                for (int i = 0; i < sessions.length; i++) ...[
                  _buildSproutSessionCard(
                    context: context,
                    ref: ref,
                    session: sessions[i],
                    dateIso: selectedDateIso,
                    isFuture: DateUtils.dateOnly(selectedDate).isAfter(DateUtils.dateOnly(DateTime.now())),
                    isDark: isDark,
                    tokens: tokens,
                  ),
                  if (i < sessions.length - 1) const SizedBox(height: 10),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopActionStrip(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    bool isToday,
    bool isHoliday,
    String selectedDateIso,
    AppThemeTokens tokens,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left: Date Chip with Dropdown Indicator
        GestureDetector(
          onTap: onPickDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B3626) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0xFF2E593E) : const Color(0xFFE4ECE0),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.event_note_rounded,
                  size: 15,
                  color: tokens.primaryAccent,
                ),
                const SizedBox(width: 6),
                Text(
                  DateFormatter.formatHeaderDate(selectedDate),
                  style: GoogleFonts.quicksand(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: tokens.textSecondary,
                ),
              ],
            ),
          ),
        ),

        // Right Action Buttons
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Jump to Today button if on another date
            if (!isToday) ...[
              GestureDetector(
                onTap: onGoToToday,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: tokens.primaryAccent.withValues(alpha: isDark ? 0.25 : 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: tokens.primaryAccent, width: 1.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Today 🌱',
                        style: GoogleFonts.quicksand(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: tokens.primaryAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Declare / Remove Holiday Button
            GestureDetector(
              onTap: () {
                if (isHoliday) {
                  ref.read(holidaysProvider.notifier).removeHolidayForDate(selectedDateIso);
                  AppToast.info(context, 'Holiday removed for $selectedDateIso');
                } else {
                  DeclareHolidaySheet.show(context, initialDate: selectedDate);
                }
              },
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isHoliday
                      ? (isDark ? const Color(0xFF78350F).withValues(alpha: 0.4) : const Color(0xFFFEF3C7))
                      : (isDark ? const Color(0xFF1B3626) : Colors.white),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isHoliday
                        ? const Color(0xFFD97706)
                        : (isDark ? const Color(0xFF2E593E) : const Color(0xFFE4ECE0)),
                    width: 1.2,
                  ),
                ),
                child: Center(
                  child: Text(
                    isHoliday ? '🏖️' : '🌴',
                    style: const TextStyle(fontSize: 17),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderGreeting(
    BuildContext context,
    String studentName,
    bool isDark,
    AppThemeTokens tokens,
    ThemeDefinition themeDef,
  ) {
    final greeting = _getTimeGreeting();
    final mascotPath = _getTimeMascot(themeDef);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left Column: Badge, Greeting, Subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tiny Sprout Badge Icon
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF234430) : const Color(0xFFEAF5E4),
                  shape: BoxShape.circle,
                ),
                child: const Text('🌱', style: TextStyle(fontSize: 14)),
              ),
              const SizedBox(height: 6),
              // "Good morning,"
              Text(
                greeting,
                style: GoogleFonts.quicksand(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                  color: tokens.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              // "Hirok!"
              Text(
                '$studentName!',
                style: GoogleFonts.quicksand(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                  color: tokens.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              // Subtitle encouragement
              Row(
                children: [
                  Text(
                    "Show up. You're doing great!",
                    style: GoogleFonts.quicksand(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: tokens.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('🌱', style: TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        // Right: Unboxed Mascot Artwork (~140px free-standing transparent PNG)
        GestureDetector(
          onTap: () {
            MascotPeekOverlay.show(
              context,
              quote: themeDef.mascotQuote,
              mascotAsset: mascotPath,
            );
          },
          child: SizedBox(
            width: 140,
            height: 140,
            child: mascotPath.isNotEmpty
                ? Image.asset(
                    mascotPath,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Text('🌱', style: TextStyle(fontSize: 48)),
                    ),
                  )
                : const Center(
                    child: Text('🌱', style: TextStyle(fontSize: 48)),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildOverallAttendanceCareCard(
    BuildContext context,
    OverallAttendanceStats stats,
    bool isDark,
    AppThemeTokens tokens,
  ) {
    final double displayPct = stats.totalHeld == 0 ? 100.0 : stats.overallPercentage;
    final double targetPct = stats.targetPercentage;
    final bool isBelowTarget = displayPct < targetPct;

    final Color statusColor = isBelowTarget ? tokens.absentColor : tokens.presentColor;
    final Color badgeBg = isBelowTarget
        ? (isDark ? const Color(0xFF3F2020) : const Color(0xFFFDE8E8))
        : (isDark ? const Color(0xFF1E3827) : const Color(0xFFEAF5E4));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B3626) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF2E593E) : const Color(0xFFEDE9DF),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left Column: Metrics
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overall Attendance',
                      style: GoogleFonts.quicksand(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: tokens.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Large Bold Percentage
                    Text(
                      '${displayPct.toStringAsFixed(1)}%',
                      style: GoogleFonts.quicksand(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 3),
                    // Target indicator
                    Row(
                      children: [
                        Text(
                          'Target ${targetPct.toInt()}%',
                          style: GoogleFonts.quicksand(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: tokens.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isBelowTarget ? '🔻' : '🌱',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Right: Modern Circular Gradient Gauge Ring
              SizedBox(
                width: 78,
                height: 78,
                child: CustomPaint(
                  painter: _SproutRingPainter(
                    percentage: displayPct,
                    targetPercentage: targetPct,
                    activeColor: statusColor,
                    trackColor: isDark ? const Color(0xFF264835) : const Color(0xFFF1EDE4),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Care / Thriving Status Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            isBelowTarget ? '⭐' : '🌟',
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isBelowTarget ? 'Needs a little more care' : 'Sprout is thriving!',
                            style: GoogleFonts.quicksand(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isBelowTarget
                            ? 'Attend ${stats.requiredClassesToAttend} more class${stats.requiredClassesToAttend == 1 ? '' : 'es'} to reach your target.'
                            : (stats.marginClassesToMiss > 0
                                ? 'You can safely miss ${stats.marginClassesToMiss} class${stats.marginClassesToMiss == 1 ? '' : 'es'} and stay above target.'
                                : "You're right on target! Keep showing up."),
                        style: GoogleFonts.quicksand(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: tokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Text('🌱', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextClassHeroCard(
    BuildContext context,
    WidgetRef ref,
    ClassSessionEntity session,
    String dateIso,
    bool isDark,
    AppThemeTokens tokens,
  ) {
    final hasOutcome = session.attendanceOutcome != 'PENDING';
    final isPresent = session.attendanceOutcome == 'PRESENT';
    final isAbsent = session.attendanceOutcome == 'ABSENT';
    final isCancelled = session.attendanceOutcome == 'CANCELLED';

    final Color outcomeColor = isPresent
        ? tokens.presentColor
        : isAbsent
            ? tokens.absentColor
            : isCancelled
                ? tokens.cancelledColor
                : (isDark ? const Color(0xFFA7F3A0) : const Color(0xFF2E7D32));

    final Color outcomeBg = isPresent
        ? tokens.presentColor.withValues(alpha: isDark ? 0.35 : 0.18)
        : isAbsent
            ? tokens.absentColor.withValues(alpha: isDark ? 0.35 : 0.18)
            : isCancelled
                ? tokens.cancelledColor.withValues(alpha: isDark ? 0.35 : 0.18)
                : (isDark ? const Color(0xFF1E3827) : const Color(0xFFE8F5E9));

    final IconData outcomeIcon = isPresent
        ? Icons.check_circle_rounded
        : isAbsent
            ? Icons.cancel_rounded
            : isCancelled
                ? Icons.remove_circle_rounded
                : Icons.spa_rounded;

    final String outcomeLabel = isPresent
        ? 'Present'
        : isAbsent
            ? 'Absent'
            : isCancelled
                ? 'Cancelled'
                : 'Mark';

    return GestureDetector(
      onTap: () => onSessionTap(session, dateIso),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B3626) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF2E593E) : const Color(0xFFEDE9DF),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Vertical Accent Bar
            Container(
              width: 4.5,
              height: 48,
              decoration: BoxDecoration(
                color: tokens.primaryAccent,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),

            // Class Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.subjectName,
                    style: GoogleFonts.quicksand(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: tokens.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${DateFormatter.formatTime12h(session.startTime)} – ${DateFormatter.formatTime12h(session.endTime)}',
                    style: GoogleFonts.quicksand(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: tokens.textSecondary,
                    ),
                  ),
                  if (session.room != null && session.room!.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Room ${session.room}',
                      style: GoogleFonts.quicksand(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: tokens.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Pill Outcome Button (Tap to select Present, Absent, Cancelled, or Reset)
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                _showOutcomeSelectionSheet(context, ref, session, dateIso, tokens, isDark);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: outcomeBg,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: hasOutcome ? outcomeColor : (isDark ? const Color(0xFF388E3C) : const Color(0xFF81C784)),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    hasOutcome
                        ? Icon(
                            outcomeIcon,
                            size: 15,
                            color: outcomeColor,
                          )
                        : const Text(
                            '🌱',
                            style: TextStyle(fontSize: 13.5),
                          ),
                    const SizedBox(width: 5),
                    Text(
                      outcomeLabel,
                      style: GoogleFonts.quicksand(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: outcomeColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 14,
                      color: outcomeColor,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOutcomeSelectionSheet(
    BuildContext context,
    WidgetRef ref,
    ClassSessionEntity session,
    String dateIso,
    AppThemeTokens tokens,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final currentOutcome = session.attendanceOutcome;
        final hasOutcome = currentOutcome != 'PENDING';

        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF163424) : const Color(0xFFFAF9F5),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark ? const Color(0xFF2E593E) : const Color(0xFFE9E5DB),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2E593E) : const Color(0xFFD8DED4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 14),

                // Clean Header: Class Name + Time & Room
                Text(
                  session.subjectName,
                  style: GoogleFonts.quicksand(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: tokens.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    '${DateFormatter.formatTime12h(session.startTime)} – ${DateFormatter.formatTime12h(session.endTime)}',
                    if (session.room != null && session.room!.trim().isNotEmpty) 'Room ${session.room}',
                  ].join('  •  '),
                  style: GoogleFonts.quicksand(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: tokens.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),

                // Floating Segmented Capsule (Sibling to Navbar)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1C3E2B) : const Color(0xFFEDE9E0),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isDark ? const Color(0xFF27533B) : const Color(0xFFDFDAD0),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildCapsuleSegment(
                        context: ctx,
                        ref: ref,
                        session: session,
                        dateIso: dateIso,
                        outcome: 'PRESENT',
                        label: 'Present',
                        emoji: '🌱',
                        isSelected: currentOutcome == 'PRESENT',
                        activeColor: tokens.presentColor,
                        activeBg: isDark ? const Color(0xFF2A543B) : Colors.white,
                        tokens: tokens,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 4),
                      _buildCapsuleSegment(
                        context: ctx,
                        ref: ref,
                        session: session,
                        dateIso: dateIso,
                        outcome: 'ABSENT',
                        label: 'Absent',
                        emoji: '✕',
                        isSelected: currentOutcome == 'ABSENT',
                        activeColor: tokens.absentColor,
                        activeBg: isDark ? const Color(0xFF2A543B) : Colors.white,
                        tokens: tokens,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 4),
                      _buildCapsuleSegment(
                        context: ctx,
                        ref: ref,
                        session: session,
                        dateIso: dateIso,
                        outcome: 'CANCELLED',
                        label: 'Cancel',
                        emoji: '⏸',
                        isSelected: currentOutcome == 'CANCELLED',
                        activeColor: tokens.cancelledColor,
                        activeBg: isDark ? const Color(0xFF2A543B) : Colors.white,
                        tokens: tokens,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),

                // Reset to unmarked (only if currently marked)
                if (hasOutcome) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () async {
                      Navigator.pop(ctx);
                      HapticFeedback.lightImpact();
                      await ref.read(attendanceRecordsProvider.notifier).markAttendance(
                            sessionId: session.id,
                            slotId: session.sourceRefId ?? session.id,
                            subjectId: session.subjectComponentId,
                            sessionDate: dateIso,
                            outcome: 'PENDING',
                          );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                      child: Text(
                        'Reset to unmarked',
                        style: GoogleFonts.quicksand(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: tokens.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCapsuleSegment({
    required BuildContext context,
    required WidgetRef ref,
    required ClassSessionEntity session,
    required String dateIso,
    required String outcome,
    required String label,
    required String emoji,
    required bool isSelected,
    required Color activeColor,
    required Color activeBg,
    required AppThemeTokens tokens,
    required bool isDark,
  }) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          Navigator.pop(context);
          HapticFeedback.selectionClick();
          await ref.read(attendanceRecordsProvider.notifier).markAttendance(
                sessionId: session.id,
                slotId: session.sourceRefId ?? session.id,
                subjectId: session.subjectComponentId,
                sessionDate: dateIso,
                outcome: outcome,
              );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                emoji,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? activeColor : tokens.textSecondary,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.quicksand(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                  color: isSelected ? activeColor : tokens.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSproutSessionCard({
    required BuildContext context,
    required WidgetRef ref,
    required ClassSessionEntity session,
    required String dateIso,
    required bool isFuture,
    required bool isDark,
    required AppThemeTokens tokens,
  }) {
    final hasOutcome = session.attendanceOutcome != 'PENDING';
    final isPresent = session.attendanceOutcome == 'PRESENT';
    final isAbsent = session.attendanceOutcome == 'ABSENT';
    final isCancelled = session.attendanceOutcome == 'CANCELLED';
    final isHoliday = session.attendanceOutcome == 'HOLIDAY' || session.status == 'HOLIDAY';

    final Color outcomeColor = isPresent
        ? tokens.presentColor
        : isAbsent
            ? tokens.absentColor
            : isCancelled
                ? tokens.cancelledColor
                : (isDark ? const Color(0xFFA7F3A0) : const Color(0xFF2E7D32));

    final Color outcomeBg = isPresent
        ? tokens.presentColor.withValues(alpha: isDark ? 0.35 : 0.18)
        : isAbsent
            ? tokens.absentColor.withValues(alpha: isDark ? 0.35 : 0.18)
            : isCancelled
                ? tokens.cancelledColor.withValues(alpha: isDark ? 0.35 : 0.18)
                : (isDark ? const Color(0xFF1E3827) : const Color(0xFFE8F5E9));

    final IconData outcomeIcon = isPresent
        ? Icons.check_circle_rounded
        : isAbsent
            ? Icons.cancel_rounded
            : isCancelled
                ? Icons.remove_circle_rounded
                : Icons.spa_rounded;

    final String outcomeLabel = isPresent
        ? 'Present'
        : isAbsent
            ? 'Absent'
            : isCancelled
                ? 'Cancelled'
                : 'Mark';

    Color stripeColor;
    try {
      final hex = session.colorHex.replaceAll('#', '');
      stripeColor = Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      stripeColor = tokens.primaryAccent;
    }

    return GestureDetector(
      onTap: () => onSessionTap(session, dateIso),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B3626) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF2E593E) : const Color(0xFFEDE9DF),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Rounded Vertical Accent Bar
            Container(
              width: 4.5,
              height: 48,
              decoration: BoxDecoration(
                color: isHoliday ? const Color(0xFFD97706) : stripeColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),

            // Class Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.subjectName,
                    style: GoogleFonts.quicksand(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: tokens.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${DateFormatter.formatTime12h(session.startTime)} – ${DateFormatter.formatTime12h(session.endTime)}',
                    style: GoogleFonts.quicksand(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: tokens.textSecondary,
                    ),
                  ),
                  if (session.room != null && session.room!.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Room ${session.room}',
                      style: GoogleFonts.quicksand(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: tokens.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Trailing indicator: Upcoming badge (future) vs Outcome pill (past/today)
            if (isHoliday)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF78350F).withValues(alpha: 0.35) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isDark ? const Color(0xFFB45309).withValues(alpha: 0.4) : const Color(0xFFFDE68A),
                    width: 1.0,
                  ),
                ),
                child: Text(
                  'Holiday',
                  style: GoogleFonts.quicksand(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
                  ),
                ),
              )
            else if (isFuture)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E3A2B) : const Color(0xFFF1F5F0),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2C553C) : const Color(0xFFDCE6DA),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_clock_outlined,
                      size: 13,
                      color: tokens.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Upcoming',
                      style: GoogleFonts.quicksand(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            else
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.selectionClick();
                  _showOutcomeSelectionSheet(context, ref, session, dateIso, tokens, isDark);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: outcomeBg,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: hasOutcome ? outcomeColor : (isDark ? const Color(0xFF388E3C) : const Color(0xFF81C784)),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      hasOutcome
                          ? Icon(
                              outcomeIcon,
                              size: 15,
                              color: outcomeColor,
                            )
                          : const Text(
                              '🌱',
                              style: TextStyle(fontSize: 13.5),
                            ),
                      const SizedBox(width: 5),
                      Text(
                        outcomeLabel,
                        style: GoogleFonts.quicksand(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: outcomeColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 14,
                        color: outcomeColor,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark, AppThemeTokens tokens, {int? count}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.quicksand(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: tokens.textPrimary,
          ),
        ),
        if (count != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF244833) : const Color(0xFFE8F3E5),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isDark ? const Color(0xFF2E593E) : const Color(0xFFD4E6CE),
                width: 1.0,
              ),
            ),
            child: Text(
              '$count ${count == 1 ? "class" : "classes"}',
              style: GoogleFonts.quicksand(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFA7F3A0) : const Color(0xFF2E7D32),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHolidayBanner(
    BuildContext context,
    HolidayItem? currentHoliday,
    bool isDark,
    AppThemeTokens tokens,
    ThemeDefinition themeDef,
  ) {
    final title = currentHoliday?.title.trim().isNotEmpty == true ? currentHoliday!.title : 'College Holiday';
    final holidayMascot = themeDef.assets.holidayMascot;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B3626) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF2E593E) : const Color(0xFFEDE9DF),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          if (holidayMascot != null && holidayMascot.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Image.asset(
                holidayMascot,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Text('🏖️', style: TextStyle(fontSize: 48)),
              ),
            )
          else
            const Text('🏖️', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.quicksand(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Classes are suspended for today. Enjoy your break! 🌱',
            textAlign: TextAlign.center,
            style: GoogleFonts.quicksand(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: tokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyClassesCard(
    BuildContext context,
    bool isDark,
    AppThemeTokens tokens,
    ThemeDefinition themeDef,
  ) {
    final mascotPath = themeDef.assets.emptyStateMascot ?? themeDef.assets.todayMascot;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B3626) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF2E593E) : const Color(0xFFEDE9DF),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          // Mascot Avatar
          ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: mascotPath.isNotEmpty
                ? Image.asset(
                    mascotPath,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Text('🌱', style: TextStyle(fontSize: 40)),
                  )
                : const Text('🌱', style: TextStyle(fontSize: 40)),
          ),
          const SizedBox(height: 12),
          Text(
            'All Caught Up!',
            style: GoogleFonts.quicksand(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No classes scheduled for this date. Time to relax and recharge your mind! 🌿',
            textAlign: TextAlign.center,
            style: GoogleFonts.quicksand(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: tokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom circular progress ring painter for the Sprout Care Card
class _SproutRingPainter extends CustomPainter {
  final double percentage;
  final double targetPercentage;
  final Color activeColor;
  final Color trackColor;

  _SproutRingPainter({
    required this.percentage,
    required this.targetPercentage,
    required this.activeColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 8.5;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    // Background track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Active sweep arc
    final sweepAngle = 2 * math.pi * (percentage.clamp(0.0, 100.0) / 100.0);
    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SproutRingPainter oldDelegate) {
    return oldDelegate.percentage != percentage ||
        oldDelegate.targetPercentage != targetPercentage ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.trackColor != trackColor;
  }
}
