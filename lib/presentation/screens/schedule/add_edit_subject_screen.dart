import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/ui/app_toast.dart';
import '../../../core/utils/uuid_generator.dart';
import '../../../domain/entities/subject_entity.dart';
import '../../providers/app_state_provider.dart';

class AddEditSubjectScreen extends ConsumerStatefulWidget {
  final SubjectEntity? existingSubject;

  const AddEditSubjectScreen({
    super.key,
    this.existingSubject,
  });

  @override
  ConsumerState<AddEditSubjectScreen> createState() => _AddEditSubjectScreenState();
}

class _AddEditSubjectScreenState extends ConsumerState<AddEditSubjectScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _creditsController;
  late final TextEditingController _heldController;
  late final TextEditingController _attendedController;
  late String _selectedCategory;

  static const List<String> _categories = [
    'MAJOR',
    'MINOR',
    'AEC',
    'MDC',
    'SEC',
    'VAC',
    'ELECTIVE',
  ];

  @override
  void initState() {
    super.initState();
    final sub = widget.existingSubject;
    _nameController = TextEditingController(text: sub?.name ?? '');
    _codeController = TextEditingController(text: sub?.code ?? '');
    _creditsController = TextEditingController(text: sub?.credits.toString() ?? '3');
    _heldController = TextEditingController(text: sub?.baselineHeld.toString() ?? '0');
    _attendedController = TextEditingController(text: sub?.baselineAttended.toString() ?? '0');
    _selectedCategory = sub?.category ?? 'MAJOR';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _creditsController.dispose();
    _heldController.dispose();
    _attendedController.dispose();
    super.dispose();
  }

  void _saveSubject() {
    if (_formKey.currentState!.validate()) {
      final isEditing = widget.existingSubject != null;
      final activeSem = ref.read(activeSemesterProvider);

      if (activeSem.isUnset) {
        AppToast.error(context, 'Please create an active semester first');
        return;
      }

      final updatedSubject = SubjectEntity(
        id: isEditing ? widget.existingSubject!.id : UuidGenerator.generate(),
        semesterId: activeSem.id,
        name: _nameController.text.trim(),
        code: _codeController.text.trim().isNotEmpty ? _codeController.text.trim() : null,
        category: _selectedCategory,
        credits: int.tryParse(_creditsController.text) ?? 3,
        targetAttendancePct: 75.0,
        baselineHeld: int.tryParse(_heldController.text) ?? 0,
        baselineAttended: int.tryParse(_attendedController.text) ?? 0,
        colorHex: '#4F46E5',
        isArchived: false,
        components: [],
      );

      if (isEditing) {
        ref.read(subjectsProvider.notifier).updateSubject(updatedSubject);
      } else {
        ref.read(subjectsProvider.notifier).addSubject(updatedSubject);
      }

      Navigator.pop(context);
      AppToast.success(context, '${isEditing ? "Updated" : "Added"} subject ${updatedSubject.name}');
    }
  }

  void _deleteSubject() {
    if (widget.existingSubject != null) {
      ref.read(subjectsProvider.notifier).deleteSubject(widget.existingSubject!.id);
      Navigator.pop(context);
      AppToast.info(context, 'Deleted subject ${widget.existingSubject!.name}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.existingSubject != null;

    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);
    final inputBg = isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC);

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
          isEditing ? 'Edit Subject' : 'Add New Subject',
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
              tooltip: 'Delete Subject',
              onPressed: _deleteSubject,
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
                      TextFormField(
                        controller: _nameController,
                        style: TextStyle(
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'e.g. Data Structures & Algorithms',
                          hintStyle: TextStyle(
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            fontSize: 13,
                          ),
                          filled: true,
                          fillColor: inputBg,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: isDark ? AppColors.accentIndigoDark : AppColors.accentIndigoLight,
                              width: 1.5,
                            ),
                          ),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Enter subject name' : null,
                      ),
                      const SizedBox(height: 16),

                      // CODE & CREDITS ROW
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'COURSE CODE:',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _codeController,
                                  style: TextStyle(
                                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                    fontSize: 13.5,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'e.g. CS-201',
                                    hintStyle: TextStyle(
                                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                      fontSize: 13,
                                    ),
                                    filled: true,
                                    fillColor: inputBg,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: borderColor),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: borderColor),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CREDITS:',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _creditsController,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(
                                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                    fontSize: 13.5,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '3',
                                    hintStyle: TextStyle(
                                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                      fontSize: 13,
                                    ),
                                    filled: true,
                                    fillColor: inputBg,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: borderColor),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: borderColor),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // CATEGORY SELECTION
                      Text(
                        'COURSE CATEGORY:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _categories.map((cat) {
                          final isSel = _selectedCategory == cat;
                          return InkWell(
                            onTap: () => setState(() => _selectedCategory = cat),
                            borderRadius: BorderRadius.circular(8),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                                    : (isDark ? AppColors.cardDark : Colors.white),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSel
                                      ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                                      : borderColor,
                                  width: 0.9,
                                ),
                              ),
                              child: Text(
                                cat,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                                  color: isSel
                                      ? (isDark ? AppColors.bgDark : Colors.white)
                                      : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 22),

                      // BASELINE ATTENDANCE
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardDark : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor, width: 0.9),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.history_rounded,
                                  size: 16,
                                  color: isDark ? AppColors.accentIndigoDark : AppColors.accentIndigoLight,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'MID-SEMESTER BASELINE (OPTIONAL):',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.6,
                                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'If you already attended classes before tracking here, enter your prior stats.',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Attended So Far',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      TextFormField(
                                        controller: _attendedController,
                                        keyboardType: TextInputType.number,
                                        style: TextStyle(
                                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: inputBg,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: borderColor),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: borderColor),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Held So Far',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      TextFormField(
                                        controller: _heldController,
                                        keyboardType: TextInputType.number,
                                        style: TextStyle(
                                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: inputBg,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: borderColor),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: borderColor),
                                          ),
                                        ),
                                      ),
                                    ],
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
                      onPressed: _saveSubject,
                      child: Text(
                        isEditing ? 'Save Changes' : 'Add Subject',
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
}
