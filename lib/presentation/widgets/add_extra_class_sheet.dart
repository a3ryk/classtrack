import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/ui/app_toast.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/uuid_generator.dart';
import '../../domain/entities/subject_entity.dart';
import '../providers/app_state_provider.dart';

/// Premium Tactile Bottom Slider Sheet for Scheduling Extra Classes
/// Supports both existing subjects and on-the-fly new subject creation.
class AddExtraClassSheet extends ConsumerStatefulWidget {
  final String dateIso;
  final DateTime? initialDate;
  final String? editExtraId;
  final String? initialSubjectId;
  final TimeOfDay? initialStartTime;
  final TimeOfDay? initialEndTime;
  final String? initialRoom;
  final String? initialReason;

  const AddExtraClassSheet({
    super.key,
    required this.dateIso,
    this.initialDate,
    this.editExtraId,
    this.initialSubjectId,
    this.initialStartTime,
    this.initialEndTime,
    this.initialRoom,
    this.initialReason,
  });

  static Future<void> show(
    BuildContext context, {
    required String dateIso,
    DateTime? initialDate,
    String? editExtraId,
    String? initialSubjectId,
    TimeOfDay? initialStartTime,
    TimeOfDay? initialEndTime,
    String? initialRoom,
    String? initialReason,
  }) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: AnimationStyle(
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
        duration: const Duration(milliseconds: 320),
      ),
      builder: (context) => RepaintBoundary(
        child: AddExtraClassSheet(
          dateIso: dateIso,
          initialDate: initialDate,
          editExtraId: editExtraId,
          initialSubjectId: initialSubjectId,
          initialStartTime: initialStartTime,
          initialEndTime: initialEndTime,
          initialRoom: initialRoom,
          initialReason: initialReason,
        ),
      ),
    );
  }

  @override
  ConsumerState<AddExtraClassSheet> createState() => _AddExtraClassSheetState();
}

class _AddExtraClassSheetState extends ConsumerState<AddExtraClassSheet> {
  final _roomController = TextEditingController();
  final _reasonController = TextEditingController();

  // Existing subject selection
  String? _selectedSubjectId;

  // New subject fields
  bool _isNewSubject = false;
  final _newSubjectNameController = TextEditingController();
  final _newSubjectCodeController = TextEditingController();
  String _newSubjectCategory = 'MAJOR';
  String _newSubjectColorHex = '#4F46E5';

  static const List<String> _categories = [
    'MAJOR',
    'MINOR',
    'AEC',
    'MDC',
    'SEC',
    'VAC',
    'ELECTIVE',
  ];

  static const List<String> _colorPalette = [
    '#4F46E5',
    '#2563EB',
    '#0D9488',
    '#16A34A',
    '#D97706',
    '#DC2626',
    '#9333EA',
    '#DB2777',
  ];

