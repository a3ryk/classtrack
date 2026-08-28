import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
        leadingWidth: 80,
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
