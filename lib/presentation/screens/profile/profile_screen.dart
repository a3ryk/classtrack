import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_theme_tokens.dart';
import '../../../domain/entities/semester_entity.dart';
import '../../providers/app_state_provider.dart';
import '../../widgets/user_profile_dialog.dart';
import '../../widgets/semester_history_dialog.dart';
import '../../widgets/university_selector_dialog.dart';
import '../../widgets/template_selector_dialog.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).extension<AppThemeTokens>();
    final isCute = tokens?.isCute ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isCute && tokens != null) {
      return _buildSproutProfileView(context, ref, tokens, isDark);
    }
    return _buildClassicProfileView(context, ref, isDark);
  }

  Widget _buildClassicProfileView(BuildContext context, WidgetRef ref, bool isDark) {
    final profile = ref.watch(userProfileProvider);
    final activeSemester = ref.watch(activeSemesterProvider);
    final university = ref.watch(selectedUniversityProvider);
    final activeTemplate = ref.watch(activeTemplateProvider);

    final String initials = profile.studentName.trim().isNotEmpty
        ? profile.studentName.trim().split(' ').map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').take(2).join()
        : 'ST';

    final Color groupBg = isDark ? AppColors.cardDark : Colors.white;
    final Color groupBorder = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);
    final Color dividerColor = isDark ? AppColors.borderDark.withValues(alpha: 0.6) : const Color(0xFFF1F5F9);

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF8FAFC),
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 100,
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: [
              const SizedBox(width: 16),
              const Icon(Icons.chevron_left_rounded, size: 22, color: AppColors.accentBlue),
              const Text(
                'Back',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentBlue,
                ),
              ),
            ],
          ),
        ),
        title: Text(
          'Profile',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // HERO PROFILE HEADER
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Column(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    profile.studentName.isNotEmpty ? profile.studentName : 'Student Profile',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    profile.rollNumber.isNotEmpty
                        ? 'Roll: ${profile.rollNumber}${profile.enrollmentNumber.isNotEmpty ? " • Enr: ${profile.enrollmentNumber}" : ""}'
                        : (university.universityName.isNotEmpty ? university.universityName : 'Local Academic Account'),
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 1. UNIFIED ACADEMIC DETAILS
          _buildSectionHeader('Academic Details', isDark),
          Container(
            decoration: BoxDecoration(
              color: groupBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: groupBorder, width: 0.8),
            ),
            child: Column(
              children: [
                _buildDetailRow(
                  label: 'Programme',
                  value: profile.degreeProgramme.isNotEmpty ? profile.degreeProgramme : 'Not Configured',
                  isDark: isDark,
                ),
                Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                _buildDetailRow(
                  label: 'University',
                  value: university.universityName.isNotEmpty ? university.universityName : 'Not Configured',
                  isDark: isDark,
                ),
                if (university.locationType == 'AFFILIATED_COLLEGE' && university.collegeName != null && university.collegeName!.isNotEmpty) ...[
                  Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                  _buildDetailRow(
                    label: 'College',
                    value: university.collegeName!,
                    isDark: isDark,
                  ),
                ],
                Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                _buildDetailRow(
                  label: 'Department',
                  value: profile.department.isNotEmpty ? profile.department : 'Not Set',
                  isDark: isDark,
                ),
                Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                _buildDetailRow(
                  label: 'Academic Year',
                  value: activeSemester.academicYear.isNotEmpty ? activeSemester.academicYear : 'Current Year',
                  isDark: isDark,
                ),
                Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                _buildDetailRow(
                  label: 'Active Term',
                  value: '${activeSemester.name} (${activeSemester.termType.displayName})',
                  isDark: isDark,
                ),
                Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                _buildDetailRow(
                  label: 'Curriculum Structure',
                  value: activeTemplate.name,
                  isDark: isDark,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 2. MANAGE IDENTITY & STRUCTURE
          _buildSectionHeader('Manage Identity & Structure', isDark),
          Container(
            decoration: BoxDecoration(
              color: groupBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: groupBorder, width: 0.8),
            ),
            child: Column(
              children: [
                _buildActionTile(
                  title: 'Edit Student Profile',
                  subtitle: profile.studentName.isNotEmpty ? profile.studentName : 'Configure name, roll & department',
                  isDark: isDark,
                  onTap: () => UserProfileSheet.show(context),
                ),
                Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                _buildActionTile(
                  title: 'Academic Period & Semesters',
                  subtitle: activeSemester.name,
                  isDark: isDark,
                  onTap: () => SemesterHistorySheet.show(context),
                ),
                Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                _buildActionTile(
                  title: 'University & Affiliated College',
                  subtitle: university.universityName.isNotEmpty ? university.universityName : 'Select university/institute',
                  isDark: isDark,
                  onTap: () => UniversitySelectorSheet.show(context),
                ),
                Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                _buildActionTile(
                  title: 'Degree Curriculum Structure',
                  subtitle: activeTemplate.name,
                  isDark: isDark,
                  onTap: () => TemplateSelectorSheet.show(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSproutProfileView(
    BuildContext context,
    WidgetRef ref,
    AppThemeTokens tokens,
    bool isDark,
  ) {
    final profile = ref.watch(userProfileProvider);
    final activeSemester = ref.watch(activeSemesterProvider);
    final university = ref.watch(selectedUniversityProvider);
    final activeTemplate = ref.watch(activeTemplateProvider);

    final String initials = profile.studentName.trim().isNotEmpty
        ? profile.studentName.trim().split(' ').map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').take(2).join()
        : 'ST';

    final Color cardBg = isDark ? const Color(0xFF1B3626) : Colors.white;
    final Color cardBorder = isDark ? const Color(0xFF274C37) : const Color(0xFFE4ECE0);
    final Color dividerColor = isDark ? const Color(0xFF274C37) : const Color(0xFFF0ECE1);
    final Color scaffoldBg = tokens.scaffoldBg;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 100,
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Icon(Icons.chevron_left_rounded, size: 22, color: tokens.primaryAccent),
              Text(
                'Back',
                style: GoogleFonts.quicksand(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: tokens.primaryAccent,
                ),
              ),
            ],
          ),
        ),
        title: Text(
          'Profile',
          style: GoogleFonts.quicksand(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: tokens.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // 1. HERO IDENTITY CARD
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: cardBorder, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF163424) : const Color(0xFFEAF8E7),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isDark ? const Color(0xFF2E593E) : const Color(0xFFD7F0D6),
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: GoogleFonts.quicksand(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: isDark ? const Color(0xFF8BC34A) : const Color(0xFF1E6B3F),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    profile.studentName.isNotEmpty ? profile.studentName : 'Student Profile',
                    style: GoogleFonts.quicksand(
                      fontSize: 17.5,
                      fontWeight: FontWeight.w800,
                      color: tokens.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    profile.rollNumber.isNotEmpty
                        ? 'Roll: ${profile.rollNumber}${profile.enrollmentNumber.isNotEmpty ? " • Enr: ${profile.enrollmentNumber}" : ""}'
                        : (university.universityName.isNotEmpty ? university.universityName : 'Local Academic Account'),
                    style: GoogleFonts.quicksand(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: tokens.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!activeSemester.isUnset) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF164130) : const Color(0xFFEAF8E7),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: isDark ? const Color(0xFF2C5B45) : const Color(0xFFD7F0D6),
                              width: 1.0,
                            ),
                          ),
                          child: Text(
                            activeSemester.name,
                            style: GoogleFonts.quicksand(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isDark ? const Color(0xFFEAF8EA) : const Color(0xFF1E6B3F),
                            ),
                          ),
                        ),
                      ],
                      if (!activeSemester.isUnset && university.universityName.isNotEmpty)
                        const SizedBox(width: 8),
                      if (university.universityName.isNotEmpty) ...[
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF163424) : const Color(0xFFFAF7F2),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: isDark ? const Color(0xFF274C37) : const Color(0xFFE4ECE0),
                                width: 1.0,
                              ),
                            ),
                            child: Text(
                              university.universityName,
                              style: GoogleFonts.quicksand(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: tokens.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 2. ACADEMIC DETAILS (No emoji in heading)
          _buildSproutSectionHeader('Academic Details', tokens),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: cardBorder, width: 1.0),
            ),
            child: Column(
              children: [
                _buildSproutDetailRow(
                  label: 'Programme',
                  value: profile.degreeProgramme.isNotEmpty ? profile.degreeProgramme : 'Not Configured',
                  tokens: tokens,
                ),
                Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                _buildSproutDetailRow(
                  label: 'University',
                  value: university.universityName.isNotEmpty ? university.universityName : 'Not Configured',
                  tokens: tokens,
                ),
                if (university.locationType == 'AFFILIATED_COLLEGE' && university.collegeName != null && university.collegeName!.isNotEmpty) ...[
                  Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                  _buildSproutDetailRow(
                    label: 'College',
                    value: university.collegeName!,
                    tokens: tokens,
                  ),
                ],
                Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                _buildSproutDetailRow(
                  label: 'Department',
                  value: profile.department.isNotEmpty ? profile.department : 'Not Set',
                  tokens: tokens,
                ),
                Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                _buildSproutDetailRow(
                  label: 'Academic Year',
                  value: activeSemester.academicYear.isNotEmpty ? activeSemester.academicYear : 'Current Year',
                  tokens: tokens,
                ),
                Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                _buildSproutDetailRow(
                  label: 'Active Term',
                  value: '${activeSemester.name} (${activeSemester.termType.displayName})',
                  tokens: tokens,
                  valueColor: tokens.primaryAccent,
                ),
                Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                _buildSproutDetailRow(
                  label: 'Curriculum Structure',
                  value: activeTemplate.name,
                  tokens: tokens,
                ),
              ],
            ),
          ),

          // 3. MANAGE IDENTITY & STRUCTURE (No emoji in heading)
          _buildSproutSectionHeader('Manage Identity & Structure', tokens),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: cardBorder, width: 1.0),
            ),
            child: Column(
              children: [
                _buildSproutActionTile(
                  icon: Icons.person_outline_rounded,
                  iconBg: isDark ? const Color(0xFF163424) : const Color(0xFFEAF8E7),
                  iconColor: isDark ? const Color(0xFF8BC34A) : const Color(0xFF2E7D32),
                  title: 'Edit Student Profile',
                  subtitle: profile.studentName.isNotEmpty ? profile.studentName : 'Configure name, roll & department',
                  tokens: tokens,
                  onTap: () => UserProfileSheet.show(context),
                ),
                Divider(height: 1, indent: 56, endIndent: 16, color: dividerColor),
                _buildSproutActionTile(
                  icon: Icons.calendar_month_rounded,
                  iconBg: isDark ? const Color(0xFF3B2D12) : const Color(0xFFFEF3C7),
                  iconColor: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                  title: 'Academic Period & Semesters',
                  subtitle: activeSemester.name,
                  tokens: tokens,
                  onTap: () => SemesterHistorySheet.show(context),
                ),
                Divider(height: 1, indent: 56, endIndent: 16, color: dividerColor),
                _buildSproutActionTile(
                  icon: Icons.account_balance_rounded,
                  iconBg: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                  iconColor: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                  title: 'University & Affiliated College',
                  subtitle: university.universityName.isNotEmpty ? university.universityName : 'Select university/institute',
                  tokens: tokens,
                  onTap: () => UniversitySelectorSheet.show(context),
                ),
                Divider(height: 1, indent: 56, endIndent: 16, color: dividerColor),
                _buildSproutActionTile(
                  icon: Icons.auto_stories_rounded,
                  iconBg: isDark ? const Color(0xFF2E1065).withValues(alpha: 0.5) : const Color(0xFFF3E8FF),
                  iconColor: isDark ? const Color(0xFFC084FC) : const Color(0xFF7E22CE),
                  title: 'Degree Curriculum Structure',
                  subtitle: activeTemplate.name,
                  tokens: tokens,
                  onTap: () => TemplateSelectorSheet.show(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 36),
        ],
      ),
    );
  }

  Widget _buildSproutSectionHeader(String title, AppThemeTokens tokens) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 20, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.quicksand(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: tokens.textMuted,
        ),
      ),
    );
  }

  Widget _buildSproutDetailRow({
    required String label,
    required String value,
    required AppThemeTokens tokens,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.quicksand(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.quicksand(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: valueColor ?? tokens.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSproutActionTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required AppThemeTokens tokens,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(13),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.quicksand(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 1.5),
                    Text(
                      subtitle,
                      style: GoogleFonts.quicksand(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: tokens.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: tokens.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
