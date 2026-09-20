import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Animated mascot overlay that peeks in horizontally from the side of the screen
class MascotPeekOverlay {
  MascotPeekOverlay._();

  static OverlayEntry? _currentEntry;

  static void show(
    BuildContext context, {
    required String quote,
    String mascotAsset = 'assets/themes/sprout/mascots/mascot_sprout.jpg',
    VoidCallback? onDismiss,
  }) {
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _MascotPeekWidget(
        quote: quote,
        mascotAsset: mascotAsset,
        onDismiss: () {
          entry.remove();
          if (_currentEntry == entry) _currentEntry = null;
          onDismiss?.call();
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }
}

class _MascotPeekWidget extends StatefulWidget {
  final String quote;
  final String mascotAsset;
  final VoidCallback onDismiss;

  const _MascotPeekWidget({
    required this.quote,
    required this.mascotAsset,
    required this.onDismiss,
  });

  @override
  State<_MascotPeekWidget> createState() => _MascotPeekWidgetState();
}

class _MascotPeekWidgetState extends State<_MascotPeekWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  bool _isDismissing = false;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    // Bouncy elastic peek-in curve from the side edge
    _slideAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward();

    // Auto-dismiss after 3.8 seconds
    _dismissTimer = Timer(const Duration(milliseconds: 3800), () {
      if (mounted && !_isDismissing) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    if (_isDismissing) return;
    _isDismissing = true;
    _dismissTimer?.cancel();
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Positioned(
      bottom: bottomPadding + 86,
      right: 12,
      child: Material(
        color: Colors.transparent,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // Translates horizontally from the right screen edge
            final slideX = (1.0 - _slideAnimation.value) * 260.0;
            final tilt = math.sin(_slideAnimation.value * math.pi) * -0.06;
            return Transform.translate(
              offset: Offset(slideX, 0),
              child: Transform.rotate(
                angle: tilt,
                alignment: Alignment.bottomRight,
                child: Opacity(
                  opacity: _fadeAnimation.value.clamp(0.0, 1.0),
                  child: child,
                ),
              ),
            );
          },
          child: GestureDetector(
            onTap: _dismiss,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Speech bubble pointing to the mascot
                _buildSpeechBubble(context, isDark),
                const SizedBox(width: 8),
                // 3D Marshmallow Sprout Mascot
                _buildMascotAvatar(isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpeechBubble(BuildContext context, bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxBubbleWidth = math.min(screenWidth - 120, 240.0);

    return Container(
      constraints: BoxConstraints(maxWidth: maxBubbleWidth),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B3626) : const Color(0xFFFAF7F2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF336242) : const Color(0xFFDCEAD4),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Attendly Mascot',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                  color: isDark ? const Color(0xFFA4D673) : const Color(0xFF689F38),
                ),
              ),
              const SizedBox(width: 4),
              const Text('🌱', style: TextStyle(fontSize: 11)),
              const Spacer(),
              Icon(
                Icons.close_rounded,
                size: 14,
                color: isDark ? const Color(0xFFA3C2AC) : const Color(0xFF8BA392),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            widget.quote,
            style: GoogleFonts.quicksand(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              height: 1.25,
              color: isDark ? const Color(0xFFF4F8F3) : const Color(0xFF1E3526),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMascotAvatar(bool isDark) {
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? const Color(0xFFA4D673) : const Color(0xFF7CB342),
          width: 2.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7CB342).withValues(alpha: isDark ? 0.35 : 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          widget.mascotAsset,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: isDark ? const Color(0xFF1B3626) : const Color(0xFFE8F5E9),
            alignment: Alignment.center,
            child: const Text('🌱', style: TextStyle(fontSize: 30)),
          ),
        ),
      ),
    );
  }
}
