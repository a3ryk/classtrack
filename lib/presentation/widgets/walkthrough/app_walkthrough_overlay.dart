import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_theme_tokens.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/profile/profile_screen.dart';

class WalkthroughStepData {
  final String title;
  final String description;
  final IconData icon;
  final int targetTabIndex;
  final String badgeText;

  const WalkthroughStepData({
    required this.title,
    required this.description,
    required this.icon,
    required this.targetTabIndex,
    required this.badgeText,
  });
}

class AppWalkthroughOverlay extends StatefulWidget {
  final ValueChanged<int> onTabChangeRequested;
  final VoidCallback onComplete;
  final VoidCallback onDismiss;

  const AppWalkthroughOverlay({
    super.key,
    required this.onTabChangeRequested,
    required this.onComplete,
    required this.onDismiss,
  });

  @override
  State<AppWalkthroughOverlay> createState() => _AppWalkthroughOverlayState();
}

class _AppWalkthroughOverlayState extends State<AppWalkthroughOverlay> {
  int _currentStepIndex = 0;

  List<WalkthroughStepData> _getSteps(bool isCute) {
    return [
      const WalkthroughStepData(
        title: '1. Today & Live Attendance',
        description: 'See live countdowns ("Starts in 10m") and in-progress status. Mark Present, Absent, or Cancelled in 1 tap with instant undo protection.',
        icon: Icons.space_dashboard_rounded,
        targetTabIndex: 0,
        badgeText: 'LIVE TODAY SCREEN',
      ),
      WalkthroughStepData(
        title: '2. Weekly Timetable Grid',
        description: 'View your full weekly Sunday-to-Saturday schedule. Filter by day, inspect room and faculty details, and manage course categories.',
        icon: Icons.grid_view_rounded,
        targetTabIndex: isCute ? 1 : 2,
        badgeText: 'WEEKLY TIMETABLE',
      ),
      WalkthroughStepData(
        title: '3. Supercharged Batch Setup',
        description: 'Tap the repeat icon in Timetable to add lectures, practical labs, and tutorials across multiple days (e.g. Mon, Wed, Fri) in one single click!',
        icon: Icons.event_repeat_rounded,
        targetTabIndex: isCute ? 1 : 2,
        badgeText: 'BATCH SCHEDULING',
      ),
      WalkthroughStepData(
        title: '4. Calendar & Date Overrides',
        description: 'Need to reschedule a lab or cancel a class for one day only? Tap any session in Calendar to reschedule, remove, or add extra makeup classes.',
        icon: Icons.edit_calendar_rounded,
        targetTabIndex: isCute ? 2 : 3,
        badgeText: 'CALENDAR & EXCEPTIONS',
      ),
      WalkthroughStepData(
        title: '5. Subject Analytics & Margins',
        description: 'Track attendance for every Major, Minor, and Lab. See the exact number of classes you can safely miss (+N margin) or must attend to stay above target.',
        icon: Icons.insights_rounded,
        targetTabIndex: isCute ? 3 : 1,
        badgeText: 'MARGIN ANALYTICS',
      ),
      WalkthroughStepData(
        title: '6. What-If Leave Simulator',
        description: 'Planning a trip, college fest, or medical leave? Use the What-If Simulator on Analytics to test attendance impacts before taking leaves!',
        icon: Icons.calculate_rounded,
        targetTabIndex: isCute ? 3 : 1,
        badgeText: 'WHAT-IF SIMULATOR',
      ),
      WalkthroughStepData(
        title: isCute ? '7. Settings, Mascot & Profile' : '7. Profile, Backups & Exports',
        description: isCute
            ? 'Classtrack is 100% offline. Customize your academic mascot companion, generate multi-date attendance registers, and configure backups.'
            : 'Attendly is 100% offline. Generate multi-date PDF/Excel attendance registers, configure your student profile, and create encrypted .ctbackup snapshots.',
        icon: isCute ? Icons.spa_rounded : Icons.security_rounded,
        targetTabIndex: isCute ? 4 : 0,
        badgeText: isCute ? 'SETTINGS & MASCOT' : 'OFFLINE & PRIVACY',
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    // Navigate to initial step tab immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final tokens = Theme.of(context).extension<AppThemeTokens>();
        final isCute = tokens?.isCute ?? false;
        final steps = _getSteps(isCute);
        widget.onTabChangeRequested(steps[0].targetTabIndex);
      }
    });
  }

  void _goToStep(int index, List<WalkthroughStepData> steps) {
    if (index >= 0 && index < steps.length) {
      setState(() => _currentStepIndex = index);
      widget.onTabChangeRequested(steps[index].targetTabIndex);
    } else if (index >= steps.length) {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = Theme.of(context).extension<AppThemeTokens>();
    final isCute = tokens?.isCute ?? false;
    final steps = _getSteps(isCute);
    final safeIndex = _currentStepIndex >= steps.length ? steps.length - 1 : _currentStepIndex;
    final step = steps[safeIndex];
    final bool isLast = safeIndex == steps.length - 1;

    final Color badgeBg = isCute
        ? (isDark ? const Color(0xFF163424) : const Color(0xFFEAF8E7))
        : (isDark ? const Color(0xFF1E1B4B) : const Color(0xFFEEF2FF));
    final Color badgeBorder = isCute
        ? (isDark ? const Color(0xFF2E593E) : const Color(0xFFD7F0D6))
        : (isDark ? const Color(0xFF4F46E5).withValues(alpha: 0.4) : const Color(0xFFC7D2FE));
    final Color badgeColor = isCute
        ? (isDark ? const Color(0xFF8BC34A) : const Color(0xFF2E7D32))
        : AppColors.accentIndigoLight;

    return Stack(
      children: [
        // Semi-transparent backdrop
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              if (isLast) {
                widget.onComplete();
              } else {
                _goToStep(safeIndex + 1, steps);
              }
            },
            child: Container(
              color: Colors.black.withValues(alpha: isDark ? 0.65 : 0.55),
            ),
          ),
        ),

        // Top-right Skip button
        SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextButton.icon(
                onPressed: widget.onDismiss,
                icon: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                label: Text(
                  'Skip Tour',
                  style: isCute
                      ? GoogleFonts.quicksand(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)
                      : const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.45),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
          ),
        ),

        // Floating Tour Card (Positioned at lower center)
        SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, isCute ? 96 : 75),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(animation),
                    child: child,
                  ),
                ),
                child: Container(
                  key: ValueKey(safeIndex),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isCute
                        ? (isDark ? const Color(0xFF1B3626) : Colors.white)
                        : (isDark ? AppColors.cardDark : Colors.white),
                    borderRadius: BorderRadius.circular(isCute ? 24 : 16),
                    border: Border.all(
                      color: isCute
                          ? (isDark ? const Color(0xFF274C37) : const Color(0xFFE4ECE0))
                          : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                      width: isCute ? 1.2 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.35 : (isCute ? 0.08 : 0.2)),
                        blurRadius: isCute ? 24 : 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge & Step Counter
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(isCute ? 10 : 6),
                              border: Border.all(color: badgeBorder, width: 0.8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(step.icon, size: 12.5, color: badgeColor),
                                const SizedBox(width: 5),
                                Text(
                                  step.badgeText,
                                  style: isCute
                                      ? GoogleFonts.quicksand(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: badgeColor,
                                          letterSpacing: 0.6,
                                        )
                                      : TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: badgeColor,
                                          letterSpacing: 0.5,
                                        ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isCute) ...[
                                Image.asset(
                                  'assets/themes/sprout/mascots/sprout_home_wave.png',
                                  width: 22,
                                  height: 22,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                'Step ${safeIndex + 1} of ${steps.length}',
                                style: isCute
                                    ? GoogleFonts.quicksand(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? const Color(0xFF7A9D87) : const Color(0xFF6B8A75),
                                      )
                                    : TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                      ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Title
                      Text(
                        step.title,
                        style: isCute
                            ? GoogleFonts.quicksand(
                                fontSize: 17.5,
                                fontWeight: FontWeight.w800,
                                color: isDark ? const Color(0xFFE8F4EB) : const Color(0xFF192E21),
                                letterSpacing: -0.3,
                              )
                            : TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                letterSpacing: -0.3,
                              ),
                      ),
                      const SizedBox(height: 6),

                      // Description
                      Text(
                        step.description,
                        style: isCute
                            ? GoogleFonts.quicksand(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFF98B5A3) : const Color(0xFF526B5C),
                                height: 1.42,
                              )
                            : TextStyle(
                                fontSize: 13,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                height: 1.4,
                              ),
                      ),

                      // Quick Action Buttons on Final Step (Profile & Settings)
                      if (isLast) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () {
                                widget.onDismiss();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (ctx) => const ProfileScreen()),
                                );
                              },
                              icon: const Icon(Icons.person_outline_rounded, size: 15),
                              label: Text(
                                'Open Profile',
                                style: isCute
                                    ? GoogleFonts.quicksand(fontSize: 12, fontWeight: FontWeight.w700)
                                    : const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: isCute
                                    ? (isDark ? const Color(0xFF8BC34A) : const Color(0xFF2E7D32))
                                    : null,
                                side: BorderSide(
                                  color: isCute
                                      ? (isDark ? const Color(0xFF2E593E) : const Color(0xFFD7F0D6))
                                      : (isDark ? AppColors.borderDark : const Color(0xFFCBD5E1)),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isCute ? 12 : 8)),
                              ),
                            ),
                            if (!isCute)
                              OutlinedButton.icon(
                                onPressed: () {
                                  widget.onDismiss();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (ctx) => const SettingsScreen()),
                                  );
                                },
                                icon: const Icon(Icons.settings_outlined, size: 15),
                                label: const Text('Open Settings', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 18),

                      // Progress Dots & Nav Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Dots
                          Row(
                            children: List.generate(steps.length, (idx) {
                              final active = idx == safeIndex;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin: const EdgeInsets.only(right: 5),
                                width: active ? 18 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: active
                                      ? (isCute
                                          ? (isDark ? const Color(0xFF8BC34A) : const Color(0xFF2E7D32))
                                          : AppColors.accentIndigoLight)
                                      : (isCute
                                          ? (isDark ? const Color(0xFF274C37) : const Color(0xFFDDE7DA))
                                          : (isDark ? const Color(0xFF3F3F46) : const Color(0xFFCBD5E1))),
                                  borderRadius: BorderRadius.circular(isCute ? 4 : 3),
                                ),
                              );
                            }),
                          ),

                          // Back & Next Action Buttons
                          Row(
                            children: [
                              if (safeIndex > 0)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: OutlinedButton(
                                    onPressed: () => _goToStep(safeIndex - 1, steps),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: isCute
                                          ? (isDark ? const Color(0xFFE8F4EB) : const Color(0xFF192E21))
                                          : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                                      side: BorderSide(
                                        color: isCute
                                            ? (isDark ? const Color(0xFF274C37) : const Color(0xFFDDE7DA))
                                            : (isDark ? AppColors.borderDark : const Color(0xFFCBD5E1)),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isCute ? 14 : 8)),
                                    ),
                                    child: Text(
                                      'Back',
                                      style: isCute
                                          ? GoogleFonts.quicksand(fontSize: 12, fontWeight: FontWeight.w700)
                                          : const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                              ElevatedButton(
                                onPressed: () => _goToStep(safeIndex + 1, steps),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isCute
                                      ? (isDark ? const Color(0xFF8BC34A) : const Color(0xFF2E7D32))
                                      : AppColors.accentIndigoLight,
                                  foregroundColor: isCute
                                      ? (isDark ? const Color(0xFF0F2417) : Colors.white)
                                      : Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isCute ? 14 : 8)),
                                  elevation: 0,
                                ),
                                child: Text(
                                  isLast ? 'Get Started' : 'Next',
                                  style: isCute
                                      ? GoogleFonts.quicksand(fontSize: 12.5, fontWeight: FontWeight.w800)
                                      : const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
