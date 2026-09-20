import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/ui/app_toast.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/uuid_generator.dart';
import '../../../data/database/app_database.dart';
import '../../../domain/entities/class_session_entity.dart';
import '../../../domain/entities/subject_entity.dart';
import '../../providers/app_state_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_theme_tokens.dart';

class AddEditSlotScreen extends ConsumerStatefulWidget {
  final ClassSessionEntity? existingSlot;
  final int initialDayOfWeek;

  const AddEditSlotScreen({
    super.key,
    this.existingSlot,
    this.initialDayOfWeek = 7, // Default Sunday
  });

  @override
  ConsumerState<AddEditSlotScreen> createState() => _AddEditSlotScreenState();
}

class _AddEditSlotScreenState extends ConsumerState<AddEditSlotScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectNameController = TextEditingController();
  final _subjectCodeController = TextEditingController();
  String _selectedCategory = 'MAJOR';
  String _selectedComponentType = 'LECTURE';
  late int _selectedDay;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  final _roomController = TextEditingController();
  final _teacherController = TextEditingController();

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
    int day = widget.initialDayOfWeek;
    if (widget.existingSlot != null) {
      if (widget.existingSlot!.dayOfWeek != null &&
          widget.existingSlot!.dayOfWeek! >= 1 &&
          widget.existingSlot!.dayOfWeek! <= 7) {
        day = widget.existingSlot!.dayOfWeek!;
      } else if (widget.existingSlot!.sessionDate.isNotEmpty) {
        final parsed = DateTime.tryParse(widget.existingSlot!.sessionDate);
        if (parsed != null) {
          day = DateFormatter.getDayOfWeek(parsed);
        }
      }
    }
    _selectedDay = day;
    _startTime = const TimeOfDay(hour: 9, minute: 0);
    _endTime = const TimeOfDay(hour: 10, minute: 0);
    final activeSem = ref.read(activeSemesterProvider);
    _customStartDate = activeSem.startDate;
    _customEndDate = activeSem.endDate;

    if (widget.existingSlot != null) {
      final slot = widget.existingSlot!;
      _subjectNameController.text = slot.subjectName;
      _subjectCodeController.text = slot.subjectCode ?? '';
      _selectedCategory = slot.category;
      _selectedComponentType = slot.componentType;
      _roomController.text = slot.room ?? '';
      _teacherController.text = slot.teacherName ?? '';

      if (slot.effectiveFrom != null || slot.effectiveUntil != null) {
        if (slot.effectiveFrom != null && slot.effectiveFrom!.isNotEmpty) {
          _customStartDate = DateTime.tryParse(slot.effectiveFrom!);
        }
        if (slot.effectiveUntil != null && slot.effectiveUntil!.isNotEmpty) {
          _customEndDate = DateTime.tryParse(slot.effectiveUntil!);
        }
        _useCustomDateRange = true;
      }

      try {
        final startParts = slot.startTime.split(':');
        _startTime = TimeOfDay(hour: int.parse(startParts[0]), minute: int.parse(startParts[1]));
        final endParts = slot.endTime.split(':');
        _endTime = TimeOfDay(hour: int.parse(endParts[0]), minute: int.parse(endParts[1]));
      } catch (_) {}
    }
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

  Future<void> _saveSlot() async {
    if (_formKey.currentState!.validate()) {
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

      final targetSlotId = widget.existingSlot?.sourceRefId ?? widget.existingSlot?.id ?? UuidGenerator.generate();

      final slotData = TimetableSlotData(
        id: targetSlotId,
        semesterId: activeSem.id,
        subjectComponentId: targetSub.id,
        dayOfWeek: _selectedDay,
        startTime: _formatTimeOfDay(_startTime),
        endTime: _formatTimeOfDay(_endTime),
        room: _roomController.text.trim().isNotEmpty ? _roomController.text.trim() : null,
        teacherName: _teacherController.text.trim().isNotEmpty ? _teacherController.text.trim() : null,
        notes: _selectedComponentType,
        effectiveFrom: fromStr,
        effectiveUntil: untilStr,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      await ref.read(timetableSlotsProvider.notifier).addSlot(slotData);

      if (mounted) {
        Navigator.pop(context);
        AppToast.success(context, '${widget.existingSlot != null ? "Updated" : "Added"} slot for $subjectName');
      }
    }
  }

  void _deleteSlot() {
    if (widget.existingSlot != null) {
      final targetSlotId = widget.existingSlot!.sourceRefId ?? widget.existingSlot!.id;
      ref.read(timetableSlotsProvider.notifier).deleteSlot(targetSlotId);
      Navigator.pop(context);
      AppToast.info(context, 'Deleted slot ${widget.existingSlot!.subjectName}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = Theme.of(context).extension<AppThemeTokens>();
    final isCute = tokens?.isCute ?? false;
    final subjects = ref.watch(subjectsProvider);
    final bool isEditing = widget.existingSlot != null;
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);

    if (isCute) {
      return _buildSproutAddEditSlotScreen(
        context: context,
        isDark: isDark,
        tokens: tokens,
        isEditing: isEditing,
        subjects: subjects,
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF8FAFC),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 22),
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? 'Edit Slot' : 'Add Class Slot',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          if (isEditing)
            IconButton(
              icon: Icon(
                Icons.delete_outline_rounded,
                color: isDark ? AppColors.absentRedDark : AppColors.absentRedLight,
              ),
              tooltip: 'Delete Slot',
              onPressed: _deleteSlot,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                  // DAY OF WEEK SELECTOR (Sunday First)
                  Text(
                    'DAY OF WEEK:',
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
                      final isSelected = _selectedDay == dayVal;
                      return InkWell(
                        onTap: () => setState(() => _selectedDay = dayVal),
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
                  const SizedBox(height: 14),

                  // TIME PICKERS (Side by Side Clock Cards)
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

                  // SUBJECT NAME (Autocomplete or Free Text)
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
                          hintText: 'e.g. Data Structures & Algorithms',
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
                          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(8),
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

                  // CATEGORY PILLS (Horizontal Scroll)
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
                                  Flexible(
                                    child: Text(
                                      label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                                        color: isSel
                                            ? (isDark ? const Color(0xFFA5B4FC) : AppColors.accentIndigoLight)
                                            : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                      ),
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

                  // ROOM & TEACHER (Compact Inputs)
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
                                hintText: 'Room 204',
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
                                hintText: 'Prof. Sharma',
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

                  // DATE BOUNDARIES SELECTOR
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
                ],
              ),
            ),
          ),
        ),
        // FIXED BOTTOM ACTION BAR
        Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                border: Border(top: BorderSide(color: borderColor, width: 0.9)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        side: BorderSide(color: borderColor),
                      ),
                      onPressed: () => Navigator.pop(context),
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        foregroundColor: isDark ? AppColors.bgDark : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      onPressed: _saveSlot,
                      child: Text(
                        isEditing ? 'Save Changes' : 'Add Slot',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // SPROUTS THEME ADD & EDIT SLOT IMPLEMENTATION
  // ==========================================

  Widget _buildSproutAddEditSlotScreen({
    required BuildContext context,
    required bool isDark,
    required AppThemeTokens? tokens,
    required bool isEditing,
    required List<SubjectEntity> subjects,
  }) {
    final screenBg = isDark ? const Color(0xFF112318) : const Color(0xFFFAF7F2);
    final cardBg = isDark ? const Color(0xFF183122) : Colors.white;
    final borderColor = isDark ? const Color(0xFF264A34) : const Color(0xFFDFE8DC);
    final textPrimary = isDark ? const Color(0xFFE8F4EB) : const Color(0xFF192E21);
    final textSecondary = isDark ? const Color(0xFF98B5A3) : const Color(0xFF526B5C);
    final textMuted = isDark ? const Color(0xFF648671) : const Color(0xFF849E8E);
    final primaryAccent = tokens?.primaryAccent ?? const Color(0xFF558A50);
    final activeSem = ref.watch(activeSemesterProvider);

    final durationStr = _formatDurationSprout(_startTime, _endTime);
    final titleText = isEditing ? 'Edit Class Slot' : 'Add Class Slot';
    final subtitleText = isEditing
        ? widget.existingSlot!.subjectName.toUpperCase()
        : (activeSem.isUnset ? 'SCHEDULE' : activeSem.name.toUpperCase());

    return Scaffold(
      backgroundColor: screenBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1A3725) : const Color(0xFFF1F6EF),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: isDark ? const Color(0xFF2A5339) : const Color(0xFFDFE9DA),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        size: 20,
                        color: isDark ? const Color(0xFFA6D4A4) : const Color(0xFF3C6737),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titleText,
                          style: GoogleFonts.quicksand(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: -0.6,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitleText,
                          style: GoogleFonts.quicksand(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: textMuted,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (isEditing)
                    InkWell(
                      onTap: () => _confirmDeleteSprout(context),
                      borderRadius: BorderRadius.circular(15),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF381A1A) : const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: isDark ? const Color(0xFF5C2626) : const Color(0xFFFFCDD2),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                          color: Color(0xFFD32F2F),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Scrollable Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Card 1: Subject Details
                      _buildSproutFormCard(
                        isDark: isDark,
                        cardBg: cardBg,
                        borderColor: borderColor,
                        children: [
                          _buildSproutFieldLabel('SUBJECT NAME', textMuted),
                          const SizedBox(height: 6),
                          Autocomplete<String>(
                            initialValue: TextEditingValue(text: _subjectNameController.text),
                            optionsBuilder: (textEditingValue) {
                              if (textEditingValue.text.isEmpty) {
                                return subjects.map((s) => s.name);
                              }
                              return subjects
                                  .where((s) => s.name.toLowerCase().contains(textEditingValue.text.toLowerCase()))
                                  .map((s) => s.name);
                            },
                            onSelected: (selection) {
                              _subjectNameController.text = selection;
                              final match = subjects.where((s) => s.name == selection).firstOrNull;
                              if (match != null) {
                                setState(() {
                                  _selectedCategory = match.category;
                                  if (match.code != null && match.code!.isNotEmpty) {
                                    _subjectCodeController.text = match.code!;
                                  }
                                });
                              }
                            },
                            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                              return TextFormField(
                                controller: controller,
                                focusNode: focusNode,
                                style: GoogleFonts.quicksand(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: textPrimary,
                                ),
                                decoration: _buildSproutInputDecoration(
                                  hintText: 'e.g. Operating Systems',
                                  isDark: isDark,
                                  borderColor: borderColor,
                                  screenBg: screenBg,
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Please enter subject name';
                                  }
                                  return null;
                                },
                                onChanged: (val) => _subjectNameController.text = val,
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSproutFieldLabel('CODE (OPTIONAL)', textMuted),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _subjectCodeController,
                                      style: GoogleFonts.quicksand(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: textPrimary,
                                      ),
                                      decoration: _buildSproutInputDecoration(
                                        hintText: 'e.g. CS401',
                                        isDark: isDark,
                                        borderColor: borderColor,
                                        screenBg: screenBg,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSproutFieldLabel('ROOM / HALL', textMuted),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _roomController,
                                      style: GoogleFonts.quicksand(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: textPrimary,
                                      ),
                                      decoration: _buildSproutInputDecoration(
                                        hintText: 'e.g. Room 102',
                                        isDark: isDark,
                                        borderColor: borderColor,
                                        screenBg: screenBg,
                                        prefixIcon: Icons.location_on_rounded,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Card 2: Category & Component Type
                      _buildSproutFormCard(
                        isDark: isDark,
                        cardBg: cardBg,
                        borderColor: borderColor,
                        children: [
                          _buildSproutFieldLabel('SUBJECT CATEGORY', textMuted),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _categories.map((cat) {
                              final isSelected = _selectedCategory.toUpperCase() == cat.toUpperCase();
                              return _buildSproutSelectChip(
                                label: cat,
                                isSelected: isSelected,
                                isDark: isDark,
                                primaryAccent: primaryAccent,
                                borderColor: borderColor,
                                onTap: () => setState(() => _selectedCategory = cat),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 14),
                          _buildSproutFieldLabel('COMPONENT TYPE', textMuted),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: ['LECTURE', 'LAB', 'TUTORIAL', 'SEMINAR', 'PRACTICAL'].map((comp) {
                              final isSelected = _selectedComponentType.toUpperCase() == comp.toUpperCase();
                              final display = comp == 'LECTURE' ? 'Theory' : (comp[0] + comp.substring(1).toLowerCase());
                              return _buildSproutSelectChip(
                                label: display,
                                isSelected: isSelected,
                                isDark: isDark,
                                primaryAccent: primaryAccent,
                                borderColor: borderColor,
                                onTap: () => setState(() => _selectedComponentType = comp),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Card 3: Day & Time
                      _buildSproutFormCard(
                        isDark: isDark,
                        cardBg: cardBg,
                        borderColor: borderColor,
                        children: [
                          _buildSproutFieldLabel('DAY OF WEEK', textMuted),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF112318) : const Color(0xFFEEF4EB),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: borderColor, width: 1.2),
                            ),
                            padding: const EdgeInsets.all(5),
                            child: Row(
                              children: List.generate(7, (index) {
                                final dayVal = _dayValues[index];
                                final isSelected = _selectedDay == dayVal;

                                return Expanded(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => setState(() => _selectedDay = dayVal),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(vertical: 9),
                                      decoration: BoxDecoration(
                                        color: isSelected ? primaryAccent : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: primaryAccent.withValues(alpha: 0.3),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        _dayLabels[index],
                                        style: GoogleFonts.quicksand(
                                          fontSize: 12.5,
                                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                                          color: isSelected
                                              ? (isDark ? const Color(0xFF0C1D12) : Colors.white)
                                              : textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildSproutFieldLabel('CLASS TIME', textMuted),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1D3A28) : const Color(0xFFEFF5EC),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  durationStr,
                                  style: GoogleFonts.quicksand(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: primaryAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: _pickStartTime,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: screenBg,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: borderColor, width: 1.5),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'START TIME',
                                          style: GoogleFonts.quicksand(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: textMuted,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _formatTimeOfDayDisplay(_startTime),
                                          style: GoogleFonts.quicksand(
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.w800,
                                            color: textPrimary,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Icon(Icons.arrow_forward_rounded, size: 16, color: textMuted),
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: _pickEndTime,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: screenBg,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: borderColor, width: 1.5),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'END TIME',
                                          style: GoogleFonts.quicksand(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: textMuted,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _formatTimeOfDayDisplay(_endTime),
                                          style: GoogleFonts.quicksand(
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.w800,
                                            color: textPrimary,
                                            letterSpacing: -0.2,
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
                      const SizedBox(height: 14),

                      // Card 4: Teacher
                      _buildSproutFormCard(
                        isDark: isDark,
                        cardBg: cardBg,
                        borderColor: borderColor,
                        children: [
                          _buildSproutFieldLabel('TEACHER NAME (OPTIONAL)', textMuted),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _teacherController,
                            style: GoogleFonts.quicksand(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: textPrimary,
                            ),
                            decoration: _buildSproutInputDecoration(
                              hintText: 'e.g. Dr. Ramesh Sharma',
                              isDark: isDark,
                              borderColor: borderColor,
                              screenBg: screenBg,
                              prefixIcon: Icons.person_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Action Buttons
                      ElevatedButton(
                        onPressed: _saveSlot,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryAccent,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          elevation: 4,
                          shadowColor: primaryAccent.withValues(alpha: 0.4),
                        ),
                        child: Text(
                          isEditing ? 'Update Class Slot' : 'Add Slot to Timetable',
                          style: GoogleFonts.quicksand(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (isEditing) ...[
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: () => _confirmDeleteSprout(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFD32F2F),
                            minimumSize: const Size(double.infinity, 48),
                            side: BorderSide(
                              color: isDark ? const Color(0xFF5C2626) : const Color(0xFFFFCDD2),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          ),
                          child: Text(
                            'Delete This Slot',
                            style: GoogleFonts.quicksand(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSproutFormCard({
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : const Color(0x12558A50),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildSproutFieldLabel(String label, Color color) {
    return Text(
      label,
      style: GoogleFonts.quicksand(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: color,
        letterSpacing: 0.6,
      ),
    );
  }

  InputDecoration _buildSproutInputDecoration({
    required String hintText,
    required bool isDark,
    required Color borderColor,
    required Color screenBg,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.quicksand(
        fontWeight: FontWeight.w600,
        fontSize: 13.5,
        color: isDark ? const Color(0xFF648671) : const Color(0xFF849E8E),
      ),
      filled: true,
      fillColor: screenBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, size: 18, color: isDark ? const Color(0xFF648671) : const Color(0xFF849E8E))
          : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF558A50), width: 1.8),
      ),
    );
  }

  Widget _buildSproutSelectChip({
    required String label,
    required bool isSelected,
    required bool isDark,
    required Color primaryAccent,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    final chipBg = isSelected
        ? (isDark ? const Color(0xFF1D3D29) : const Color(0xFFEBF4E8))
        : (isDark ? const Color(0xFF1E3D2A) : const Color(0xFFF1F6EE));
    final textColor = isSelected
        ? primaryAccent
        : (isDark ? const Color(0xFF98B5A3) : const Color(0xFF526B5C));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: chipBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryAccent : borderColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.quicksand(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
            color: textColor,
          ),
        ),
      ),
    );
  }

  void _confirmDeleteSprout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF183122) : const Color(0xFFFAF7F2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Delete Class Slot?',
            style: GoogleFonts.quicksand(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: isDark ? const Color(0xFFE8F4EB) : const Color(0xFF192E21),
            ),
          ),
          content: Text(
            'Are you sure you want to delete this weekly slot for ${widget.existingSlot?.subjectName}?',
            style: GoogleFonts.quicksand(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF98B5A3) : const Color(0xFF526B5C),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.quicksand(
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFF98B5A3) : const Color(0xFF526B5C),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteSlot();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                'Delete',
                style: GoogleFonts.quicksand(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDurationSprout(TimeOfDay start, TimeOfDay end) {
    final sMin = start.hour * 60 + start.minute;
    final eMin = end.hour * 60 + end.minute;
    final diff = eMin - sMin;
    if (diff > 0) {
      final hours = diff ~/ 60;
      final mins = diff % 60;
      if (hours > 0 && mins > 0) return '${hours}h ${mins}m';
      if (hours > 0) return '${hours}h';
      return '${mins}m';
    }
    return 'Slot';
  }
}
