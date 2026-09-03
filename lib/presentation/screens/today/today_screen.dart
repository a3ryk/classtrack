import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/ui/app_toast.dart';
import '../../../core/ui/tactile_button.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/entities/class_session_entity.dart';
import '../../../domain/entities/subject_entity.dart';
import '../../../domain/services/attendance_math.dart';
import '../../providers/app_state_provider.dart';
import '../../widgets/attendance_ring_widget.dart';
import '../../widgets/today_class_card.dart';
import '../../widgets/edit_semester_dialog.dart';
import '../../widgets/declare_holiday_dialog.dart';
import '../../../domain/services/schedule_engine.dart';
import '../schedule/add_edit_slot_screen.dart';
import '../schedule/manage_subject_slots_screen.dart';
import '../schedule/reschedule_session_screen.dart';
import '../schedule/subject_room_manager_screen.dart';
import '../settings/settings_screen.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String selectedDateIso = DateFormatter.toIsoDate(_selectedDate);
    final sessions = ref.watch(resolvedDayScheduleProvider(_selectedDate));
    final overallStats = ref.watch(overallStatsProvider);
    final holidays = ref.watch(holidaysProvider);
    final isToday = DateFormatter.toIsoDate(_selectedDate) == DateFormatter.toIsoDate(DateTime.now());
    final isSelectedDateHoliday = holidays.any((h) => selectedDateIso.compareTo(h.startDate) >= 0 && selectedDateIso.compareTo(h.endDate) <= 0);
    final HolidayItem? currentHoliday = holidays.where((h) => selectedDateIso.compareTo(h.startDate) >= 0 && selectedDateIso.compareTo(h.endDate) <= 0).firstOrNull;

    final isSafe = overallStats.totalHeld == 0 || overallStats.overallPercentage >= overallStats.targetPercentage;

    final String dayName = DateFormat('EEEE').format(_selectedDate);
    final String countTitle = isSelectedDateHoliday
        ? 'Holiday Today'
        : (isToday
            ? '${sessions.length} class${sessions.length == 1 ? '' : 'es'} today'
            : '${sessions.length} class${sessions.length == 1 ? '' : 'es'} on $dayName');

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Top App Bar / Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDate = picked;
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              DateFormatter.formatHeaderDate(_selectedDate),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          countTitle,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            letterSpacing: -0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Top Right: Date navigation, Today Chip & Settings Button
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isToday)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedDate = DateTime.now();
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.pillDark : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0), width: 0.8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.today_rounded, size: 14, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                                const SizedBox(width: 4),
                                Text(
                                  'Today',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: TactileIconButton(
                        icon: isSelectedDateHoliday ? Icons.beach_access_rounded : Icons.beach_access_outlined,
                        iconSize: 18,
                        size: 38,
                        backgroundColor: isSelectedDateHoliday
                            ? (isDark ? const Color(0xFF78350F).withValues(alpha: 0.4) : const Color(0xFFFEF3C7))
                            : (isDark ? AppColors.cardDark : Colors.white),
                        borderColor: isSelectedDateHoliday
                            ? (isDark ? const Color(0xFFB45309).withValues(alpha: 0.5) : const Color(0xFFFDE68A))
                            : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                        iconColor: isSelectedDateHoliday
                            ? const Color(0xFFD97706)
                            : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                        onTap: () {
                          if (isSelectedDateHoliday) {
                            ref.read(holidaysProvider.notifier).removeHolidayForDate(selectedDateIso);
                            AppToast.info(context, 'Holiday removed for $selectedDateIso');
                          } else {
                            DeclareHolidaySheet.show(context, initialDate: _selectedDate);
                          }
                        },
                      ),
                    ),
                    TactileIconButton(
                      icon: Icons.settings_outlined,
                      iconSize: 19,
                      size: 38,
                      backgroundColor: isDark ? AppColors.cardDark : Colors.white,
                      borderColor: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                      iconColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SettingsScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Hero Card (Overall Attendance)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0), width: 0.8),
              ),
              child: Row(
                children: [
                  AttendanceRingWidget(
                    percentage: overallStats.overallPercentage,
                    targetPercentage: overallStats.targetPercentage,
                    size: 80,
                    isDataEmpty: overallStats.totalHeld == 0,
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Overall Attendance',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Keep this above ${overallStats.targetPercentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Ultra-Clean Inline Status Indicator (Zero box clutter, smooth color cross-fade)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 350),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isSafe
                                    ? (isDark ? AppColors.presentGreenDark : AppColors.presentGreen)
                                    : (isDark ? const Color(0xFFFB7185) : AppColors.absentRed),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                overallStats.totalHeld == 0
                                    ? 'No classes recorded'
                                    : (isSafe
                                        ? 'Safe · ${overallStats.marginClassesToMiss} class${overallStats.marginClassesToMiss == 1 ? "" : "es"} to spare'
                                        : 'Must attend next ${overallStats.requiredClassesToAttend} class${overallStats.requiredClassesToAttend == 1 ? "" : "es"}'),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: overallStats.totalHeld == 0
                                      ? (isDark ? AppColors.textMutedDark : AppColors.textMutedLight)
                                      : (isSafe
                                          ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
                                          : (isDark ? const Color(0xFFFB7185) : const Color(0xFFE11D48))),
                                  letterSpacing: -0.1,
                                ),
                                overflow: TextOverflow.ellipsis,
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

            // Smooth & Soothing Forecast Banner Animation
            AnimatedSize(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              child: (isToday && sessions.any((s) => s.attendanceOutcome == 'PENDING') && overallStats.totalHeld > 0)
                  ? Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        builder: (context, opacity, child) {
                          return Opacity(
                            opacity: opacity,
                            child: child,
                          );
                        },
                        child: Builder(
                          builder: (context) {
                            final remaining = sessions.where((s) => s.attendanceOutcome == 'PENDING').length;
                            final futureHeld = overallStats.totalHeld + remaining;
                            final futureAttended = overallStats.totalAttended + remaining;
                            final futurePct = AttendanceMathService.calculatePercentage(futureAttended, futureHeld);
                            final diff = futurePct - overallStats.overallPercentage;

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E1B4B).withValues(alpha: 0.35) : const Color(0xFFF5F3FF),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF4F46E5).withValues(alpha: 0.3) : const Color(0xFFDDD6FE),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 15,
                                    color: AppColors.accentIndigoLight,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Attend all $remaining remaining today → Overall rises to $futurePct% (+${diff >= 0 ? diff.toStringAsFixed(1) : "0.0"}%)',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? const Color(0xFFC7D2FE) : const Color(0xFF4338CA),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            const SizedBox(height: 20),

            if (isSelectedDateHoliday)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF78350F).withValues(alpha: 0.25) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? const Color(0xFFB45309).withValues(alpha: 0.45) : const Color(0xFFFDE68A),
                    width: 0.9,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF92400E).withValues(alpha: 0.4) : const Color(0xFFFDE68A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.beach_access_rounded,
                        size: 24,
                        color: Color(0xFFD97706),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentHoliday?.title.isNotEmpty == true ? currentHoliday!.title : 'College Holiday Declared',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Classes are suspended for today. Attendance percentages are preserved with zero penalties.',
                            style: TextStyle(
                              fontSize: 11.5,
                              height: 1.3,
                              color: isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E),
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        await ref.read(holidaysProvider.notifier).removeHolidayForDate(selectedDateIso);
                        if (context.mounted) {
                          AppToast.info(context, 'Holiday removed for $selectedDateIso');
                        }
                      },
                      child: const Text('Undo', style: TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              ),

            // Section Title: Upcoming Classes
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 10),
              child: Text(
                isSelectedDateHoliday ? "Scheduled Classes (Holiday)" : "Upcoming Classes",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ),

            // Class Cards List
            if (ref.watch(activeSemesterProvider).isUnset)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0), width: 0.8),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.school_outlined,
                      size: 36,
                      color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No Active Semester',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Set up your semester to start tracking your daily classes and attendance.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => const EditSemesterDialog(),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        foregroundColor: isDark ? AppColors.bgDark : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Set Up Semester', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ],
                ),
              )
            else if (sessions.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0), width: 0.8),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.event_available_outlined,
                      size: 34,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isToday ? 'No classes scheduled for today' : 'No classes scheduled for this day',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Enjoy your free time or check other dates.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...List.generate(sessions.length, (index) {
                final session = sessions[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TodayClassCard(
                    session: session,
                    isFuture: selectedDateIso.compareTo(DateFormatter.toIsoDate(DateTime.now())) > 0,
                    onTap: () => _showSessionActionSheet(context, session, selectedDateIso),
                    onOutcomeChanged: (outcome) {
                      ref.read(attendanceRecordsProvider.notifier).markAttendance(
                        sessionId: session.id,
                        slotId: session.sourceRefId ?? session.id,
                        subjectId: session.subjectComponentId,
                        sessionDate: selectedDateIso,
                        outcome: outcome,
                      );

                      final ToastType toastType = outcome == 'PRESENT'
                          ? ToastType.success
                          : (outcome == 'ABSENT' ? ToastType.error : ToastType.info);

                      AppToast.show(
                        context,
                        'Marked ${outcome.toLowerCase()} for ${session.subjectName}',
                        type: toastType,
                        duration: const Duration(seconds: 4),
                        actionLabel: 'UNDO',
                        onAction: () {
                          ref.read(attendanceRecordsProvider.notifier).markAttendance(
                            sessionId: session.id,
                            slotId: session.sourceRefId ?? session.id,
                            subjectId: session.subjectComponentId,
                            sessionDate: selectedDateIso,
                            outcome: 'PENDING',
                          );
                        },
                      );
                    },
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  void _showSessionActionSheet(BuildContext context, ClassSessionEntity session, String dateIso) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.cardDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const SizedBox(height: 14),
                  Text(
                    session.subjectName,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${DateFormatter.formatTime12h(session.startTime)} – ${DateFormatter.formatTime12h(session.endTime)}  •  ${session.componentType}',
                    style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                  ),
                  const SizedBox(height: 16),

                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.pillDark : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.edit_calendar_rounded, size: 16, color: isDark ? AppColors.accentIndigoDark : AppColors.accentIndigoLight),
                    ),
                    title: const Text('Change room / time for today only', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Override today without altering weekly timetable', style: TextStyle(fontSize: 11)),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                    onTap: () {
                      Navigator.pop(ctx);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RescheduleSessionScreen(
                                session: session,
                                dateIso: dateIso,
                              ),
                            ),
                          );
                        }
                      });
                    },
                  ),

                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.pillDark : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.meeting_room_outlined, size: 16, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                    ),
                    title: const Text('Manage rooms for this subject', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Set or customize rooms for all days of this subject', style: TextStyle(fontSize: 11)),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                    onTap: () {
                      final subjects = ref.read(subjectsProvider);
                      final sub = subjects.firstWhere(
                        (s) => s.id == session.subjectComponentId,
                        orElse: () => SubjectEntity(
                          id: session.subjectComponentId,
                          semesterId: session.semesterId,
                          name: session.subjectName,
                          category: session.category,
                          credits: 3,
                          targetAttendancePct: 75.0,
                          baselineHeld: 0,
                          baselineAttended: 0,
                          isArchived: false,
                          colorHex: session.colorHex,
                          components: [],
                        ),
                      );
                      Navigator.pop(ctx);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SubjectRoomManagerScreen(
                                subject: sub,
                                initialRoom: session.room,
                              ),
                            ),
                          );
                        }
                      });
                    },
                  ),

                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.pillDark : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.edit_note_rounded, size: 16, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                    ),
                    title: const Text('Edit this weekly slot permanently', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Change time, room, or teacher for this recurring day', style: TextStyle(fontSize: 11)),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddEditSlotScreen(
                            existingSlot: session,
                            initialDayOfWeek: session.dayOfWeek ?? DateFormatter.getDayOfWeek(DateTime.now()),
                          ),
                        ),
                      );
                    },
                  ),

                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF4C0519).withValues(alpha: 0.3) : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.absentRed),
                    ),
                    title: const Text('Remove for today only', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Erase this session from today\'s schedule', style: TextStyle(fontSize: 11)),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                    onTap: () async {
                      Navigator.pop(ctx);
                      if (session.sourceRefId != null) {
                        await ref.read(scheduleExceptionsProvider.notifier).addOrUpdateException(
                          timetableSlotId: session.sourceRefId!,
                          exceptionDate: dateIso,
                          actionType: 'CANCELLED',
                        );
                        if (context.mounted) {
                          AppToast.info(context, 'Removed ${session.subjectName} for today');
                        }
                      }
                    },
                  ),

                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.pillDark : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.tune_rounded, size: 16, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                    ),
                    title: const Text('Manage all slots for this subject', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: const Text('View, add, and customize all weekly days and times', style: TextStyle(fontSize: 11)),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                    onTap: () {
                      Navigator.pop(ctx);
                      final subjects = ref.read(subjectsProvider);
                      final sub = subjects.firstWhere(
                        (s) => s.id == session.subjectComponentId,
                        orElse: () => SubjectEntity(
                          id: session.subjectComponentId,
                          semesterId: session.semesterId,
                          name: session.subjectName,
                          category: session.category,
                          credits: 3,
                          targetAttendancePct: 75.0,
                          baselineHeld: 0,
                          baselineAttended: 0,
                          isArchived: false,
                          colorHex: session.colorHex,
                          components: [],
                        ),
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ManageSubjectSlotsScreen(subject: sub),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
