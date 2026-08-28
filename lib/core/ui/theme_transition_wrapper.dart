import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/providers/theme_provider.dart';

/// Global controller to trigger soothing circular theme transitions
class ThemeTransition {
  ThemeTransition._();

  static ThemeTransitionWrapperState? _state;

  static void _register(ThemeTransitionWrapperState state) {
    _state = state;
  }

  static void _unregister(ThemeTransitionWrapperState state) {
    if (_state == state) _state = null;
  }

  /// Triggers a circular radial wave theme change originating from [origin]
  static Future<void> switchTheme(
    BuildContext context,
    WidgetRef ref,
    ThemeMode newMode, {
    Offset? origin,
  }) async {
    final state = _state;
    if (state == null) {
      await ref.read(themeModeProvider.notifier).setThemeMode(newMode);
      return;
    }

    await state.startTransition(ref, newMode, origin: origin);
  }
}

/// Root widget that wraps the application to provide soothing radial theme transitions
class ThemeTransitionWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const ThemeTransitionWrapper({super.key, required this.child});

  @override
  ConsumerState<ThemeTransitionWrapper> createState() => ThemeTransitionWrapperState();
}

class ThemeTransitionWrapperState extends ConsumerState<ThemeTransitionWrapper>
    with SingleTickerProviderStateMixin {
  final GlobalKey _boundaryKey = GlobalKey();
  late AnimationController _animController;
  late Animation<double> _animation;
  ui.Image? _capturedImage;
  Offset _origin = Offset.zero;

  @override
  void initState() {
    super.initState();
    ThemeTransition._register(this);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _animation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOutCubic,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          final old = _capturedImage;
          setState(() {
            _capturedImage = null;
          });
          old?.dispose();
          _animController.reset();
        }
      });
  }

  @override
  void dispose() {
    ThemeTransition._unregister(this);
    _animController.dispose();
    _capturedImage?.dispose();
    super.dispose();
  }

  Future<void> startTransition(
    WidgetRef ref,
    ThemeMode newMode, {
    Offset? origin,
  }) async {
    try {
      final boundary = _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        await ref.read(themeModeProvider.notifier).setThemeMode(newMode);
        return;
      }

      final size = MediaQuery.maybeOf(context)?.size ?? Size.zero;
      final pixelRatio = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0;
      final defaultOrigin = Offset(size.width / 2, size.height / 2);

      final image = await boundary.toImage(pixelRatio: pixelRatio);
      if (!mounted) {
        image.dispose();
        return;
      }

      setState(() {
        _capturedImage = image;
        _origin = origin ?? defaultOrigin;
      });

      // Update actual theme in state
      await ref.read(themeModeProvider.notifier).setThemeMode(newMode);

      // Start circular reveal wave
      _animController.forward(from: 0.0);
    } catch (_) {
      // Fallback if headless test or capture failure
      await ref.read(themeModeProvider.notifier).setThemeMode(newMode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _boundaryKey,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Live widget tree (new theme rendered underneath)
          widget.child,

          // Animated radial cutout of previous theme snapshot
          if (_capturedImage != null)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _RadialRevealPainter(
                        image: _capturedImage!,
                        progress: _animation.value,
                        origin: _origin,
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RadialRevealPainter extends CustomPainter {
  final ui.Image image;
  final double progress;
  final Offset origin;

  _RadialRevealPainter({
    required this.image,
    required this.progress,
    required this.origin,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1.0) return;

    // Calculate maximum radius to cover the furthest screen corner from origin
    final maxDx = math.max(origin.dx, size.width - origin.dx);
    final maxDy = math.max(origin.dy, size.height - origin.dy);
    final maxRadius = math.sqrt(maxDx * maxDx + maxDy * maxDy);
    final currentRadius = maxRadius * progress;

    canvas.save();

    // Clip: outer rectangle minus expanding circle at origin (evenOdd cutout)
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(Rect.fromCircle(center: origin, radius: currentRadius))
      ..fillType = PathFillType.evenOdd;

    canvas.clipPath(path);

    // Draw the captured old theme image over the non-revealed area
    final srcRect = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final dstRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()..filterQuality = FilterQuality.medium;

    canvas.drawImageRect(image, srcRect, dstRect, paint);
    canvas.restore();

    // Draw a soft soothing wave rim along the expanding perimeter
    if (currentRadius > 6 && currentRadius < maxRadius) {
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
        ..color = Colors.white.withValues(alpha: 0.15);
      canvas.drawCircle(origin, currentRadius, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadialRevealPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.image != image;
  }
}
