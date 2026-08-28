import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
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

  static const List<WalkthroughStepData> _steps = [
    WalkthroughStepData(
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
      targetTabIndex: 2,
      badgeText: 'WEEKLY TIMETABLE',
    ),
    WalkthroughStepData(
      title: '3. Supercharged Batch Setup',
      description: 'Tap the repeat icon (🔁) in Timetable to add lectures, practical labs, and tutorials across multiple days (e.g. Mon, Wed, Fri) in one single click!',
      icon: Icons.event_repeat_rounded,
      targetTabIndex: 2,
      badgeText: 'BATCH SCHEDULING',
    ),
    WalkthroughStepData(
      title: '4. Calendar & Date Overrides',
      description: 'Need to reschedule a lab or cancel a class for one day only? Tap any session in Calendar to reschedule, remove, or add extra makeup classes.',
      icon: Icons.edit_calendar_rounded,
      targetTabIndex: 3,
      badgeText: 'CALENDAR & EXCEPTIONS',
    ),
    WalkthroughStepData(
      title: '5. Subject Analytics & Margins',
      description: 'Track attendance for every Major, Minor, and Lab. See the exact number of classes you can safely miss (+N margin) or must attend to stay above target.',
      icon: Icons.insights_rounded,
      targetTabIndex: 1,
      badgeText: 'MARGIN ANALYTICS',
    ),
    WalkthroughStepData(
      title: '6. What-If Leave Simulator',
      description: 'Planning a trip, college fest, or medical leave? Use the What-If Simulator on Analytics to test attendance impacts before taking leaves!',
      icon: Icons.calculate_rounded,
      targetTabIndex: 1,
      badgeText: 'WHAT-IF SIMULATOR',
    ),
    WalkthroughStepData(
      title: '7. Profile, Backups & Exports',
      description: 'ClassTrack is 100% offline. Generate multi-date PDF/Excel attendance registers, configure your student profile, and create encrypted .ctbackup snapshots.',
      icon: Icons.security_rounded,
      targetTabIndex: 0,
      badgeText: 'OFFLINE & PRIVACY',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Navigate to initial step tab immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onTabChangeRequested(_steps[0].targetTabIndex);
      }
    });
  }

  void _goToStep(int index) {
    if (index >= 0 && index < _steps.length) {
      setState(() => _currentStepIndex = index);
      widget.onTabChangeRequested(_steps[index].targetTabIndex);
    } else if (index >= _steps.length) {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final step = _steps[_currentStepIndex];
    final bool isLast = _currentStepIndex == _steps.length - 1;

    return Stack(
      children: [
        // Semi-transparent backdrop
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              if (isLast) {
                widget.onComplete();
              } else {
                _goToStep(_currentStepIndex + 1);
              }
            },
            child: Container(
              color: Colors.black.withValues(alpha: 0.6),
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
                label: const Text(
                  'Skip Tour',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.4),
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
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 75),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(animation),
                    child: child,
                  ),
                ),
                child: Container(
                  key: ValueKey(_currentStepIndex),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E1B4B) : const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isDark ? const Color(0xFF4F46E5).withValues(alpha: 0.4) : const Color(0xFFC7D2FE),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(step.icon, size: 12, color: AppColors.accentIndigoLight),
                                const SizedBox(width: 4),
                                Text(
                                  step.badgeText,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.accentIndigoLight,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Step ${_currentStepIndex + 1} of ${_steps.length}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Title
                      Text(
                        step.title,
                        style: TextStyle(
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
                        style: TextStyle(
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
                              label: const Text('Open Profile', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
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
                            children: List.generate(_steps.length, (idx) {
                              final active = idx == _currentStepIndex;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin: const EdgeInsets.only(right: 5),
                                width: active ? 18 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: active
                                      ? AppColors.accentIndigoLight
                                      : (isDark ? const Color(0xFF3F3F46) : const Color(0xFFCBD5E1)),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              );
                            }),
                          ),

                          // Back & Next Action Buttons
                          Row(
                            children: [
                              if (_currentStepIndex > 0)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: OutlinedButton(
                                    onPressed: () => _goToStep(_currentStepIndex - 1),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                      side: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFCBD5E1)),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: const Text('Back', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  ),
                                ),
                              ElevatedButton(
                                onPressed: () => _goToStep(_currentStepIndex + 1),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accentIndigoLight,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  elevation: 0,
                                ),
                                child: Text(
                                  isLast ? 'Get Started' : 'Next',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
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
