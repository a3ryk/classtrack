import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/ui/app_toast.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/uuid_generator.dart';
import '../../data/database/app_database.dart';
import '../../domain/entities/subject_entity.dart';
import '../providers/app_state_provider.dart';

class BatchAddSlotDialog extends ConsumerStatefulWidget {
  const BatchAddSlotDialog({super.key});

  @override
  ConsumerState<BatchAddSlotDialog> createState() => _BatchAddSlotDialogState();
}

class _BatchAddSlotDialogState extends ConsumerState<BatchAddSlotDialog> {
  final _formKey = GlobalKey<FormState>();
  final _subjectNameController = TextEditingController();
  final _subjectCodeController = TextEditingController();
  final _roomController = TextEditingController();
  final _teacherController = TextEditingController();

  final Set<int> _selectedDays = {1, 3, 5}; // Mon, Wed, Fri default
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  String _selectedCategory = 'MAJOR';
  String _selectedComponentType = 'LECTURE';

  // Date Scope Variables
  bool _useCustomDateRange = false;
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  static const List<String> _dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  static const List<int> _dayValues = [7, 1, 2, 3, 4, 5, 6];

  final List<String> _categories = ['MAJOR', 'MINOR', 'AEC', 'MDC', 'SEC', 'VAC', 'ELECTIVE'];

  @override
  void initState() {
    super.initState();
    _startTime = const TimeOfDay(hour: 9, minute: 0);
    _endTime = const TimeOfDay(hour: 10, minute: 0);
    final activeSem = ref.read(activeSemesterProvider);
    _customStartDate = activeSem.startDate;
    _customEndDate = activeSem.endDate;
  }

