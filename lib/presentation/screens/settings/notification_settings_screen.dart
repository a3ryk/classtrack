import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/ui/app_toast.dart';
import '../../../domain/entities/notification_preferences_entity.dart';
import '../../providers/app_state_provider.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> {
  Future<void> _sendTestNotification(NotificationPreferencesEntity prefs) async {
    final hasPerm = await NotificationService.checkAndRequestNotificationPermission();
    if (!hasPerm) {
      if (mounted) {
        AppToast.error(context, 'Notification permission is required to display notifications.');
      }
      return;
    }

    final now = DateTime.now();
    final testDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final payload = jsonEncode({
      'sessionId': 'test_session_${now.millisecondsSinceEpoch}',
      'slotId': 'test_slot',
      'subjectId': 'test_subject',
      'sessionDate': testDate,
      'subjectName': 'Sample Lecture',
    });

    await NotificationService.instance.showImmediateClassNotification(
      id: 9999,
      title: 'Sample Lecture • Attendance Reminder',
      body: 'Class ended • Mark your attendance directly below:',
      payload: payload,
      withQuickActions: prefs.enableQuickActions,
      sound: prefs.sound,
      vibrate: prefs.vibrate,
    );

    if (mounted) {
      AppToast.success(context, 'Test notification sent! Check your notification shade.');
    }
  }

  void _openBatteryInfoSheet({
    required BuildContext context,
    required bool isDark,
  }) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      transitionAnimationController: AnimationController(
        vsync: Navigator.of(context),
        duration: const Duration(milliseconds: 340),
        reverseDuration: const Duration(milliseconds: 240),
      ),
      builder: (sheetContext) => _BatteryInfoSheet(isDark: isDark),
    );
  }

  void _openTimingSheet({
    required BuildContext context,
    required bool isStart,
    required int currentMinutes,
    required bool isDark,
    required ValueChanged<int> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      transitionAnimationController: AnimationController(
        vsync: Navigator.of(context),
        duration: const Duration(milliseconds: 340),
        reverseDuration: const Duration(milliseconds: 240),
      ),
      builder: (sheetContext) => _ReminderTimingSheet(
        isStart: isStart,
        currentMinutes: currentMinutes,
        isDark: isDark,
        onSelected: onSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prefs = ref.watch(notificationPreferencesProvider);
    final notifier = ref.read(notificationPreferencesProvider.notifier);

    final Color groupBg = isDark ? AppColors.cardDark : Colors.white;
    final Color groupBorder = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);
    final Color dividerColor = isDark ? AppColors.borderDark.withValues(alpha: 0.6) : const Color(0xFFF1F5F9);

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF8FAFC),
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 100,
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(8),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 14),
              Icon(Icons.chevron_left_rounded, size: 22, color: AppColors.accentBlue),
              Text(
                'Back',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentBlue,
                ),
              ),
            ],
          ),
        ),
        title: Text(
          'Notifications',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.info_outline_rounded,
              size: 22,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
            tooltip: 'Battery Info',
            onPressed: () => _openBatteryInfoSheet(
              context: context,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // GROUP 1: CLASS REMINDERS
          _buildSectionHeader('Class Reminders', isDark),
          RepaintBoundary(
            child: Container(
              decoration: BoxDecoration(
                color: groupBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: groupBorder, width: 0.8),
              ),
              child: Column(
                children: [
                  _buildSwitchRow(
                    title: 'Class Reminders',
                    value: prefs.enabled,
                    isDark: isDark,
                    onChanged: (val) async {
                      if (val) {
                        final hasPerm = await NotificationService.checkAndRequestNotificationPermission();
                        if (!hasPerm) {
                          if (context.mounted) {
                            AppToast.error(context, 'Notification permission is required to receive class reminders.');
                          }
                          return;
                        }
                      }
                      notifier.updatePreferences(prefs.copyWith(enabled: val));
                    },
                  ),
                  if (prefs.enabled) ...[
                    Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                    _buildSwitchRow(
                       title: 'Remind Before Class',
                      value: prefs.enableClassStart,
                      isDark: isDark,
                      onChanged: (val) async {
                        if (val) {
                          final hasPerm = await NotificationService.checkAndRequestNotificationPermission();
                          if (!hasPerm) {
                            if (context.mounted) {
                              AppToast.error(context, 'Notification permission is required to receive class reminders.');
                            }
                            return;
                          }
                        }
                        notifier.updatePreferences(prefs.copyWith(enableClassStart: val));
                      },
                    ),
                    if (prefs.enableClassStart) ...[
                      Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                      _buildValueRow(
                        title: 'Reminder Timing',
                        value: prefs.startLeadMinutes == 0
                            ? 'At start'
                            : '${prefs.startLeadMinutes}m before',
                        isDark: isDark,
                        onTap: () => _openTimingSheet(
                          context: context,
                          isStart: true,
                          currentMinutes: prefs.startLeadMinutes,
                          isDark: isDark,
                          onSelected: (mins) {
                            notifier.updatePreferences(prefs.copyWith(startLeadMinutes: mins));
                          },
                        ),
                      ),
                    ],
                    Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                    _buildSwitchRow(
                      title: 'Remind When Class Ends',
                      value: prefs.enableClassEnd,
                      isDark: isDark,
                      onChanged: (val) async {
                        if (val) {
                          final hasPerm = await NotificationService.checkAndRequestNotificationPermission();
                          if (!hasPerm) {
                            if (context.mounted) {
                              AppToast.error(context, 'Notification permission is required to receive class reminders.');
                            }
                            return;
                          }
                        }
                        notifier.updatePreferences(prefs.copyWith(enableClassEnd: val));
                      },
                    ),
                    if (prefs.enableClassEnd) ...[
                      Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                      _buildValueRow(
                        title: 'End Reminder Timing',
                        value: prefs.endLeadMinutes == 0
                            ? 'At class end'
                            : '${prefs.endLeadMinutes}m before end',
                        isDark: isDark,
                        onTap: () => _openTimingSheet(
                          context: context,
                          isStart: false,
                          currentMinutes: prefs.endLeadMinutes,
                          isDark: isDark,
                          onSelected: (mins) {
                            notifier.updatePreferences(prefs.copyWith(endLeadMinutes: mins));
                          },
                        ),
                      ),
                    ],
                    Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                    _buildSwitchRow(
                      title: 'Quick Attendance Buttons',
                      value: prefs.enableQuickActions,
                      isDark: isDark,
                      onChanged: (val) {
                        notifier.updatePreferences(prefs.copyWith(enableQuickActions: val));
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // GROUP 2: ALERTS & TESTING
          _buildSectionHeader('Alerts & Testing', isDark),
          RepaintBoundary(
            child: Container(
              decoration: BoxDecoration(
                color: groupBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: groupBorder, width: 0.8),
              ),
              child: Column(
                children: [
                  _buildSwitchRow(
                    title: 'Vibration',
                    value: prefs.vibrate,
                    isDark: isDark,
                    onChanged: (val) {
                      notifier.updatePreferences(prefs.copyWith(vibrate: val));
                    },
                  ),
                  Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                  _buildSwitchRow(
                    title: 'Sound',
                    value: prefs.sound,
                    isDark: isDark,
                    onChanged: (val) {
                      notifier.updatePreferences(prefs.copyWith(sound: val));
                    },
                  ),
                  Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                  InkWell(
                    onTap: () => _sendTestNotification(prefs),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                      child: Row(
                        children: [
                          const Icon(Icons.bolt_rounded, size: 20, color: AppColors.accentBlue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Send Test Notification',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildSwitchRow({
    required String title,
    required bool value,
    required bool isDark,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            activeThumbColor: AppColors.presentGreen,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildValueRow({
    required String title,
    required String value,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentBlue,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: AppColors.accentBlue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tactile modal bottom sheet for timing selection (Matching TargetPercentageSheet)
class _ReminderTimingSheet extends StatefulWidget {
  final bool isStart;
  final int currentMinutes;
  final bool isDark;
  final ValueChanged<int> onSelected;

  const _ReminderTimingSheet({
    required this.isStart,
    required this.currentMinutes,
    required this.isDark,
    required this.onSelected,
  });

  @override
  State<_ReminderTimingSheet> createState() => _ReminderTimingSheetState();
}

class _ReminderTimingSheetState extends State<_ReminderTimingSheet> {
  late double _selectedMinutes;

  List<int> get _presets => widget.isStart ? const [0, 5, 10, 15, 30] : const [0, 5, 10, 15];

  @override
  void initState() {
    super.initState();
    _selectedMinutes = widget.currentMinutes.clamp(0, 60).toDouble();
  }

  void _updateMinutes(double mins) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedMinutes = mins.clamp(0.0, 60.0);
    });
  }

  void _save() {
    widget.onSelected(_selectedMinutes.round());
    Navigator.pop(context);
  }

  String _formatHero(int mins) {
    if (mins == 0) {
      return widget.isStart ? 'At class start' : 'At class end';
    }
    return '$mins min before';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final int currentInt = _selectedMinutes.round();

    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight, width: 0.8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.isStart ? 'Start Reminder' : 'End Reminder',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Big Hero Text Display
          Center(
            child: Text(
              _formatHero(currentInt),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Quick Preset Pills
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _presets.map((preset) {
              final isSel = currentInt == preset;
              final label = preset == 0
                  ? (widget.isStart ? 'At start' : 'At end')
                  : '${preset}m';

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  onTap: () => _updateMinutes(preset.toDouble()),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSel
                          ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                          : (isDark ? AppColors.pillDark : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                        color: isSel
                            ? (isDark ? AppColors.bgDark : AppColors.surfaceLight)
                            : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Slider with Steppers Row
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_rounded, size: 20),
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                onPressed: currentInt > 0 ? () => _updateMinutes(_selectedMinutes - 1) : null,
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                    activeTrackColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    inactiveTrackColor: isDark ? AppColors.pillDark : const Color(0xFFE2E8F0),
                    thumbColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                  ),
                  child: Slider(
                    value: _selectedMinutes,
                    min: 0.0,
                    max: 60.0,
                    divisions: 60,
                    onChanged: _updateMinutes,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_rounded, size: 20),
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                onPressed: currentInt < 60 ? () => _updateMinutes(_selectedMinutes + 1) : null,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Save Action
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                foregroundColor: isDark ? AppColors.bgDark : AppColors.surfaceLight,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Save',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tactile bottom sheet explaining battery efficiency and zero-drain architecture
class _BatteryInfoSheet extends StatelessWidget {
  final bool isDark;

  const _BatteryInfoSheet({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight, width: 0.8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Did You Know?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Clean subtle pill badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.bolt_rounded,
                  size: 14,
                  color: AppColors.accentBlue,
                ),
                const SizedBox(width: 4),
                Text(
                  '100% Battery Friendly',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Class reminders consume 0% extra battery throughout your day.',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 20),

          // 3 Feature points
          _buildFeaturePoint(
            icon: Icons.alarm_on_rounded,
            iconColor: AppColors.accentBlue,
            iconBg: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            title: 'Exact Scheduled Alarms',
            description: 'The operating system wakes ClassTrack only at your class time to post the alert, then goes right back to sleep.',
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          _buildFeaturePoint(
            icon: Icons.power_off_rounded,
            iconColor: AppColors.accentBlue,
            iconBg: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            title: 'Never Runs in the Background',
            description: 'No background services, persistent workers, or location checks. When you close the app, it stays completely inactive.',
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          _buildFeaturePoint(
            icon: Icons.battery_saver_rounded,
            iconColor: AppColors.accentBlue,
            iconBg: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            title: 'Zero Idle CPU Usage',
            description: 'You get 100% on-time attendance reminders without any noticeable impact on battery life.',
            isDark: isDark,
          ),
          const SizedBox(height: 24),

          // "Got It" Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                foregroundColor: isDark ? AppColors.bgDark : AppColors.surfaceLight,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Got It',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturePoint({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String description,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 0.8,
            ),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w400,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
