import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../providers/app_state_provider.dart';
import '../providers/app_update_provider.dart';
import '../widgets/walkthrough/app_walkthrough_overlay.dart';
import 'onboarding/welcome_onboarding_screen.dart';
import 'today/today_screen.dart';
import 'attendance/attendance_screen.dart';
import 'schedule/schedule_screen.dart';
import 'calendar/calendar_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;
  bool _hasCheckedOnboarding = false;
  Timer? _updateTimer;

  final List<Widget> _screens = const [
    TodayScreen(),
    AttendanceScreen(),
    ScheduleScreen(),
    CalendarScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstRun();
      _checkStartupUpdates();
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _checkStartupUpdates() {
    _updateTimer?.cancel();
    _updateTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        ref.read(appUpdateProvider.notifier).checkForUpdates(
              context: context,
              manualTrigger: false,
            );
      }
    });
  }

  void _checkFirstRun() {
    if (_hasCheckedOnboarding || !mounted) return;
    _hasCheckedOnboarding = true;

    final hasCompleted = ref.read(hasCompletedOnboardingProvider);
    if (!hasCompleted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeOnboardingScreen()),
      );
    }
  }

  static const List<_NavItemData> _navItems = [
    _NavItemData(
      label: 'Today',
      icon: Icons.space_dashboard_outlined,
      activeIcon: Icons.space_dashboard_rounded,
    ),
    _NavItemData(
      label: 'Analytics',
      icon: Icons.insights_outlined,
      activeIcon: Icons.insights_rounded,
    ),
    _NavItemData(
      label: 'Timetable',
      icon: Icons.calendar_view_week_outlined,
      activeIcon: Icons.calendar_view_week_rounded,
    ),
    _NavItemData(
      label: 'Calendar',
      icon: Icons.calendar_month_outlined,
      activeIcon: Icons.calendar_month_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTourActive = ref.watch(activeTourProvider);

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          if (isTourActive)
            AppWalkthroughOverlay(
              onTabChangeRequested: (idx) {
                if (mounted && _currentIndex != idx) {
                  setState(() => _currentIndex = idx);
                }
              },
              onComplete: () {
                ref.read(activeTourProvider.notifier).state = false;
                ref.read(hasCompletedOnboardingProvider.notifier).setCompleted(true);
                if (mounted) setState(() => _currentIndex = 0);
              },
              onDismiss: () {
                ref.read(activeTourProvider.notifier).state = false;
                ref.read(hasCompletedOnboardingProvider.notifier).setCompleted(true);
                if (mounted) setState(() => _currentIndex = 0);
              },
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgDark : AppColors.bgLight,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 58,
            child: Row(
              children: List.generate(_navItems.length, (index) {
                final item = _navItems[index];
                final isSelected = _currentIndex == index;

                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (_currentIndex != index) {
                        setState(() => _currentIndex = index);
                      }
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isSelected ? item.activeIcon : item.icon,
                          size: 22,
                          color: isSelected
                              ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                              : (isDark ? AppColors.textSecondaryDark : const Color(0xFF94A3B8)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            letterSpacing: -0.2,
                            color: isSelected
                                ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                                : (isDark ? AppColors.textSecondaryDark : const Color(0xFF94A3B8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _NavItemData({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}