  @override
  void dispose() {
    _subjectNameController.dispose();
    _subjectCodeController.dispose();
    _roomController.dispose();
    _teacherController.dispose();
    super.dispose();
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatTimeOfDayDisplay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  void _applyPreset(Set<int> days) {
    setState(() {
      _selectedDays.clear();
      _selectedDays.addAll(days);
    });
  }

  Future<void> _saveBatchSlots() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final startMins = _startTime.hour * 60 + _startTime.minute;
    final endMins = _endTime.hour * 60 + _endTime.minute;
    if (endMins <= startMins) {
      AppToast.error(context, 'End time must be after start time');
      return;
    }

    if (_selectedDays.isEmpty) {
      AppToast.error(context, 'Please select at least one day for this batch');
      return;
    }

    if (_useCustomDateRange && _customStartDate == null) {
      AppToast.error(context, 'Please select a start date for the custom date range');
      return;
    }

    if (_useCustomDateRange && _customStartDate != null && _customEndDate != null && _customEndDate!.isBefore(_customStartDate!)) {
      AppToast.error(context, 'End date cannot be earlier than start date');
      return;
    }

    final subjectName = _subjectNameController.text.trim();
    final subjectCode = _subjectCodeController.text.trim();
    final activeSem = ref.read(activeSemesterProvider);

    if (activeSem.isUnset) {
      AppToast.error(context, 'Please create an active semester first');
      return;
    }

    final subjects = ref.read(subjectsProvider);
    SubjectEntity? targetSub;

    final existingIndex = subjects.indexWhere((s) => s.name.toLowerCase() == subjectName.toLowerCase());
    if (existingIndex != -1) {
      targetSub = subjects[existingIndex];
    } else {
      final newSub = SubjectEntity(
        id: UuidGenerator.generate(),
        semesterId: activeSem.id,
        name: subjectName,
        code: subjectCode.isNotEmpty ? subjectCode : null,
        category: _selectedCategory,
        credits: 3,
        targetAttendancePct: 75.0,
        baselineHeld: 0,
        baselineAttended: 0,
        isArchived: false,
        colorHex: '#4F46E5',
        components: [],
      );
      await ref.read(subjectsProvider.notifier).addSubject(newSub);
      targetSub = newSub;
    }

    final String? fromStr = _useCustomDateRange && _customStartDate != null
        ? DateFormatter.toIsoDate(_customStartDate!)
        : null;
    final String? untilStr = _useCustomDateRange && _customEndDate != null
        ? DateFormatter.toIsoDate(_customEndDate!)
        : null;

    final nowIso = DateTime.now().toIso8601String();
    final List<TimetableSlotData> batchList = [];

    for (final dayIndex in _selectedDays) {
      batchList.add(
        TimetableSlotData(
          id: UuidGenerator.generate(),
          semesterId: activeSem.id,
          subjectComponentId: targetSub.id,
          dayOfWeek: dayIndex,
          startTime: _formatTimeOfDay(_startTime),
          endTime: _formatTimeOfDay(_endTime),
          room: _roomController.text.trim().isNotEmpty ? _roomController.text.trim() : null,
          teacherName: _teacherController.text.trim().isNotEmpty ? _teacherController.text.trim() : null,
          notes: _selectedComponentType,
          effectiveFrom: fromStr,
          effectiveUntil: untilStr,
          createdAt: nowIso,
          updatedAt: nowIso,
        ),
      );
    }

    await ref.read(timetableSlotsProvider.notifier).addBatchSlots(batchList);

    if (mounted) {
      Navigator.pop(context);
      AppToast.success(context, 'Added ${batchList.length} classes for $subjectName across selected days');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subjects = ref.watch(subjectsProvider);

    return Dialog(
      backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Batch Add Slots',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              'Schedule one subject across multiple days',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // DAYS SELECTION (Sunday First)
                  Text(
                    'SELECT RECURRING DAYS:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (i) {
                      final dayVal = _dayValues[i];
                      final isSelected = _selectedDays.contains(dayVal);
                      return InkWell(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedDays.remove(dayVal);
                            } else {
                              _selectedDays.add(dayVal);
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                                : (isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9)),
                            border: Border.all(
                              color: isSelected
                                  ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                                  : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _dayLabels[i],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? (isDark ? AppColors.bgDark : AppColors.surfaceLight)
                                  : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),

                  // PRESET SHORTCUTS
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildPresetChip('Weekdays (Mon-Fri)', {1, 2, 3, 4, 5}, isDark),
                        const SizedBox(width: 6),
                        _buildPresetChip('MWF', {1, 3, 5}, isDark),
                        const SizedBox(width: 6),
                        _buildPresetChip('TTS', {2, 4, 6}, isDark),
                        const SizedBox(width: 6),
                        _buildPresetChip('All 7 Days', {7, 1, 2, 3, 4, 5, 6}, isDark),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // TIME PICKERS (Clock Cards)
                  Text(
                    'TIME SCHEDULE:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _pickStartTime,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.access_time_rounded, size: 16, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Start', style: TextStyle(fontSize: 10, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                                    Text(_formatTimeOfDayDisplay(_startTime), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: _pickEndTime,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.access_time_filled_rounded, size: 16, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('End', style: TextStyle(fontSize: 10, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                                    Text(_formatTimeOfDayDisplay(_endTime), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // SUBJECT NAME
                  Text(
                    'SUBJECT NAME:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                  ),
                  const SizedBox(height: 6),
                  RawAutocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) return subjects.map((s) => s.name);
                      return subjects
                          .where((s) => s.name.toLowerCase().contains(textEditingValue.text.toLowerCase()))
                          .map((s) => s.name);
                    },
                    onSelected: (String selection) {
                      _subjectNameController.text = selection;
                      final matched = subjects.firstWhere((s) => s.name == selection);
                      setState(() {
                        _selectedCategory = matched.category;
                        if (matched.code != null) _subjectCodeController.text = matched.code!;
                      });
                    },
                    fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                      if (_subjectNameController.text.isNotEmpty && controller.text.isEmpty) {
                        controller.text = _subjectNameController.text;
                      }
                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        onEditingComplete: onEditingComplete,
                        style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'e.g. Operating Systems',
                          hintStyle: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight, fontSize: 13),
                          filled: true,
                          fillColor: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? AppColors.accentIndigoDark : AppColors.accentIndigoLight, width: 1.5)),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Enter subject name' : null,
                        onChanged: (val) => _subjectNameController.text = val,
                      );
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(8),
                          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                          child: Container(
                            constraints: const BoxConstraints(maxHeight: 180, maxWidth: 300),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                            ),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (BuildContext context, int index) {
                                final String option = options.elementAt(index);
                                return InkWell(
                                  onTap: () => onSelected(option),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    child: Text(
                                      option,
                                      style: TextStyle(
                                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // CATEGORY CHIPS
                  Text(
                    'COURSE CATEGORY:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((cat) {
                        final isSel = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InkWell(
                            onTap: () => setState(() => _selectedCategory = cat),
                            borderRadius: BorderRadius.circular(6),
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                                    : (isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9)),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isSel
                                      ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                                      : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                                ),
                              ),
                              child: Text(
                                cat,
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
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // COURSE TYPE (Lecture, Practical / Lab, Tutorial, Seminar)
                  Text(
                    'COURSE TYPE:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      {'type': 'LECTURE', 'label': 'Lecture', 'icon': Icons.menu_book_rounded},
                      {'type': 'PRACTICAL', 'label': 'Practical', 'icon': Icons.science_rounded},
                      {'type': 'TUTORIAL', 'label': 'Tutorial', 'icon': Icons.edit_note_rounded},
                      {'type': 'SEMINAR', 'label': 'Seminar', 'icon': Icons.groups_rounded},
                    ].map((item) {
                      final type = item['type'] as String;
                      final label = item['label'] as String;
                      final icon = item['icon'] as IconData;
                      final isSel = _selectedComponentType == type;

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.5),
                          child: InkWell(
                            onTap: () => setState(() => _selectedComponentType = type),
                            borderRadius: BorderRadius.circular(6),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(vertical: 7),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSel
                                    ? (isDark ? const Color(0xFF312E81) : const Color(0xFFEEF2FF))
                                    : (isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9)),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isSel
                                      ? (isDark ? AppColors.accentIndigoDark : AppColors.accentIndigoLight)
                                      : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                                  width: isSel ? 1.2 : 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    icon,
                                    size: 13,
                                    color: isSel
                                        ? (isDark ? const Color(0xFFA5B4FC) : AppColors.accentIndigoLight)
                                        : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                                      color: isSel
                                          ? (isDark ? const Color(0xFFA5B4FC) : AppColors.accentIndigoLight)
                                          : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  // ROOM & TEACHER
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ROOM / LAB (OPTIONAL):', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                            const SizedBox(height: 4),
                            TextFormField(
                              controller: _roomController,
                              style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Lab B',
                                hintStyle: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight, fontSize: 12),
                                filled: true,
                                fillColor: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0))),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('TEACHER (OPTIONAL):', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                            const SizedBox(height: 4),
                            TextFormField(
                              controller: _teacherController,
                              style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Dr. Roy',
                                hintStyle: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight, fontSize: 12),
                                filled: true,
                                fillColor: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0))),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // DATE BOUNDARIES
                  Text(
                    'DATE BOUNDARIES:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _useCustomDateRange = false),
                          borderRadius: BorderRadius.circular(8),
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            height: 38,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: !_useCustomDateRange
                                  ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                                  : (isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: !_useCustomDateRange
                                    ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                                    : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                              ),
                            ),
                            child: Text(
                              'Active Term',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: !_useCustomDateRange
                                    ? (isDark ? AppColors.bgDark : AppColors.surfaceLight)
                                    : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _useCustomDateRange = true),
                          borderRadius: BorderRadius.circular(8),
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            height: 38,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _useCustomDateRange
                                  ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                                  : (isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _useCustomDateRange
                                    ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                                    : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                              ),
                            ),
                            child: Text(
                              'Custom Range',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _useCustomDateRange
                                    ? (isDark ? AppColors.bgDark : AppColors.surfaceLight)
                                    : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                   if (_useCustomDateRange) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _customStartDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2035),
                              );
                              if (picked != null) {
                                setState(() {
                                  _customStartDate = picked;
                                  if (_customEndDate != null && _customEndDate!.isBefore(picked)) {
                                    _customEndDate = picked.add(const Duration(days: 90));
                                  }
                                });
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Start Date', style: TextStyle(fontSize: 10, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                                  Text(
                                    _customStartDate != null ? DateFormatter.formatDateIndian(_customStartDate!) : 'Pick Start',
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
                            onTap: () async {
                              final firstEnd = _customStartDate ?? DateTime(2020);
                              DateTime initialEnd = _customEndDate ?? firstEnd.add(const Duration(days: 90));
                              if (initialEnd.isBefore(firstEnd)) {
                                initialEnd = firstEnd;
                              }
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: initialEnd,
                                firstDate: firstEnd,
                                lastDate: DateTime(2035),
                              );
                              if (picked != null) setState(() => _customEndDate = picked);
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('End Date', style: TextStyle(fontSize: 10, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                                  Text(
                                    _customEndDate != null ? DateFormatter.formatDateIndian(_customEndDate!) : 'Continuous',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 18),

                  // FULL-WIDTH SAVE BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _saveBatchSlots,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        foregroundColor: isDark ? AppColors.bgDark : AppColors.surfaceLight,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      child: Text(
                        _selectedDays.isEmpty
                            ? 'Select Days to Add'
                            : 'Add to ${_selectedDays.length} Selected Day${_selectedDays.length > 1 ? "s" : ""}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, Set<int> days, bool isDark) {
    final isMatching = _selectedDays.length == days.length && _selectedDays.containsAll(days);
    return InkWell(
      onTap: () => _applyPreset(days),
      borderRadius: BorderRadius.circular(6),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isMatching
              ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
              : (isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isMatching
                ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isMatching ? FontWeight.bold : FontWeight.w500,
            color: isMatching
                ? (isDark ? AppColors.bgDark : AppColors.surfaceLight)
                : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
          ),
        ),
      ),
    );
  }
}
