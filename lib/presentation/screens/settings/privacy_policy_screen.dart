import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.cardDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);
    final brandBlue = AppColors.accentBlue;

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
            fontSize: 18,
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
            // Minimalist Header Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: brandBlue.withValues(alpha: isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: brandBlue.withValues(alpha: isDark ? 0.3 : 0.2),
                  width: 0.8,
                ),
              ),
              child: Text(
                'OFFLINE-FIRST ARCHITECTURE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: brandBlue,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Main Title & Subtitle
            Text(
              'Your Data Stays on Your Device',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Attendly operates with zero external tracking, zero analytics telemetry, and zero mandatory cloud accounts. Your academic records belong solely to you.',
              style: TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: isDark ? AppColors.textSecondaryDark : const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Effective Date: September 2026 • Policy Version 1.1',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
            const SizedBox(height: 24),

            // Numbered Structured Sections
            _buildSection(
              number: '01',
              title: 'Local Storage Architecture',
              content:
                  'Attendly is designed from the ground up as a strictly offline-first application. All information (including student names, roll numbers, university selections, course subjects, attendance logs, timetables, and notes) is saved directly to your device local sandboxed SQLite database. We operate no cloud databases and have no access to your data.',
              tag: 'Strictly Local',
              cardBg: cardBg,
              borderColor: borderColor,
              isDark: isDark,
            ),
            const SizedBox(height: 14),

            _buildSection(
              number: '02',
              title: 'Zero Telemetry & Analytics',
              content:
                  'We do not collect, track, or transmit any analytics, crash telemetry, user identifiers, or usage statistics to external servers or third-party advertising networks. The application makes network requests strictly when you choose to check for application updates on GitHub or fetch web timetable links.',
              tag: 'Zero Telemetry',
              cardBg: cardBg,
              borderColor: borderColor,
              isDark: isDark,
            ),
            const SizedBox(height: 14),

            _buildSection(
              number: '03',
              title: 'Timetable QR Code Sharing',
              content:
                  'When sharing a timetable with a classmate via QR code, only course names, categories, and weekly slot times are encoded into the QR payload. Your personal attendance records, grades, notes, and profile details are strictly excluded from the exported code.',
              tag: 'Peer-to-Peer Only',
              cardBg: cardBg,
              borderColor: borderColor,
              isDark: isDark,
            ),
            const SizedBox(height: 14),

            _buildSection(
              number: '04',
              title: 'Device Permissions Explained',
              content:
                  'Attendly requests minimal device permissions, and only when necessary for specific features:\n\n• Camera: Used strictly to scan timetable QR codes from classmates. No photos or video frames are saved or transmitted.\n• Notifications & Alarms: Used strictly for local scheduled lecture chimes and morning attendance summaries.\n• Storage & Documents: Used only when you manually initiate an export (PDF, Excel, or .ctbackup) or select a backup file to restore.',
              tag: 'On-Demand Only',
              cardBg: cardBg,
              borderColor: borderColor,
              isDark: isDark,
            ),
            const SizedBox(height: 14),

            _buildSection(
              number: '05',
              title: 'Complete Data Ownership & Portability',
              content:
                  'You retain absolute ownership of your data at all times. You can generate print-ready PDF reports, export Excel spreadsheets, save complete encrypted .ctbackup files, or permanently delete your entire database with one tap in Settings.',
              tag: 'Full Portability',
              cardBg: cardBg,
              borderColor: borderColor,
              isDark: isDark,
            ),
            const SizedBox(height: 14),

            _buildSection(
              number: '06',
              title: 'Open Source & Licensing',
              content:
                  'Attendly is built using open source software components under standard permissive licenses (MIT, Apache 2.0, BSD). You can review third-party licenses anytime in the Legal section.',
              tag: 'Open & Auditable',
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
    required String number,
    required String title,
    required String content,
    required String tag,
    required Color cardBg,
    required Color borderColor,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  '$number. $title',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : const Color(0xFFCBD5E1),
                    width: 0.6,
                  ),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textSecondaryDark : const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: TextStyle(
              fontSize: 13,
              height: 1.55,
              color: isDark ? AppColors.textSecondaryDark : const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }
}