  TimeOfDay _startTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 11, minute: 0);
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialRoom != null) {
      _roomController.text = widget.initialRoom!;
    }
    if (widget.initialReason != null) {
      _reasonController.text = widget.initialReason!;
    }
    if (widget.initialStartTime != null) {
      _startTime = widget.initialStartTime!;
    }
    if (widget.initialEndTime != null) {
      _endTime = widget.initialEndTime!;
    }

    final subjects = ref.read(subjectsProvider);
    if (widget.initialSubjectId != null && subjects.any((s) => s.id == widget.initialSubjectId)) {
      _selectedSubjectId = widget.initialSubjectId;
      _isNewSubject = false;
    } else if (subjects.isNotEmpty) {
      _selectedSubjectId = subjects.first.id;
      _isNewSubject = false;
    } else {
      _isNewSubject = true;
    }
  }

  @override
  void dispose() {
    _roomController.dispose();
    _reasonController.dispose();
    _newSubjectNameController.dispose();
    _newSubjectCodeController.dispose();
    super.dispose();
  }

  Future<void> _pickStartTime() async {
    HapticFeedback.selectionClick();
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null && mounted) {
      setState(() {
        _startTime = picked;
        // Automatically nudge end time if needed
        final startMinutes = _startTime.hour * 60 + _startTime.minute;
        final endMinutes = _endTime.hour * 60 + _endTime.minute;
        if (endMinutes <= startMinutes) {
          _endTime = TimeOfDay(
            hour: (_startTime.hour + 1) % 24,
            minute: _startTime.minute,
          );
        }
      });
    }
  }

  Future<void> _pickEndTime() async {
    HapticFeedback.selectionClick();
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null && mounted) {
      setState(() => _endTime = picked);
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatTimeDisplay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Color _parseSubjectColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) return const Color(0xFF6366F1);
    try {
      final hex = colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF6366F1);
    }
  }

  Future<void> _saveExtraClass() async {
    if (_isSaving) return;

    final subjects = ref.read(subjectsProvider);
    String subjectIdToUse;
    String subjectNameToUse;

    if (_isNewSubject) {
      final name = _newSubjectNameController.text.trim();
      if (name.isEmpty) {
        AppToast.error(context, 'Please enter subject name');
        return;
      }

      // Check if subject with same name already exists
      final existing = subjects.where((s) => s.name.trim().toLowerCase() == name.toLowerCase()).firstOrNull;
      if (existing != null) {
        subjectIdToUse = existing.id;
        subjectNameToUse = existing.name;
      } else {
        setState(() => _isSaving = true);
        HapticFeedback.mediumImpact();

        final activeSem = ref.read(activeSemesterProvider);
        final targetPct = ref.read(targetPercentageProvider);
        final code = _newSubjectCodeController.text.trim();

        final newSub = SubjectEntity(
          id: UuidGenerator.generate(),
          semesterId: activeSem.id,
          name: name,
          code: code.isNotEmpty ? code : null,
          category: _newSubjectCategory,
          credits: 3,
          targetAttendancePct: targetPct,
          baselineHeld: 0,
          baselineAttended: 0,
          colorHex: _newSubjectColorHex,
          isArchived: false,
          components: [],
        );

        try {
          await ref.read(subjectsProvider.notifier).addSubject(newSub);
        } catch (e) {
          if (mounted) {
            setState(() => _isSaving = false);
            AppToast.error(context, 'Failed to create subject: $e');
            return;
          }
        }
        subjectIdToUse = newSub.id;
        subjectNameToUse = newSub.name;
      }
    } else {
      if (subjects.isEmpty) {
        AppToast.error(context, 'Please add a subject first');
        return;
      }
      subjectIdToUse = _selectedSubjectId ?? subjects.first.id;
      final sub = subjects.firstWhere((s) => s.id == subjectIdToUse, orElse: () => subjects.first);
      subjectNameToUse = sub.name;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final startStr = _formatTimeOfDay(_startTime);
    final endStr = _formatTimeOfDay(_endTime);
    final roomStr = _roomController.text.trim();
    final reasonStr = _reasonController.text.trim();

    try {
      if (widget.editExtraId != null) {
        await ref.read(extraClassesProvider.notifier).updateExtraClass(
          id: widget.editExtraId!,
          subjectId: subjectIdToUse,
          classDate: widget.dateIso,
          startTime: startStr,
          endTime: endStr,
          room: roomStr.isNotEmpty ? roomStr : null,
          reason: reasonStr.isNotEmpty ? reasonStr : null,
        );
        if (mounted) {
          AppToast.success(context, 'Updated Extra Class for $subjectNameToUse');
          Navigator.pop(context);
        }
      } else {
        await ref.read(extraClassesProvider.notifier).addExtraClass(
          subjectId: subjectIdToUse,
          classDate: widget.dateIso,
          startTime: startStr,
          endTime: endStr,
          room: roomStr.isNotEmpty ? roomStr : null,
          reason: reasonStr.isNotEmpty ? reasonStr : null,
        );
        if (mounted) {
          AppToast.success(context, 'Added Extra Class for $subjectNameToUse');
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppToast.error(context, 'Failed to save extra class: $e');
      }
    }
  }

  Future<void> _deleteExtraClass() async {
    if (widget.editExtraId == null || _isSaving) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.cardDark : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Delete Extra Class?', style: TextStyle(fontWeight: FontWeight.w700)),
          content: const Text(
            'Are you sure you want to delete this extra class? This will also remove any attendance recorded for it.',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.absentRed),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true && mounted) {
      setState(() => _isSaving = true);
      HapticFeedback.mediumImpact();
      try {
        await ref.read(extraClassesProvider.notifier).deleteExtraClass(widget.editExtraId!);
        if (mounted) {
          AppToast.info(context, 'Extra class deleted');
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSaving = false);
          AppToast.error(context, 'Failed to delete extra class: $e');
        }
      }
    }
  }

  Future<void> _openSubjectPicker(BuildContext context, List<SubjectEntity> subjects) async {
    HapticFeedback.selectionClick();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = subjects.where((s) {
              final q = query.toLowerCase().trim();
              if (q.isEmpty) return true;
              return s.name.toLowerCase().contains(q) ||
                  (s.code?.toLowerCase().contains(q) ?? false) ||
                  s.category.toLowerCase().contains(q);
            }).toList();

            final currentId = _selectedSubjectId ?? (subjects.isNotEmpty ? subjects.first.id : null);

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.70,
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                  width: 0.8,
                ),
              ),
              child: SafeArea(
                top: false,
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
                          color: isDark ? AppColors.borderDark : const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select Subject',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
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
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Search field if > 4 subjects
                    if (subjects.length > 4) ...[
                      Container(
                        height: 40,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                            width: 0.8,
                          ),
                        ),
                        child: TextField(
                          autofocus: false,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search subjects...',
                            hintStyle: TextStyle(
                              fontSize: 12.5,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              size: 18,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onChanged: (val) {
                            setSheetState(() => query = val);
                          },
                        ),
                      ),
                    ],

                    // Subject Items List
                    Flexible(
                      child: filtered.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text(
                                  'No matching subjects found',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                  ),
                                ),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 6),
                              itemBuilder: (context, index) {
                                final sub = filtered[index];
                                final isSelected = sub.id == currentId;
                                final subColor = _parseSubjectColor(sub.colorHex);

                                return InkWell(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() => _selectedSubjectId = sub.id);
                                    Navigator.pop(sheetContext);
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? (isDark ? const Color(0xFF1E1B4B) : const Color(0xFFEEF2FF))
                                          : (isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC)),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF6366F1)
                                            : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                                        width: isSelected ? 1.4 : 0.8,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: subColor,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: subColor.withValues(alpha: 0.4),
                                                blurRadius: 4,
                                                offset: const Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                sub.name,
                                                style: TextStyle(
                                                  fontSize: 13.5,
                                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (sub.code != null && sub.code!.isNotEmpty) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  sub.code!,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                          decoration: BoxDecoration(
                                            color: subColor.withValues(alpha: isDark ? 0.25 : 0.12),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            sub.category,
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                              color: subColor,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Icon(
                                          isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                                          size: 18,
                                          color: isSelected
                                              ? const Color(0xFF6366F1)
                                              : (isDark ? AppColors.borderDark : const Color(0xFFCBD5E1)),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),

                    const SizedBox(height: 12),

                    // Add New Subject Action Tile
                    InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.pop(sheetContext);
                        setState(() => _isNewSubject = true);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1B4B) : const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? const Color(0xFF4338CA) : const Color(0xFFC7D2FE),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.add_rounded,
                              size: 16,
                              color: Color(0xFF6366F1),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Add New Subject',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF6366F1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
    final subjects = ref.watch(subjectsProvider);

    DateTime parsedDate;
    try {
      parsedDate = widget.initialDate ?? DateFormatter.parseIsoDate(widget.dateIso);
    } catch (_) {
      parsedDate = DateTime.now();
    }
    final formattedDate = DateFormat('EEEE, MMM d, yyyy').format(parsedDate);

    final selectedSubject = subjects.where((s) => s.id == _selectedSubjectId).firstOrNull ??
        (subjects.isNotEmpty ? subjects.first : null);

    final subjectColor = _isNewSubject
        ? _parseSubjectColor(_newSubjectColorHex)
        : (selectedSubject != null
            ? _parseSubjectColor(selectedSubject.colorHex)
            : const Color(0xFF6366F1));

    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
          width: 0.8,
        ),
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
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.borderDark : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: subjectColor.withValues(alpha: isDark ? 0.25 : 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      widget.editExtraId != null ? Icons.edit_calendar_rounded : Icons.more_time_rounded,
                      color: subjectColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.editExtraId != null ? 'Edit Extra Class' : 'Add Extra Class',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.editExtraId != null)
                    IconButton(
                      tooltip: 'Delete Extra Class',
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.absentRed),
                      onPressed: _isSaving ? null : _deleteExtraClass,
                    ),
                ],
              ),

              const SizedBox(height: 20),

              // Subject Section Header with Clean Toggle Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isNewSubject ? 'NEW SUBJECT' : 'SELECT SUBJECT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                  ),
                  if (subjects.isNotEmpty)
                    InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _isNewSubject = !_isNewSubject);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1B4B) : const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? const Color(0xFF4338CA) : const Color(0xFFC7D2FE),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isNewSubject ? Icons.arrow_back_rounded : Icons.add_rounded,
                              size: 13,
                              color: const Color(0xFF6366F1),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _isNewSubject ? 'Choose Existing' : 'New Subject',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF6366F1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // Existing Subject Selector Card vs New Subject Form
              if (!_isNewSubject && subjects.isNotEmpty) ...[
                InkWell(
                  onTap: () => _openSubjectPicker(context, subjects),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: subjectColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: subjectColor.withValues(alpha: 0.4),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                selectedSubject?.name ?? 'Select a Subject',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (selectedSubject != null && (selectedSubject.code?.isNotEmpty ?? false)) ...[
                                const SizedBox(height: 2),
                                Text(
                                  selectedSubject.code!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (selectedSubject != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: subjectColor.withValues(alpha: isDark ? 0.25 : 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              selectedSubject.category,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: subjectColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Icon(
                          Icons.unfold_more_rounded,
                          size: 18,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // New Subject Name
                TextField(
                  controller: _newSubjectNameController,
                  textCapitalization: TextCapitalization.words,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.menu_book_rounded,
                      size: 20,
                      color: subjectColor,
                    ),
                    hintText: 'Subject Name (e.g. Cloud Computing)',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                    filled: true,
                    fillColor: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: subjectColor, width: 1.5),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Category Chips Selector
                Text(
                  'CATEGORY',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  ),
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = cat == _newSubjectCategory;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _newSubjectCategory = cat);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? subjectColor
                                  : (isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? subjectColor
                                    : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 12),

                // Palette Color Dots Row & Optional Code
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ACCENT COLOR',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _colorPalette.map((hex) {
                                final color = _parseSubjectColor(hex);
                                final isSelected = hex == _newSubjectColorHex;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: InkWell(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(() => _newSubjectColorHex = hex);
                                    },
                                    borderRadius: BorderRadius.circular(14),
                                    child: Container(
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                        border: isSelected
                                            ? Border.all(color: Colors.white, width: 2)
                                            : null,
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: color.withValues(alpha: 0.6),
                                                  blurRadius: 5,
                                                  spreadRadius: 1,
                                                ),
                                              ]
                                            : null,
                                      ),
                                      alignment: Alignment.center,
                                      child: isSelected
                                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                                          : null,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 95,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CODE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _newSubjectCodeController,
                            textCapitalization: TextCapitalization.characters,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                            decoration: InputDecoration(
                              hintText: 'e.g. CS301',
                              hintStyle: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                              ),
                              filled: true,
                              fillColor: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: subjectColor, width: 1.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),

              // Time Picker Row
              Text(
                'TIME SLOT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickStartTime,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 18,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Start',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  _formatTimeDisplay(_startTime),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _pickEndTime,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 18,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'End',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  _formatTimeDisplay(_endTime),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Room Input
              Text(
                'LOCATION (OPTIONAL)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _roomController,
                style: TextStyle(
                  fontSize: 13.5,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.meeting_room_outlined,
                    size: 20,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  ),
                  hintText: 'Room or Lab (e.g. Lab 2, Hall 301)',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  ),
                  filled: true,
                  fillColor: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: subjectColor, width: 1.5),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Reason Input
              Text(
                'REASON / TOPIC (OPTIONAL)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _reasonController,
                style: TextStyle(
                  fontSize: 13.5,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.edit_note_rounded,
                    size: 20,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  ),
                  hintText: 'e.g. Makeup Class, Revision, Exam Prep',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  ),
                  filled: true,
                  fillColor: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: subjectColor, width: 1.5),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: isDark ? AppColors.borderDark : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveExtraClass,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: subjectColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              widget.editExtraId != null ? 'Save Changes' : 'Add Extra Class',
                              style: const TextStyle(
                                fontSize: 14,
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
      ),
    );
  }
}
