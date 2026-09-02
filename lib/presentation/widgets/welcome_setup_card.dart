import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../providers/app_state_provider.dart';
import '../screens/ocr/ocr_scanner_screen.dart';
import '../screens/schedule/batch_add_slots_screen.dart';
import 'qr_scanner_dialog.dart';

class WelcomeSetupCard extends ConsumerWidget {
  const WelcomeSetupCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBetaEnabled = ref.watch(betaFeaturesEnabledProvider);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.presentContainerDark : AppColors.presentContainerLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 20,
                  color: isDark ? AppColors.presentGreenDark : AppColors.presentGreenLight,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to ClassTrack',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Choose how you want to set up your schedule:',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Option 1: AI OCR Scanner (BETA Only)
          if (isBetaEnabled) ...[
            _buildSetupOption(
              context: context,
              icon: Icons.document_scanner_rounded,
              title: 'Scan Timetable (AI OCR) [BETA]',
              subtitle: 'Upload a JPG, PNG photo or PDF document',
              isDark: isDark,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OcrScannerScreen()),
                );
              },
            ),
            const SizedBox(height: 10),
          ],

          // Option 2: Scan Classmate QR
          _buildSetupOption(
            context: context,
            icon: Icons.qr_code_scanner_rounded,
            title: 'Scan Classmate QR Code',
            subtitle: 'Clone a friend\'s schedule in 1 second',
            isDark: isDark,
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => const QrScannerDialog(),
              );
            },
          ),
          const SizedBox(height: 10),

          // Option 3: Manual / Batch Add
          _buildSetupOption(
            context: context,
            icon: Icons.edit_calendar_rounded,
            title: 'Add Classes Manually / Batch',
            subtitle: 'Type your subjects and pick multiple days at once',
            isDark: isDark,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BatchAddSlotsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSetupOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgDark : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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
    );
  }
}
