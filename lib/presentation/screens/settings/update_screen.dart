import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/update_constants.dart';
import '../../../core/services/app_update_service.dart';
import '../../../core/ui/app_toast.dart';

class UpdateScreen extends StatefulWidget {
  final AppReleaseInfo releaseInfo;
  final bool isWhatsNewMode;

  const UpdateScreen({
    super.key,
    required this.releaseInfo,
    this.isWhatsNewMode = false,
  });

  static Route<void> route(AppReleaseInfo releaseInfo, {bool isWhatsNewMode = false}) {
    return PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (context, animation, secondaryAnimation) => RepaintBoundary(
        child: UpdateScreen(
          releaseInfo: releaseInfo,
          isWhatsNewMode: isWhatsNewMode,
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

  late final List<String> _features;
  late final List<String> _fixes;
  late final List<String> _general;

  @override
  void initState() {
    super.initState();
    _features = [];
    _fixes = [];
    _general = [];

    for (final item in widget.releaseInfo.changelog) {
      final lower = item.toLowerCase();
      if (lower.contains('fix') || lower.contains('bug') || item.startsWith('🧩')) {
        _fixes.add(item.replaceAll(RegExp(r'^(🧩|\-|\*|•)\s*'), ''));
      } else if (lower.contains('feat') || lower.contains('add') || item.startsWith('✨')) {
        _features.add(item.replaceAll(RegExp(r'^(✨|\-|\*|•)\s*'), ''));
      } else {
        _general.add(item.replaceAll(RegExp(r'^(\-|\*|•)\s*'), ''));
      }
    }
  }

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
          AppToast.success(context, 'Download complete! Opening package installer...');
          await AppUpdateService.installApk(apkFile);
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMandatory = widget.releaseInfo.isMandatory;
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);
    final brandBlue = AppColors.accentBlue;

    final downloadUrl = widget.releaseInfo.downloadUrl?.isNotEmpty == true
        ? widget.releaseInfo.downloadUrl!
        : (widget.releaseInfo.releasePageUrl?.isNotEmpty == true
            ? widget.releaseInfo.releasePageUrl!
            : UpdateConstants.defaultWebsiteUrl);

    final githubUrl = widget.releaseInfo.releasePageUrl?.isNotEmpty == true
        ? widget.releaseInfo.releasePageUrl!
        : 'https://github.com/${UpdateConstants.defaultGithubOwner}/${UpdateConstants.defaultGithubRepo}/releases/latest';

    final features = _features;
    final fixes = _fixes;
    final general = _general;

    return PopScope(
      canPop: !isMandatory,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF8FAFC),
          elevation: 0,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: !isMandatory,
          leading: isMandatory
              ? null
              : IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, size: 22),
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  onPressed: () => Navigator.pop(context),
                ),
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
                        const SizedBox(height: 8),
                        Icon(
                          widget.isWhatsNewMode
                              ? Icons.auto_awesome_rounded
                              : (isMandatory ? Icons.warning_amber_rounded : Icons.system_update_alt_rounded),
                          size: 44,
                          color: widget.isWhatsNewMode
                              ? AppColors.accentIndigoLight
                              : (isMandatory
                                  ? (isDark ? AppColors.absentRedDark : AppColors.absentRedText)
                                  : brandBlue),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.isWhatsNewMode
                              ? (widget.releaseInfo.releaseTitle.isNotEmpty
                                  ? widget.releaseInfo.releaseTitle
                                  : 'What\'s New in v${widget.releaseInfo.latestVersion}')
                              : (isMandatory ? 'Critical Update Required' : 'New version available!'),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.isWhatsNewMode
                              ? 'v${widget.releaseInfo.latestVersion}${widget.releaseInfo.releaseDate.isNotEmpty ? " • Released ${widget.releaseInfo.releaseDate}" : " • Current Version"}'
                              : 'v${widget.releaseInfo.latestVersion}${widget.releaseInfo.releaseDate.isNotEmpty ? " • Released ${widget.releaseInfo.releaseDate}" : ""}',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (isMandatory || (widget.releaseInfo.warningMessage != null && widget.releaseInfo.warningMessage!.isNotEmpty)) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isMandatory
                                  ? (isDark ? AppColors.absentContainerDark : AppColors.absentContainerLight)
                                  : (isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF)),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isMandatory
                                    ? (isDark ? AppColors.absentRedDark.withValues(alpha: 0.35) : AppColors.absentRed.withValues(alpha: 0.35))
                                    : (isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.35) : const Color(0xFF93C5FD)),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  isMandatory ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
                                  size: 18,
                                  color: isMandatory
                                      ? (isDark ? AppColors.absentRedDark : AppColors.absentRedText)
                                      : (isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    widget.releaseInfo.warningMessage ?? (isMandatory ? 'Mandatory update required for app stability and features.' : 'Important notice for this release.'),
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      height: 1.4,
                                      fontWeight: FontWeight.w600,
                                      color: isMandatory
                                          ? (isDark ? AppColors.absentRedDark : AppColors.absentRedText)
                                          : (isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        Text(
                          widget.isWhatsNewMode
                              ? 'Here is what was added and improved in this version.'
                              : 'Check out the release notes below or download the latest package to update in-place.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            color: isDark ? AppColors.textSecondaryDark : const Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.cardDark : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor, width: 0.8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (features.isNotEmpty) ...[
                                _buildCategoryHeader('✨ Features', isDark),
                                const SizedBox(height: 8),
                                ...features.map((item) => _buildBulletItem(item, isDark)),
                                const SizedBox(height: 14),
                              ],
                              if (fixes.isNotEmpty) ...[
                                _buildCategoryHeader('🧩 Fixes', isDark),
                                const SizedBox(height: 8),
                                ...fixes.map((item) => _buildBulletItem(item, isDark)),
                                const SizedBox(height: 14),
                              ],
                              if (general.isNotEmpty && features.isEmpty && fixes.isEmpty) ...[
                                _buildCategoryHeader('⚡ Improvements', isDark),
                                const SizedBox(height: 8),
                                ...general.map((item) => _buildBulletItem(item, isDark)),
                                const SizedBox(height: 14),
                              ],
                              if (widget.releaseInfo.changelog.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    '• General performance improvements and bug fixes.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ),
                            ],
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
                      if (!isMandatory && !_isDownloading) ...[
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
                            child: const Text(
                              'Not now',
                              style: TextStyle(
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

  Widget _buildCategoryHeader(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      ),
    );
  }

  Widget _buildBulletItem(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
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
