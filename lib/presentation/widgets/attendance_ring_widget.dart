import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AttendanceRingWidget extends StatelessWidget {
  final double percentage;
  final double targetPercentage;
  final double size;
  final bool isDataEmpty;

  const AttendanceRingWidget({
    super.key,
    required this.percentage,
    this.targetPercentage = 75.0,
    this.size = 80,
    this.isDataEmpty = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final targetVal = isDataEmpty ? 0.0 : percentage;

    final Color trackColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final Color notchColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: targetVal, end: targetVal),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (context, animValue, _) {
        final bool isSafe = animValue >= targetPercentage;

        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _RingPainter(
              percentage: animValue,
              targetPercentage: targetPercentage,
              isSafe: isSafe,
              isDataEmpty: isDataEmpty,
              isDark: isDark,
              trackColor: trackColor,
              notchColor: notchColor,
              strokeWidth: 7.5,
            ),
            child: Center(
              child: Text(
                isDataEmpty
                    ? '--%'
                    : (animValue >= 99.95 ? '100%' : '${animValue.toStringAsFixed(1)}%'),
                style: TextStyle(
                  fontSize: size <= 64 ? 13 : 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: isDataEmpty
                      ? (isDark ? AppColors.textMutedDark : AppColors.textMutedLight)
                      : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double percentage;
  final double targetPercentage;
  final bool isSafe;
  final bool isDataEmpty;
  final bool isDark;
  final Color trackColor;
  final Color notchColor;
  final double strokeWidth;

  _RingPainter({
    required this.percentage,
    required this.targetPercentage,
    required this.isSafe,
    required this.isDataEmpty,
    required this.isDark,
    required this.trackColor,
    required this.notchColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // 1. Background Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // 2. Target Threshold Marker Notch (e.g. at 75%)
    if (targetPercentage > 0 && targetPercentage <= 100) {
      final targetAngle = -pi / 2 + 2 * pi * (targetPercentage / 100.0);
      final r1 = radius - (strokeWidth / 2) - 1.5;
      final r2 = radius + (strokeWidth / 2) + 1.5;
      final p1 = center + Offset(r1 * cos(targetAngle), r1 * sin(targetAngle));
      final p2 = center + Offset(r2 * cos(targetAngle), r2 * sin(targetAngle));

      final notchPaint = Paint()
        ..color = notchColor.withValues(alpha: 0.65)
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(p1, p2, notchPaint);
    }

    // 3. Active Progress Arc with Rich Gradient & Tip Glow
    if (!isDataEmpty && percentage > 0) {
      final sweepAngle = 2 * pi * (min(percentage, 100.0) / 100.0);

      final List<Color> gradientColors = isSafe
          ? [
              const Color(0xFF059669),
              const Color(0xFF10B981),
              const Color(0xFF34D399),
            ]
          : [
              const Color(0xFFBE123C),
              const Color(0xFFE11D48),
              const Color(0xFFFB7185),
            ];

      final gradient = SweepGradient(
        startAngle: 0,
        endAngle: sweepAngle,
        colors: gradientColors,
        transform: const GradientRotation(-pi / 2),
      );

      final progressPaint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      // Draw Arc
      canvas.drawArc(
        rect,
        -pi / 2,
        sweepAngle,
        false,
        progressPaint,
      );

      // Leading Tip Glow
      if (percentage >= 2.0) {
        final tipAngle = -pi / 2 + sweepAngle;
        final tipOffset = center + Offset(radius * cos(tipAngle), radius * sin(tipAngle));

        final glowPaint = Paint()
          ..color = (isSafe ? const Color(0xFF34D399) : const Color(0xFFFB7185)).withValues(alpha: 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);

        canvas.drawCircle(tipOffset, strokeWidth / 2, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.percentage != percentage ||
        oldDelegate.targetPercentage != targetPercentage ||
        oldDelegate.isSafe != isSafe ||
        oldDelegate.isDataEmpty != isDataEmpty ||
        oldDelegate.isDark != isDark ||
        oldDelegate.trackColor != trackColor;
  }
}
