import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme_tokens.dart';
import '../../core/ui/app_toast.dart';
import '../../domain/entities/user_profile_entity.dart';
import '../providers/app_state_provider.dart';

/// Modern Modal Bottom Sheet for Editing Student Profile Info
class UserProfileSheet extends ConsumerStatefulWidget {
  const UserProfileSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const UserProfileSheet(),
    );
  }

  @override
  ConsumerState<UserProfileSheet> createState() => _UserProfileSheetState();
}

class _UserProfileSheetState extends ConsumerState<UserProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _rollController;
  late TextEditingController _enrollController;
  late TextEditingController _programmeController;
  late TextEditingController _deptController;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider);
    _nameController = TextEditingController(text: profile.studentName);
    _rollController = TextEditingController(text: profile.rollNumber);
    _enrollController = TextEditingController(text: profile.enrollmentNumber);
    _programmeController = TextEditingController(text: profile.degreeProgramme);
    _deptController = TextEditingController(text: profile.department);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rollController.dispose();
    _enrollController.dispose();
    _programmeController.dispose();
    _deptController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      final updated = UserProfileEntity(
        studentName: _nameController.text.trim(),
        rollNumber: _rollController.text.trim(),
        enrollmentNumber: _enrollController.text.trim(),
        degreeProgramme: _programmeController.text.trim(),
        department: _deptController.text.trim(),
      );

      ref.read(userProfileProvider.notifier).updateProfile(updated);
      Navigator.pop(context);
      AppToast.success(context, 'Profile saved for ${updated.studentName.isNotEmpty ? updated.studentName : "Student"}');
    }
  }

  InputDecoration _buildCleanInputDecoration({
    required String hint,
    required bool isDark,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.normal,
        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
      ),
      filled: true,
      fillColor: isDark ? AppColors.pillDark : const Color(0xFFF1F5F9).withValues(alpha: 0.7),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: isDark ? AppColors.absentRedDark : AppColors.absentRed),
      ),
    );
  }

  InputDecoration _buildSproutInputDecoration({
    required String hint,
    required AppThemeTokens tokens,
    required bool isDark,
  }) {
    final borderColor = isDark ? const Color(0xFF284F37) : const Color(0xFFE4ECE0);
    final fillColor = isDark ? const Color(0xFF14281C) : const Color(0xFFF5F8F2);

    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.quicksand(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: tokens.textSecondary.withValues(alpha: 0.7),
      ),
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: tokens.primaryAccent, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: isDark ? AppColors.absentRedDark : AppColors.absentRed),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (tokens?.isCute == true) {
      return _buildSproutProfileSheet(context, tokens!, isDark);
    }
    return _buildClassicProfileSheet(context, isDark);
  }

  Widget _buildClassicProfileSheet(BuildContext context, bool isDark) {

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
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
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
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
                'Student Profile',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, size: 20, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Flexible(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Student Name
                    Text(
                      'STUDENT FULL NAME',
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
                      style: TextStyle(fontSize: 14, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                      decoration: _buildCleanInputDecoration(hint: 'e.g. Alex Johnson', isDark: isDark),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Please enter student name' : null,
                    ),
                    const SizedBox(height: 12),

                    // Roll Number & Enrollment Number
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ROLL NUMBER',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _rollController,
                                style: TextStyle(fontSize: 14, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                                decoration: _buildCleanInputDecoration(hint: 'e.g. 21BCSE042', isDark: isDark),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ENROLLMENT NO.',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _enrollController,
                                style: TextStyle(fontSize: 14, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                                decoration: _buildCleanInputDecoration(hint: 'e.g. EN20210084', isDark: isDark),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Degree Programme
                    Text(
                      'DEGREE / PROGRAMME',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _programmeController,
                      style: TextStyle(fontSize: 14, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                      decoration: _buildCleanInputDecoration(hint: 'e.g. B.Tech Computer Science', isDark: isDark),
                    ),
                    const SizedBox(height: 12),

                    // Department
                    Text(
                      'DEPARTMENT / FACULTY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _deptController,
                      style: TextStyle(fontSize: 14, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                      decoration: _buildCleanInputDecoration(hint: 'e.g. School of Computing', isDark: isDark),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Save Action
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                foregroundColor: isDark ? AppColors.bgDark : AppColors.surfaceLight,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: const Text('Save Profile', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSproutProfileSheet(BuildContext context, AppThemeTokens tokens, bool isDark) {
    final sheetBg = isDark ? const Color(0xFF193223) : Colors.white;
    final borderColor = isDark ? const Color(0xFF284F37) : const Color(0xFFE4ECE0);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: borderColor, width: 1.0),
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
                color: isDark ? const Color(0xFF284F37) : const Color(0xFFD4DEC7),
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
                'Student Profile',
                style: GoogleFonts.quicksand(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: tokens.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, size: 20, color: tokens.textSecondary),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Configure your student credentials and degree stream',
            style: GoogleFonts.quicksand(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Student Name
                    Text(
                      'STUDENT FULL NAME',
                      style: GoogleFonts.quicksand(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: tokens.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameController,
                      style: GoogleFonts.quicksand(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: tokens.textPrimary,
                      ),
                      decoration: _buildSproutInputDecoration(
                        hint: 'e.g. Alex Johnson',
                        tokens: tokens,
                        isDark: isDark,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Please enter student name' : null,
                    ),
                    const SizedBox(height: 12),

                    // Roll Number & Enrollment Number
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ROLL NUMBER',
                                style: GoogleFonts.quicksand(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: tokens.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _rollController,
                                style: GoogleFonts.quicksand(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: tokens.textPrimary,
                                ),
                                decoration: _buildSproutInputDecoration(
                                  hint: 'e.g. 21BCSE042',
                                  tokens: tokens,
                                  isDark: isDark,
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
                              Text(
                                'ENROLLMENT NO.',
                                style: GoogleFonts.quicksand(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: tokens.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _enrollController,
                                style: GoogleFonts.quicksand(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: tokens.textPrimary,
                                ),
                                decoration: _buildSproutInputDecoration(
                                  hint: 'e.g. EN20210084',
                                  tokens: tokens,
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Degree Programme
                    Text(
                      'DEGREE / PROGRAMME',
                      style: GoogleFonts.quicksand(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: tokens.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _programmeController,
                      style: GoogleFonts.quicksand(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: tokens.textPrimary,
                      ),
                      decoration: _buildSproutInputDecoration(
                        hint: 'e.g. B.Tech Computer Science',
                        tokens: tokens,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Department
                    Text(
                      'DEPARTMENT / FACULTY',
                      style: GoogleFonts.quicksand(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: tokens.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _deptController,
                      style: GoogleFonts.quicksand(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: tokens.textPrimary,
                      ),
                      decoration: _buildSproutInputDecoration(
                        hint: 'e.g. School of Computing',
                        tokens: tokens,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Save Action
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: tokens.primaryAccent,
                foregroundColor: isDark ? const Color(0xFF102016) : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(
                'Save Profile',
                style: GoogleFonts.quicksand(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Backward compatibility alias
typedef UserProfileDialog = UserProfileSheet;
