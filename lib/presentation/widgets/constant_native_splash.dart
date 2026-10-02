import 'package:flutter/material.dart';

/// A high-performance, single-screen launch splash inspired directly by X and Instagram.
///
/// Holds the centered native launcher icon 100% constant and stationary during database
/// hydration, followed by a hardware-accelerated 350ms zoom-through reveal into the app.
class ConstantNativeSplash extends StatefulWidget {
  final bool isReady;
  final VoidCallback onFinished;

  const ConstantNativeSplash({
    super.key,
    required this.isReady,
    required this.onFinished,
  });

  @override
  State<ConstantNativeSplash> createState() => _ConstantNativeSplashState();
}

class _ConstantNativeSplashState extends State<ConstantNativeSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  final DateTime _mountTime = DateTime.now();
  static const Duration _minHoldDuration = Duration(milliseconds: 250);
  static const Duration _exitDuration = Duration(milliseconds: 350);

  bool _hasStartedExit = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _exitDuration,
    );

    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    // Zoom-through scale: 1.0 -> 1.45 (Icon seamlessly expands as you enter the app)
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.45).animate(curved);
    // Smooth dissolve: 1.0 -> 0.0
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(curved);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onFinished();
      }
    });

    if (widget.isReady) {
      _scheduleExit();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Precache the asset immediately to ensure 0-frame decode hitch on GPU
    precacheImage(const AssetImage('assets/icon/app_icon.png'), context);
  }

  @override
  void didUpdateWidget(covariant ConstantNativeSplash oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isReady && !oldWidget.isReady) {
      _scheduleExit();
    }
  }

  void _scheduleExit() {
    if (_hasStartedExit) return;
    _hasStartedExit = true;

    final elapsed = DateTime.now().difference(_mountTime);
    final remainingHold = _minHoldDuration - elapsed;

    if (remainingHold > Duration.zero) {
      Future.delayed(remainingHold, () {
        if (!mounted) return;
        _startAnimation();
      });
    } else {
      _startAnimation();
    }
  }

  void _startAnimation() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Pure, distraction-free native canvas (solid black / solid white)
    final bgColor = isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);

    return RepaintBoundary(
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: Container(
          color: bgColor,
          alignment: Alignment.center,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Image.asset(
                'assets/icon/app_icon.png',
                width: 124,
                height: 124,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
