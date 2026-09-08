import 'dart:convert';
import 'package:flutter/material.dart';
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
  static const List<int> _startLeadOptions = [0, 5, 10, 15, 30];
  static const List<int> _endLeadOptions = [0, 5, 10];

  Future<void> _sendTestNotification(NotificationPreferencesEntity prefs) async {
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
          'Notifications & Reminders',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. MASTER TOGGLE
          _buildSectionHeader('General', isDark),
          RepaintBoundary(
            child: Container(
              decoration: BoxDecoration(
                color: groupBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: groupBorder, width: 0.8),
              ),
              child: _buildSwitchTile(
                title: 'Enable Reminders',
                subtitle: 'Automated class alerts and notification panel attendance',
                value: prefs.enabled,
                isDark: isDark,
                onChanged: (val) {
                  notifier.updatePreferences(prefs.copyWith(enabled: val));
                },
              ),
            ),
          ),

          if (prefs.enabled) ...[
            const SizedBox(height: 20),

            // 2. CLASS START REMINDERS
            _buildSectionHeader('Class Start Reminders', isDark),
            RepaintBoundary(
              child: Container(
                decoration: BoxDecoration(
                  color: groupBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: groupBorder, width: 0.8),
                ),
                child: Column(
                  children: [
                    _buildSwitchTile(
                      title: 'Remind Before Class Starts',
                      subtitle: 'Alert with room number and subject details',
                      value: prefs.enableClassStart,
                      isDark: isDark,
                      onChanged: (val) {
                        notifier.updatePreferences(prefs.copyWith(enableClassStart: val));
                      },
                    ),
                    if (prefs.enableClassStart) ...[
                      Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reminder Lead Time',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _startLeadOptions.map((minutes) {
                                final isSelected = prefs.startLeadMinutes == minutes;
                                final label = minutes == 0 ? 'At start' : '${minutes}m before';
                                return _buildChoiceChip(
                                  label: label,
                                  isSelected: isSelected,
                                  isDark: isDark,
                                  onTap: () {
                                    notifier.updatePreferences(prefs.copyWith(startLeadMinutes: minutes));
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 3. CLASS END & QUICK ATTENDANCE
            _buildSectionHeader('Class End & Quick Attendance', isDark),
            RepaintBoundary(
              child: Container(
                decoration: BoxDecoration(
                  color: groupBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: groupBorder, width: 0.8),
                ),
                child: Column(
                  children: [
                    _buildSwitchTile(
                      title: 'Remind When Class Ends',
                      subtitle: 'Prompts you to mark attendance promptly',
                      value: prefs.enableClassEnd,
                      isDark: isDark,
                      onChanged: (val) {
                        notifier.updatePreferences(prefs.copyWith(enableClassEnd: val));
                      },
                    ),
                    if (prefs.enableClassEnd) ...[
                      Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'End Reminder Timing',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _endLeadOptions.map((minutes) {
                                final isSelected = prefs.endLeadMinutes == minutes;
                                final label = minutes == 0 ? 'At class end' : '${minutes}m before end';
                                return _buildChoiceChip(
                                  label: label,
                                  isSelected: isSelected,
                                  isDark: isDark,
                                  onTap: () {
                                    notifier.updatePreferences(prefs.copyWith(endLeadMinutes: minutes));
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                    Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                    _buildSwitchTile(
                      title: 'Quick Attendance Actions',
                      subtitle: 'Present, Absent, and Cancelled buttons directly on the notification panel',
                      value: prefs.enableQuickActions,
                      isDark: isDark,
                      onChanged: (val) {
                        notifier.updatePreferences(prefs.copyWith(enableQuickActions: val));
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 4. SOUND & VIBRATION
            _buildSectionHeader('Alert Preferences', isDark),
            RepaintBoundary(
              child: Container(
                decoration: BoxDecoration(
                  color: groupBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: groupBorder, width: 0.8),
                ),
                child: Column(
                  children: [
                    _buildSwitchTile(
                      title: 'Vibration',
                      subtitle: 'Vibrate on class alerts',
                      value: prefs.vibrate,
                      isDark: isDark,
                      onChanged: (val) {
                        notifier.updatePreferences(prefs.copyWith(vibrate: val));
                      },
                    ),
                    Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                    _buildSwitchTile(
                      title: 'Sound',
                      subtitle: 'Play default notification ringtone',
                      value: prefs.sound,
                      isDark: isDark,
                      onChanged: (val) {
                        notifier.updatePreferences(prefs.copyWith(sound: val));
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 5. TEST NOTIFICATION BUTTON
            RepaintBoundary(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: groupBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: groupBorder, width: 0.8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.bolt_rounded, size: 20, color: AppColors.accentBlue),
                        const SizedBox(width: 8),
                        Text(
                          'Test Notification Panel',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Preview how quick attendance buttons appear in your notification shade and verify that instant background marking works smoothly.',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: () => _sendTestNotification(prefs),
                        icon: const Icon(Icons.notifications_active_rounded, size: 18),
                        label: const Text(
                          'Send Test Reminder Now',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 6. ZERO BATTERY DRAIN INFO CALLOUT
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  width: 0.8,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.battery_charging_full_rounded, size: 18, color: AppColors.presentGreen),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Zero Battery Drain Architecture',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'ClassTrack uses native OS exact alarms scheduled in the Android kernel. The app does NOT run persistent foreground services and uses 0% CPU and 0% battery while closed.',
                          style: TextStyle(
                            fontSize: 11.5,
                            height: 1.4,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

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

  Widget _buildSwitchTile({
    required String title,
    String? subtitle,
    required bool value,
    required bool isDark,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ],
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

  Widget _buildChoiceChip({
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final activeBg = isDark ? AppColors.accentBlue.withValues(alpha: 0.25) : const Color(0xFFEFF6FF);
    final activeBorder = AppColors.accentBlue;
    final inactiveBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final inactiveBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : inactiveBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? activeBorder : inactiveBorder,
            width: isSelected ? 1.4 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? AppColors.accentBlue
                : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
          ),
        ),
      ),
    );
  }
}
