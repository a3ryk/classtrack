import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  static const int _kInitialPage = 10000;
  late final PageController _pageController;
  late final DateTime _baseDate;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _baseDate = DateUtils.dateOnly(DateTime.now());
    _selectedDate = _baseDate;
    _pageController = PageController(initialPage: _kInitialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToToday() {
    HapticFeedback.mediumImpact();
    final today = DateUtils.dateOnly(DateTime.now());
    setState(() {
      _selectedDate = today;
    });

    if (!_pageController.hasClients) return;

    final currentPage = _pageController.page?.round() ?? _kInitialPage;
    final distance = (currentPage - _kInitialPage).abs();

    if (distance == 0) return;

    if (distance <= 2) {
      _pageController.animateToPage(
        _kInitialPage,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    } else {
      // Large distance: jump off-screen to adjacent page in the direction we came from,
      // then glide smoothly into _kInitialPage to avoid a multi-page strobe blur.
      final intermediatePage = _kInitialPage + (currentPage > _kInitialPage ? 1 : -1);
      _pageController.jumpToPage(intermediatePage);
      _pageController.animateToPage(
        _kInitialPage,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      final targetDate = DateUtils.dateOnly(picked);
      final diffDays = targetDate.difference(_baseDate).inDays;
      final targetPage = _kInitialPage + diffDays;
      setState(() {
        _selectedDate = targetDate;
      });

      if (_pageController.hasClients) {
        final currentPage = _pageController.page?.round() ?? _kInitialPage;
        final distance = (currentPage - targetPage).abs();
        if (distance <= 2) {
          _pageController.animateToPage(
            targetPage,
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeOutCubic,
          );
        } else {
          _pageController.jumpToPage(targetPage);
        }
      }
    }
  }

  String _getCountTitle({
    required bool isHoliday,
    required DateTime date,
    required int classCount,
  }) {
    final today = DateUtils.dateOnly(DateTime.now());
    final target = DateUtils.dateOnly(date);
    final diffDays = target.difference(today).inDays;

    if (isHoliday) {
      if (diffDays == 0) return 'Holiday Today';
      if (diffDays == 1) return 'Holiday Tomorrow';
      if (diffDays == -1) return 'Holiday Yesterday';
      return 'College Holiday';
    }

    final String plural = classCount == 1 ? '' : 'es';
    if (diffDays == 0) return classCount == 0 ? 'No classes today' : '$classCount class$plural today';
    if (diffDays == 1) return classCount == 0 ? 'No classes tomorrow' : '$classCount class$plural tomorrow';
    if (diffDays == -1) return classCount == 0 ? 'No classes yesterday' : '$classCount class$plural yesterday';
    return classCount == 0 ? 'No classes scheduled' : '$classCount class$plural scheduled';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String selectedDateIso = DateFormatter.toIsoDate(_selectedDate);
    final sessions = ref.watch(resolvedDayScheduleProvider(_selectedDate));
    final holidays = ref.watch(holidaysProvider);
    final isToday = DateUtils.dateOnly(_selectedDate) == DateUtils.dateOnly(DateTime.now());
    final isSelectedDateHoliday = holidays.any((h) => selectedDateIso.compareTo(h.startDate) >= 0 && selectedDateIso.compareTo(h.endDate) <= 0);

    final countTitle = _getCountTitle(
      isHoliday: isSelectedDateHoliday,
      date: _selectedDate,
      classCount: sessions.length,
    );

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar / Fixed Header
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 14, bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Date Chip Selector on left, Action buttons on right
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Date Selector Chip (Tap to pick date)
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 260),
                            layoutBuilder: (child, list) => Stack(
                              alignment: Alignment.centerLeft,
                              children: [...list, if (child != null) child],
                            ),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.15),
                                    end: Offset.zero,
                                  ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                                  child: child,
                                ),
                              );
                            },
                            child: Row(
                              key: ValueKey(selectedDateIso),
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  DateFormatter.formatHeaderDate(_selectedDate),
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 18,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Actions: [Today Pill] [Holiday] [Settings]
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedSize(
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOutCubic,
                            child: !isToday
                                ? Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: InkWell(
                                      onTap: _goToToday,
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: isDark ? AppColors.pillDark : const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.today_rounded,
                                              size: 14,
                                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Today',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
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

                  const SizedBox(height: 2),

                  // Row 2: Full-width Headline Title with smooth crossfade, strictly left-aligned
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(8),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      layoutBuilder: (child, list) => Stack(
                        alignment: Alignment.centerLeft,
                        children: [...list, if (child != null) child],
                      ),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.12),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        key: ValueKey(countTitle + selectedDateIso),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          countTitle,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            letterSpacing: -0.6,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Horizontal Swipeable Day Schedule PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                onPageChanged: (index) {
                  final newDate = _baseDate.add(Duration(days: index - _kInitialPage));
                  setState(() {
                    _selectedDate = newDate;
                  });
                },
                itemBuilder: (context, index) {
                  final pageDate = _baseDate.add(Duration(days: index - _kInitialPage));
                  return _TodayDatePageContent(
                    key: ValueKey(DateFormatter.toIsoDate(pageDate)),
                    date: pageDate,
                    onSessionTap: (session) => _showSessionActionSheet(context, session, DateFormatter.toIsoDate(pageDate)),
                  );
                },
              ),
            ),
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

