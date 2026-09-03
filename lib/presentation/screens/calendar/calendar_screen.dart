import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/ui/app_toast.dart';
import '../../../core/ui/tactile_button.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/entities/class_session_entity.dart';
import '../../../domain/entities/subject_entity.dart';
import '../../providers/app_state_provider.dart';
import '../../widgets/edit_semester_dialog.dart';
import '../schedule/add_edit_slot_screen.dart';
import '../schedule/manage_subject_slots_screen.dart';
import '../schedule/reschedule_session_screen.dart';
import '../schedule/subject_room_manager_screen.dart';

enum CalendarViewMode {
  week,
  month,
}

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> with SingleTickerProviderStateMixin {
  late DateTime _selectedDate;
  late DateTime _weekStartDate;
  late DateTime _currentMonth;
  CalendarViewMode _viewMode = CalendarViewMode.week;

  @override
  void initState() {
    super.initState();
    _goToToday(animate: false);
  }

  void _goToToday({bool animate = true}) {
    final now = DateTime.now();
    setState(() {
      _selectedDate = DateTime(now.year, now.month, now.day);
      _currentMonth = DateTime(now.year, now.month, 1);
      _weekStartDate = _selectedDate.subtract(Duration(days: _selectedDate.weekday % 7));
    });
  }

  void _previousPeriod() {
    setState(() {
      if (_viewMode == CalendarViewMode.week) {
        _weekStartDate = _weekStartDate.subtract(const Duration(days: 7));
        _selectedDate = _weekStartDate;
        _currentMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
      } else {
        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
        _selectedDate = DateTime(_currentMonth.year, _currentMonth.month, 1);
        _weekStartDate = _selectedDate.subtract(Duration(days: _selectedDate.weekday % 7));
      }
    });
  }

  void _nextPeriod() {
    setState(() {
      if (_viewMode == CalendarViewMode.week) {
        _weekStartDate = _weekStartDate.add(const Duration(days: 7));
        _selectedDate = _weekStartDate;
        _currentMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
      } else {
        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
        _selectedDate = DateTime(_currentMonth.year, _currentMonth.month, 1);
        _weekStartDate = _selectedDate.subtract(Duration(days: _selectedDate.weekday % 7));
      }
    });
  }

  void _toggleViewMode() {
    setState(() {
      if (_viewMode == CalendarViewMode.week) {
        _viewMode = CalendarViewMode.month;
        _currentMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
      } else {
        _viewMode = CalendarViewMode.week;
        _weekStartDate = _selectedDate.subtract(Duration(days: _selectedDate.weekday % 7));
      }
    });
  }

  void _showMonthYearPickerModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    int selectedYear = _currentMonth.year;
    int selectedMonth = _currentMonth.month;

    final List<String> monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Sheet Handle
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Header with Year Selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Jump to Month & Year',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.cardDark : AppColors.cardLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              InkWell(
                                onTap: selectedYear > 2020
                                    ? () => setModalState(() => selectedYear--)
                                    : null,
                                child: Icon(Icons.chevron_left_rounded, size: 20, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$selectedYear',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: selectedYear < 2030
                                    ? () => setModalState(() => selectedYear++)
                                    : null,
                                child: Icon(Icons.chevron_right_rounded, size: 20, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 12 Months Grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 12,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.8,
                      ),
                      itemBuilder: (context, index) {
                        final monthNum = index + 1;
                        final isSelected = monthNum == selectedMonth;

                        return InkWell(
                          onTap: () {
                            setState(() {
                              _currentMonth = DateTime(selectedYear, monthNum, 1);
                              _selectedDate = DateTime(selectedYear, monthNum, 1);
                              _weekStartDate = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
                            });
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                                  : (isDark ? AppColors.cardDark : AppColors.cardLight),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              monthNames[index],
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? (isDark ? AppColors.bgDark : AppColors.surfaceLight)
                                    : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String selectedDateIso = DateFormatter.toIsoDate(_selectedDate);
    final bool isToday = DateFormatter.toIsoDate(_selectedDate) == DateFormatter.toIsoDate(DateTime.now());

    List<ClassSessionEntity> getSessionsForDay(DateTime date) => ref.watch(resolvedDayScheduleProvider(date));
    final daySessions = getSessionsForDay(_selectedDate);

    final int presentCount = daySessions.where((s) => s.attendanceOutcome == 'PRESENT').length;
    final int totalHeld = daySessions.where((s) => s.attendanceOutcome != 'CANCELLED').length;

    final monthYearTitle = DateFormat('MMMM yyyy').format(_viewMode == CalendarViewMode.week ? _selectedDate : _currentMonth);
    final dayHeaderTitle = DateFormat('MMMM d').format(_selectedDate);

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header: Calendar Title + Quick "Today" & Mode Toggle
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Calendar',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      letterSpacing: -0.8,
                    ),
                  ),

                    Row(
                    children: [
                      // Instant "Today" Button (Shown when not currently on today)
                      if (!isToday)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: TapScaleContainer(
                            onTap: () => _goToToday(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.today_rounded,
                                    size: 14,
                                    color: isDark ? AppColors.bgDark : AppColors.surfaceLight,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Today',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.bgDark : AppColors.surfaceLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // Mode Toggle Button (Week vs Month View)
                      TapScaleContainer(
                        onTap: _toggleViewMode,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.cardDark : AppColors.cardLight,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0), width: 0.8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _viewMode == CalendarViewMode.week
                                    ? Icons.calendar_view_month_rounded
                                    : Icons.view_week_rounded,
                                size: 16,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _viewMode == CalendarViewMode.week ? 'Month' : 'Week',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Month Title & Navigation Arrows Row (Interactive)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Month/Year clickable button with Dropdown chevron
                  TapScaleContainer(
                    onTap: () => _showMonthYearPickerModal(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                      child: Row(
                        children: [
                          Text(
                            monthYearTitle,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Left & Right Arrow Navigation
                  Row(
                    children: [
                      TactileIconButton(
                        icon: Icons.chevron_left_rounded,
                        size: 32,
                        iconSize: 22,
                        iconColor: isDark ? AppColors.textSecondaryDark : AppColors.textPrimaryLight,
                        onTap: _previousPeriod,
                      ),
                      const SizedBox(width: 4),
                      TactileIconButton(
                        icon: Icons.chevron_right_rounded,
                        size: 32,
                        iconSize: 22,
                        iconColor: isDark ? AppColors.textSecondaryDark : AppColors.textPrimaryLight,
                        onTap: _nextPeriod,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Animated Calendar Container (Week Strip vs Full Month Grid)
            GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity != null) {
                  if (details.primaryVelocity! < -200) {
                    _nextPeriod();
                  } else if (details.primaryVelocity! > 200) {
                    _previousPeriod();
                  }
                }
              },
              child: AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOutCubic,
                alignment: Alignment.topCenter,
                child: _viewMode == CalendarViewMode.week
                    ? _buildWeekStrip(isDark, getSessionsForDay)
                    : _buildMonthGrid(isDark, getSessionsForDay),
              ),
            ),

            const SizedBox(height: 14),

            // Subtle Full-Width Divider Line
            Divider(
              height: 1,
              thickness: 1,
              color: isDark ? AppColors.borderDark : const Color(0xFFF1F5F9),
            ),

            const SizedBox(height: 14),

            // Selected Date & Attended Status Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dayHeaderTitle,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        totalHeld > 0 ? 'Attended $presentCount of $totalHeld' : 'No classes',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                  if (!ref.watch(activeSemesterProvider).isUnset)
                    InkWell(
                      onTap: () => _showAddExtraClassDialog(context, selectedDateIso),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.pillDark : const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : const Color(0xFFC7D2FE),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.add_rounded,
                              size: 14,
                              color: isDark ? AppColors.accentIndigoDark : AppColors.accentIndigoLight,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Extra Class',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.accentIndigoDark : AppColors.accentIndigoLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Animated Session List (Smooth Slide & Fade on date change)
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.0, 0.04),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: ref.watch(activeSemesterProvider).isUnset
                    ? KeyedSubtree(
                        key: const ValueKey('empty_unset_sem'),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isDark ? AppColors.surfaceDark : const Color(0xFFEFF6FF),
                                  ),
                                  child: Icon(
                                    Icons.school_rounded,
                                    size: 28,
                                    color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No Active Semester',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Set up your semester to start tracking your daily classes and attendance.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.4,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => const EditSemesterDialog(),
                                    );
                                  },
                                  icon: const Icon(Icons.add_rounded, size: 18),
                                  label: const Text('Set Up Semester', style: TextStyle(fontWeight: FontWeight.w700)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                    foregroundColor: isDark ? AppColors.bgDark : Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : daySessions.isEmpty
                        ? KeyedSubtree(
                            key: ValueKey('empty_$selectedDateIso'),
                            child: Center(
                              child: Text(
                                'No classes recorded for this date.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                ),
                              ),
                            ),
                          )
                    : ListView.separated(
                        key: ValueKey('list_$selectedDateIso'),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        itemCount: daySessions.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 24,
                          thickness: 1,
                          color: isDark ? AppColors.borderDark : const Color(0xFFF1F5F9),
                        ),
                        itemBuilder: (context, index) {
                          final session = daySessions[index];

                          String badgeLabel;
                          Color badgeBg;
                          Color badgeTextColor;

                          switch (session.attendanceOutcome) {
                            case 'PRESENT':
                              badgeLabel = 'Present';
                              badgeBg = isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : AppColors.presentContainerLight;
                              badgeTextColor = isDark ? AppColors.presentGreenDark : AppColors.presentGreenText;
                              break;
                            case 'ABSENT':
                              badgeLabel = 'Absent';
                              badgeBg = isDark ? const Color(0xFF4C0519).withValues(alpha: 0.3) : AppColors.absentContainerLight;
                              badgeTextColor = isDark ? const Color(0xFFFB7185) : AppColors.absentRedText;
                              break;
                            case 'CANCELLED':
                              badgeLabel = 'Cancelled';
                              badgeBg = isDark ? const Color(0xFF2E1065).withValues(alpha: 0.3) : AppColors.cancelledContainerLight;
                              badgeTextColor = isDark ? const Color(0xFFA78BFA) : AppColors.cancelledVioletText;
                              break;
                            default:
                              badgeLabel = 'Pending';
                              badgeBg = isDark ? AppColors.pillDark : AppColors.pillLight;
                              badgeTextColor = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
                          }

                          final String subtitle = [
                            '${session.startTime} – ${session.endTime}',
                            if (session.room != null && session.room!.isNotEmpty)
                              (session.room!.toLowerCase().contains('room') || session.room!.toLowerCase().contains('lab')
                                  ? session.room!
                                  : 'Room ${session.room}')
                            else if (session.teacherName != null && session.teacherName!.isNotEmpty)
                              session.teacherName!
                            else
                              session.componentType,
                          ].join('  •  ');

                          final bool isPastOrToday = selectedDateIso.compareTo(DateFormatter.toIsoDate(DateTime.now())) <= 0;

                          return InkWell(
                            onTap: isPastOrToday
                                ? () => _showQuickAttendancePicker(context, session, selectedDateIso)
                                : null,
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          session.subjectName,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          subtitle,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w400,
                                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: badgeBg,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      badgeLabel,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: badgeTextColor,
                                        letterSpacing: -0.1,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WEEK STRIP WIDGET ---
  Widget _buildWeekStrip(bool isDark, List<ClassSessionEntity> Function(DateTime) getSessionsForDay) {
    final weekDays = List.generate(7, (index) => _weekStartDate.add(Duration(days: index)));
    final weekdayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (index) {
          final date = weekDays[index];
          final isSelected = date.year == _selectedDate.year &&
              date.month == _selectedDate.month &&
              date.day == _selectedDate.day;

          final sessionsForDate = getSessionsForDay(date);

          Color? dotColor;
          if (sessionsForDate.isNotEmpty) {
            if (sessionsForDate.any((s) => s.attendanceOutcome == 'ABSENT')) {
              dotColor = AppColors.absentRed;
            } else if (sessionsForDate.any((s) => s.attendanceOutcome == 'PRESENT')) {
              dotColor = AppColors.presentGreen;
            } else if (sessionsForDate.any((s) => s.attendanceOutcome == 'CANCELLED')) {
              dotColor = AppColors.cancelledViolet;
            } else {
              dotColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
            }
          }

          return InkWell(
            onTap: () {
              setState(() {
                _selectedDate = date;
              });
            },
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              width: 44,
              child: Column(
                children: [
                  Text(
                    weekdayLabels[index],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textMutedDark : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutBack,
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? (isDark ? AppColors.bgDark : AppColors.surfaceLight)
                            : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: dotColor ?? Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // --- FULL MONTH GRID WIDGET ---
  Widget _buildMonthGrid(bool isDark, List<ClassSessionEntity> Function(DateTime) getSessionsForDay) {
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);

    final weekdayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    final int startOffset = firstDayOfMonth.weekday % 7;
    final int totalDays = lastDayOfMonth.day;
    final int totalCells = ((startOffset + totalDays) / 7.0).ceil() * 7;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekdayLabels.map((lbl) {
              return SizedBox(
                width: 40,
                child: Text(
                  lbl,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textMutedDark : const Color(0xFF94A3B8),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalCells,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 0.95,
            ),
            itemBuilder: (context, index) {
              final int dayNumber = index - startOffset + 1;
              if (dayNumber < 1 || dayNumber > totalDays) {
                return const SizedBox.shrink();
              }

              final date = DateTime(_currentMonth.year, _currentMonth.month, dayNumber);
              final isSelected = date.year == _selectedDate.year &&
                  date.month == _selectedDate.month &&
                  date.day == _selectedDate.day;

              final sessionsForDate = getSessionsForDay(date);

              Color? dotColor;
              if (sessionsForDate.isNotEmpty) {
                if (sessionsForDate.any((s) => s.attendanceOutcome == 'ABSENT')) {
                  dotColor = AppColors.absentRed;
                } else if (sessionsForDate.any((s) => s.attendanceOutcome == 'PRESENT')) {
                  dotColor = AppColors.presentGreen;
                } else if (sessionsForDate.any((s) => s.attendanceOutcome == 'CANCELLED')) {
                  dotColor = AppColors.cancelledViolet;
                } else {
                  dotColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
                }
              }

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedDate = date;
                    _weekStartDate = _selectedDate.subtract(Duration(days: _selectedDate.weekday % 7));
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutBack,
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$dayNumber',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                            ? (isDark ? AppColors.bgDark : AppColors.surfaceLight)
                            : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: dotColor ?? Colors.transparent,
                        shape: BoxShape.circle,
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
  }

  void _showQuickAttendancePicker(BuildContext context, ClassSessionEntity session, String dateIso) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPastOrToday = dateIso.compareTo(DateFormatter.toIsoDate(DateTime.now())) <= 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.cardDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
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

                  // Header
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              session.subjectName,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${DateFormatter.formatTime12h(session.startTime)} – ${DateFormatter.formatTime12h(session.endTime)}  •  $dateIso',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 1-TAP ATTENDANCE BUTTONS (if today or past)
                  if (isPastOrToday) ...[
                    Text(
                      'MARK ATTENDANCE:',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: session.attendanceOutcome == 'PRESENT'
                                  ? AppColors.presentGreen
                                  : (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : AppColors.presentContainerLight),
                              foregroundColor: session.attendanceOutcome == 'PRESENT'
                                  ? Colors.white
                                  : (isDark ? AppColors.presentGreenDark : AppColors.presentGreenText),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.check_rounded, size: 16),
                            label: const Text('Present', style: TextStyle(fontWeight: FontWeight.w600)),
                            onPressed: () {
                              Navigator.pop(context);
                              ref.read(attendanceRecordsProvider.notifier).markAttendance(
                                sessionId: session.id,
                                slotId: session.sourceRefId ?? session.id,
                                subjectId: session.subjectComponentId,
                                sessionDate: dateIso,
                                outcome: 'PRESENT',
                              );
                              AppToast.success(context, 'Marked Present for ${session.subjectName}');
                            },
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: session.attendanceOutcome == 'ABSENT'
                                  ? AppColors.absentRed
                                  : (isDark ? const Color(0xFF4C0519).withValues(alpha: 0.3) : AppColors.absentContainerLight),
                              foregroundColor: session.attendanceOutcome == 'ABSENT'
                                  ? Colors.white
                                  : (isDark ? const Color(0xFFFB7185) : AppColors.absentRedText),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.close_rounded, size: 16),
                            label: const Text('Absent', style: TextStyle(fontWeight: FontWeight.w600)),
                            onPressed: () {
                              Navigator.pop(context);
                              ref.read(attendanceRecordsProvider.notifier).markAttendance(
                                sessionId: session.id,
                                slotId: session.sourceRefId ?? session.id,
                                subjectId: session.subjectComponentId,
                                sessionDate: dateIso,
                                outcome: 'ABSENT',
                              );
                              AppToast.info(context, 'Marked Absent for ${session.subjectName}');
                            },
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: session.attendanceOutcome == 'CANCELLED'
                                  ? AppColors.cancelledViolet
                                  : (isDark ? const Color(0xFF2E1065).withValues(alpha: 0.3) : AppColors.cancelledContainerLight),
                              foregroundColor: session.attendanceOutcome == 'CANCELLED'
                                  ? Colors.white
                                  : (isDark ? const Color(0xFFA78BFA) : AppColors.cancelledVioletText),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.block_rounded, size: 16),
                            label: const Text('Cancelled', style: TextStyle(fontWeight: FontWeight.w600)),
                            onPressed: () {
                              Navigator.pop(context);
                              ref.read(attendanceRecordsProvider.notifier).markAttendance(
                                sessionId: session.id,
                                slotId: session.sourceRefId ?? session.id,
                                subjectId: session.subjectComponentId,
                                sessionDate: dateIso,
                                outcome: 'CANCELLED',
                              );
                              AppToast.info(context, 'Marked Cancelled for ${session.subjectName}');
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],

                  // SCHEDULE ACTIONS SECTION
                  Text(
                    'SCHEDULE ACTIONS:',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Reschedule for this date only
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
                    title: const Text('Change room / time for this date only', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Override this date without affecting weekly timetable', style: TextStyle(fontSize: 11)),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RescheduleSessionScreen(
                            session: session,
                            dateIso: dateIso,
                          ),
                        ),
                      );
                    },
                  ),

                  // Update room for all weekly slots of this subject
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
                      Navigator.pop(context);
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
                          builder: (context) => SubjectRoomManagerScreen(
                            subject: sub,
                            initialRoom: session.room,
                          ),
                        ),
                      );
                    },
                  ),

                  // Edit this recurring weekly slot permanently
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
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddEditSlotScreen(
                            existingSlot: session,
                            initialDayOfWeek: session.dayOfWeek ?? DateFormatter.getDayOfWeek(DateTime.tryParse(dateIso) ?? DateTime.now()),
                          ),
                        ),
                      );
                    },
                  ),

                  // Cancel class for this date only
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
                    title: const Text('Remove from this date only', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Erase this session from this date\'s schedule', style: TextStyle(fontSize: 11)),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                    onTap: () async {
                      Navigator.pop(context);
                      if (session.sourceRefId != null) {
                        await ref.read(scheduleExceptionsProvider.notifier).addOrUpdateException(
                          timetableSlotId: session.sourceRefId!,
                          exceptionDate: dateIso,
                          actionType: 'CANCELLED',
                        );
                        if (context.mounted) {
                          AppToast.info(context, 'Removed ${session.subjectName} for $dateIso');
                        }
                      }
                    },
                  ),

                  // Edit master slot or manage all slots
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
                    subtitle: const Text('View, add, and customize all weekly days and rooms', style: TextStyle(fontSize: 11)),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                    onTap: () {
                      Navigator.pop(context);
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

  void _showAddExtraClassDialog(BuildContext context, String dateIso) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subjects = ref.read(subjectsProvider);

    if (subjects.isEmpty) {
      AppToast.error(context, 'Please add at least one subject first');
      return;
    }

    String selectedSubjectId = subjects.first.id;
    TimeOfDay extraStart = const TimeOfDay(hour: 10, minute: 0);
    TimeOfDay extraEnd = const TimeOfDay(hour: 11, minute: 0);
    final extraRoomController = TextEditingController();
    final extraReasonController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: isDark ? AppColors.cardDark : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('+ Extra Class on $dateIso'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SELECT SUBJECT:',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: selectedSubjectId,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: subjects.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => selectedSubjectId = v);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final p = await showTimePicker(context: ctx, initialTime: extraStart);
                          if (p != null) setDialogState(() => extraStart = p);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Start', style: TextStyle(fontSize: 10, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                              Text('${extraStart.hour.toString().padLeft(2, "0")}:${extraStart.minute.toString().padLeft(2, "0")}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final p = await showTimePicker(context: ctx, initialTime: extraEnd);
                          if (p != null) setDialogState(() => extraEnd = p);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('End', style: TextStyle(fontSize: 10, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                              Text('${extraEnd.hour.toString().padLeft(2, "0")}:${extraEnd.minute.toString().padLeft(2, "0")}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: extraRoomController,
                  style: TextStyle(fontSize: 13, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                  decoration: InputDecoration(
                    hintText: 'Room / Lab (Optional)',
                    hintStyle: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.normal,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                    filled: true,
                    fillColor: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: extraReasonController,
                  style: TextStyle(fontSize: 13, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                  decoration: InputDecoration(
                    hintText: 'Reason (e.g. Makeup Lab, Extra Lecture)',
                    hintStyle: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.normal,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                    filled: true,
                    fillColor: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  final startStr = '${extraStart.hour.toString().padLeft(2, "0")}:${extraStart.minute.toString().padLeft(2, "0")}';
                  final endStr = '${extraEnd.hour.toString().padLeft(2, "0")}:${extraEnd.minute.toString().padLeft(2, "0")}';
                  await ref.read(extraClassesProvider.notifier).addExtraClass(
                    subjectId: selectedSubjectId,
                    classDate: dateIso,
                    startTime: startStr,
                    endTime: endStr,
                    room: extraRoomController.text.trim().isNotEmpty ? extraRoomController.text.trim() : null,
                    reason: extraReasonController.text.trim().isNotEmpty ? extraReasonController.text.trim() : null,
                  );
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    AppToast.success(context, 'Added extra class on $dateIso');
                  }
                },
                child: const Text('Add Class'),
              ),
            ],
          );
        },
      ),
    );
  }
}
