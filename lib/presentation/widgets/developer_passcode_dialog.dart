import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/developer_auth_service.dart';
import '../../core/ui/app_toast.dart';
import '../providers/app_state_provider.dart';

class DeveloperPasscodeDialog extends ConsumerStatefulWidget {
  final VoidCallback onUnlocked;
  final VoidCallback? onScanQrRequested;

  const DeveloperPasscodeDialog({
    super.key,
    required this.onUnlocked,
    this.onScanQrRequested,
  });

  @override
  ConsumerState<DeveloperPasscodeDialog> createState() => _DeveloperPasscodeDialogState();
}

class _DeveloperPasscodeDialogState extends ConsumerState<DeveloperPasscodeDialog>
    with SingleTickerProviderStateMixin {
  String _enteredPin = '';
  bool _isError = false;
  Timer? _lockoutTimer;
  int _lockoutSecondsRemaining = 0;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: 8.0, end: -6.0), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: -6.0, end: 6.0), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: 6.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));

    _checkLockout();
  }

  void _checkLockout() {
    if (DeveloperRateLimiter.isLockedOut) {
      _lockoutSecondsRemaining = DeveloperRateLimiter.remainingLockoutSeconds;
      _lockoutTimer?.cancel();
      _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return;
        setState(() {
          _lockoutSecondsRemaining = DeveloperRateLimiter.remainingLockoutSeconds;
          if (_lockoutSecondsRemaining <= 0) {
            _lockoutTimer?.cancel();
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _lockoutTimer?.cancel();
    super.dispose();
  }

  void _onDigitPressed(String digit) {
    if (_lockoutSecondsRemaining > 0 || _enteredPin.length >= 4) return;
    HapticFeedback.lightImpact();

    setState(() {
      _isError = false;
      _enteredPin += digit;
    });

    if (_enteredPin.length == 4) {
      _validatePin();
    }
  }

  void _onBackspacePressed() {
    if (_enteredPin.isEmpty || _lockoutSecondsRemaining > 0) return;
    HapticFeedback.lightImpact();
    setState(() {
      _isError = false;
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
    });
  }

  void _validatePin() {
    final customHash = ref.read(customDevPasscodeHashProvider);
    final isValid = DeveloperAuthService.verifyPasscode(_enteredPin, customHash);

    if (isValid) {
      DeveloperRateLimiter.recordSuccess();
      ref.read(isDeveloperUnlockedProvider.notifier).setUnlocked(true);
      ref.read(developerModeEnabledProvider.notifier).toggle(true);
      Navigator.of(context).pop();
      widget.onUnlocked();
      AppToast.success(context, 'Developer Mode Unlocked');
    } else {
      DeveloperRateLimiter.recordFailure();
      _shakeController.forward(from: 0.0);
      setState(() {
        _isError = true;
        _enteredPin = '';
      });

      if (DeveloperRateLimiter.isLockedOut) {
        _checkLockout();
        AppToast.error(context, 'Too many failed attempts. Locked for 30s.');
      } else {
        final remainingAttempts = 5 - DeveloperRateLimiter.failedAttempts;
        AppToast.error(context, 'Incorrect passcode ($remainingAttempts attempts left)');
      }
    }
  }

  Future<void> _handleQrScan() async {
    if (_lockoutSecondsRemaining > 0) return;
    HapticFeedback.lightImpact();

    // 1. Try to read clipboard first
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    final clipText = clipboardData?.text?.trim();

    final customHash = ref.read(customDevPasscodeHashProvider);
    if (clipText != null && clipText.isNotEmpty && DeveloperAuthService.verifyQrPayload(clipText, customHash)) {
      DeveloperRateLimiter.recordSuccess();
      ref.read(isDeveloperUnlockedProvider.notifier).setUnlocked(true);
      ref.read(developerModeEnabledProvider.notifier).toggle(true);
      if (mounted) {
        Navigator.of(context).pop();
        widget.onUnlocked();
        AppToast.success(context, 'Developer Mode Unlocked via Badge!');
      }
      return;
    }

    // 2. If clipboard didn't have valid payload, open the badge importer modal
    if (!mounted) return;
    final tokenController = TextEditingController(text: clipText ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.cardDark : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark ? AppColors.borderDark : const Color(0xFFE2E8F0),
            width: 0.8,
          ),
        ),
        title: const Text('Unlock with Badge Token', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste the developer badge link or QR token payload below:',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: tokenController,
              decoration: InputDecoration(
                hintText: 'classtrack://dev-unlock?hash=...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final payload = tokenController.text.trim();
              if (DeveloperAuthService.verifyQrPayload(payload, customHash)) {
                DeveloperRateLimiter.recordSuccess();
                ref.read(isDeveloperUnlockedProvider.notifier).setUnlocked(true);
                ref.read(developerModeEnabledProvider.notifier).toggle(true);
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
                widget.onUnlocked();
                AppToast.success(context, 'Developer Mode Unlocked!');
              } else {
                DeveloperRateLimiter.recordFailure();
                AppToast.error(context, 'Invalid Developer Badge or QR payload');
              }
            },
            child: const Text('Verify & Unlock', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF18181B) : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);
    final isLocked = _lockoutSecondsRemaining > 0;

    return Dialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: borderColor, width: 0.8),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.terminal_rounded,
                  size: 20,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Developer Access',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Enter the 4-digit passcode or scan developer badge',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // PIN 4-Cell Display
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_shakeAnimation.value, 0),
                  child: child,
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final hasDigit = index < _enteredPin.length;
                  final isFocused = index == _enteredPin.length && !isLocked;

                  Color cellBorder = borderColor;
                  if (_isError) {
                    cellBorder = AppColors.absentRed;
                  } else if (isFocused) {
                    cellBorder = AppColors.accentIndigoLight;
                  }

                  return Container(
                    width: 44,
                    height: 50,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF27272A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: cellBorder,
                        width: isFocused || _isError ? 1.4 : 0.8,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: hasDigit
                        ? Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                          )
                        : (isFocused
                            ? Container(
                                width: 2,
                                height: 16,
                                color: AppColors.accentIndigoLight,
                              )
                            : null),
                  );
                }),
              ),
            ),

            const SizedBox(height: 12),

            // Lockout / Status Text
            if (isLocked)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Locked out: try again in ${_lockoutSecondsRemaining}s',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.absentRed,
                  ),
                ),
              )
            else
              const SizedBox(height: 8),

            // Minimalist Keypad Grid
            Opacity(
              opacity: isLocked ? 0.4 : 1.0,
              child: IgnorePointer(
                ignoring: isLocked,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor, width: 0.8),
                  ),
                  child: Column(
                    children: [
                      _buildKeypadRow(['1', '2', '3'], isDark, borderColor),
                      Divider(height: 1, color: borderColor, thickness: 0.8),
                      _buildKeypadRow(['4', '5', '6'], isDark, borderColor),
                      Divider(height: 1, color: borderColor, thickness: 0.8),
                      _buildKeypadRow(['7', '8', '9'], isDark, borderColor),
                      Divider(height: 1, color: borderColor, thickness: 0.8),
                      Row(
                        children: [
                          _buildActionButton(
                            icon: Icons.qr_code_scanner_rounded,
                            isDark: isDark,
                            onTap: widget.onScanQrRequested ?? _handleQrScan,
                          ),
                          Container(width: 0.8, height: 48, color: borderColor),
                          _buildNumberKey('0', isDark),
                          Container(width: 0.8, height: 48, color: borderColor),
                          _buildActionButton(
                            icon: Icons.backspace_outlined,
                            isDark: isDark,
                            onTap: _onBackspacePressed,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> digits, bool isDark, Color borderColor) {
    return Row(
      children: [
        _buildNumberKey(digits[0], isDark),
        Container(width: 0.8, height: 48, color: borderColor),
        _buildNumberKey(digits[1], isDark),
        Container(width: 0.8, height: 48, color: borderColor),
        _buildNumberKey(digits[2], isDark),
      ],
    );
  }

  Widget _buildNumberKey(String number, bool isDark) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onDigitPressed(number),
          child: Container(
            height: 48,
            alignment: Alignment.center,
            child: Text(
              number,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required bool isDark,
    required VoidCallback? onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 48,
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 18,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ),
      ),
    );
  }
}
