import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/update_constants.dart';
import '../../core/services/app_update_service.dart';
import '../../core/ui/app_toast.dart';

class UpdateAvailableDialog extends StatelessWidget {
  final AppReleaseInfo releaseInfo;

  const UpdateAvailableDialog({
    super.key,
    required this.releaseInfo,
  });

  Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (context.mounted) {
          AppToast.error(context, 'Could not open link: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMandatory = releaseInfo.isMandatory;
    final cardBg = isDark ? const Color(0xFF18181B) : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);
    final brandBlue = const Color(0xFF1D64EC);

    final downloadUrl = releaseInfo.downloadUrl?.isNotEmpty == true
        ? releaseInfo.downloadUrl!
        : (releaseInfo.releasePageUrl?.isNotEmpty == true
            ? releaseInfo.releasePageUrl!
            : UpdateConstants.defaultWebsiteUrl);

    final githubUrl = releaseInfo.releasePageUrl?.isNotEmpty == true
        ? releaseInfo.releasePageUrl!
        : 'https://github.com/${UpdateConstants.defaultGithubOwner}/${UpdateConstants.defaultGithubRepo}/releases/latest';

    // Separate changelog into categories if possible
    final features = <String>[];
    final fixes = <String>[];
    final general = <String>[];

    for (final item in releaseInfo.changelog) {
      final lower = item.toLowerCase();
      if (lower.contains('fix') || lower.contains('bug') || item.startsWith('🧩')) {
        fixes.add(item.replaceAll(RegExp(r'^(🧩|\-|\*|•)\s*'), ''));
      } else if (lower.contains('feat') || lower.contains('add') || item.startsWith('✨')) {
        features.add(item.replaceAll(RegExp(r'^(✨|\-|\*|•)\s*'), ''));
      } else {
        general.add(item.replaceAll(RegExp(r'^(\-|\*|•)\s*'), ''));
      }
    }

    return PopScope(
      canPop: !isMandatory,
      child: Dialog(
        backgroundColor: cardBg,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor, width: 0.8),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380, maxHeight: 680),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header: Starburst Badge Icon & Close (if non-mandatory)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: brandBlue.withValues(alpha: isDark ? 0.18 : 0.1),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.new_releases_rounded,
                          size: 26,
                          color: brandBlue,
                        ),
                      ),
                    ),
                    if (!isMandatory)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Title & Version
                Text(
                  'New version available!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'v${releaseInfo.latestVersion}',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 14),

                // Mandatory notice if applicable
                if (isMandatory) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.absentContainerDark : AppColors.absentContainerLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? AppColors.absentRedDark.withValues(alpha: 0.3) : AppColors.absentRed.withValues(alpha: 0.3),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: isDark ? AppColors.absentRedDark : AppColors.absentRedText,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            releaseInfo.warningMessage ??
                                (isMandatory
                                    ? 'Mandatory update required for app stability and features.'
                                    : 'Important notice for this release.'),
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.absentRedDark : AppColors.absentRedText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Description Subtitle
                Text(
                  'Check out the release notes below or view on GitHub if you are upgrading from an earlier version.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: isDark ? AppColors.textSecondaryDark : const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 14),

                // Scrollable Changelog Area
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (features.isNotEmpty) ...[
                          _buildCategoryHeader('✨ Features', isDark),
                          const SizedBox(height: 6),
                          ...features.map((item) => _buildBulletItem(item, isDark)),
                          const SizedBox(height: 12),
                        ],
                        if (fixes.isNotEmpty) ...[
                          _buildCategoryHeader('🧩 Fixes', isDark),
                          const SizedBox(height: 6),
                          ...fixes.map((item) => _buildBulletItem(item, isDark)),
                          const SizedBox(height: 12),
                        ],
                        if (general.isNotEmpty && features.isEmpty && fixes.isEmpty) ...[
                          _buildCategoryHeader('⚡ Improvements', isDark),
                          const SizedBox(height: 6),
                          ...general.map((item) => _buildBulletItem(item, isDark)),
                          const SizedBox(height: 12),
                        ],
                        if (releaseInfo.changelog.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              '• General performance improvements and bug fixes.',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Open on GitHub Link
                InkWell(
                  onTap: () => _launchUrl(context, githubUrl),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Open on GitHub',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: brandBlue,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.open_in_new_rounded, size: 14, color: brandBlue),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Sticky Action Buttons (Download & Not now)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () => _launchUrl(context, downloadUrl),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text(
                          'Download',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    if (!isMandatory) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            side: BorderSide(color: borderColor, width: 1.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: const Text(
                            'Not now',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                            ),
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
      ),
    );
  }

  Widget _buildCategoryHeader(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      ),
    );
  }

  Widget _buildBulletItem(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5, left: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.35,
                color: isDark ? AppColors.textSecondaryDark : const Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
