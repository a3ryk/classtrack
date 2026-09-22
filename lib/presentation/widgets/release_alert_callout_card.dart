import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/app_update_service.dart';

/// Renders a single GitHub-style release alert callout card (Caution, Warning, Note, Tip, Important)
/// with zero hardcoded text (only the icon on the left and raw Markdown on the right).
class ReleaseAlertCalloutCard extends StatelessWidget {
  final ReleaseAlertCallout callout;
  final bool isCute;
  final bool isDark;
  final void Function(String url)? onLinkTap;

  const ReleaseAlertCalloutCard({
    super.key,
    required this.callout,
    this.isCute = false,
    this.isDark = false,
    this.onLinkTap,
  });

  Future<void> _handleLink(String url) async {
    if (onLinkTap != null) {
      onLinkTap!(url);
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final styling = _resolveStyling();

    TextStyle baseTextStyle({
      required FontWeight fontWeight,
      required Color color,
      FontStyle? fontStyle,
      double fontSize = 12.5,
    }) {
      if (isCute) {
        return GoogleFonts.quicksand(
          fontSize: fontSize,
          height: 1.45,
          fontWeight: fontWeight,
          fontStyle: fontStyle,
          color: color,
        );
      }
      return TextStyle(
        fontSize: fontSize,
        height: 1.45,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        color: color,
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: styling.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: styling.border, width: 1.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            styling.icon,
            size: 18,
            color: styling.iconColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: MarkdownBody(
              data: callout.markdown.replaceAll('ClassTrack', 'Attendly'),
              selectable: true,
              onTapLink: (text, href, title) {
                if (href != null && href.isNotEmpty) {
                  _handleLink(href);
                }
              },
              styleSheet: MarkdownStyleSheet(
                p: baseTextStyle(
                  fontWeight: FontWeight.w600,
                  color: styling.textColor,
                ),
                strong: baseTextStyle(
                  fontWeight: FontWeight.w800,
                  color: styling.strongColor,
                ),
                em: baseTextStyle(
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                  color: styling.strongColor,
                ),
                listBullet: baseTextStyle(
                  fontWeight: FontWeight.w800,
                  color: styling.iconColor,
                  fontSize: 12.5,
                ),
                code: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  backgroundColor: styling.codeBg,
                  color: styling.strongColor,
                ),
                codeblockDecoration: BoxDecoration(
                  color: styling.codeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                a: TextStyle(
                  color: styling.strongColor,
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
                blockSpacing: 4.0,
                listIndent: 16.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _AlertCardStyling _resolveStyling() {
    switch (callout.type) {
      case AlertCalloutType.caution:
        return _AlertCardStyling(
          background: isDark ? AppColors.absentContainerDark : const Color(0xFFFDE8E8),
          border: isDark ? AppColors.absentRedDark.withValues(alpha: 0.4) : const Color(0xFFF8B4B4),
          iconColor: isDark ? AppColors.absentRedDark : const Color(0xFFDC2626),
          textColor: isDark ? AppColors.absentRedDark : const Color(0xFF9B1C1C),
          strongColor: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF771D1D),
          codeBg: isDark ? Colors.black.withValues(alpha: 0.3) : const Color(0xFFF8D7DA),
          icon: Icons.error_outline_rounded,
        );

      case AlertCalloutType.warning:
        return _AlertCardStyling(
          background: isDark ? const Color(0xFF2E2408) : const Color(0xFFFEF9C3),
          border: isDark ? const Color(0xFF854D0E) : const Color(0xFFFACC15),
          iconColor: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
          textColor: isDark ? const Color(0xFFFDE047) : const Color(0xFF854D0E),
          strongColor: isDark ? const Color(0xFFFEF08A) : const Color(0xFF713F12),
          codeBg: isDark ? Colors.black.withValues(alpha: 0.3) : const Color(0xFFFEF08A).withValues(alpha: 0.6),
          icon: Icons.warning_amber_rounded,
        );

      case AlertCalloutType.tip:
        // Bulb icon for Tip!
        return _AlertCardStyling(
          background: isDark ? const Color(0xFF2E220C) : const Color(0xFFFFFBEB),
          border: isDark ? const Color(0xFF78350F) : const Color(0xFFFCD34D),
          iconColor: isDark ? const Color(0xFFFCD34D) : const Color(0xFFD97706),
          textColor: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
          strongColor: isDark ? const Color(0xFFFEF3C7) : const Color(0xFF78350F),
          codeBg: isDark ? Colors.black.withValues(alpha: 0.3) : const Color(0xFFFEF3C7),
          icon: Icons.lightbulb_rounded,
        );

      case AlertCalloutType.important:
        return _AlertCardStyling(
          background: isDark ? const Color(0xFF172554) : const Color(0xFFEFF6FF),
          border: isDark ? const Color(0xFF1D4ED8) : const Color(0xFFBFDBFE),
          iconColor: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
          textColor: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF),
          strongColor: isDark ? const Color(0xFFBFDBFE) : const Color(0xFF1E3A8A),
          codeBg: isDark ? Colors.black.withValues(alpha: 0.3) : const Color(0xFFDBEAFE),
          icon: Icons.priority_high_rounded,
        );

      case AlertCalloutType.note:
        return _AlertCardStyling(
          background: isCute
              ? (isDark ? const Color(0xFF14261B) : const Color(0xFFF6FCF5))
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          border: isCute
              ? (isDark ? const Color(0xFF274D36) : const Color(0xFFD7F0D6))
              : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
          iconColor: isCute
              ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A))
              : (isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB)),
          textColor: isCute
              ? (isDark ? const Color(0xFF86EFAC) : const Color(0xFF1E6B3F))
              : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
          strongColor: isCute
              ? (isDark ? const Color(0xFFBBF7D0) : const Color(0xFF164E2A))
              : (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A)),
          codeBg: isDark ? Colors.black.withValues(alpha: 0.3) : (isCute ? const Color(0xFFE5F3E3) : const Color(0xFFE2E8F0)),
          icon: Icons.sticky_note_2_rounded,
        );
    }
  }
}

class _AlertCardStyling {
  final Color background;
  final Color border;
  final Color iconColor;
  final Color textColor;
  final Color strongColor;
  final Color codeBg;
  final IconData icon;

  const _AlertCardStyling({
    required this.background,
    required this.border,
    required this.iconColor,
    required this.textColor,
    required this.strongColor,
    required this.codeBg,
    required this.icon,
  });
}

/// Renders a list of [ReleaseAlertCallout] sequentially in exact order.
class ReleaseAlertCalloutsList extends StatelessWidget {
  final List<ReleaseAlertCallout> alertCallouts;
  final bool isCute;
  final bool isDark;
  final void Function(String url)? onLinkTap;

  const ReleaseAlertCalloutsList({
    super.key,
    required this.alertCallouts,
    this.isCute = false,
    this.isDark = false,
    this.onLinkTap,
  });

  @override
  Widget build(BuildContext context) {
    if (alertCallouts.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final callout in alertCallouts)
          ReleaseAlertCalloutCard(
            callout: callout,
            isCute: isCute,
            isDark: isDark,
            onLinkTap: onLinkTap,
          ),
      ],
    );
  }
}
