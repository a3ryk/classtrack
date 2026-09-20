import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_theme_tokens.dart';
import '../../../core/ui/app_toast.dart';
import '../../../core/ui/brand_social_icons.dart';
import '../../../core/ui/tactile_button.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/app_update_provider.dart';
import '../../../core/services/app_update_service.dart';
import '../../widgets/developer_passcode_dialog.dart';
import 'update_screen.dart';
import 'privacy_policy_screen.dart';
import 'licenses_screen.dart';

class AboutScreen extends ConsumerStatefulWidget {
  const AboutScreen({super.key});

  @override
  ConsumerState<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends ConsumerState<AboutScreen> {
  int _devTapCount = 0;
  DateTime? _lastDevTapTime;

  void _handleVersionTap() {
    final now = DateTime.now();
    if (_lastDevTapTime == null || now.difference(_lastDevTapTime!) > const Duration(seconds: 2)) {
      _devTapCount = 1;
    } else {
      _devTapCount++;
    }
    _lastDevTapTime = now;

    final isUnlocked = ref.read(isDeveloperUnlockedProvider);
    if (isUnlocked) {
      if (_devTapCount >= 3) {
        AppToast.info(context, 'Developer mode is already active');
        _devTapCount = 0;
      }
      return;
    }

    if (_devTapCount >= 4 && _devTapCount <= 6) {
      final remaining = 7 - _devTapCount;
      AppToast.info(context, 'You are $remaining step${remaining == 1 ? "" : "s"} away from developer options');
    } else if (_devTapCount >= 7) {
      _devTapCount = 0;
      showDialog(
        context: context,
        builder: (ctx) => DeveloperPasscodeDialog(
          onUnlocked: () {},
        ),
      );
    }
  }

  Future<void> _launchExternalUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (mounted) {
          AppToast.error(context, 'Could not open link: $e');
        }
      }
    }
  }

  Future<void> _showWhatsNewDialog(BuildContext context, bool isDark) async {
    final updateState = ref.read(appUpdateProvider);
    final installedVersion = updateState.currentVersion;
    final releaseInfo = await AppUpdateService.fetchReleaseNotesForVersion(versionStr: installedVersion);

    if (context.mounted) {
      Navigator.push(
        context,
        UpdateScreen.route(
          releaseInfo,
          isWhatsNewMode: true,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final updateState = ref.watch(appUpdateProvider);

    if (tokens?.isCute == true) {
      return _buildSproutAboutView(context, tokens!, updateState, isDark);
    }
    return _buildClassicAboutView(context, updateState, isDark);
  }

  Widget _buildClassicAboutView(BuildContext context, AppUpdateState updateState, bool isDark) {
    final groupBg = isDark ? AppColors.cardDark : Colors.white;
    final groupBorder = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);
    final dividerColor = isDark ? AppColors.borderDark.withValues(alpha: 0.6) : const Color(0xFFF1F5F9);

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
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 14),
              Icon(Icons.chevron_left_rounded, size: 22, color: AppColors.accentBlue),
              Text(
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
          'About',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: groupBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: groupBorder, width: 0.8),
                    ),
                    child: Column(
                      children: [
                        // 1. Version Tile (7-Tap Developer Trigger)
                        _buildTile(
                          title: 'Version',
                          subtitle: 'Stable ${updateState.currentVersion} (${DateTime.now().year})',
                          isDark: isDark,
                          onTap: _handleVersionTap,
                        ),
                        Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),

                        // 2. Check for Updates
                        _buildTile(
                          title: 'Check for updates',
                          isDark: isDark,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (updateState.isChecking)
                                SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                  ),
                                )
                              else if (updateState.hasUpdate)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.presentContainerDark : AppColors.presentContainerLight,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Update Available',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? AppColors.presentGreenDark : AppColors.presentGreenText,
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                              ),
                            ],
                          ),
                          onTap: () {
                            ref.read(appUpdateProvider.notifier).checkForUpdates(
                                  context: context,
                                  manualTrigger: true,
                                );
                          },
                        ),
                        Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),

                        // 3. What's New
                        _buildTile(
                          title: 'What\'s new',
                          isDark: isDark,
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                          onTap: () => _showWhatsNewDialog(context, isDark),
                        ),
                        Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),

                        // 4. Open Source Licenses
                        _buildTile(
                          title: 'Open source licenses',
                          isDark: isDark,
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LicensesScreen(
                                  currentVersion: updateState.currentVersion,
                                ),
                              ),
                            );
                          },
                        ),
                        Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),

                        // 5. Privacy Policy
                        _buildTile(
                          title: 'Privacy Policy',
                          subtitle: '100% offline data protection & telemetry guarantees',
                          isDark: isDark,
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Socials Row (Single Color Minimalist Icons)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSocialIcon(
                    svgString: BrandSocialIcons.websiteSvg,
                    tooltip: 'Website',
                    url: 'https://example.com',
                    isDark: isDark,
                  ),
                  const SizedBox(width: 18),
                  _buildSocialIcon(
                    svgString: BrandSocialIcons.discordSvg,
                    tooltip: 'Discord',
                    url: 'https://example.com/discord',
                    isDark: isDark,
                  ),
                  const SizedBox(width: 18),
                  _buildSocialIcon(
                    svgString: BrandSocialIcons.xTwitterSvg,
                    tooltip: 'X (Twitter)',
                    url: 'https://example.com/x',
                    isDark: isDark,
                  ),
                  const SizedBox(width: 18),
                  _buildSocialIcon(
                    svgString: BrandSocialIcons.redditSvg,
                    tooltip: 'Reddit',
                    url: 'https://example.com/reddit',
                    isDark: isDark,
                  ),
                  const SizedBox(width: 18),
                  _buildSocialIcon(
                    svgString: BrandSocialIcons.githubSvg,
                    tooltip: 'GitHub',
                    url: 'https://example.com/github',
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSproutAboutView(
    BuildContext context,
    AppThemeTokens tokens,
    AppUpdateState updateState,
    bool isDark,
  ) {
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
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 14),
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
          'About',
          style: GoogleFonts.quicksand(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: tokens.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            // 1. APP & UPDATES (Zero emojis in heading)
            _buildSproutAboutSectionHeader('App & Updates', tokens, topPadding: 16),
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: cardBorder, width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildSproutTile(
                    title: 'Version',
                    subtitle: 'Stable ${updateState.currentVersion} (${DateTime.now().year})',
                    tokens: tokens,
                    isDark: isDark,
                    onTap: _handleVersionTap,
                  ),
                  Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                  _buildSproutTile(
                    title: 'Check for updates',
                    subtitle: 'Verify the latest available release',
                    tokens: tokens,
                    isDark: isDark,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (updateState.isChecking)
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: tokens.primaryAccent,
                            ),
                          )
                        else if (updateState.hasUpdate)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF163424) : const Color(0xFFEAF8E7),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: isDark ? const Color(0xFF2C5B45) : const Color(0xFFD7F0D6),
                                width: 1.0,
                              ),
                            ),
                            child: Text(
                              'Update Available',
                              style: GoogleFonts.quicksand(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isDark ? const Color(0xFF8BC34A) : const Color(0xFF1E6B3F),
                              ),
                            ),
                          ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: tokens.textMuted,
                        ),
                      ],
                    ),
                    onTap: () {
                      ref.read(appUpdateProvider.notifier).checkForUpdates(
                            context: context,
                            manualTrigger: true,
                          );
                    },
                  ),
                  Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                  _buildSproutTile(
                    title: 'What\'s new',
                    subtitle: 'Latest additions & fixes',
                    tokens: tokens,
                    isDark: isDark,
                    onTap: () => _showWhatsNewDialog(context, isDark),
                  ),
                ],
              ),
            ),

            // 2. LEGAL & DATA ETHICS (Zero emojis in heading)
            _buildSproutAboutSectionHeader('Legal & Data Ethics', tokens),
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: cardBorder, width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildSproutTile(
                    title: 'Open source licenses',
                    subtitle: 'Third-party software libraries & credits',
                    tokens: tokens,
                    isDark: isDark,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LicensesScreen(
                            currentVersion: updateState.currentVersion,
                          ),
                        ),
                      );
                    },
                  ),
                  Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                  _buildSproutTile(
                    title: 'Privacy Policy',
                    subtitle: '100% offline data protection & telemetry guarantees',
                    tokens: tokens,
                    isDark: isDark,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),

            // 3. COMMUNITY & SOURCE (Zero emojis in heading)
            _buildSproutAboutSectionHeader('Community & Source', tokens),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: cardBorder, width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSproutSocialButton(
                    svgString: BrandSocialIcons.websiteSvg,
                    tooltip: 'Website',
                    url: 'https://example.com',
                    tokens: tokens,
                    cardBorder: cardBorder,
                    isDark: isDark,
                  ),
                  _buildSproutSocialButton(
                    svgString: BrandSocialIcons.discordSvg,
                    tooltip: 'Discord',
                    url: 'https://example.com/discord',
                    tokens: tokens,
                    cardBorder: cardBorder,
                    isDark: isDark,
                  ),
                  _buildSproutSocialButton(
                    svgString: BrandSocialIcons.xTwitterSvg,
                    tooltip: 'X (Twitter)',
                    url: 'https://example.com/x',
                    tokens: tokens,
                    cardBorder: cardBorder,
                    isDark: isDark,
                  ),
                  _buildSproutSocialButton(
                    svgString: BrandSocialIcons.redditSvg,
                    tooltip: 'Reddit',
                    url: 'https://example.com/reddit',
                    tokens: tokens,
                    cardBorder: cardBorder,
                    isDark: isDark,
                  ),
                  _buildSproutSocialButton(
                    svgString: BrandSocialIcons.githubSvg,
                    tooltip: 'GitHub',
                    url: 'https://example.com/github',
                    tokens: tokens,
                    cardBorder: cardBorder,
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSproutTile({
    required String title,
    String? subtitle,
    Widget? trailing,
    required AppThemeTokens tokens,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.quicksand(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: tokens.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.quicksand(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: tokens.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                trailing
              else
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

  Widget _buildSproutSocialButton({
    required String svgString,
    required String tooltip,
    required String url,
    required AppThemeTokens tokens,
    required Color cardBorder,
    required bool isDark,
  }) {
    return Tooltip(
      message: tooltip,
      child: TapScaleContainer(
        onTap: () => _launchExternalUrl(url),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF163424) : const Color(0xFFF0F6EE),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cardBorder, width: 0.8),
          ),
          alignment: Alignment.center,
          child: BrandSocialIcons.icon(
            svgString: svgString,
            color: tokens.primaryAccent,
            size: 19,
          ),
        ),
      ),
    );
  }

  Widget _buildSproutAboutSectionHeader(
    String title,
    AppThemeTokens tokens, {
    double topPadding = 20,
    double bottomPadding = 8,
  }) {
    return Padding(
      padding: EdgeInsets.only(left: 4, top: topPadding, bottom: bottomPadding),
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

  Widget _buildTile({
    required String title,
    String? subtitle,
    Widget? trailing,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialIcon({
    required String svgString,
    required String tooltip,
    required String url,
    required bool isDark,
  }) {
    final iconColor = isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);

    return Tooltip(
      message: tooltip,
      child: TapScaleContainer(
        onTap: () => _launchExternalUrl(url),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: iconColor.withValues(alpha: isDark ? 0.15 : 0.08),
          ),
          alignment: Alignment.center,
          child: BrandSocialIcons.icon(
            svgString: svgString,
            color: iconColor,
            size: 19,
          ),
        ),
      ),
    );
  }
}
