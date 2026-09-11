import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/app_update_service.dart';
import '../screens/settings/update_screen.dart';

class UpToDateDialog extends StatelessWidget {
  final String currentVersion;
  final AppReleaseInfo? releaseInfo;
  final DateTime? lastCheckedTime;

  const UpToDateDialog({
    super.key,
    required this.currentVersion,
    this.releaseInfo,
    this.lastCheckedTime,
  });

  /// Presents the UpToDate experience as a modern modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required String currentVersion,
    AppReleaseInfo? releaseInfo,
    DateTime? lastCheckedTime,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => UpToDateSheet(
        currentVersion: currentVersion,
        releaseInfo: releaseInfo,
        lastCheckedTime: lastCheckedTime,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF18181B) : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);

    return Dialog(
      backgroundColor: cardBg,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor, width: 0.8),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: _UpToDateContent(
          currentVersion: currentVersion,
          releaseInfo: releaseInfo,
          lastCheckedTime: lastCheckedTime,
          isBottomSheet: false,
        ),
      ),
    );
  }
}

class UpToDateSheet extends StatelessWidget {
  final String currentVersion;
  final AppReleaseInfo? releaseInfo;
  final DateTime? lastCheckedTime;

  const UpToDateSheet({
    super.key,
    required this.currentVersion,
    this.releaseInfo,
    this.lastCheckedTime,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF18181B) : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 480),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: borderColor, width: 0.8)),
      ),
      child: SafeArea(
        top: false,
        child: _UpToDateContent(
          currentVersion: currentVersion,
          releaseInfo: releaseInfo,
          lastCheckedTime: lastCheckedTime,
          isBottomSheet: true,
        ),
      ),
    );
  }
}

class _UpToDateContent extends StatelessWidget {
  final String currentVersion;
  final AppReleaseInfo? releaseInfo;
  final DateTime? lastCheckedTime;
  final bool isBottomSheet;

  const _UpToDateContent({
    required this.currentVersion,
    this.releaseInfo,
    this.lastCheckedTime,
    this.isBottomSheet = false,
  });

  String _formatCheckedTime(DateTime? time) {
    if (time == null) return 'Checked just now';
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Checked just now';
    if (diff.inMinutes < 60) return 'Checked ${diff.inMinutes}m ago';
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute.toString().padLeft(2, '0');
    return 'Checked today at $hour:$minute $period';
  }

  Future<void> _openWhatsNew(BuildContext context) async {
    Navigator.pop(context);
    final targetInfo = releaseInfo ??
        await AppUpdateService.fetchReleaseNotesForVersion(versionStr: currentVersion);
    if (context.mounted) {
      Navigator.push(
        context,
        UpdateScreen.route(
          targetInfo,
          isWhatsNewMode: true,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);
    final greenAccent = isDark ? AppColors.presentGreenDark : AppColors.presentGreen;
    final brandBlue = AppColors.accentBlue;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        22,
        isBottomSheet ? 10 : 22,
        22,
        isBottomSheet ? 24 : 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (isBottomSheet) ...[
            // Drag handle for bottom sheet
            Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],

          Icon(
            Icons.check_rounded,
            size: 36,
            color: greenAccent,
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            'You\'re on the Latest Version',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18.5,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 6),

          // Subtitle
          Text(
            'Attendly is up to date and running the latest stable build with all features and performance optimizations.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 18),

          // Minimalist Metadata Container
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: 0.8),
            ),
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: greenAccent.withValues(alpha: isDark ? 0.2 : 0.12),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    'LATEST',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: greenAccent,
                    ),
                  ),
                ),
                Text(
                  'v$currentVersion',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                Text(
                  '•',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  ),
                ),
                Text(
                  _formatCheckedTime(lastCheckedTime),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Actions
          Row(
            children: [
              // 1. "What's New" Button (Outlined/Tonal)
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: () => _openWhatsNew(context),
                    icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                    label: const Text(
                      'What\'s New',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? const Color(0xFF93C5FD) : brandBlue,
                      side: BorderSide(
                        color: isDark
                            ? brandBlue.withValues(alpha: 0.4)
                            : brandBlue.withValues(alpha: 0.3),
                        width: 1.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // 2. "Done" Button (Solid Filled Pill)
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      foregroundColor: isDark ? AppColors.bgDark : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

