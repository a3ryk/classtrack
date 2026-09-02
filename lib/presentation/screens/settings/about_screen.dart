import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_release_notes.dart';
import '../../../core/ui/app_toast.dart';
import '../../../core/ui/brand_social_icons.dart';
import '../../../core/ui/tactile_button.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/app_update_provider.dart';
import '../../widgets/developer_passcode_dialog.dart';
import 'update_screen.dart';
import 'privacy_policy_screen.dart';

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
    final releaseInfo = AppReleaseNotes.getForVersion(installedVersion);

    Navigator.push(
      context,
      UpdateScreen.route(
        releaseInfo,
        isWhatsNewMode: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final updateState = ref.watch(appUpdateProvider);

    final groupBg = isDark ? AppColors.cardDark : Colors.white;
    final groupBorder = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);
    final dividerColor = isDark ? AppColors.borderDark.withValues(alpha: 0.6) : const Color(0xFFF1F5F9);

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
          'About',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            letterSpacing: -0.4,
          ),
        ),
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
                            showLicensePage(
                              context: context,
                              applicationName: 'ClassTrack',
                              applicationVersion: 'v${updateState.currentVersion}',
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
