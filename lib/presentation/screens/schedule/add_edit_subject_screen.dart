import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_theme_tokens.dart';
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
  late String _selectedColorHex;

  static const List<String> _categories = [
    'MAJOR',
    'MINOR',
    'CORE',
    'AEC',
    'MDC',
    'SEC',
    'VAC',
    'ELECTIVE',
  ];

  static const List<String> _sproutColors = [
    '#2E5A36', // Sage Forest
    '#1B4965', // Ocean Deep
    '#C94A29', // Terracotta
    '#D97706', // Ochre Amber
    '#7C3AED', // Soft Lavender
    '#0D9488', // Botanical Teal
    '#9333EA', // Berry Plum
    '#475569', // Slate Stone
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
    _selectedColorHex = sub?.colorHex ?? '#2E5A36';
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
        colorHex: _selectedColorHex,
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

  Color _parseColor(String? hexString, Color fallback) {
    if (hexString == null || hexString.isEmpty) return fallback;
    try {
      final hex = hexString.replaceAll('#', '');
      return Color(int.parse('0xFF$hex'));
    } catch (_) {
      return fallback;
    }
  }

  void _confirmDeleteSubject(BuildContext context, AppThemeTokens tokens, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tokens.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Subject?',
          style: GoogleFonts.quicksand(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: tokens.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${widget.existingSubject?.name}"? All related attendance records and timetable slots will be removed.',
          style: TextStyle(
            fontSize: 13,
            color: tokens.textSecondary,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: tokens.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteSubject();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: tokens.absentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>();
    final isCute = tokens?.isCute ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveTokens = tokens ?? (isDark ? AppThemeTokens.cuteSproutDark : AppThemeTokens.cuteSproutLight);

    if (isCute) {
      return _buildSproutView(context, effectiveTokens, isDark);
    }

    return _buildClassicView(context, isDark);
  }

  Widget _buildSproutView(BuildContext context, AppThemeTokens tokens, bool isDark) {
    final isEditing = widget.existingSubject != null;

    return Scaffold(
      backgroundColor: tokens.scaffoldBg,
      appBar: AppBar(
        backgroundColor: tokens.scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: tokens.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: tokens.cardBorder, width: 1),
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 20,
                  color: tokens.textPrimary,
                ),
              ),
            ),
          ),
        ),
        title: Text(
          isEditing ? 'Edit Subject' : 'Add New Subject',
          style: GoogleFonts.quicksand(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: tokens.textPrimary,
          ),
        ),
        actions: [
          if (isEditing)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: InkWell(
                  onTap: () => _confirmDeleteSubject(context, tokens, isDark),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: tokens.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: tokens.cardBorder, width: 1),
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: tokens.absentColor,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // SUBJECT NAME
                      Text(
                        'SUBJECT NAME',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: tokens.textMuted,
                        ),
                      ),
                      const SizedBox(height: 7),
                      TextFormField(
                        controller: _nameController,
                        style: GoogleFonts.quicksand(
                          color: tokens.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          hintText: 'e.g. Data Structures & Algorithms',
                          hintStyle: TextStyle(
                            color: tokens.textMuted,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                          ),
                          filled: true,
                          fillColor: tokens.cardBg,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: tokens.cardBorder, width: 1),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: tokens.cardBorder, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: tokens.primaryAccent, width: 1.6),
                          ),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Enter subject name' : null,
                      ),
                      const SizedBox(height: 18),

                      // CODE & CREDITS ROW
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'COURSE CODE',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                    color: tokens.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                TextFormField(
                                  controller: _codeController,
                                  style: TextStyle(
                                    color: tokens.textPrimary,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'e.g. CS-201',
                                    hintStyle: TextStyle(
                                      color: tokens.textMuted,
                                      fontSize: 13,
                                    ),
                                    filled: true,
                                    fillColor: tokens.cardBg,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(color: tokens.cardBorder, width: 1),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(color: tokens.cardBorder, width: 1),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(color: tokens.primaryAccent, width: 1.6),
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
                                  'CREDITS',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                    color: tokens.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                TextFormField(
                                  controller: _creditsController,
                                  keyboardType: TextInputType.number,
                                  style: GoogleFonts.quicksand(
                                    color: tokens.textPrimary,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '3',
                                    hintStyle: TextStyle(
                                      color: tokens.textMuted,
                                      fontSize: 13,
                                    ),
                                    filled: true,
                                    fillColor: tokens.cardBg,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(color: tokens.cardBorder, width: 1),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(color: tokens.cardBorder, width: 1),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(color: tokens.primaryAccent, width: 1.6),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // BOTANICAL COLOR PALETTE PICKER
                      Text(
                        'COLOR THEME',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: tokens.textMuted,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: tokens.cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: tokens.cardBorder, width: 1),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: _sproutColors.map((colorHex) {
                            final isSel = _selectedColorHex.toUpperCase() == colorHex.toUpperCase();
                            final color = _parseColor(colorHex, tokens.primaryAccent);
                            return InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedColorHex = colorHex);
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSel ? tokens.textPrimary : Colors.transparent,
                                    width: isSel ? 2.5 : 0,
                                  ),
                                  boxShadow: isSel
                                      ? [
                                          BoxShadow(
                                            color: color.withValues(alpha: 0.4),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: isSel
                                    ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // CATEGORY SELECTION
                      Text(
                        'COURSE CATEGORY',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: tokens.textMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _categories.map((cat) {
                          final isSel = _selectedCategory == cat;
                          return InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedCategory = cat);
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? tokens.primaryAccent
                                    : tokens.cardBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSel
                                      ? tokens.primaryAccent
                                      : tokens.cardBorder,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                cat,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w600,
                                  color: isSel
                                      ? Colors.white
                                      : tokens.textSecondary,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // MID-SEMESTER BASELINE (OPTIONAL)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: tokens.cardBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: tokens.cardBorder, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: tokens.primaryAccent.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.history_rounded,
                                    size: 15,
                                    color: tokens.primaryAccent,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'MID-SEMESTER BASELINE (OPTIONAL)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.6,
                                      color: tokens.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'If you already attended sessions before using Attendly, enter your counts below.',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: tokens.textSecondary,
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
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: tokens.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      TextFormField(
                                        controller: _attendedController,
                                        keyboardType: TextInputType.number,
                                        style: GoogleFonts.quicksand(
                                          color: tokens.textPrimary,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                        ),
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: tokens.scaffoldBg,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: BorderSide(color: tokens.cardBorder),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: BorderSide(color: tokens.cardBorder),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: BorderSide(color: tokens.primaryAccent, width: 1.5),
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
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: tokens.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      TextFormField(
                                        controller: _heldController,
                                        keyboardType: TextInputType.number,
                                        style: GoogleFonts.quicksand(
                                          color: tokens.textPrimary,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                        ),
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: tokens.scaffoldBg,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: BorderSide(color: tokens.cardBorder),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: BorderSide(color: tokens.cardBorder),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: BorderSide(color: tokens.primaryAccent, width: 1.5),
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
                color: tokens.cardBg,
                border: Border(top: BorderSide(color: tokens.cardBorder, width: 1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: BorderSide(color: tokens.cardBorder),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: tokens.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tokens.primaryAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      onPressed: _saveSubject,
                      child: Text(
                        isEditing ? 'Save Changes' : 'Save Subject',
                        style: GoogleFonts.quicksand(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
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

  Widget _buildClassicView(BuildContext context, bool isDark) {
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
                                Expanded(
                                  child: Text(
                                    'MID-SEMESTER BASELINE (OPTIONAL):',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.6,
                                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                    ),
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
