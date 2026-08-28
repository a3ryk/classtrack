import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/attendance_stats.dart';

class StatusBadge extends StatelessWidget {
  final SubjectAttendanceStatus status;
  final String text;

  const StatusBadge({
    super.key,
    required this.status,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Color textColor;
    Color bgColor;

    switch (status) {
      case SubjectAttendanceStatus.safe:
        textColor = isDark ? AppColors.presentGreenDark : AppColors.presentGreenLight;
        bgColor = isDark ? AppColors.presentContainerDark : AppColors.presentContainerLight;
        break;
      case SubjectAttendanceStatus.warning:
        textColor = isDark ? AppColors.warningAmberDark : AppColors.warningAmberLight;
        bgColor = isDark ? AppColors.warningContainerDark : AppColors.warningContainerLight;
        break;
      case SubjectAttendanceStatus.critical:
        textColor = isDark ? AppColors.absentRedDark : AppColors.absentRedLight;
        bgColor = isDark ? AppColors.absentContainerDark : AppColors.absentContainerLight;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
