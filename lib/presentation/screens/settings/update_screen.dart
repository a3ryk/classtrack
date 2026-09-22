import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/update_constants.dart';
import '../../../core/services/app_update_service.dart';
import '../../../core/constants/app_theme_tokens.dart';
import '../../../core/ui/app_toast.dart';
import '../../widgets/release_alert_callout_card.dart';

class UpdateScreen extends StatefulWidget {
  final AppReleaseInfo releaseInfo;
  final bool isWhatsNewMode;
  final bool isDevInspectMode;

  const UpdateScreen({
    super.key,
    required this.releaseInfo,
    this.isWhatsNewMode = false,
    this.isDevInspectMode = false,
  });

  static Route<void> route(
    AppReleaseInfo releaseInfo, {
    bool isWhatsNewMode = false,
    bool isDevInspectMode = false,
  }) {
    return PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (context, animation, secondaryAnimation) => RepaintBoundary(
        child: UpdateScreen(
          releaseInfo: releaseInfo,
          isWhatsNewMode: isWhatsNewMode,
          isDevInspectMode: isDevInspectMode,
        ),
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.fastOutSlowIn,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, -0.04),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  int _receivedBytes = 0;
  int _totalBytes = 0;
  File? _downloadedApkFile;

  Future<void> _launchUrl(String url) async {
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

  Future<void> _handleUpdateAction(String downloadUrl) async {
    // If APK is already downloaded, install it immediately
    if (_downloadedApkFile != null && await _downloadedApkFile!.exists()) {
      final success = await AppUpdateService.installApk(_downloadedApkFile!);
      if (!success && mounted) {
        AppToast.info(context, 'Please allow installing unknown apps from Settings to proceed.');
      }
      return;
    }

    // If platform is Android and download URL is an APK, download directly in-app
    if (Platform.isAndroid && downloadUrl.toLowerCase().endsWith('.apk')) {
      setState(() {
        _isDownloading = true;
        _downloadProgress = 0.0;
        _receivedBytes = 0;
        _totalBytes = 0;
      });

      try {
        final apkFile = await AppUpdateService.downloadApk(
          downloadUrl: downloadUrl,
          onProgress: (received, total, pct) {
            if (mounted) {
              setState(() {
                _receivedBytes = received;
                _totalBytes = total;
                _downloadProgress = pct;
              });
            }
          },
        );

        if (mounted && apkFile != null) {
          setState(() {
            _isDownloading = false;
            _downloadedApkFile = apkFile;
          });
          final installed = await AppUpdateService.installApk(apkFile);
          if (!installed && mounted) {
            AppToast.info(context, 'Please allow "Install unknown apps" in Settings to update.');
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isDownloading = false;
          });
          AppToast.error(context, 'Direct download failed. Opening browser fallback...');
          _launchUrl(downloadUrl);
        }
      }
    } else {
      // Fallback for iOS / Web / non-APK links
      _launchUrl(downloadUrl);
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _extractReleaseTheme(String title) {
    final sanitized = title.replaceAll('ClassTrack', 'Attendly').trim();
    final match = RegExp(r'\((.*?)\)').firstMatch(sanitized);
    if (match != null && match.group(1) != null && match.group(1)!.trim().isNotEmpty) {
      return match.group(1)!.trim();
    }
    final stripped = sanitized.replaceFirst(RegExp(r'^(?:Attendly|ClassTrack)?\s*v?[0-9\.\-a-zA-Z]+\s*[:\-–—]?\s*'), '').trim();
    if (stripped.isNotEmpty && stripped != sanitized) {
      return stripped;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMandatory = widget.releaseInfo.isMandatory;
    final canDismiss = widget.isWhatsNewMode || !isMandatory || widget.isDevInspectMode;

    final downloadUrl = widget.releaseInfo.downloadUrl?.isNotEmpty == true
        ? widget.releaseInfo.downloadUrl!
        : (widget.releaseInfo.releasePageUrl?.isNotEmpty == true
            ? widget.releaseInfo.releasePageUrl!
            : UpdateConstants.defaultWebsiteUrl);

    final githubUrl = widget.releaseInfo.releasePageUrl?.isNotEmpty == true
        ? widget.releaseInfo.releasePageUrl!
        : 'https://github.com/${UpdateConstants.defaultGithubOwner}/${UpdateConstants.defaultGithubRepo}/releases/latest';

    if (tokens?.isCute == true) {
      return _buildSproutUpdateView(
        context,
        tokens!,
        isDark,
        downloadUrl,
        githubUrl,
        canDismiss,
        isMandatory,
      );
    }
    return _buildClassicUpdateView(
      context,
      isDark,
      downloadUrl,
      githubUrl,
      canDismiss,
      isMandatory,
    );
  }

  Widget _buildClassicUpdateView(
    BuildContext context,
    bool isDark,
    String downloadUrl,
    String githubUrl,
    bool canDismiss,
    bool isMandatory,
  ) {
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);
    final brandBlue = AppColors.accentBlue;

    return PopScope(
      canPop: canDismiss,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF8FAFC),
          elevation: 0,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: canDismiss,
          leading: canDismiss
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, size: 22),
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  onPressed: () => Navigator.pop(context),
                )
              : null,
          title: Text(
            widget.isWhatsNewMode
                ? 'What\'s New'
                : (isMandatory ? 'Update Required' : 'Update Available'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              letterSpacing: -0.3,
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.isDevInspectMode) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber.withValues(alpha: 0.4), width: 0.8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.developer_mode_rounded, size: 16, color: Colors.amber),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'DEV INSPECT MODE: Testing release notes (Bypass active)',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    'Exit',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        if (widget.isWhatsNewMode) ...[
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 36,
                            color: isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'What\'s New in Attendly',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                          ),
                          if (_extractReleaseTheme(widget.releaseInfo.releaseTitle).isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Text(
                              _extractReleaseTheme(widget.releaseInfo.releaseTitle),
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                height: 1.35,
                                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: (isDark ? const Color(0xFF6366F1) : const Color(0xFF4F46E5)).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: (isDark ? const Color(0xFF818CF8) : const Color(0xFF6366F1)).withValues(alpha: 0.25),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  'v${widget.releaseInfo.latestVersion}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5),
                                  ),
                                ),
                              ),
                              if (widget.releaseInfo.releaseDate.isNotEmpty)
                                Text(
                                  widget.releaseInfo.releaseDate,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: (isDark ? AppColors.presentGreenDark : AppColors.presentGreen).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: (isDark ? AppColors.presentGreenDark : AppColors.presentGreen).withValues(alpha: 0.25),
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      size: 12,
                                      color: isDark ? AppColors.presentGreenDark : AppColors.presentGreen,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Current Version',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? AppColors.presentGreenDark : AppColors.presentGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isMandatory
                                  ? (isDark ? AppColors.absentContainerDark : AppColors.absentContainerLight)
                                  : brandBlue.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isMandatory
                                    ? (isDark ? AppColors.absentRedDark : AppColors.absentRedText.withValues(alpha: 0.35))
                                    : brandBlue.withValues(alpha: 0.25),
                                width: 1.0,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                isMandatory ? Icons.warning_amber_rounded : Icons.system_update_alt_rounded,
                                size: 24,
                                color: isMandatory
                                    ? (isDark ? AppColors.absentRedDark : AppColors.absentRedText)
                                    : brandBlue,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            isMandatory ? 'Critical Update Required' : 'New version available!',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'v${widget.releaseInfo.latestVersion}${widget.releaseInfo.releaseDate.isNotEmpty ? " • Released ${widget.releaseInfo.releaseDate}" : ""}',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                          if (_extractReleaseTheme(widget.releaseInfo.releaseTitle).isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              _extractReleaseTheme(widget.releaseInfo.releaseTitle),
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                height: 1.35,
                                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                              ),
                            ),
                          ],
                        ],
                        if (!widget.isWhatsNewMode && Platform.isAndroid && downloadUrl.toLowerCase().endsWith('.apk')) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: brandBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: brandBlue.withValues(alpha: 0.25), width: 0.8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.memory_rounded, size: 15, color: brandBlue),
                                const SizedBox(width: 6),
                                Text(
                                  downloadUrl.contains('arm64-v8a')
                                      ? 'Device-Optimized: ARM64 package'
                                      : (downloadUrl.contains('armeabi-v7a')
                                          ? 'Device-Optimized: ARM 32-bit package'
                                          : (downloadUrl.contains('x86_64')
                                              ? 'Device-Optimized: x86_64 package'
                                              : 'Universal APK package')),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: brandBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        if (widget.releaseInfo.alertCallouts.isNotEmpty) ...[
                          ReleaseAlertCalloutsList(
                            alertCallouts: widget.releaseInfo.alertCallouts,
                            isCute: false,
                            isDark: isDark,
                            onLinkTap: _launchUrl,
                          ),
                          const SizedBox(height: 6),
                        ] else if (!widget.isWhatsNewMode && (isMandatory || (widget.releaseInfo.warningMessage != null && widget.releaseInfo.warningMessage!.isNotEmpty))) ...[
                          ReleaseAlertCalloutCard(
                            callout: ReleaseAlertCallout(
                              type: isMandatory ? AlertCalloutType.caution : AlertCalloutType.warning,
                              markdown: widget.releaseInfo.warningMessage ?? (isMandatory ? 'Mandatory update required for app stability and features.' : 'Important notice for this release.'),
                            ),
                            isCute: false,
                            isDark: isDark,
                            onLinkTap: _launchUrl,
                          ),
                          const SizedBox(height: 6),
                        ],
                        Text(
                          widget.isWhatsNewMode
                              ? 'Discover the latest features, performance improvements, and fixes in this release.'
                              : 'Check out the release notes below or download the latest package to update in-place.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            color: isDark ? AppColors.textSecondaryDark : const Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.cardDark : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor, width: 0.8),
                          ),
                          child: MarkdownBody(
                            data: widget.releaseInfo.effectiveMarkdown.replaceAll('ClassTrack', 'Attendly'),
                            selectable: true,
                            onTapLink: (text, href, title) {
                              if (href != null) _launchUrl(href);
                            },
                            styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                              p: TextStyle(
                                fontSize: 13,
                                height: 1.45,
                                color: isDark ? AppColors.textSecondaryDark : const Color(0xFF334155),
                              ),
                              h1: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                              h2: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                              h3: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                              h4: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                              h5: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                              h6: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                              code: TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                                backgroundColor: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9),
                                color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                              ),
                              codeblockDecoration: BoxDecoration(
                                color: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                                  width: 0.8,
                                ),
                              ),
                              listBullet: TextStyle(
                                fontSize: 13,
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
                                fontSize: 12.5,
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
                              listIndent: 18,
                              blockSpacing: 8.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: () => _launchUrl(githubUrl),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.open_in_new_rounded,
                                  size: 15,
                                  color: brandBlue,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'View complete release notes on GitHub',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: brandBlue,
                                    decoration: TextDecoration.underline,
                                    decorationColor: brandBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                if (_isDownloading) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor, width: 0.8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Downloading update package...',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '${(_downloadProgress * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: brandBlue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _downloadProgress > 0 ? _downloadProgress : null,
                            backgroundColor: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                            valueColor: AlwaysStoppedAnimation<Color>(brandBlue),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (_totalBytes > 0)
                          Text(
                            '${_formatBytes(_receivedBytes)} of ${_formatBytes(_totalBytes)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                if (widget.isWhatsNewMode) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        foregroundColor: isDark ? AppColors.bgDark : Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isDownloading
                              ? null
                              : () => _handleUpdateAction(downloadUrl),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _downloadedApkFile != null
                                ? AppColors.presentGreen
                                : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                            foregroundColor: isDark ? AppColors.bgDark : Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _downloadedApkFile != null
                                ? 'Install Update'
                                : (_isDownloading ? 'Downloading...' : 'Update Now'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      if (canDismiss && !_isDownloading) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              side: BorderSide(color: borderColor, width: 1.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              widget.isDevInspectMode && isMandatory ? 'Exit Dev Preview' : 'Not now',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSproutUpdateView(
    BuildContext context,
    AppThemeTokens tokens,
    bool isDark,
    String downloadUrl,
    String githubUrl,
    bool canDismiss,
    bool isMandatory,
  ) {
    final cardBg = isDark ? const Color(0xFF1B3626) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF274C37) : const Color(0xFFE4ECE0);
    final badgeBg = isDark ? const Color(0xFF163424) : const Color(0xFFEAF8E7);
    final badgeBorder = isDark ? const Color(0xFF2C5B45) : const Color(0xFFD7F0D6);

    return PopScope(
      canPop: canDismiss,
      child: Scaffold(
        backgroundColor: tokens.scaffoldBg,
        appBar: AppBar(
          backgroundColor: tokens.scaffoldBg,
          elevation: 0,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: false,
          leadingWidth: canDismiss ? 100 : 0,
          leading: canDismiss
              ? InkWell(
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
                )
              : null,
          title: Text(
            widget.isWhatsNewMode
                ? 'What\'s New'
                : (isMandatory ? 'Update Required' : 'Software Update'),
            style: GoogleFonts.quicksand(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: tokens.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.isDevInspectMode) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.amber.withValues(alpha: 0.4), width: 0.8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.developer_mode_rounded, size: 18, color: Colors.amber),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'DEV INSPECT MODE: Testing release notes (Bypass active)',
                                    style: GoogleFonts.quicksand(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'Exit',
                                    style: GoogleFonts.quicksand(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        // Hero Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    widget.isWhatsNewMode ? 'ATTENDLY RELEASE' : 'SOFTWARE UPDATE',
                                    style: GoogleFonts.quicksand(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                      color: tokens.primaryAccent,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: badgeBg,
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(color: badgeBorder, width: 1.0),
                                    ),
                                    child: Text(
                                      widget.isWhatsNewMode ? 'Current Version' : 'v${widget.releaseInfo.latestVersion}',
                                      style: GoogleFonts.quicksand(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? const Color(0xFF8BC34A) : const Color(0xFF1E6B3F),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                widget.isWhatsNewMode
                                    ? 'What\'s New in Attendly'
                                    : (isMandatory ? 'Critical Update Required' : 'New version available!'),
                                style: GoogleFonts.quicksand(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: tokens.textPrimary,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              if (_extractReleaseTheme(widget.releaseInfo.releaseTitle).isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _extractReleaseTheme(widget.releaseInfo.releaseTitle),
                                  style: GoogleFonts.quicksand(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: tokens.textSecondary,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 6),
                              Text(
                                'v${widget.releaseInfo.latestVersion}${widget.releaseInfo.releaseDate.isNotEmpty ? " • Released ${widget.releaseInfo.releaseDate}" : ""}',
                                style: GoogleFonts.quicksand(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: tokens.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!widget.isWhatsNewMode && Platform.isAndroid && downloadUrl.toLowerCase().endsWith('.apk')) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: badgeBorder, width: 0.8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.memory_rounded, size: 15, color: tokens.primaryAccent),
                                const SizedBox(width: 6),
                                Text(
                                  downloadUrl.contains('arm64-v8a')
                                      ? 'Device-Optimized: ARM64 package'
                                      : (downloadUrl.contains('armeabi-v7a')
                                          ? 'Device-Optimized: ARM 32-bit package'
                                          : (downloadUrl.contains('x86_64')
                                              ? 'Device-Optimized: x86_64 package'
                                              : 'Universal APK package')),
                                  style: GoogleFonts.quicksand(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: tokens.primaryAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        if (widget.releaseInfo.alertCallouts.isNotEmpty) ...[
                          ReleaseAlertCalloutsList(
                            alertCallouts: widget.releaseInfo.alertCallouts,
                            isCute: true,
                            isDark: isDark,
                            onLinkTap: _launchUrl,
                          ),
                          const SizedBox(height: 6),
                        ] else if (!widget.isWhatsNewMode && (isMandatory || (widget.releaseInfo.warningMessage != null && widget.releaseInfo.warningMessage!.isNotEmpty))) ...[
                          ReleaseAlertCalloutCard(
                            callout: ReleaseAlertCallout(
                              type: isMandatory ? AlertCalloutType.caution : AlertCalloutType.warning,
                              markdown: widget.releaseInfo.warningMessage ?? (isMandatory ? 'Mandatory update required for app stability and features.' : 'Important notice for this release.'),
                            ),
                            isCute: true,
                            isDark: isDark,
                            onLinkTap: _launchUrl,
                          ),
                          const SizedBox(height: 6),
                        ],
                        // Zero emojis in section header!
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                          child: Text(
                            widget.isWhatsNewMode ? 'KEY HIGHLIGHTS' : 'RELEASE NOTES',
                            style: GoogleFonts.quicksand(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: tokens.textMuted,
                            ),
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
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
                          child: MarkdownBody(
                            data: widget.releaseInfo.effectiveMarkdown.replaceAll('ClassTrack', 'Attendly'),
                            selectable: true,
                            onTapLink: (text, href, title) {
                              if (href != null) _launchUrl(href);
                            },
                            styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                              p: GoogleFonts.quicksand(
                                fontSize: 13,
                                height: 1.45,
                                fontWeight: FontWeight.w500,
                                color: tokens.textSecondary,
                              ),
                              h1: GoogleFonts.quicksand(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: tokens.textPrimary,
                              ),
                              h2: GoogleFonts.quicksand(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: tokens.textPrimary,
                              ),
                              h3: GoogleFonts.quicksand(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: tokens.textPrimary,
                              ),
                              code: TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                                backgroundColor: isDark ? const Color(0xFF163424) : const Color(0xFFFAF7F2),
                                color: tokens.primaryAccent,
                              ),
                              codeblockDecoration: BoxDecoration(
                                color: isDark ? const Color(0xFF163424) : const Color(0xFFFAF7F2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: cardBorder,
                                  width: 0.8,
                                ),
                              ),
                              listBullet: GoogleFonts.quicksand(
                                fontSize: 13,
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
                              blockSpacing: 8.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        InkWell(
                          onTap: () => _launchUrl(githubUrl),
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.open_in_new_rounded,
                                  size: 15,
                                  color: tokens.primaryAccent,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'View complete release notes on GitHub',
                                  style: GoogleFonts.quicksand(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: tokens.primaryAccent,
                                    decoration: TextDecoration.underline,
                                    decorationColor: tokens.primaryAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                if (_isDownloading) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Downloading update package...',
                              style: GoogleFonts.quicksand(fontSize: 12.5, fontWeight: FontWeight.w700, color: tokens.textPrimary),
                            ),
                            Text(
                              '${(_downloadProgress * 100).toInt()}%',
                              style: GoogleFonts.quicksand(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: tokens.primaryAccent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: _downloadProgress > 0 ? _downloadProgress : null,
                            backgroundColor: isDark ? const Color(0xFF274C37) : const Color(0xFFF0ECE1),
                            valueColor: AlwaysStoppedAnimation<Color>(tokens.primaryAccent),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_totalBytes > 0)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_formatBytes(_receivedBytes)} of ${_formatBytes(_totalBytes)}',
                                style: GoogleFonts.quicksand(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: tokens.textMuted,
                                ),
                              ),
                              Text(
                                _downloadProgress >= 1.0 ? 'Verified' : 'Direct Download',
                                style: GoogleFonts.quicksand(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: tokens.primaryAccent,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
                if (widget.isWhatsNewMode) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tokens.primaryAccent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Done',
                        style: GoogleFonts.quicksand(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isDownloading
                              ? null
                              : () => _handleUpdateAction(downloadUrl),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _downloadedApkFile != null
                                ? const Color(0xFF1E6B3F)
                                : tokens.primaryAccent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            _downloadedApkFile != null
                                ? 'Install Update'
                                : (_isDownloading ? 'Downloading...' : 'Update Now'),
                            style: GoogleFonts.quicksand(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      if (canDismiss && !_isDownloading) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
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
                              widget.isDevInspectMode && isMandatory ? 'Exit Dev Preview' : 'Not now',
                              style: GoogleFonts.quicksand(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
