import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme_tokens.dart';
import '../../core/theme/app_theme_registry.dart';
import '../providers/app_state_provider.dart';
import '../providers/app_theme_style_provider.dart';
import '../providers/app_update_provider.dart';
import '../providers/backup_provider.dart';
import '../widgets/sprout_floating_nav_bar.dart';
import '../widgets/walkthrough/app_walkthrough_overlay.dart';
import 'onboarding/welcome_onboarding_screen.dart';
import 'today/today_screen.dart';
import 'attendance/attendance_screen.dart';
import 'schedule/schedule_screen.dart';
import 'calendar/calendar_screen.dart';
import 'settings/settings_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> with WidgetsBindingObserver {
  bool _hasCheckedOnboarding = false;
  Timer? _updateTimer;
  Timer? _autoBackupTimer;

  final List<Widget> _screens = const [
    TodayScreen(),
    ScheduleScreen(),
    CalendarScreen(),
    AttendanceScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstRun();
      _checkStartupUpdates();
      _checkAutoBackup();
      _startAutoBackupHeartbeat();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _updateTimer?.cancel();
    _autoBackupTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAutoBackup();
      ref.read(attendanceRecordsProvider.notifier).loadFromDb();
      ref.read(notificationPreferencesProvider.notifier).triggerDebouncedResync();
      ref.read(widgetSyncProvider).syncWidgets();
    } else if (state == AppLifecycleState.paused) {
      ref.read(widgetSyncProvider).syncWidgets();
    }
  }

  void _startAutoBackupHeartbeat() {
    _autoBackupTimer?.cancel();
    if (WidgetsBinding.instance.runtimeType.toString() != 'WidgetsFlutterBinding') return;
    _autoBackupTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      _checkAutoBackup();
    });
  }

  void _checkAutoBackup() {
    if (!mounted) return;
    ref.read(backupProvider.notifier).checkAndRunAutoBackup(ref.read(databaseProvider));
  }

  void _checkStartupUpdates() {
    _updateTimer?.cancel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTourActive = ref.watch(activeTourProvider);
    final themeStyle = ref.watch(appThemeStyleProvider);
    final themeDef = AppThemeRegistry.getTheme(themeStyle);
    final tokens = Theme.of(context).extension<AppThemeTokens>();
    final isCute = tokens?.isCute ?? false;

    final screens = _screens;
    final currentIndex = ref.watch(mainShellTabProvider);
    final safeIndex = currentIndex >= screens.length ? 0 : currentIndex;

    return Scaffold(
      body: Stack(
        children: [
          SmoothCrossFadeStack(
            index: safeIndex,
            children: screens,
          ),
          if (isTourActive)
            AppWalkthroughOverlay(
              onTabChangeRequested: (idx) {
                ref.read(mainShellTabProvider.notifier).state = idx;
              },
              onComplete: () {
                ref.read(activeTourProvider.notifier).state = false;
                ref.read(hasCompletedOnboardingProvider.notifier).setCompleted(true);
                ref.read(mainShellTabProvider.notifier).state = 0;
              },
              onDismiss: () {
                ref.read(activeTourProvider.notifier).state = false;
                ref.read(hasCompletedOnboardingProvider.notifier).setCompleted(true);
                ref.read(mainShellTabProvider.notifier).state = 0;
              },
            ),
        ],
      ),
      bottomNavigationBar: isCute
          ? Container(
              color: tokens?.scaffoldBg ?? Theme.of(context).scaffoldBackgroundColor,
              child: SproutFloatingNavBar(
                currentIndex: safeIndex,
                onTap: (idx) {
                  ref.read(mainShellTabProvider.notifier).state = idx;
                },
                items: themeDef.navItems,
              ),
            )
          : Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
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
                  child: _buildNavRow(themeDef.navItems, isCute, isDark, safeIndex),
                ),
              ),
            ),
    );
  }

  Widget _buildNavRow(List<ThemeNavItem> navItems, bool isCute, bool isDark, int selectedIndex) {
    return Row(
      children: List.generate(navItems.length, (index) {
        final item = navItems[index];
        final isSelected = selectedIndex == index;
        final activeColor = isCute
            ? Theme.of(context).colorScheme.primary
            : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight);
        final inactiveColor = isCute
            ? (isDark ? const Color(0xFF6E8B79) : const Color(0xFF9EAA9F))
            : (isDark ? AppColors.textSecondaryDark : const Color(0xFF94A3B8));

        return Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              ref.read(mainShellTabProvider.notifier).state = index;
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? item.activeIcon : item.inactiveIcon,
                  size: isCute ? 24 : 22,
                  color: isSelected ? activeColor : inactiveColor,
                ),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: isCute ? 0.1 : -0.2,
                    color: isSelected ? activeColor : inactiveColor,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

/// A true dual-layer crossfade stack that smoothly transitions between screens
/// without flashing to blank scaffold background, while maintaining widget state.
class SmoothCrossFadeStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  final Duration duration;

  const SmoothCrossFadeStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 240),
  });

  @override
  State<SmoothCrossFadeStack> createState() => _SmoothCrossFadeStackState();
}

class _SmoothCrossFadeStackState extends State<SmoothCrossFadeStack> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late int _currentIndex;
  int? _previousIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.index;
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _controller.value = 1.0;
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _previousIndex = null;
        });
      }
    });
  }

  @override
  void didUpdateWidget(SmoothCrossFadeStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != _currentIndex) {
      _previousIndex = _currentIndex;
      _currentIndex = widget.index;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final t = _animation.value;
        final isTransitioning = _controller.isAnimating || _previousIndex != null;

        return Stack(
          fit: StackFit.expand,
          children: List.generate(widget.children.length, (i) {
            final isIncoming = i == _currentIndex;
            final isOutgoing = i == _previousIndex;

            if (isIncoming) {
              final opacity = isTransitioning ? t.clamp(0.0, 1.0) : 1.0;
              final translateY = isTransitioning ? (4.0 * (1.0 - t)) : 0.0;
              return Opacity(
                opacity: opacity,
                child: Transform.translate(
                  offset: Offset(0, translateY),
                  child: widget.children[i],
                ),
              );
            } else if (isOutgoing) {
              final opacity = (1.0 - t).clamp(0.0, 1.0);
              return IgnorePointer(
                child: Opacity(
                  opacity: opacity,
                  child: widget.children[i],
                ),
              );
            } else {
              return Offstage(
                offstage: true,
                child: widget.children[i],
              );
            }
          }),
        );
      },
    );
  }
}

/// Backward compatibility alias
typedef FadeIndexedStack = SmoothCrossFadeStack;
