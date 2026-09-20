import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/providers/theme_provider.dart';
import '../../presentation/providers/app_theme_style_provider.dart';

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

  /// Returns true if a theme transition is actively capturing or animating
  static bool get isAnimating => _state?.isAnimating ?? false;

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
    if (state.isAnimating) return;

    await state.startTransition(ref, newMode, origin: origin);
  }

  /// Triggers a circular radial wave theme style change originating from [origin]
  static Future<void> switchThemeStyle(
    BuildContext context,
    WidgetRef ref,
    String newStyleId, {
    Offset? origin,
    VoidCallback? onComplete,
  }) async {
    final state = _state;
    if (state == null) {
      await ref.read(appThemeStyleProvider.notifier).setThemeStyle(newStyleId);
      onComplete?.call();
      return;
    }
    if (state.isAnimating) return;

    await state.startStyleTransition(ref, newStyleId, origin: origin, onComplete: onComplete);
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
  bool _isRevealingDark = true;
  bool _isCapturing = false;
  bool _isTransitionActive = false;
  bool _isStyleTransition = false;
  Color _styleWaveColor = const Color(0xFF7CB342);
  VoidCallback? _onStyleTransitionComplete;

  /// Returns true if a transition is in progress and visually active
  bool get isAnimating =>
      _isCapturing || (_isTransitionActive && _animController.isAnimating && _animation.value < 0.88);

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
          final cb = _onStyleTransitionComplete;
          _onStyleTransitionComplete = null;
          _cleanupSnapshot();
          cb?.call();
        }
      });
  }

  void _cleanupSnapshot() {
    _isCapturing = false;
    _isTransitionActive = false;
    _isStyleTransition = false;
    final old = _capturedImage;
    if (_capturedImage != null) {
      setState(() {
        _capturedImage = null;
      });
      old?.dispose();
    }
    _animController.reset();
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
    if (isAnimating) return;
    _cleanupSnapshot();

    try {
      final currentMode = ref.read(themeModeProvider);
      final platformBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;

      final currentIsDark = currentMode == ThemeMode.dark ||
          (currentMode == ThemeMode.system && platformBrightness == Brightness.dark);

      final newIsDark = newMode == ThemeMode.dark ||
          (newMode == ThemeMode.system && platformBrightness == Brightness.dark);

      // If the effective visual appearance does not change, update state without animation
      if (currentIsDark == newIsDark) {
        await ref.read(themeModeProvider.notifier).setThemeMode(newMode);
        return;
      }

      _isCapturing = true;

      final boundary = _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        _isCapturing = false;
        await ref.read(themeModeProvider.notifier).setThemeMode(newMode);
        return;
      }

      final size = MediaQuery.maybeOf(context)?.size ?? Size.zero;
      final devicePixelRatio = MediaQuery.maybeOf(context)?.devicePixelRatio ??
          WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
      final defaultOrigin = Offset(size.width / 2, size.height / 2);

      // Snapshot capture at true 1:1 devicePixelRatio for pixel-perfect raster alignment (zero shaking/resizing)
      final image = await boundary.toImage(pixelRatio: devicePixelRatio);
      if (!mounted) {
        image.dispose();
        _isCapturing = false;
        return;
      }

      // Stage snapshot overlay immediately so the user sees a frozen frame with zero flash
      setState(() {
        _capturedImage = image;
        _origin = origin ?? defaultOrigin;
        _isRevealingDark = newIsDark;
        _isTransitionActive = true;
      });

      // Post-frame dispatch: Rebuild live tree invisibly behind snapshot before starting smooth wave
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) {
          _cleanupSnapshot();
          return;
        }
        await ref.read(themeModeProvider.notifier).setThemeMode(newMode);
        if (mounted) {
          _isCapturing = false;
          _animController.forward(from: 0.0);
        } else {
          _cleanupSnapshot();
        }
      });
    } catch (_) {
      _cleanupSnapshot();
      await ref.read(themeModeProvider.notifier).setThemeMode(newMode);
    }
  }

  /// Triggers a soothing circular radial wave reveal when switching theme style
  Future<void> startStyleTransition(
    WidgetRef ref,
    String newStyleId, {
    Offset? origin,
    VoidCallback? onComplete,
  }) async {
    if (isAnimating) return;
    _cleanupSnapshot();

    try {
      final currentStyle = ref.read(appThemeStyleProvider);
      if (currentStyle == newStyleId) {
        onComplete?.call();
        return;
      }

      final waveColor = newStyleId == 'cute_sprout'
          ? const Color(0xFF7CB342)
          : const Color(0xFF6366F1);

      _isCapturing = true;

      final boundary = _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        _isCapturing = false;
        await ref.read(appThemeStyleProvider.notifier).setThemeStyle(newStyleId);
        onComplete?.call();
        return;
      }

      final size = MediaQuery.maybeOf(context)?.size ?? Size.zero;
      final devicePixelRatio = MediaQuery.maybeOf(context)?.devicePixelRatio ??
          WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
      final defaultOrigin = Offset(size.width / 2, size.height / 2);

      final image = await boundary.toImage(pixelRatio: devicePixelRatio);
      if (!mounted) {
        image.dispose();
        _isCapturing = false;
        return;
      }

      setState(() {
        _capturedImage = image;
        _origin = origin ?? defaultOrigin;
        _isStyleTransition = true;
        _styleWaveColor = waveColor;
        _onStyleTransitionComplete = onComplete;
        _isTransitionActive = true;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) {
          _cleanupSnapshot();
          return;
        }
        await ref.read(appThemeStyleProvider.notifier).setThemeStyle(newStyleId);
        if (mounted) {
          _isCapturing = false;
          _animController.forward(from: 0.0);
        } else {
          _cleanupSnapshot();
        }
      });
    } catch (_) {
      _cleanupSnapshot();
      await ref.read(appThemeStyleProvider.notifier).setThemeStyle(newStyleId);
      onComplete?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Live widget tree (new theme rendered underneath, isolated for clean snapshot capture)
        RepaintBoundary(
          key: _boundaryKey,
          child: widget.child,
        ),

        // Animated luxury radial cutout of previous theme snapshot (visible throughout staging and animation)
        if (_capturedImage != null && _isTransitionActive)
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _isStyleTransition
                          ? _StyleRadialRevealPainter(
                              image: _capturedImage!,
                              progress: _animation.value,
                              origin: _origin,
                              accentColor: _styleWaveColor,
                            )
                          : _RadialRevealPainter(
                              image: _capturedImage!,
                              progress: _animation.value,
                              origin: _origin,
                              isRevealingDark: _isRevealingDark,
                            ),
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _StyleRadialRevealPainter extends CustomPainter {
  final ui.Image image;
  final double progress;
  final Offset origin;
  final Color accentColor;

  _StyleRadialRevealPainter({
    required this.image,
    required this.progress,
    required this.origin,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1.0) return;

    final maxDx = math.max(origin.dx, size.width - origin.dx);
    final maxDy = math.max(origin.dy, size.height - origin.dy);
    final maxRadius = math.sqrt(maxDx * maxDx + maxDy * maxDy) * 1.05;
    final currentRadius = maxRadius * progress;

    final double masterOpacity = progress > 0.88
        ? (1.0 - (progress - 0.88) / 0.12).clamp(0.0, 1.0)
        : 1.0;

    canvas.save();

    // Outer rectangle minus expanding circle at origin (reveals new theme underneath)
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(Rect.fromCircle(center: origin, radius: currentRadius))
      ..fillType = PathFillType.evenOdd;

    canvas.clipPath(path);

    final srcRect = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final dstRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..filterQuality = FilterQuality.medium
      ..color = Colors.white.withValues(alpha: masterOpacity);

    canvas.drawImageRect(image, srcRect, dstRect, paint);
    canvas.restore();

    // Glowing ripple wave front along the perimeter
    if (currentRadius > 0 && progress < 0.95) {
      final ringAlpha = (1.0 - progress).clamp(0.0, 1.0) * 0.75;
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..color = accentColor.withValues(alpha: ringAlpha);
      canvas.drawCircle(origin, currentRadius, ringPaint);

      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8.0
        ..color = accentColor.withValues(alpha: ringAlpha * 0.35);
      canvas.drawCircle(origin, currentRadius, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StyleRadialRevealPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.image != image ||
        oldDelegate.origin != origin ||
        oldDelegate.accentColor != accentColor;
  }
}

class _RadialRevealPainter extends CustomPainter {
  final ui.Image image;
  final double progress;
  final Offset origin;
  final bool isRevealingDark;

  _RadialRevealPainter({
    required this.image,
    required this.progress,
    required this.origin,
    required this.isRevealingDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1.0) return;

    // Calculate maximum radius to cover the furthest screen corner from origin
    final maxDx = math.max(origin.dx, size.width - origin.dx);
    final maxDy = math.max(origin.dy, size.height - origin.dy);
    final maxRadius = math.sqrt(maxDx * maxDx + maxDy * maxDy) * 1.05;

    // Telegram Dual-Direction Geometry:
    // 1. Light ➔ Dark (Push Outward): Expanding dark hole from 0 ➔ maxRadius
    // 2. Dark ➔ Light (Pull Inward): Contracting dark circle from maxRadius ➔ 0
    final double currentRadius = isRevealingDark
        ? maxRadius * progress
        : maxRadius * (1.0 - progress);

    // Soft opacity falloff towards the final 10% of the transition for a seamless dissolve
    final double masterOpacity = progress > 0.90
        ? (1.0 - (progress - 0.90) / 0.10).clamp(0.0, 1.0)
        : 1.0;

    canvas.save();

    final path = Path();
    if (isRevealingDark) {
      // Light ➔ Dark: Clip outer rectangle minus expanding circle at origin (evenOdd cutout)
      path
        ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
        ..addOval(Rect.fromCircle(center: origin, radius: currentRadius))
        ..fillType = PathFillType.evenOdd;
    } else {
      // Dark ➔ Light: Clip only inside the contracting dark circle (nonZero mask)
      path
        ..addOval(Rect.fromCircle(center: origin, radius: currentRadius))
        ..fillType = PathFillType.nonZero;
    }

    canvas.clipPath(path);

    // Draw the captured old theme image over the masked area with pristine 1:1 pixel fidelity
    final srcRect = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final dstRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..filterQuality = FilterQuality.medium
      ..color = Colors.white.withValues(alpha: masterOpacity);

    canvas.drawImageRect(image, srcRect, dstRect, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RadialRevealPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.image != image ||
        oldDelegate.isRevealingDark != isRevealingDark;
  }
}
