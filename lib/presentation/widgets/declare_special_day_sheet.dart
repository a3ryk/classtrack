import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_theme_tokens.dart';
import '../../core/constants/app_colors.dart';
import '../../core/ui/app_toast.dart';
import '../../core/utils/date_formatter.dart';
import '../../domain/entities/class_session_entity.dart';
import '../../domain/services/schedule_engine.dart';
import '../providers/app_state_provider.dart';

enum SpecialDayTab { holiday, exam }

enum SpecialDayScope { singleDay, multiDay, period }

/// Unified Modal Bottom Sheet for Declaring Holidays or Exams (Single-day, Multi-day, or Period-specific)
class DeclareSpecialDaySheet extends ConsumerStatefulWidget {
  final DateTime initialDate;
  final SpecialDayTab initialTab;
  final String? initialSlotId;
  final List<ClassSessionEntity>? todaySessions;

  const DeclareSpecialDaySheet({
    super.key,
    required this.initialDate,
    this.initialTab = SpecialDayTab.holiday,
    this.initialSlotId,
    this.todaySessions,
  });

  static Future<void> show(
    BuildContext context, {
    required DateTime initialDate,
    SpecialDayTab initialTab = SpecialDayTab.holiday,
    String? initialSlotId,
    List<ClassSessionEntity>? todaySessions,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: AnimationStyle(
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
        duration: const Duration(milliseconds: 280),
      ),
      builder: (context) => RepaintBoundary(
        child: DeclareSpecialDaySheet(
          initialDate: initialDate,
          initialTab: initialTab,
          initialSlotId: initialSlotId,
          todaySessions: todaySessions,
        ),
      ),
    );
  }

  @override
  ConsumerState<DeclareSpecialDaySheet> createState() => _DeclareSpecialDaySheetState();
}

class _DeclareSpecialDaySheetState extends ConsumerState<DeclareSpecialDaySheet> {
  late SpecialDayTab _selectedTab;
  late SpecialDayScope _selectedScope;

  // Shared controllers & date state
  final _holidayTitleController = TextEditingController();
  final _examTitleController = TextEditingController();
  late DateTime _startDate;
  late DateTime _endDate;
  String? _selectedSlotId;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialSlotId != null ? SpecialDayTab.exam : widget.initialTab;
    _selectedScope = widget.initialSlotId != null ? SpecialDayScope.period : SpecialDayScope.singleDay;

    _startDate = widget.initialDate;
    _endDate = widget.initialDate.add(const Duration(days: 4));
    _selectedSlotId = widget.initialSlotId;

    if (_selectedSlotId == null && widget.todaySessions != null && widget.todaySessions!.isNotEmpty) {
      _selectedSlotId = widget.todaySessions!.first.sourceRefId ?? widget.todaySessions!.first.id;
    }

