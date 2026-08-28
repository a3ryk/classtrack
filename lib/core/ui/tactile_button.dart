import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tactile Scale Micro-Interaction Container
class TapScaleContainer extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double minScale;
  final Duration pressDuration;
  final Duration releaseDuration;
  final Curve releaseCurve;
  final HitTestBehavior behavior;

  const TapScaleContainer({
    super.key,
    required this.child,
    required this.onTap,
    this.minScale = 0.88,
    this.pressDuration = const Duration(milliseconds: 90),
    this.releaseDuration = const Duration(milliseconds: 140),
    this.releaseCurve = Curves.easeOutBack,
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  State<TapScaleContainer> createState() => _TapScaleContainerState();
}

class _TapScaleContainerState extends State<TapScaleContainer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.pressDuration,
      reverseDuration: widget.releaseDuration,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.minScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: widget.releaseCurve,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap == null) return;
    HapticFeedback.selectionClick();
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap == null) return;
    _controller.reverse();
    widget.onTap!();
  }

  void _onTapCancel() {
    if (widget.onTap == null) return;
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return widget.child;

    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Circular Header & Action Icon Button with Tactile Scale and Haptic Feedback
class TactileIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final double size;
  final double iconSize;
  final String? tooltip;
  final BoxShape shape;
  final BorderRadius? borderRadius;

  const TactileIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.backgroundColor,
    this.borderColor,
    this.size = 40.0,
    this.iconSize = 20.0,
    this.tooltip,
    this.shape = BoxShape.circle,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.transparent,
        shape: shape,
        borderRadius: shape == BoxShape.rectangle ? (borderRadius ?? BorderRadius.circular(10)) : null,
        border: borderColor != null ? Border.all(color: borderColor!, width: 0.8) : null,
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: iconSize,
        color: iconColor,
      ),
    );

    if (tooltip != null && tooltip!.isNotEmpty) {
      button = Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return TapScaleContainer(
      onTap: onTap,
      child: button,
    );
  }
}