class _TodayDatePageContent extends ConsumerWidget {
  final DateTime date;
  final ValueChanged<ClassSessionEntity> onSessionTap;

  const _TodayDatePageContent({
    super.key,
    required this.date,
    required this.onSessionTap,
  });

  String _getClassesSectionTitle({
    required bool isHoliday,
    required DateTime date,
  }) {
    if (isHoliday) return 'Scheduled Classes (Holiday)';
    final today = DateUtils.dateOnly(DateTime.now());
    final target = DateUtils.dateOnly(date);
    final diffDays = target.difference(today).inDays;
    final dayName = DateFormat('EEEE').format(date);

    if (diffDays == 0) {
      return "Today's Classes";
    } else if (diffDays == 1) {
      return "Tomorrow's Classes";
    } else if (diffDays == -1) {
      return "Yesterday's Classes";
    } else if (diffDays > 1) {
      return "Upcoming Classes ($dayName)";
    } else {
      return "Past Classes ($dayName)";
    }
  }

  String _getEmptyStateTitle({
    required DateTime date,
  }) {
    final today = DateUtils.dateOnly(DateTime.now());
    final target = DateUtils.dateOnly(date);
    final diffDays = target.difference(today).inDays;
    final dayName = DateFormat('EEEE').format(date);

    if (diffDays == 0) return 'No classes scheduled for today';
    if (diffDays == 1) return 'No classes scheduled for tomorrow';
    if (diffDays == -1) return 'No classes scheduled for yesterday';
    return 'No classes scheduled for $dayName';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String dateIso = DateFormatter.toIsoDate(date);
    final sessions = ref.watch(resolvedDayScheduleProvider(date));
    final overallStats = ref.watch(overallStatsProvider);
    final holidays = ref.watch(holidaysProvider);
    final isToday = DateFormatter.toIsoDate(date) == DateFormatter.toIsoDate(DateTime.now());
    final isSelectedDateHoliday = holidays.any((h) => dateIso.compareTo(h.startDate) >= 0 && dateIso.compareTo(h.endDate) <= 0);
    final HolidayItem? currentHoliday = holidays.where((h) => dateIso.compareTo(h.startDate) >= 0 && dateIso.compareTo(h.endDate) <= 0).firstOrNull;

    final isSafe = overallStats.totalHeld == 0 || overallStats.overallPercentage >= overallStats.targetPercentage;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
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

                    // Ultra-Clean Inline Status Indicator
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

        // Smooth & Soothing Holiday Banner Animation
        AnimatedSize(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          child: isSelectedDateHoliday
              ? Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    builder: (context, opacity, child) {
                      return Opacity(
                        opacity: opacity,
                        child: Transform.translate(
                          offset: Offset(0, 6 * (1 - opacity)),
                          child: child,
                        ),
                      );
                    },
                    child: Container(
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
                                  isToday ? 'Classes are suspended for today.' : 'Classes are suspended for this day.',
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
                              await ref.read(holidaysProvider.notifier).removeHolidayForDate(dateIso);
                              if (context.mounted) {
                                AppToast.info(context, 'Holiday removed for $dateIso');
                              }
                            },
                            child: const Text('Undo', style: TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),

        // Section Title: Contextual title
        Padding(
          padding: const EdgeInsets.only(left: 2, top: 18, bottom: 10),
          child: Text(
            _getClassesSectionTitle(
              isHoliday: isSelectedDateHoliday,
              date: date,
            ),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ),

        // Class Cards List / Contextual Empty States
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
                  _getEmptyStateTitle(date: date),
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
                isFuture: dateIso.compareTo(DateFormatter.toIsoDate(DateTime.now())) > 0,
                onTap: () => onSessionTap(session),
                onOutcomeChanged: (outcome) {
                  ref.read(attendanceRecordsProvider.notifier).markAttendance(
                    sessionId: session.id,
                    slotId: session.sourceRefId ?? session.id,
                    subjectId: session.subjectComponentId,
                    sessionDate: dateIso,
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
                        sessionDate: dateIso,
                        outcome: 'PENDING',
                      );
                    },
                  );
                },
              ),
            );
          }),
      ],
    );
  }
}
