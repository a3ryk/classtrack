import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

enum ToastType { success, error, info }

/// Sleek Floating Pill Toast / Banner Notification System
class AppToast {
  AppToast._();

  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
    if (scaffoldMessenger == null) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Color border;
    Color iconColor;
    Color textColor;
    IconData icon;

    switch (type) {
      case ToastType.success:
        bg = isDark ? const Color(0xFF13221C) : const Color(0xFFECFDF5);
        border = isDark ? const Color(0xFF1E3A2E) : const Color(0xFFA7F3D0);
        iconColor = isDark ? AppColors.presentGreenDark : AppColors.presentGreen;
        textColor = isDark ? const Color(0xFFD1FAE5) : const Color(0xFF065F46);
        icon = Icons.check_circle_rounded;
        break;
      case ToastType.error:
        bg = isDark ? const Color(0xFF241416) : const Color(0xFFFEF2F2);
        border = isDark ? const Color(0xFF3E1D21) : const Color(0xFFFECACA);
        iconColor = isDark ? AppColors.absentRedDark : AppColors.absentRed;
        textColor = isDark ? const Color(0xFFFEE2E2) : const Color(0xFF991B1B);
        icon = Icons.error_rounded;
        break;
      case ToastType.info:
        bg = isDark ? AppColors.cardDark : AppColors.surfaceLight;
        border = isDark ? AppColors.borderDark : AppColors.borderLight;
        iconColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
        textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
        icon = Icons.info_outline_rounded;
        break;
    }

    scaffoldMessenger.hideCurrentSnackBar();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        padding: EdgeInsets.zero,
        duration: duration,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    scaffoldMessenger.hideCurrentSnackBar();
                    onAction();
                  },
                  child: Text(
                    actionLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: iconColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static void success(BuildContext context, String message, {Duration duration = const Duration(seconds: 3)}) {
    show(context, message, type: ToastType.success, duration: duration);
  }

  static void error(BuildContext context, String message, {Duration duration = const Duration(seconds: 4)}) {
    show(context, message, type: ToastType.error, duration: duration);
  }

  static void info(BuildContext context, String message, {Duration duration = const Duration(seconds: 3)}) {
    show(context, message, type: ToastType.info, duration: duration);
  }
}
