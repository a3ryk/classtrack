import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/ui/app_toast.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/uuid_generator.dart';
import '../../domain/entities/attendance_stats.dart';
import '../../domain/entities/semester_entity.dart';
import '../../domain/services/semester_sequencer.dart';
import '../providers/app_state_provider.dart';

/// Interactive multi-step wizard for wrapping up and archiving the current semester
/// and seamlessly initializing the new academic term.
class SemesterTransitionWizard extends ConsumerStatefulWidget {
  const SemesterTransitionWizard({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SemesterTransitionWizard(),
    );
  }

  @override
  ConsumerState<SemesterTransitionWizard> createState() => _SemesterTransitionWizardState();
}

class _SemesterTransitionWizardState extends ConsumerState<SemesterTransitionWizard> {
  int _currentStep = 0; // 0: Wrap-up, 1: Configure, 2: Subjects
  int _direction = 1;
  final ScrollController _scrollController = ScrollController();
  bool _isSubmitting = false;

  void _goToStep(int newStep) {
    if (newStep == _currentStep) return;
    setState(() {
      _direction = newStep > _currentStep ? 1 : -1;
      _currentStep = newStep;
    });
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  // Step 2 Form Controllers
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _yearController;
  late TermType _selectedTermType;
  late DateTime _startDate;
  DateTime? _endDate;
  bool _hasEndDate = true;

  // Step 3 Subject Selection
  bool _carryOverSubjects = true;
  final Set<String> _selectedSubjectIds = {};
  bool _hasInitializedSubjects = false;

  @override
  void initState() {
    super.initState();
    final activeSem = ref.read(activeSemesterProvider);

    _selectedTermType = activeSem.isUnset ? TermType.semester : activeSem.termType;

    // Smart sequential naming suggestion
    final suggestedName = activeSem.isUnset
        ? 'Semester I'
        : SemesterSequencer.suggestNextTermName(
            currentName: activeSem.name,
            termType: _selectedTermType,
          );
    _nameController = TextEditingController(text: suggestedName);

    // Smart date progression
    final now = DateTime.now();
    if (!activeSem.isUnset && activeSem.endDate != null) {
      final dayAfter = activeSem.endDate!.add(const Duration(days: 1));
      _startDate = dayAfter.isBefore(now) ? now : dayAfter;
    } else {
      _startDate = now;
    }

    _endDate = _startDate.add(Duration(days: _selectedTermType == TermType.yearly ? 365 : 140));
    _hasEndDate = true;

    // Smart academic year suggestion
    final suggestedYear = activeSem.isUnset
        ? '-'
        : SemesterSequencer.suggestNextAcademicYear(
            currentAcademicYear: activeSem.academicYear,
            currentEndDate: activeSem.endDate ?? now,
            nextStartDate: _startDate,
          );
    _yearController = TextEditingController(text: suggestedYear);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _yearController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTermTypeChanged(TermType newType) {
    setState(() {
      _selectedTermType = newType;
      final activeSem = ref.read(activeSemesterProvider);
      _nameController.text = SemesterSequencer.suggestNextTermName(
        currentName: activeSem.name,
        termType: newType,
      );
      if (_hasEndDate) {
        if (newType == TermType.yearly) {
          _endDate = _startDate.add(const Duration(days: 365));
        } else if (newType == TermType.trimester) {
          _endDate = _startDate.add(const Duration(days: 90));
        } else {
          _endDate = _startDate.add(const Duration(days: 140));
        }
      }
    });
  }

  List<String> _getPresetsForType(TermType type) {
    switch (type) {
      case TermType.yearly:
        return SemesterSequencer.yearPresets;
      case TermType.trimester:
        return SemesterSequencer.trimesterPresets;
      case TermType.semester:
      case TermType.custom:
        return const [
          'Semester I',
          'Semester II',
          'Semester III',
          'Semester IV',
          'Semester V',
          'Semester VI',
          'Semester VII',
          'Semester VIII',
        ];
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(_startDate)) {
          _endDate = _startDate.add(Duration(days: _selectedTermType == TermType.yearly ? 365 : 140));
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate.add(Duration(days: _selectedTermType == TermType.yearly ? 365 : 140)),
      firstDate: _startDate,
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _completeTransition() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final newSem = SemesterEntity(
        id: UuidGenerator.generate(),
        name: _nameController.text.trim(),
        academicYear: _yearController.text.trim(),
        termType: _selectedTermType,
        startDate: _startDate,
        endDate: _hasEndDate ? _endDate : null,
        isCurrent: true,
        isArchived: false,
      );

      final carryIds = _carryOverSubjects ? _selectedSubjectIds.toList() : <String>[];

      await ref.read(semestersListProvider.notifier).transitionSemester(
        newSemester: newSem,
        carryOverSubjectIds: carryIds,
      );

      if (mounted) {
        Navigator.pop(context);
        AppToast.success(context, '🎉 Welcome to ${newSem.name}!');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        AppToast.error(context, 'Failed to transition: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeSem = ref.watch(activeSemesterProvider);
    final overallStats = ref.watch(overallStatsProvider);
    final currentSubjects = ref.watch(subjectsProvider);

    // Initialize subject selection once on load
    if (!_hasInitializedSubjects && currentSubjects.isNotEmpty) {
      _selectedSubjectIds.addAll(currentSubjects.map((s) => s.id));
      _hasInitializedSubjects = true;
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header with Step Title & Close Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Semester Transition Wizard',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getStepSubtitle(_currentStep),
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Step Progress Indicator
          Row(
            children: [
              _buildStepIndicator(0, 'Wrap-Up', isDark),
              const SizedBox(width: 6),
              _buildStepIndicator(1, 'New Term', isDark),
              const SizedBox(width: 6),
              _buildStepIndicator(2, 'Subjects', isDark),
            ],
          ),
          const SizedBox(height: 16),

          // Step Content with Smooth Shared-Axis Transition
          Flexible(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final inAnimation = Tween<Offset>(
                    begin: Offset(_direction * 0.12, 0.0),
                    end: Offset.zero,
                  ).animate(animation);

                  return SlideTransition(
                    position: inAnimation,
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey<int>(_currentStep),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    child: _buildCurrentStepContent(
                      isDark: isDark,
                      activeSem: activeSem,
                      overallStats: overallStats,
                      currentSubjects: currentSubjects,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Bottom Action Navigation Row
          Row(
            children: [
              if (_currentStep > 0) ...[
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        side: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _isSubmitting ? null : () => _goToStep(_currentStep - 1),
                      child: const Text('Back', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                flex: _currentStep > 0 ? 2 : 1,
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      foregroundColor: isDark ? AppColors.bgDark : AppColors.surfaceLight,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            if (_currentStep == 0) {
                              _goToStep(1);
                            } else if (_currentStep == 1) {
                              if (_formKey.currentState!.validate()) {
                                _goToStep(2);
                              }
                            } else {
                              _completeTransition();
                            }
                          },
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _currentStep == 2 ? 'Archive & Launch New Term' : 'Continue',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
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

  String _getStepSubtitle(int step) {
    switch (step) {
      case 0:
        return 'Step 1 of 3: Final performance milestone report';
      case 1:
        return 'Step 2 of 3: Configure your next academic term';
      case 2:
        return 'Step 3 of 3: Select continuing subjects or start fresh';
      default:
        return '';
    }
  }

  Widget _buildStepIndicator(int stepIndex, String title, bool isDark) {
    final isActive = _currentStep == stepIndex;
    final isDone = _currentStep > stepIndex;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (isDone) _goToStep(stepIndex);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isActive
                ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                : (isDone
                    ? (isDark ? AppColors.presentContainerDark : AppColors.presentContainerLight)
                    : (isDark ? AppColors.pillDark : const Color(0xFFF1F5F9))),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isActive
                  ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                  : (isDone
                      ? (isDark ? AppColors.presentGreenDark.withValues(alpha: 0.3) : AppColors.presentGreenText.withValues(alpha: 0.3))
                      : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0))),
            ),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isDone
                    ? Icons.check_rounded
                    : (stepIndex == 0
                        ? Icons.insights_rounded
                        : (stepIndex == 1 ? Icons.edit_calendar_rounded : Icons.library_books_rounded)),
                size: 13,
                color: isActive
                    ? (isDark ? AppColors.bgDark : AppColors.surfaceLight)
                    : (isDone
                        ? (isDark ? AppColors.presentGreenDark : AppColors.presentGreenText)
                        : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
              ),
              const SizedBox(width: 5),
              Text(
                title,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  color: isActive
                      ? (isDark ? AppColors.bgDark : AppColors.surfaceLight)
                      : (isDone
                          ? (isDark ? AppColors.presentGreenDark : AppColors.presentGreenText)
                          : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent({
    required bool isDark,
    required SemesterEntity activeSem,
    required OverallAttendanceStats overallStats,
    required List<dynamic> currentSubjects,
  }) {
    if (_currentStep == 0) {
      return _buildStep1WrapUp(
        isDark: isDark,
        activeSem: activeSem,
        stats: overallStats,
      );
    } else if (_currentStep == 1) {
      return _buildStep2Configure(isDark: isDark);
    } else {
      return _buildStep3Subjects(
        isDark: isDark,
        subjects: currentSubjects,
      );
    }
  }

  // ==========================================
  // STEP 1: MILESTONE WRAP-UP & REPORT CARD
  // ==========================================
  Widget _buildStep1WrapUp({
    required bool isDark,
    required SemesterEntity activeSem,
    required OverallAttendanceStats stats,
  }) {
    final isPremature = activeSem.endDate != null && DateTime.now().isBefore(activeSem.endDate!);
    final isZeroHeld = stats.totalHeld == 0;
    final pct = stats.overallPercentage;
    final isSafe = pct >= stats.targetPercentage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isPremature)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF78350F).withValues(alpha: 0.25) : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? const Color(0xFFB45309).withValues(alpha: 0.4) : const Color(0xFFFDE68A),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFD97706)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Scheduled term end is ${DateFormatter.formatDateIndian(activeSem.endDate!)}. Archiving now will lock this semester\'s records.',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
            ),
          ),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.pillDark : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CLOSING TERM: ${activeSem.name.toUpperCase()}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            isZeroHeld ? 'N/A' : '${pct.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: isZeroHeld
                                  ? (isDark ? AppColors.textMutedDark : AppColors.textMutedLight)
                                  : (isSafe
                                      ? (isDark ? AppColors.presentGreenDark : AppColors.presentGreenText)
                                      : (isDark ? AppColors.absentRedDark : AppColors.absentRed)),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Target: ${stats.targetPercentage.toInt()}%',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isZeroHeld
                          ? (isDark ? AppColors.pillDark : const Color(0xFFE2E8F0))
                          : (isSafe
                              ? (isDark ? AppColors.presentContainerDark : AppColors.presentContainerLight)
                              : (isDark ? AppColors.absentContainerDark : AppColors.absentContainerLight)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isZeroHeld ? 'NO RECORDS' : (isSafe ? 'GOAL ACHIEVED' : 'BELOW GOAL'),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: isZeroHeld
                            ? (isDark ? AppColors.textMutedDark : AppColors.textMutedLight)
                            : (isSafe
                                ? (isDark ? AppColors.presentGreenDark : AppColors.presentGreenText)
                                : (isDark ? AppColors.absentRedDark : AppColors.absentRed)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _buildMetricBox('Held', '${stats.totalHeld}', isDark),
                  const SizedBox(width: 6),
                  _buildMetricBox('Attended', '${stats.totalAttended}', isDark),
                  const SizedBox(width: 6),
                  _buildMetricBox('Missed', '${stats.totalHeld - stats.totalAttended}', isDark),
                  const SizedBox(width: 6),
                  _buildMetricBox('Cancelled', '${stats.totalCancelled}', isDark),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        Text(
          'SUBJECT STANDINGS (${stats.subjectStats.length})',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
        ),
        const SizedBox(height: 6),
        if (stats.subjectStats.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'No subjects logged in this term.',
                style: TextStyle(fontSize: 12, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: stats.subjectStats.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, idx) {
              final sub = stats.subjectStats[idx];
              final subSafe = sub.currentPercentage >= sub.targetPercentage;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.pillDark : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sub.subjectName,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${sub.totalAttended}/${sub.totalHeld} attended',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      sub.totalHeld == 0 ? '--%' : '${sub.currentPercentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: sub.totalHeld == 0
                            ? (isDark ? AppColors.textMutedDark : AppColors.textMutedLight)
                            : (subSafe
                                ? (isDark ? AppColors.presentGreenDark : AppColors.presentGreenText)
                                : (isDark ? AppColors.absentRedDark : AppColors.absentRed)),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildMetricBox(String label, String value, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // STEP 2: CONFIGURE NEW TERM
  // ==========================================
  Widget _buildStep2Configure({required bool isDark}) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STRUCTURE TYPE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: TermType.values.map((type) {
              final isSel = _selectedTermType == type;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: InkWell(
                    onTap: () => _onTermTypeChanged(type),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSel
                            ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                            : (isDark ? AppColors.pillDark : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSel
                              ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                              : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: Text(
                        type.displayName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                          color: isSel
                              ? (isDark ? AppColors.bgDark : AppColors.surfaceLight)
                              : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          Text(
            'NAME PRESETS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: _getPresetsForType(_selectedTermType).map((preset) {
                final isSel = _nameController.text == preset;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () => setState(() => _nameController.text = preset),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSel
                            ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                            : (isDark ? AppColors.pillDark : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSel
                              ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                              : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: Text(
                        preset,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                          color: isSel
                              ? (isDark ? AppColors.bgDark : AppColors.surfaceLight)
                              : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          Text(
            'TERM NAME',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _nameController,
            style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'e.g. Semester IV, 2nd Year',
              filled: true,
              fillColor: isDark ? AppColors.pillDark : const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0))),
            ),
            validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a name for the new term' : null,
          ),
          const SizedBox(height: 12),

          Text(
            'ACADEMIC YEAR',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _yearController,
            style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'e.g. 2026-2027',
              filled: true,
              fillColor: isDark ? AppColors.pillDark : const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0))),
            ),
          ),
          const SizedBox(height: 14),

          Text(
            'TERM DATES',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _pickStartDate,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.pillDark : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Start Date', style: TextStyle(fontSize: 10, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                        const SizedBox(height: 2),
                        Text(
                          DateFormatter.formatDateIndian(_startDate),
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: _hasEndDate ? _pickEndDate : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.pillDark : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('End Date', style: TextStyle(fontSize: 10, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                        const SizedBox(height: 2),
                        Text(
                          _hasEndDate && _endDate != null ? DateFormatter.formatDateIndian(_endDate!) : 'Continuous',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _hasEndDate
                                ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                                : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                          ),
                        ),
                      ],
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

  // ==========================================
  // STEP 3: SUBJECT SETUP (NO TEMPLATE DEPENDENCY)
  // ==========================================
  Widget _buildStep3Subjects({
    required bool isDark,
    required List<dynamic> subjects,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _carryOverSubjects = true),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _carryOverSubjects
                        ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                        : (isDark ? AppColors.pillDark : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _carryOverSubjects
                          ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                          : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Text(
                    'Carry Forward Subjects',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: _carryOverSubjects ? FontWeight.bold : FontWeight.w600,
                      color: _carryOverSubjects
                          ? (isDark ? AppColors.bgDark : AppColors.surfaceLight)
                          : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _carryOverSubjects = false),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: !_carryOverSubjects
                        ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                        : (isDark ? AppColors.pillDark : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: !_carryOverSubjects
                          ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                          : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Text(
                    'Start Fresh (Blank)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: !_carryOverSubjects ? FontWeight.bold : FontWeight.w600,
                      color: !_carryOverSubjects
                          ? (isDark ? AppColors.bgDark : AppColors.surfaceLight)
                          : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (_carryOverSubjects) ...[
          if (subjects.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              alignment: Alignment.center,
              child: Text(
                'No previous subjects to carry forward. New semester will start with a fresh slate.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
              ),
            )
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SELECT SUBJECTS (${_selectedSubjectIds.length}/${subjects.length})',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  ),
                ),
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          _selectedSubjectIds.addAll(subjects.map((s) => s.id as String));
                        });
                      },
                      child: const Text('Select All', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentIndigoLight)),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: () => setState(() => _selectedSubjectIds.clear()),
                      child: Text('Deselect', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: subjects.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, idx) {
                final sub = subjects[idx];
                final isChecked = _selectedSubjectIds.contains(sub.id);

                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isChecked) {
                        _selectedSubjectIds.remove(sub.id);
                      } else {
                        _selectedSubjectIds.add(sub.id);
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.pillDark : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isChecked
                            ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                            : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                        width: isChecked ? 1.2 : 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: isChecked,
                          visualDensity: VisualDensity.compact,
                          activeColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          checkColor: isDark ? AppColors.bgDark : Colors.white,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedSubjectIds.add(sub.id);
                              } else {
                                _selectedSubjectIds.remove(sub.id);
                              }
                            });
                          },
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sub.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${sub.category} · Target ${sub.targetAttendancePct.toInt()}%',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1B4B).withValues(alpha: 0.3) : const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? const Color(0xFF4F46E5).withValues(alpha: 0.3) : const Color(0xFFC7D2FE),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.refresh_rounded, size: 16, color: AppColors.accentIndigoLight),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Selected subjects will reset to 0 classes held / 0 attended for the new semester. All historical records remain safely intact in the archived semester.',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? const Color(0xFFC7D2FE) : const Color(0xFF3730A3),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ] else ...[
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDark ? AppColors.pillDark : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.auto_stories_outlined,
                  size: 36,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
                const SizedBox(height: 10),
                Text(
                  'Starting With A Blank Catalog',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your new semester will be activated immediately. You can create new subjects and build your timetable whenever your syllabus is announced.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
