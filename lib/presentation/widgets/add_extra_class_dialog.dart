import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/ui/app_toast.dart';
import '../../core/utils/uuid_generator.dart';
import '../../domain/entities/class_session_entity.dart';
import '../../domain/entities/subject_entity.dart';
import '../providers/app_state_provider.dart';

class AddExtraClassDialog extends ConsumerStatefulWidget {
  final String? preSelectedSubjectId;

  const AddExtraClassDialog({
    super.key,
    this.preSelectedSubjectId,
  });

  @override
  ConsumerState<AddExtraClassDialog> createState() => _AddExtraClassDialogState();
}

class _AddExtraClassDialogState extends ConsumerState<AddExtraClassDialog> {
  final _formKey = GlobalKey<FormState>();
  final _subjectNameController = TextEditingController();
  final _subjectCodeController = TextEditingController();
  String _selectedCategory = 'MAJOR';
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  final _roomController = TextEditingController();
  final _teacherController = TextEditingController();

  final List<String> _categories = ['MAJOR', 'MINOR', 'AEC', 'MDC', 'SEC', 'VAC', 'ELECTIVE'];

  @override
  void initState() {
    super.initState();
    _startTime = TimeOfDay.now();
    _endTime = TimeOfDay(hour: (_startTime.hour + 1) % 24, minute: _startTime.minute);

    if (widget.preSelectedSubjectId != null) {
      final subjects = ref.read(subjectsProvider);
      final preSelected = subjects.firstWhere((s) => s.id == widget.preSelectedSubjectId, orElse: () => subjects.first);
      _subjectNameController.text = preSelected.name;
      _selectedCategory = preSelected.category;
      if (preSelected.code != null) _subjectCodeController.text = preSelected.code!;
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

  void _saveExtraClass() {
    if (_formKey.currentState!.validate()) {
      final subjectName = _subjectNameController.text.trim();
      final subjectCode = _subjectCodeController.text.trim();

      final subjects = ref.read(subjectsProvider);
      final existingSub = subjects.firstWhere(
        (s) => s.name.toLowerCase() == subjectName.toLowerCase(),
        orElse: () {
          final newSub = SubjectEntity(
            id: UuidGenerator.generate(),
            semesterId: 'sem_1',
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
          ref.read(subjectsProvider.notifier).addSubject(newSub);
          return newSub;
        },
      );

      final session = ClassSessionEntity(
        id: UuidGenerator.generate(),
        semesterId: 'sem_1',
        subjectComponentId: existingSub.id,
        subjectName: subjectName,
        subjectCode: subjectCode.isNotEmpty ? subjectCode : existingSub.code,
        category: _selectedCategory,
        componentType: 'EXTRA_CLASS',
        colorHex: existingSub.colorHex,
        sessionDate: '2026-08-19',
        startTime: _formatTimeOfDay(_startTime),
        endTime: _formatTimeOfDay(_endTime),
        sessionSource: 'EXTRA_CLASS',
        status: 'HELD',
        room: _roomController.text.trim().isNotEmpty ? _roomController.text.trim() : null,
        teacherName: _teacherController.text.trim().isNotEmpty ? _teacherController.text.trim() : null,
        attendanceOutcome: 'PENDING',
      );

      ref.read(dailySessionsProvider.notifier).addExtraClass(session);

      Navigator.pop(context);
      AppToast.success(context, 'Added Extra Class for $subjectName');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subjects = ref.watch(subjectsProvider);

    return AlertDialog(
      backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      title: Text(
        'Add Extra Class',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
      ),
      content: SizedBox(
        width: 280,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Free-Text Subject Name Autocomplete / Input Field
                RawAutocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return subjects.map((s) => s.name);
                    }
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
                      style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                      decoration: const InputDecoration(
                        labelText: 'Subject Name',
                        hintText: 'Type any subject name freely',
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Enter subject name' : null,
                      onChanged: (val) {
                        _subjectNameController.text = val;
                      },
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
                          constraints: const BoxConstraints(maxHeight: 150),
                          width: 240,
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final option = options.elementAt(index);
                              return ListTile(
                                dense: true,
                                title: Text(option, style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                                onTap: () => onSelected(option),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),

                // Category Selection
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  isExpanded: true,
                  dropdownColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: _categories.map((c) {
                    return DropdownMenuItem(value: c, child: Text(c));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCategory = val);
                  },
                ),
                const SizedBox(height: 12),

                // Start & End Time Pickers
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _pickStartTime,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Start Time', style: TextStyle(fontSize: 10, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                              const SizedBox(height: 2),
                              Text(_formatTimeOfDayDisplay(_startTime), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
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
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('End Time', style: TextStyle(fontSize: 10, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                              const SizedBox(height: 2),
                              Text(_formatTimeOfDayDisplay(_endTime), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _roomController,
                  style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                  decoration: const InputDecoration(labelText: 'Room / Hall'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _teacherController,
                  style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                  decoration: const InputDecoration(labelText: 'Professor / Teacher Name'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            foregroundColor: isDark ? AppColors.bgDark : AppColors.surfaceLight,
          ),
          onPressed: _saveExtraClass,
          child: const Text('Add Extra Class'),
        ),
      ],
    );
  }
}
