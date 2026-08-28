import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/ui/app_toast.dart';
import '../../core/utils/uuid_generator.dart';
import '../../domain/entities/subject_entity.dart';
import '../providers/app_state_provider.dart';

class AddSubjectDialog extends ConsumerStatefulWidget {
  final SubjectEntity? existingSubject;

  const AddSubjectDialog({
    super.key,
    this.existingSubject,
  });

  @override
  ConsumerState<AddSubjectDialog> createState() => _AddSubjectDialogState();
}

class _AddSubjectDialogState extends ConsumerState<AddSubjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _creditsController = TextEditingController(text: '3');
  final _heldController = TextEditingController(text: '0');
  final _attendedController = TextEditingController(text: '0');
  String _selectedCategory = 'MAJOR';

  final List<String> _categories = ['MAJOR', 'MINOR', 'AEC', 'MDC', 'SEC', 'VAC', 'ELECTIVE'];

  @override
  void initState() {
    super.initState();
    if (widget.existingSubject != null) {
      final sub = widget.existingSubject!;
      _nameController.text = sub.name;
      _codeController.text = sub.code ?? '';
      _creditsController.text = sub.credits.toString();
      _heldController.text = sub.baselineHeld.toString();
      _attendedController.text = sub.baselineAttended.toString();
      _selectedCategory = sub.category;
    }
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
        semesterId: activeSem.id, // Dynamically bound to active semester!
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

    return Dialog(
      backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing ? 'Edit Subject' : 'Add New Subject',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Row(
                        children: [
                          if (isEditing)
                            IconButton(
                              icon: Icon(Icons.delete_outline_rounded, color: isDark ? AppColors.absentRedDark : AppColors.absentRedLight),
                              onPressed: _deleteSubject,
                              tooltip: 'Delete Subject',
                            ),
                          IconButton(
                            icon: Icon(Icons.close_rounded, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
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
                  TextFormField(
                    controller: _nameController,
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
                  ),
                  const SizedBox(height: 12),

                  // CODE & CREDITS
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('COURSE CODE:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                            const SizedBox(height: 4),
                            TextFormField(
                              controller: _codeController,
                              style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'CS-201',
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
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('CREDITS:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                            const SizedBox(height: 4),
                            TextFormField(
                              controller: _creditsController,
                              keyboardType: TextInputType.number,
                              style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: '3',
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
                  const SizedBox(height: 14),

                  // BASELINE ATTENDANCE (Mid-degree / Mid-semester onboarding)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MID-SEMESTER BASELINE (OPTIONAL):',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.6, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'If you already attended classes before using ClassTrack, enter them here.',
                          style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Attended So Far', style: TextStyle(fontSize: 10, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                                  const SizedBox(height: 2),
                                  TextFormField(
                                    controller: _attendedController,
                                    keyboardType: TextInputType.number,
                                    style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight, fontSize: 13, fontWeight: FontWeight.bold),
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: isDark ? AppColors.bgDark : AppColors.surfaceLight,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                                  Text('Held So Far', style: TextStyle(fontSize: 10, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                                  const SizedBox(height: 2),
                                  TextFormField(
                                    controller: _heldController,
                                    keyboardType: TextInputType.number,
                                    style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight, fontSize: 13, fontWeight: FontWeight.bold),
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: isDark ? AppColors.bgDark : AppColors.surfaceLight,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0))),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0))),
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
                  const SizedBox(height: 18),

                  // FULL-WIDTH SAVE BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _saveSubject,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        foregroundColor: isDark ? AppColors.bgDark : AppColors.surfaceLight,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      child: Text(
                        isEditing ? 'Save Changes' : 'Add Subject',
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
}

