import 'package:flutter/material.dart';

/// Gentle organic scalloped/cloud wave clipper for the Sprout bottom navigation bar
class WavyBottomBarClipper extends CustomClipper<Path> {
  final double waveHeight;
  final int waveCount;

  const WavyBottomBarClipper({
    this.waveHeight = 6.0,
    this.waveCount = 4,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    final midY = waveHeight * 0.5;
    path.moveTo(0, midY);

    final waveWidth = size.width / waveCount;
    for (int i = 0; i < waveCount; i++) {
      final startX = i * waveWidth;
      path.quadraticBezierTo(
        startX + waveWidth * 0.25,
        0,
        startX + waveWidth * 0.5,
        midY,
      );
      path.quadraticBezierTo(
        startX + waveWidth * 0.75,
        waveHeight,
        startX + waveWidth,
        midY,
      );
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant WavyBottomBarClipper oldClipper) =>
      oldClipper.waveHeight != waveHeight || oldClipper.waveCount != waveCount;
}

/// Companion painter to draw a subtle outline along the top edge of the wavy navigation bar
class WavyBorderPainter extends CustomPainter {
  final Color borderColor;
  final double borderWidth;
  final double waveHeight;
  final int waveCount;

  const WavyBorderPainter({
    required this.borderColor,
    this.borderWidth = 1.0,
    this.waveHeight = 6.0,
    this.waveCount = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke;

    final path = Path();
    final midY = waveHeight * 0.5;
    path.moveTo(0, midY);

    final waveWidth = size.width / waveCount;
    for (int i = 0; i < waveCount; i++) {
      final startX = i * waveWidth;
      path.quadraticBezierTo(
        startX + waveWidth * 0.25,
        0,
        startX + waveWidth * 0.5,
        midY,
      );
      path.quadraticBezierTo(
        startX + waveWidth * 0.75,
        waveHeight,
        startX + waveWidth,
        midY,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant WavyBorderPainter oldDelegate) =>
      oldDelegate.borderColor != borderColor ||
      oldDelegate.borderWidth != borderWidth ||
      oldDelegate.waveHeight != waveHeight ||
      oldDelegate.waveCount != waveCount;
}