    // Auto-select Exam tab if an exam is active on this date and no holiday is active
    final holidays = ref.read(holidaysProvider);
    final activeHoliday = ScheduleResolutionEngine.getActiveHolidayForDate(holidays, widget.initialDate);
    final activeExam = ScheduleResolutionEngine.getActiveExamForDate(holidays, widget.initialDate);
    final activePeriodExams = widget.todaySessions?.where((s) => s.isExam).toList() ?? [];
    if (activeHoliday == null && (activeExam != null || activePeriodExams.isNotEmpty)) {
      _selectedTab = SpecialDayTab.exam;
    }
  }

  @override
  void dispose() {
    _holidayTitleController.dispose();
    _examTitleController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({
    required DateTime initial,
    required DateTime first,
    required DateTime last,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) {
      setState(() => onPicked(picked));
    }
  }

  Future<void> _saveHoliday() async {
    if (_isSaving) return;

    final rawTitle = _holidayTitleController.text.trim();
    final title = rawTitle.isNotEmpty ? rawTitle : 'Holiday';

    setState(() => _isSaving = true);

    final startIso = DateFormatter.toIsoDate(_startDate);
    final isRange = _selectedScope == SpecialDayScope.multiDay;
    final endIso = isRange ? DateFormatter.toIsoDate(_endDate) : startIso;
    final holidayItem = HolidayItem(
      title: title,
      startDate: startIso,
      endDate: endIso,
      category: 'HOLIDAY',
    );

    final dateLabel = startIso == endIso
        ? DateFormat('MMM d, yyyy').format(_startDate)
        : '${DateFormat('MMM d').format(_startDate)} – ${DateFormat('MMM d, yyyy').format(_endDate)}';

    if (mounted) {
      AppToast.success(context, 'Holiday "$title" declared for $dateLabel');
      Navigator.pop(context);
    }

    try {
      await ref.read(holidaysProvider.notifier).addHoliday(holidayItem);
    } catch (_) {}
  }

  Future<void> _saveExam() async {
    if (_isSaving) return;

    final rawTitle = _examTitleController.text.trim();
    final examTitle = rawTitle.isNotEmpty ? rawTitle : 'Exam';

    setState(() => _isSaving = true);

    if (_selectedScope == SpecialDayScope.period) {
      if (_selectedSlotId == null || _selectedSlotId!.isEmpty) {
        setState(() => _isSaving = false);
        AppToast.error(context, 'Please select a class period');
        return;
      }
      final dateIso = DateFormatter.toIsoDate(widget.initialDate);
      if (mounted) {
        AppToast.success(context, 'Exam "$examTitle" set for selected period');
        Navigator.pop(context);
      }
      try {
        await ref.read(scheduleExceptionsProvider.notifier).setExamForSlot(
          timetableSlotId: _selectedSlotId!,
          exceptionDate: dateIso,
          examTitle: examTitle,
        );
      } catch (_) {}
    } else if (_selectedScope == SpecialDayScope.singleDay) {
      final startIso = DateFormatter.toIsoDate(_startDate);
      final dateLabel = DateFormat('MMM d, yyyy').format(_startDate);

      if (mounted) {
        AppToast.success(context, 'Exam Day "$examTitle" declared for $dateLabel');
        Navigator.pop(context);
      }
      try {
        await ref.read(holidaysProvider.notifier).addExam(
          title: examTitle,
          startDate: startIso,
          endDate: startIso,
        );
      } catch (_) {}
    } else {
      // Multi-Day Exam
      final startIso = DateFormatter.toIsoDate(_startDate);
      final endIso = DateFormatter.toIsoDate(_endDate);
      final daysCount = _endDate.difference(_startDate).inDays + 1;
      final dateLabel = '${DateFormat('MMM d').format(_startDate)} – ${DateFormat('MMM d, yyyy').format(_endDate)} ($daysCount days)';

      if (mounted) {
        AppToast.success(context, 'Exam "$examTitle" declared for $dateLabel');
        Navigator.pop(context);
      }
      try {
        await ref.read(holidaysProvider.notifier).addExam(
          title: examTitle,
          startDate: startIso,
          endDate: endIso,
        );
      } catch (_) {}
    }
  }

  Future<void> _removeActiveHoliday(String dateIso) async {
    Navigator.pop(context);
    await ref.read(holidaysProvider.notifier).removeHolidayForDate(dateIso);
    if (mounted) {
      AppToast.info(context, 'Holiday removed for $dateIso');
    }
  }

  Future<void> _removeActiveExam(String dateIso) async {
    Navigator.pop(context);
    await ref.read(holidaysProvider.notifier).removeExamForDate(dateIso);
    if (mounted) {
      AppToast.info(context, 'Exam removed for $dateIso');
    }
  }

  Future<void> _removePeriodExam(String slotId, String dateIso, String subjectName) async {
    Navigator.pop(context);
    await ref.read(scheduleExceptionsProvider.notifier).removeExamForSlot(slotId, dateIso);
    if (mounted) {
      AppToast.info(context, 'Exam removed for $subjectName');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = Theme.of(context).extension<AppThemeTokens>();
    final isCute = tokens?.isCute ?? false;
    final holidays = ref.watch(holidaysProvider);
    final dateIso = DateFormatter.toIsoDate(widget.initialDate);

    final activeHoliday = ScheduleResolutionEngine.getActiveHolidayForDate(holidays, widget.initialDate);
    final activeExam = ScheduleResolutionEngine.getActiveExamForDate(holidays, widget.initialDate);
    final activePeriodExams = widget.todaySessions?.where((s) => s.isPeriodExam).toList() ?? [];

    return RepaintBoundary(
      child: Container(
        constraints: BoxConstraints(
          minHeight: 460,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        margin: isCute ? const EdgeInsets.fromLTRB(14, 0, 14, 16) : EdgeInsets.zero,
        padding: EdgeInsets.fromLTRB(20, isCute ? 14 : 12, 20, MediaQuery.of(context).viewInsets.bottom + (isCute ? 18 : 20)),
        decoration: BoxDecoration(
          color: isDark ? (isCute ? const Color(0xFF183122) : AppColors.cardDark) : Colors.white,
          borderRadius: isCute ? BorderRadius.circular(28) : const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(
            color: isDark ? (isCute ? const Color(0xFF264A34) : AppColors.borderDark) : (isCute ? const Color(0xFFDFE8DC) : const Color(0xFFE2E8F0)),
            width: isCute ? 1.2 : 1.0,
          ),
          boxShadow: isCute
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: isCute ? 38 : 36,
                    height: isCute ? 4.5 : 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: isDark ? (isCute ? const Color(0xFF264A34) : AppColors.borderDark) : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(isCute ? 3 : 2),
                    ),
                  ),
                ),

                // Top Segmented Tab Switch: [ 🏖️ Holiday | 📝 Exam / Test ]
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? (isCute ? const Color(0xFF112318) : AppColors.surfaceDark) : (isCute ? const Color(0xFFFAF7F2) : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(isCute ? 14 : 12),
                    border: Border.all(
                      color: isDark ? (isCute ? const Color(0xFF264A34) : AppColors.borderDark) : (isCute ? const Color(0xFFDFE8DC) : const Color(0xFFE2E8F0)),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTabButton(
                          title: 'Holiday',
                          icon: Icons.beach_access_rounded,
                          isSelected: _selectedTab == SpecialDayTab.holiday,
                          isDark: isDark,
                          isCute: isCute,
                          onTap: () => setState(() {
                            _selectedTab = SpecialDayTab.holiday;
                            if (_selectedScope == SpecialDayScope.period) {
                              _selectedScope = SpecialDayScope.singleDay;
                            }
                          }),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _buildTabButton(
                          title: 'Exam / Test',
                          icon: Icons.assignment_rounded,
                          isSelected: _selectedTab == SpecialDayTab.exam,
                          isDark: isDark,
                          isCute: isCute,
                          onTap: () => setState(() => _selectedTab = SpecialDayTab.exam),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Active Banner if already declared for this date
                if (_selectedTab == SpecialDayTab.holiday && activeHoliday != null) ...[
                  _buildActiveStatusBanner(
                    title: 'Active Holiday: ${activeHoliday.title}',
                    subtitle: activeHoliday.startDate == activeHoliday.endDate
                        ? 'Declared for ${activeHoliday.startDate}'
                        : '${activeHoliday.startDate} to ${activeHoliday.endDate}',
                    icon: Icons.beach_access_rounded,
                    isDark: isDark,
                    isCute: isCute,
                    onRemove: () => _removeActiveHoliday(dateIso),
                  ),
                  const SizedBox(height: 14),
                ] else if (_selectedTab == SpecialDayTab.exam) ...[
                  if (activeExam != null) ...[
                    _buildActiveStatusBanner(
                      title: 'Active Exam: ${activeExam.title}',
                      subtitle: activeExam.startDate == activeExam.endDate
                          ? 'Declared for ${activeExam.startDate}'
                          : '${activeExam.startDate} to ${activeExam.endDate}',
                      icon: Icons.assignment_rounded,
                      isDark: isDark,
                      isCute: isCute,
                      onRemove: () => _removeActiveExam(dateIso),
                    ),
                    const SizedBox(height: 10),
                  ],
                  for (final periodSession in activePeriodExams) ...[
                    _buildActiveStatusBanner(
                      title: 'Active Period Exam: ${periodSession.examTitle ?? "Exam"}',
                      subtitle: '${periodSession.subjectName} (${DateFormatter.formatTime12h(periodSession.startTime)} - ${DateFormatter.formatTime12h(periodSession.endTime)})',
                      icon: Icons.assignment_rounded,
                      isDark: isDark,
                      isCute: isCute,
                      onRemove: () => _removePeriodExam(periodSession.sourceRefId ?? periodSession.id, dateIso, periodSession.subjectName),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (activeExam != null || activePeriodExams.isNotEmpty)
                    const SizedBox(height: 4),
                ],

                // Unified body form with smooth in-place transitions
                _buildUnifiedForm(isDark, isCute),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required bool isCute,
    required VoidCallback onTap,
  }) {
    final activeBg = isDark
        ? (isCute ? const Color(0xFF2E593E) : const Color(0xFF2E3039))
        : (isCute ? const Color(0xFF558A50) : AppColors.primaryLight);
    final activeText = Colors.white;
    final inactiveText = isDark
        ? (isCute ? const Color(0xFF8BA590) : AppColors.textSecondaryDark)
        : (isCute ? const Color(0xFF5A6E5E) : AppColors.textSecondaryLight);

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      borderRadius: BorderRadius.circular(isCute ? 10 : 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(isCute ? 10 : 8),
          boxShadow: isSelected && !isDark
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 1))]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? activeText : inactiveText,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: isCute
                    ? GoogleFonts.quicksand(
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? activeText : inactiveText,
                      )
                    : TextStyle(
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? activeText : inactiveText,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveStatusBanner({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isDark,
    required bool isCute,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? (isCute ? const Color(0xFF1A3826) : const Color(0xFF22232A))
            : (isCute ? const Color(0xFFF0FDF4) : const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(isCute ? 14 : 10),
        border: Border.all(
          color: isDark
              ? (isCute ? const Color(0xFF2E593E) : AppColors.borderDark)
              : (isCute ? const Color(0xFFDCFCE7) : const Color(0xFFE2E8F0)),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isDark
                ? (isCute ? const Color(0xFFE8F4EB) : AppColors.textPrimaryDark)
                : (isCute ? const Color(0xFF192E21) : AppColors.textPrimaryLight),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: isCute
                      ? GoogleFonts.quicksand(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isDark ? const Color(0xFFE8F4EB) : const Color(0xFF192E21),
                        )
                      : TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.textPrimaryLight,
                        ),
                ),
                Text(
                  subtitle,
                  style: isCute
                      ? GoogleFonts.quicksand(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF98B5A3) : const Color(0xFF526B5C),
                        )
                      : TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onRemove,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.absentRed,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Remove',
              style: isCute
                  ? GoogleFonts.quicksand(fontSize: 12, fontWeight: FontWeight.w800)
                  : const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // UNIFIED IN-PLACE FORM
  // ==========================================
  Widget _buildUnifiedForm(bool isDark, bool isCute) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Scope Selector
        Text(
          _selectedTab == SpecialDayTab.holiday ? 'Holiday Scope' : 'Exam Scope',
          style: isCute
              ? GoogleFonts.quicksand(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFF8BA590) : const Color(0xFF5A6E5E),
                )
              : TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark
                ? (isCute ? const Color(0xFF112318) : AppColors.surfaceDark)
                : (isCute ? const Color(0xFFFAF7F2) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(isCute ? 12 : 10),
            border: Border.all(
              color: isDark
                  ? (isCute ? const Color(0xFF264A34) : AppColors.borderDark)
                  : (isCute ? const Color(0xFFDFE8DC) : const Color(0xFFE2E8F0)),
              width: 0.8,
            ),
          ),
          child: _selectedTab == SpecialDayTab.holiday
              ? Row(
                  children: [
                    Expanded(
                      child: _buildScopeOption(
                        key: const ValueKey('holiday_scope_single'),
                        title: 'Single Day',
                        isSelected: _selectedScope != SpecialDayScope.multiDay,
                        isDark: isDark,
                        isCute: isCute,
                        onTap: () {
                          if (_selectedScope == SpecialDayScope.multiDay) {
                            setState(() => _selectedScope = SpecialDayScope.singleDay);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildScopeOption(
                        key: const ValueKey('holiday_scope_multi'),
                        title: 'Multi-Day (Break)',
                        isSelected: _selectedScope == SpecialDayScope.multiDay,
                        isDark: isDark,
                        isCute: isCute,
                        onTap: () {
                          if (_selectedScope != SpecialDayScope.multiDay) {
                            setState(() {
                              _selectedScope = SpecialDayScope.multiDay;
                              if (_endDate.isBefore(_startDate)) {
                                _endDate = _startDate;
                              }
                            });
                          }
                        },
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _buildScopeOption(
                        key: const ValueKey('exam_scope_single'),
                        title: 'Single Day',
                        isSelected: _selectedScope == SpecialDayScope.singleDay,
                        isDark: isDark,
                        isCute: isCute,
                        onTap: () => setState(() => _selectedScope = SpecialDayScope.singleDay),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildScopeOption(
                        key: const ValueKey('exam_scope_multi'),
                        title: 'Multi-Day',
                        isSelected: _selectedScope == SpecialDayScope.multiDay,
                        isDark: isDark,
                        isCute: isCute,
                        onTap: () {
                          setState(() {
                            _selectedScope = SpecialDayScope.multiDay;
                            if (_endDate.isBefore(_startDate)) {
                              _endDate = _startDate;
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildScopeOption(
                        key: const ValueKey('exam_scope_period'),
                        title: 'Period',
                        isSelected: _selectedScope == SpecialDayScope.period,
                        isDark: isDark,
                        isCute: isCute,
                        onTap: () => setState(() => _selectedScope = SpecialDayScope.period),
                      ),
                    ),
                  ],
                ),
        ),

        // 2. Dynamic content area with smooth height animation
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Target Class Period (Exam Period Only)
              if (_selectedTab == SpecialDayTab.exam && _selectedScope == SpecialDayScope.period) ...[
                const SizedBox(height: 14),
                Text(
                  'Target Class Period',
                  style: isCute
                      ? GoogleFonts.quicksand(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFF8BA590) : const Color(0xFF5A6E5E),
                        )
                      : TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                ),
                const SizedBox(height: 6),
                _buildPeriodSelector(isDark, isCute),
              ],

              const SizedBox(height: 14),

              // Title / Occasion Label
              Text(
                _selectedTab == SpecialDayTab.holiday
                    ? 'Occasion / Reason'
                    : (_selectedScope == SpecialDayScope.multiDay ? 'Exam Series / Title' : 'Exam / Quiz Title'),
                style: isCute
                    ? GoogleFonts.quicksand(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFF8BA590) : const Color(0xFF5A6E5E),
                      )
                    : TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _selectedTab == SpecialDayTab.holiday
                    ? _holidayTitleController
                    : _examTitleController,
                style: isCute
                    ? GoogleFonts.quicksand(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF192E21),
                      )
                    : TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: _selectedTab == SpecialDayTab.holiday
                      ? 'e.g., Diwali, Sports Day, College Fest'
                      : (_selectedScope == SpecialDayScope.multiDay
                          ? 'e.g., End Semester Examinations, Midterm Week'
                          : 'e.g., Midterm 1, Quiz 2, Lab Practical'),
                  hintStyle: isCute
                      ? GoogleFonts.quicksand(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF648671) : const Color(0xFF849E8E),
                        )
                      : TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.textSecondaryDark : const Color(0xFF94A3B8),
                        ),
                  filled: true,
                  fillColor: isDark
                      ? (isCute ? const Color(0xFF112318) : AppColors.surfaceDark)
                      : (isCute ? const Color(0xFFFAF7F2) : const Color(0xFFF8FAFC)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(isCute ? 14 : 10),
                    borderSide: BorderSide(
                      color: isDark
                          ? (isCute ? const Color(0xFF264A34) : AppColors.borderDark)
                          : (isCute ? const Color(0xFFDFE8DC) : const Color(0xFFCBD5E1)),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(isCute ? 14 : 10),
                    borderSide: BorderSide(
                      color: isDark
                          ? (isCute ? const Color(0xFF264A34) : AppColors.borderDark)
                          : (isCute ? const Color(0xFFDFE8DC) : const Color(0xFFCBD5E1)),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(isCute ? 14 : 10),
                    borderSide: BorderSide(
                      color: isDark
                          ? (isCute ? const Color(0xFF6FA769) : AppColors.textPrimaryDark)
                          : (isCute ? const Color(0xFF558A50) : AppColors.primaryLight),
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              // Date Pickers
              if (_selectedScope == SpecialDayScope.multiDay) ...[
                const SizedBox(height: 14),
                _buildDateRangePicker(
                  startDate: _startDate,
                  endDate: _endDate,
                  onStartPicked: (d) {
                    setState(() {
                      _startDate = d;
                      if (_endDate.isBefore(_startDate)) {
                        _endDate = _startDate;
                      }
                    });
                  },
                  onEndPicked: (d) => setState(() => _endDate = d),
                  isDark: isDark,
                  isCute: isCute,
                ),
              ] else if (_selectedScope == SpecialDayScope.singleDay) ...[
                const SizedBox(height: 14),
                _buildDateTile(
                  label: _selectedTab == SpecialDayTab.holiday ? 'Holiday Date' : 'Exam Date',
                  date: _startDate,
                  onTap: () => _pickDate(
                    initial: _startDate,
                    first: DateTime(2020),
                    last: DateTime(2035),
                    onPicked: (d) => setState(() => _startDate = d),
                  ),
                  isDark: isDark,
                  isCute: isCute,
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 3. Pinned Action Button with single constant label 'Save'
        SizedBox(
          width: double.infinity,
          height: 46,
          child: FilledButton.icon(
            onPressed: _selectedTab == SpecialDayTab.holiday ? _saveHoliday : _saveExam,
            icon: const Icon(
              Icons.check_rounded,
              size: 18,
            ),
            label: Text(
              'Save',
              style: isCute
                  ? GoogleFonts.quicksand(fontSize: 14, fontWeight: FontWeight.w800)
                  : const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: isDark
                  ? (isCute ? const Color(0xFF6FA769) : AppColors.textPrimaryDark)
                  : (isCute ? const Color(0xFF558A50) : AppColors.primaryLight),
              foregroundColor: isDark
                  ? (isCute ? const Color(0xFF112318) : AppColors.bgDark)
                  : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isCute ? 16 : 10)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector(bool isDark, bool isCute) {
    if (widget.todaySessions == null || widget.todaySessions!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark
              ? (isCute ? const Color(0xFF112318) : AppColors.surfaceDark)
              : (isCute ? const Color(0xFFFAF7F2) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(isCute ? 14 : 10),
          border: Border.all(
            color: isDark
                ? (isCute ? const Color(0xFF264A34) : AppColors.borderDark)
                : (isCute ? const Color(0xFFDFE8DC) : const Color(0xFFCBD5E1)),
          ),
        ),
        child: Text(
          'No classes scheduled for today to assign an exam to.',
          style: isCute
              ? GoogleFonts.quicksand(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF8BA590) : const Color(0xFF5A6E5E),
                )
              : TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark
            ? (isCute ? const Color(0xFF112318) : AppColors.surfaceDark)
            : (isCute ? const Color(0xFFFAF7F2) : const Color(0xFFF8FAFC)),
        borderRadius: BorderRadius.circular(isCute ? 14 : 10),
        border: Border.all(
          color: isDark
              ? (isCute ? const Color(0xFF264A34) : AppColors.borderDark)
              : (isCute ? const Color(0xFFDFE8DC) : const Color(0xFFCBD5E1)),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedSlotId,
          isExpanded: true,
          dropdownColor: isDark
              ? (isCute ? const Color(0xFF183122) : AppColors.cardDark)
              : Colors.white,
          items: widget.todaySessions!.map((s) {
            final slotId = s.sourceRefId ?? s.id;
            return DropdownMenuItem<String>(
              value: slotId,
              child: Text(
                '${s.subjectName} (${DateFormatter.formatTime12h(s.startTime)} - ${DateFormatter.formatTime12h(s.endTime)})',
                style: isCute
                    ? GoogleFonts.quicksand(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF192E21),
                      )
                    : TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedSlotId = val);
          },
        ),
      ),
    );
  }

  Widget _buildDateRangePicker({
    required DateTime startDate,
    required DateTime endDate,
    required ValueChanged<DateTime> onStartPicked,
    required ValueChanged<DateTime> onEndPicked,
    required bool isDark,
    required bool isCute,
  }) {
    final daysCount = endDate.difference(startDate).inDays + 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDateTile(
                label: 'Start Date',
                date: startDate,
                onTap: () => _pickDate(
                  initial: startDate,
                  first: DateTime(2020),
                  last: DateTime(2035),
                  onPicked: onStartPicked,
                ),
                isDark: isDark,
                isCute: isCute,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildDateTile(
                label: 'End Date',
                date: endDate,
                onTap: () => _pickDate(
                  initial: endDate.isBefore(startDate) ? startDate : endDate,
                  first: startDate,
                  last: DateTime(2035),
                  onPicked: onEndPicked,
                ),
                isDark: isDark,
                isCute: isCute,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: isDark
                  ? (isCute ? const Color(0xFF1D3D29) : const Color(0xFF27282F))
                  : (isCute ? const Color(0xFFEBF4E8) : const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(isCute ? 999 : 6),
              border: Border.all(
                color: isDark
                    ? (isCute ? const Color(0xFF2E593E) : AppColors.borderDark)
                    : (isCute ? const Color(0xFFDFE8DC) : const Color(0xFFE2E8F0)),
              ),
            ),
            child: Text(
              '$daysCount Days Total',
              style: isCute
                  ? GoogleFonts.quicksand(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isDark ? const Color(0xFF6FA769) : const Color(0xFF558A50),
                    )
                  : TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScopeOption({
    Key? key,
    required String title,
    required bool isSelected,
    required bool isDark,
    required bool isCute,
    required VoidCallback onTap,
  }) {
    final activeBg = isDark
        ? (isCute ? const Color(0xFF2E593E) : const Color(0xFF2E3039))
        : (isCute ? const Color(0xFF558A50) : AppColors.primaryLight);
    final activeText = Colors.white;
    final inactiveText = isDark
        ? (isCute ? const Color(0xFF8BA590) : AppColors.textSecondaryDark)
        : (isCute ? const Color(0xFF5A6E5E) : AppColors.textSecondaryLight);

    return InkWell(
      key: key,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      borderRadius: BorderRadius.circular(isCute ? 9 : 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 8.5, horizontal: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(isCute ? 9 : 8),
          boxShadow: isSelected && !isDark
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 1))]
              : null,
        ),
        child: Text(
          title,
          style: isCute
              ? GoogleFonts.quicksand(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? activeText : inactiveText,
                )
              : TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? activeText : inactiveText,
                ),
        ),
      ),
    );
  }

  Widget _buildDateTile({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
    required bool isDark,
    required bool isCute,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: isCute
              ? GoogleFonts.quicksand(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFF8BA590) : const Color(0xFF5A6E5E),
                )
              : TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
        ),
        const SizedBox(height: 5),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(isCute ? 14 : 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: isDark
                  ? (isCute ? const Color(0xFF112318) : AppColors.surfaceDark)
                  : (isCute ? const Color(0xFFFAF7F2) : const Color(0xFFF8FAFC)),
              borderRadius: BorderRadius.circular(isCute ? 14 : 10),
              border: Border.all(
                color: isDark
                    ? (isCute ? const Color(0xFF264A34) : AppColors.borderDark)
                    : (isCute ? const Color(0xFFDFE8DC) : const Color(0xFFCBD5E1)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('EEE, MMM d, yyyy').format(date),
                  style: isCute
                      ? GoogleFonts.quicksand(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF192E21),
                        )
                      : TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                ),
                Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: isDark
                      ? (isCute ? const Color(0xFF8BA590) : AppColors.textSecondaryDark)
                      : (isCute ? const Color(0xFF5A6E5E) : AppColors.textSecondaryLight),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
