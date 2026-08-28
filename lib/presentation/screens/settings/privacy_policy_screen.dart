import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.cardDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);

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
          'Privacy Policy',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: '1. Local-First Architecture',
              content:
                  'ClassTrack is engineered from the ground up as a strictly offline-first application. All information—including student names, roll numbers, university selections, course subjects, attendance logs, timetables, and notes—is saved directly to your device\'s local SQLite database.',
              cardBg: cardBg,
              borderColor: borderColor,
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            _buildSection(
              title: '2. Zero Telemetry & Tracking',
              content:
                  'We do not collect, track, or transmit any analytics, crash telemetry, user identifiers, or usage statistics to external servers or third-party advertising networks. Your device has complete data isolation.',
              cardBg: cardBg,
              borderColor: borderColor,
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            _buildSection(
              title: '3. Timetable QR Sharing Privacy',
              content:
                  'When sharing a timetable with a classmate via QR code, only course names, categories, and weekly slot times are encoded into the QR. Your personal attendance records, grades, notes, and profile details are strictly excluded.',
              cardBg: cardBg,
              borderColor: borderColor,
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            _buildSection(
              title: '4. Data Ownership & Portability',
              content:
                  'You maintain full ownership of your data at all times. You can generate official PDF/Excel reports, export full encrypted .ctbackup files, or delete your entire database directly within the app settings.',
              cardBg: cardBg,
              borderColor: borderColor,
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            _buildSection(
              title: '5. Open Source Software',
              content:
                  'ClassTrack is built using open source software components under standard permissive licenses (MIT, Apache 2.0, BSD). You can inspect third-party open source licenses anytime in the Legal section.',
              cardBg: cardBg,
              borderColor: borderColor,
              isDark: isDark,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    required Color cardBg,
    required Color borderColor,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.5,
              color: isDark ? AppColors.textSecondaryDark : const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }
}
