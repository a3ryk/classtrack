import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/ui/app_toast.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/uuid_generator.dart';
import '../../domain/entities/semester_entity.dart';
import '../providers/app_state_provider.dart';

class EditSemesterDialog extends ConsumerStatefulWidget {
  final SemesterEntity? semesterToEdit;

  const EditSemesterDialog({
    super.key,
    this.semesterToEdit,
  });

  @override
  ConsumerState<EditSemesterDialog> createState() => _EditSemesterDialogState();
}

class _EditSemesterDialogState extends ConsumerState<EditSemesterDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _yearController;
  late TermType _selectedTermType;
  late DateTime _startDate;
  DateTime? _endDate;
  bool _hasEndDate = true;

  @override
  void initState() {
    super.initState();
    final SemesterEntity target = widget.semesterToEdit ?? ref.read(activeSemesterProvider);
    final isEditing = widget.semesterToEdit != null && !widget.semesterToEdit!.isUnset;

    _selectedTermType = target.termType;
    _nameController = TextEditingController(
      text: isEditing ? target.name : 'Semester I',
    );
    _yearController = TextEditingController(
      text: (!target.isUnset && target.academicYear.isNotEmpty) ? target.academicYear : '2026-2027',
    );
    _startDate = isEditing ? target.startDate : DateTime.now();
    _endDate = isEditing ? target.endDate : DateTime.now().add(const Duration(days: 140));
    _hasEndDate = _endDate != null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  void _onTermTypeChanged(TermType newType) {
    setState(() {
      _selectedTermType = newType;
      if (newType == TermType.yearly) {
        _nameController.text = '1st Year';
        if (_hasEndDate) {
          _endDate = _startDate.add(const Duration(days: 365));
        }
      } else if (newType == TermType.trimester) {
        _nameController.text = 'Term 1 (Trimester I)';
        if (_hasEndDate) {
          _endDate = _startDate.add(const Duration(days: 90));
        }
      } else if (newType == TermType.semester) {
        _nameController.text = 'Semester I';
        if (_hasEndDate) {
          _endDate = _startDate.add(const Duration(days: 140));
        }
      } else if (newType == TermType.custom) {
        if (_nameController.text.startsWith('Semester') || _nameController.text.contains('Year') || _nameController.text.startsWith('Term')) {
          _nameController.text = 'Module 1';
        }
      }
    });
  }

  List<String> _getPresetsForType(TermType type) {
    switch (type) {
      case TermType.yearly:
        return const ['1st Year', '2nd Year', '3rd Year', '4th Year', '5th Year'];
      case TermType.trimester:
        return const [
          'Term 1 (Trimester I)',
          'Term 2 (Trimester II)',
          'Term 3 (Trimester III)',
          'Term 4 (Trimester IV)',
          'Term 5 (Trimester V)',
          'Term 6 (Trimester VI)',
          'Term 7 (Trimester VII)',
          'Term 8 (Trimester VIII)',
          'Term 9 (Trimester IX)',
        ];
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
          'Semester IX',
          'Semester X',
        ];
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
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
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  void _saveSemester() {
    if (_formKey.currentState!.validate()) {
      final isEditing = widget.semesterToEdit != null;

      if (isEditing) {
        final updated = widget.semesterToEdit!.copyWith(
          name: _nameController.text.trim(),
          academicYear: _yearController.text.trim(),
          termType: _selectedTermType,
          startDate: _startDate,
          endDate: _hasEndDate ? _endDate : null,
        );

        ref.read(semestersListProvider.notifier).updateSemesterInList(updated);
        final activeSem = ref.read(activeSemesterProvider);
        if (activeSem.id == updated.id) {
          ref.read(activeSemesterProvider.notifier).updateSemester(updated);
        }

        Navigator.pop(context);
        AppToast.success(context, 'Updated ${updated.name}');
      } else {
        final newSem = SemesterEntity(
          id: UuidGenerator.generate(),
          name: _nameController.text.trim(),
          academicYear: _yearController.text.trim(),
          startDate: _startDate,
          endDate: _hasEndDate ? _endDate : null,
          termType: _selectedTermType,
          isArchived: false,
        );

        ref.read(semestersListProvider.notifier).addSemester(newSem);
        ref.read(activeSemesterProvider.notifier).updateSemester(newSem);

        Navigator.pop(context);
        AppToast.success(context, 'Added new term ${newSem.name}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.semesterToEdit != null;

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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          isEditing ? 'Edit Academic Term' : 'Add New Academic Term',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, size: 20, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // TERM TYPE SELECTOR
                  Text(
                    'TERM STRUCTURE TYPE',
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
                      final isSelected = _selectedTermType == type;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: InkWell(
                            onTap: () => _onTermTypeChanged(type),
                            borderRadius: BorderRadius.circular(6),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(vertical: 7),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                                    : (isDark ? AppColors.pillDark : const Color(0xFFF1F5F9)),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isSelected
                                      ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                                      : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                                ),
                              ),
                              child: Text(
                                type.displayName,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  color: isSelected
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

                  // QUICK PRESETS
                  Text(
                    'QUICK PRESETS',
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
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
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

                  // TERM NAME
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
                      hintText: 'e.g. Semester I, 2nd Year, Summer Term',
                      hintStyle: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight, fontSize: 12),
                      filled: true,
                      fillColor: isDark ? AppColors.pillDark : const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0))),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a name for this term' : null,
                  ),
                  const SizedBox(height: 12),

                  // ACADEMIC YEAR
                  Text(
                    'ACADEMIC YEAR (OPTIONAL)',
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
                      hintStyle: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight, fontSize: 12),
                      filled: true,
                      fillColor: isDark ? AppColors.pillDark : const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0))),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // DURATION / DATES
                  Text(
                    'TERM DURATION DATES',
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
                      // Start Date Button
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

                      // End Date Button
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
                  const SizedBox(height: 18),

                  // SUBMIT BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _saveSemester,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        foregroundColor: isDark ? AppColors.bgDark : AppColors.surfaceLight,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      child: Text(
                        isEditing ? 'Save Changes' : 'Create Term',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
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
}
