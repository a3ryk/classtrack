import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/update_constants.dart';
import '../../core/services/app_update_service.dart';
import '../../core/constants/app_theme_tokens.dart';
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
    final tokens = Theme.of(context).extension<AppThemeTokens>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMandatory = releaseInfo.isMandatory;

    final downloadUrl = releaseInfo.downloadUrl?.isNotEmpty == true
        ? releaseInfo.downloadUrl!
        : (releaseInfo.releasePageUrl?.isNotEmpty == true
            ? releaseInfo.releasePageUrl!
            : UpdateConstants.defaultWebsiteUrl);

    final githubUrl = releaseInfo.releasePageUrl?.isNotEmpty == true
        ? releaseInfo.releasePageUrl!
        : 'https://github.com/${UpdateConstants.defaultGithubOwner}/${UpdateConstants.defaultGithubRepo}/releases/latest';

    if (tokens?.isCute == true) {
      return _buildSproutDialog(
        context,
        tokens!,
        isDark,
        downloadUrl,
        githubUrl,
        isMandatory,
      );
    }
    return _buildClassicDialog(
      context,
      isDark,
      downloadUrl,
      githubUrl,
      isMandatory,
    );
  }

  Widget _buildClassicDialog(
    BuildContext context,
    bool isDark,
    String downloadUrl,
    String githubUrl,
    bool isMandatory,
  ) {
    final cardBg = isDark ? const Color(0xFF18181B) : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);
    final brandBlue = const Color(0xFF1D64EC);

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
                    child: MarkdownBody(
                      data: releaseInfo.effectiveMarkdown,
                      selectable: true,
                      onTapLink: (text, href, title) {
                        if (href != null) _launchUrl(context, href);
                      },
                      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                        p: TextStyle(
                          fontSize: 12.5,
                          height: 1.45,
                          color: isDark ? AppColors.textSecondaryDark : const Color(0xFF334155),
                        ),
                        h1: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                        h2: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                        h3: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                        h4: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                        h5: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                        h6: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                        code: TextStyle(
                          fontSize: 11.5,
                          fontFamily: 'monospace',
                          backgroundColor: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9),
                          color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                            width: 0.8,
                          ),
                        ),
                        listBullet: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                        a: const TextStyle(
                          color: Color(0xFF1D64EC),
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w600,
                        ),
                        strong: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                        em: const TextStyle(fontStyle: FontStyle.italic),
                        blockquote: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                        blockquoteDecoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: isDark ? AppColors.accentIndigoDark : AppColors.accentIndigoLight,
                              width: 3,
                            ),
                          ),
                        ),
                        horizontalRuleDecoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: borderColor,
                              width: 0.8,
                            ),
                          ),
                        ),
                        listIndent: 16,
                        blockSpacing: 8,
                      ),
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

  Widget _buildSproutDialog(
    BuildContext context,
    AppThemeTokens tokens,
    bool isDark,
    String downloadUrl,
    String githubUrl,
    bool isMandatory,
  ) {
    final cardBg = isDark ? const Color(0xFF1B3626) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF274C37) : const Color(0xFFE4ECE0);
    final badgeBg = isDark ? const Color(0xFF163424) : const Color(0xFFEAF8E7);
    final badgeBorder = isDark ? const Color(0xFF2C5B45) : const Color(0xFFD7F0D6);

    return PopScope(
      canPop: !isMandatory,
      child: Dialog(
        backgroundColor: cardBg,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: cardBorder, width: 1.0),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380, maxHeight: 680),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header: Squircle Badge Icon & Close
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: badgeBg,
                        border: Border.all(color: badgeBorder, width: 1.0),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.new_releases_rounded,
                          size: 24,
                          color: tokens.primaryAccent,
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
                          color: tokens.textMuted,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Title & Version (Zero emojis!)
                Text(
                  'New version available!',
                  style: GoogleFonts.quicksand(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: badgeBorder, width: 1.0),
                      ),
                      child: Text(
                        'v${releaseInfo.latestVersion}',
                        style: GoogleFonts.quicksand(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: isDark ? const Color(0xFF8BC34A) : const Color(0xFF1E6B3F),
                        ),
                      ),
                    ),
                    if (releaseInfo.releaseDate.isNotEmpty)
                      Text(
                        releaseInfo.releaseDate,
                        style: GoogleFonts.quicksand(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: tokens.textMuted,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),

                // Mandatory notice if applicable
                if (isMandatory) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.absentContainerDark : AppColors.absentContainerLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? AppColors.absentRedDark.withValues(alpha: 0.35) : AppColors.absentRed.withValues(alpha: 0.35),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 18,
                          color: isDark ? AppColors.absentRedDark : AppColors.absentRedText,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            releaseInfo.warningMessage ??
                                'Mandatory update required for app stability and features.',
                            style: GoogleFonts.quicksand(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
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
                  'Check out the release notes below or download the package to update in-place.',
                  style: GoogleFonts.quicksand(
                    fontSize: 12.5,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    color: tokens.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),

                // Scrollable Changelog Area
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF163424) : const Color(0xFFFAF7F2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: cardBorder, width: 0.8),
                      ),
                      child: MarkdownBody(
                        data: releaseInfo.effectiveMarkdown.replaceAll('ClassTrack', 'Attendly'),
                        selectable: true,
                        onTapLink: (text, href, title) {
                          if (href != null) _launchUrl(context, href);
                        },
                        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                          p: GoogleFonts.quicksand(
                            fontSize: 12.5,
                            height: 1.45,
                            fontWeight: FontWeight.w500,
                            color: tokens.textSecondary,
                          ),
                          h1: GoogleFonts.quicksand(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: tokens.textPrimary,
                          ),
                          h2: GoogleFonts.quicksand(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: tokens.textPrimary,
                          ),
                          code: TextStyle(
                            fontSize: 11.5,
                            fontFamily: 'monospace',
                            backgroundColor: isDark ? const Color(0xFF1B3626) : Colors.white,
                            color: tokens.primaryAccent,
                          ),
                          listBullet: GoogleFonts.quicksand(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: tokens.primaryAccent,
                          ),
                          a: TextStyle(
                            color: tokens.primaryAccent,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.w700,
                          ),
                          strong: GoogleFonts.quicksand(
                            fontWeight: FontWeight.w800,
                            color: tokens.textPrimary,
                          ),
                          blockSpacing: 8,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Open on GitHub Link
                InkWell(
                  onTap: () => _launchUrl(context, githubUrl),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Open on GitHub',
                          style: GoogleFonts.quicksand(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: tokens.primaryAccent,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.open_in_new_rounded, size: 14, color: tokens.primaryAccent),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Action Buttons (Download & Not now)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => _launchUrl(context, downloadUrl),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: tokens.primaryAccent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Download',
                          style: GoogleFonts.quicksand(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
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
                            foregroundColor: tokens.textPrimary,
                            side: BorderSide(color: cardBorder, width: 1.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Not now',
                            style: GoogleFonts.quicksand(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
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
}
