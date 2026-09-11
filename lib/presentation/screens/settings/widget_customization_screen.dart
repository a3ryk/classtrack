import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/ui/app_toast.dart';
import '../../../domain/entities/widget_settings_entity.dart';
import '../../providers/app_state_provider.dart';

enum PreviewWidgetType {
  pill('Next Up', '2×1 or 4×1', Icons.view_headline_rounded),
  agenda('Agenda', '4×2 or 4×3', Icons.calendar_view_day_rounded),
  gauge('Gauge', '2×2', Icons.pie_chart_rounded);

  final String title;
  final String sizeHint;
  final IconData icon;
  const PreviewWidgetType(this.title, this.sizeHint, this.icon);
}

enum WallpaperBackdrop {
  oceanicAurora('Oceanic Aurora', Color(0xFF0F2027), Color(0xFF203A43)),
  sunsetGlow('Sunset Glow', Color(0xFF1E1B4B), Color(0xFF4C1D95)),
  minimalSlate('Minimal Slate', Color(0xFF1E293B), Color(0xFF0F172A)),
  pureDark('AMOLED Black', Color(0xFF000000), Color(0xFF000000));

  final String label;
  final Color startColor;
  final Color endColor;
  const WallpaperBackdrop(this.label, this.startColor, this.endColor);
}

class WidgetCustomizationScreen extends ConsumerStatefulWidget {
  const WidgetCustomizationScreen({super.key});

  @override
  ConsumerState<WidgetCustomizationScreen> createState() => _WidgetCustomizationScreenState();
}

class _WidgetCustomizationScreenState extends ConsumerState<WidgetCustomizationScreen> {
  PreviewWidgetType _selectedWidget = PreviewWidgetType.agenda;
  WallpaperBackdrop _selectedWallpaper = WallpaperBackdrop.oceanicAurora;
  bool _isSyncing = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = ref.watch(widgetSettingsProvider);
    final stats = ref.watch(overallStatsProvider);
    final activeSem = ref.watch(activeSemesterProvider);
    final todaySessions = ref.watch(resolvedDayScheduleProvider(DateTime.now()));

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
          'Home Screen Widgets',
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
          // 1. LIVE PREVIEW STAGE
          _buildSectionHeader('Live Preview', isDark),
          RepaintBoundary(
            child: Container(
              decoration: BoxDecoration(
                color: groupBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: groupBorder, width: 0.8),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // Segmented Form-Factor Switcher
                  _buildSegmentedSwitcher(isDark),

                  const SizedBox(height: 12),

                  // Framed Widget Canvas
                  _buildWidgetStageCanvas(
                    settings: settings,
                    statsPercentage: stats.overallPercentage,
                    safeBunks: stats.marginClassesToMiss,
                    isUnsetSemester: activeSem.isUnset,
                    hasClassesToday: todaySessions.isNotEmpty,
                    sampleClassTitle: todaySessions.isNotEmpty ? todaySessions.first.subjectName : 'Operating Systems',
                    sampleClassRoom: todaySessions.isNotEmpty ? (todaySessions.first.room ?? 'Room 302') : 'LH-2',
                  ),

                  const SizedBox(height: 12),

                  // Minimal Backdrop Wallpaper Swatches
                  _buildWallpaperSelector(isDark),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 2. BACKGROUND TRANSPARENCY
          _buildSectionHeader('Background Transparency', isDark),
          RepaintBoundary(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: groupBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: groupBorder, width: 0.8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Card Opacity',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accentBlue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${(settings.backgroundOpacity * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accentBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.accentBlue,
                      thumbColor: AppColors.accentBlue,
                      inactiveTrackColor: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    ),
                    child: Slider(
                      value: settings.backgroundOpacity,
                      min: 0.0,
                      max: 1.0,
                      divisions: 20,
                      onChanged: (val) {
                        ref.read(widgetSettingsProvider.notifier).updateSettings(
                              settings.copyWith(backgroundOpacity: val),
                            );
                      },
                    ),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildPresetChip('0%', 0.0, settings.backgroundOpacity, isDark),
                        const SizedBox(width: 8),
                        _buildPresetChip('25%', 0.25, settings.backgroundOpacity, isDark),
                        const SizedBox(width: 8),
                        _buildPresetChip('50%', 0.50, settings.backgroundOpacity, isDark),
                        const SizedBox(width: 8),
                        _buildPresetChip('75%', 0.75, settings.backgroundOpacity, isDark),
                        const SizedBox(width: 8),
                        _buildPresetChip('100%', 1.0, settings.backgroundOpacity, isDark),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 3. COLOR THEME & PALETTE
          _buildSectionHeader('Color Theme & Palette', isDark),
          RepaintBoundary(
            child: Container(
              decoration: BoxDecoration(
                color: groupBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: groupBorder, width: 0.8),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < WidgetThemeMode.values.length; i++) ...[
                    _buildThemeOptionTile(
                      mode: WidgetThemeMode.values[i],
                      isSelected: settings.themeMode == WidgetThemeMode.values[i],
                      isDark: isDark,
                      onTap: () {
                        ref.read(widgetSettingsProvider.notifier).updateSettings(
                              settings.copyWith(themeMode: WidgetThemeMode.values[i]),
                            );
                      },
                    ),
                    if (i < WidgetThemeMode.values.length - 1)
                      Divider(height: 1, indent: 56, endIndent: 16, color: dividerColor),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 4. DISPLAY & PRIVACY TOGGLES
          _buildSectionHeader('Information & Privacy', isDark),
          RepaintBoundary(
            child: Container(
              decoration: BoxDecoration(
                color: groupBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: groupBorder, width: 0.8),
              ),
              child: Column(
                children: [
                  _buildSwitchTile(
                    title: 'Privacy Shield',
                    subtitle: 'Masks attendance percentage as ***% on widget',
                    value: settings.privacyMode,
                    isDark: isDark,
                    onChanged: (val) {
                      ref.read(widgetSettingsProvider.notifier).updateSettings(
                            settings.copyWith(privacyMode: val),
                          );
                    },
                  ),
                  Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                  _buildSwitchTile(
                    title: 'Show Room Numbers',
                    subtitle: 'Displays classroom or lecture hall numbers',
                    value: settings.showRoomNumber,
                    isDark: isDark,
                    onChanged: (val) {
                      ref.read(widgetSettingsProvider.notifier).updateSettings(
                            settings.copyWith(showRoomNumber: val),
                          );
                    },
                  ),
                  Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                  _buildSwitchTile(
                    title: 'Show Tomorrow\'s First Class',
                    subtitle: 'Previews next morning\'s class when today is done',
                    value: settings.showTomorrowPreviewWhenDone,
                    isDark: isDark,
                    onChanged: (val) {
                      ref.read(widgetSettingsProvider.notifier).updateSettings(
                            settings.copyWith(showTomorrowPreviewWhenDone: val),
                          );
                    },
                  ),
                  Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                  _buildSwitchTile(
                    title: '24-Hour Time Format',
                    subtitle: 'Display 14:00 instead of 2:00 PM',
                    value: settings.use24HourFormat,
                    isDark: isDark,
                    onChanged: (val) {
                      ref.read(widgetSettingsProvider.notifier).updateSettings(
                            settings.copyWith(use24HourFormat: val),
                          );
                    },
                  ),
                  Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                  _buildSwitchTile(
                    title: '1-Tap Direct Attendance',
                    subtitle: 'Mark Present or Absent right from widget buttons',
                    value: settings.directAttendanceMarking,
                    isDark: isDark,
                    onChanged: (val) {
                      ref.read(widgetSettingsProvider.notifier).updateSettings(
                            settings.copyWith(directAttendanceMarking: val),
                          );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 5. INSTRUCTION CARD: HOW TO ADD
          _buildSectionHeader('How to Add', isDark),
          RepaintBoundary(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: groupBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: groupBorder, width: 0.8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.accentBlue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Adding Widgets on Android',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildStepRow('1', 'Long-press any empty space on your home screen', isDark),
                  const SizedBox(height: 8),
                  _buildStepRow('2', 'Select "Widgets" from the launcher menu', isDark),
                  const SizedBox(height: 8),
                  _buildStepRow('3', 'Scroll to "Attendly" and choose your widget size', isDark),
                  const SizedBox(height: 8),
                  _buildStepRow('4', 'Drag and place it onto your home screen', isDark),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 6. SYNC NOW BUTTON
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: _isSyncing
                  ? null
                  : () async {
                      setState(() => _isSyncing = true);
                      final ok = await ref.read(widgetSyncProvider).syncWidgets();
                      if (!context.mounted) return;
                      setState(() => _isSyncing = false);
                      if (ok) {
                        AppToast.success(context, 'Home screen widgets updated successfully');
                      } else {
                        AppToast.info(context, 'Widget configuration saved to storage');
                      }
                    },
              icon: _isSyncing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.sync_rounded, size: 18),
              label: Text(
                _isSyncing ? 'Syncing...' : 'Force Sync All Widgets',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                foregroundColor: isDark ? AppColors.bgDark : AppColors.surfaceLight,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- WIDGET STAGE CANVAS ---
  Widget _buildWidgetStageCanvas({
    required WidgetSettingsEntity settings,
    required double statsPercentage,
    required int safeBunks,
    required bool isUnsetSemester,
    required bool hasClassesToday,
    required String sampleClassTitle,
    required String sampleClassRoom,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_selectedWallpaper.startColor, _selectedWallpaper.endColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      alignment: Alignment.center,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                ),
                child: child,
              ),
            );
          },
          child: _buildSelectedWidgetPreview(
            type: _selectedWidget,
            settings: settings,
            statsPercentage: statsPercentage,
            safeBunks: safeBunks,
            isUnsetSemester: isUnsetSemester,
            hasClassesToday: hasClassesToday,
            sampleClassTitle: sampleClassTitle,
            sampleClassRoom: sampleClassRoom,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedWidgetPreview({
    required PreviewWidgetType type,
    required WidgetSettingsEntity settings,
    required double statsPercentage,
    required int safeBunks,
    required bool isUnsetSemester,
    required bool hasClassesToday,
    required String sampleClassTitle,
    required String sampleClassRoom,
  }) {
    final Color baseBgColor = Color(settings.themeMode.cardBackgroundColorValue);
    final Color effectiveBg = baseBgColor.withValues(alpha: settings.backgroundOpacity);
    final Color accentColor = Color(settings.themeMode.primaryColorValue);

    switch (type) {
      case PreviewWidgetType.pill:
        return _buildPillPreview(
          effectiveBg: effectiveBg,
          accentColor: accentColor,
          settings: settings,
          sampleClassTitle: sampleClassTitle,
          sampleClassRoom: sampleClassRoom,
        );
      case PreviewWidgetType.agenda:
        return _buildAgendaPreview(
          effectiveBg: effectiveBg,
          accentColor: accentColor,
          settings: settings,
          statsPercentage: statsPercentage,
          sampleClassTitle: sampleClassTitle,
          sampleClassRoom: sampleClassRoom,
        );
      case PreviewWidgetType.gauge:
        return _buildGaugePreview(
          effectiveBg: effectiveBg,
          accentColor: accentColor,
          settings: settings,
          statsPercentage: statsPercentage,
          safeBunks: safeBunks,
        );
    }
  }

  // --- 1. PILL PREVIEW (2x1) ---
  Widget _buildPillPreview({
    required Color effectiveBg,
    required Color accentColor,
    required WidgetSettingsEntity settings,
    required String sampleClassTitle,
    required String sampleClassRoom,
  }) {
    final title = settings.privacyMode ? 'Class in Session' : sampleClassTitle;
    final timeStr = settings.use24HourFormat ? '10:00 - 11:00' : '10:00 - 11:00 AM';
    final roomStr = settings.privacyMode ? '***' : sampleClassRoom;
    final timeAndRoom = settings.showRoomNumber && roomStr.isNotEmpty
        ? '$timeStr • $roomStr'
        : timeStr;

    return Container(
      key: const ValueKey('preview_pill'),
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFF2E3039).withValues(alpha: settings.backgroundOpacity.clamp(0.25, 1.0)),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3.5,
            height: 28,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeAndRoom,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF27282F).withValues(alpha: settings.backgroundOpacity.clamp(0.4, 1.0)),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF2E3039).withValues(alpha: settings.backgroundOpacity.clamp(0.3, 1.0)),
                width: 0.8,
              ),
            ),
            child: Text(
              'Next Up',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. AGENDA PREVIEW (4x2) ---
  Widget _buildAgendaPreview({
    required Color effectiveBg,
    required Color accentColor,
    required WidgetSettingsEntity settings,
    required double statsPercentage,
    required String sampleClassTitle,
    required String sampleClassRoom,
  }) {
    final title = settings.privacyMode ? 'Class in Session' : sampleClassTitle;
    final timeStr = settings.use24HourFormat ? '10:00 - 11:00' : '10:00 - 11:00 AM';
    final upcomingTimeStr = settings.use24HourFormat ? '11:15' : '11:15 AM';
    final roomStr = settings.privacyMode ? '***' : sampleClassRoom;
    final pctStr = settings.privacyMode ? '***%' : '${statsPercentage.toStringAsFixed(1)}%';

    return Container(
      key: const ValueKey('preview_agenda'),
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF2E3039).withValues(alpha: settings.backgroundOpacity.clamp(0.25, 1.0)),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Today\'s Schedule',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF27282F).withValues(alpha: settings.backgroundOpacity.clamp(0.4, 1.0)),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF2E3039).withValues(alpha: settings.backgroundOpacity.clamp(0.3, 1.0)),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  pctStr,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Hero class card
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF27282F).withValues(alpha: settings.backgroundOpacity.clamp(0.4, 1.0)),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF2E3039).withValues(alpha: settings.backgroundOpacity.clamp(0.3, 1.0)),
                width: 0.8,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (settings.showRoomNumber && roomStr.isNotEmpty)
                      Text(
                        roomStr,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: accentColor,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        timeStr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    if (settings.directAttendanceMarking)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildMiniActionButton('✓', const Color(0xFF10B981)),
                          const SizedBox(width: 5),
                          _buildMiniActionButton('✗', const Color(0xFFEF4444)),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Upcoming lecture snippet
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  settings.privacyMode
                      ? 'Next: Class in Session ($upcomingTimeStr)'
                      : 'Next: Database Systems ($upcomingTimeStr)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 3. GAUGE PREVIEW (2x2) ---
  Widget _buildGaugePreview({
    required Color effectiveBg,
    required Color accentColor,
    required WidgetSettingsEntity settings,
    required double statsPercentage,
    required int safeBunks,
  }) {
    final pctStr = settings.privacyMode ? '***%' : '${statsPercentage.toStringAsFixed(1)}%';
    final bunksStr = settings.privacyMode
        ? 'Privacy Shield'
        : (safeBunks >= 0 ? '🟢 $safeBunks Safe Bunks' : '🔴 Attend next classes');

    return Container(
      key: const ValueKey('preview_gauge'),
      constraints: const BoxConstraints(minWidth: 150, maxWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF2E3039).withValues(alpha: settings.backgroundOpacity.clamp(0.25, 1.0)),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'ATTENDANCE',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            pctStr,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 8),
          // Actual Progress Gauge Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: settings.privacyMode ? 0.75 : (statsPercentage / 100.0).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: const Color(0xFF2E3039),
              valueColor: AlwaysStoppedAnimation<Color>(
                settings.privacyMode
                    ? accentColor
                    : (statsPercentage >= 75.0 ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF27282F).withValues(alpha: settings.backgroundOpacity.clamp(0.4, 1.0)),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF2E3039).withValues(alpha: settings.backgroundOpacity.clamp(0.3, 1.0)),
                width: 0.8,
              ),
            ),
            child: Text(
              bunksStr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniActionButton(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  // --- SEGMENTED SWITCHER ---
  Widget _buildSegmentedSwitcher(bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16171B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
          width: 0.8,
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: PreviewWidgetType.values.map((type) {
          final isSel = _selectedWidget == type;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: GestureDetector(
                onTap: () => setState(() => _selectedWidget = type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSel
                        ? (isDark ? AppColors.cardDark : Colors.white)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                    border: isSel
                        ? Border.all(
                            color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                            width: 0.8,
                          )
                        : null,
                    boxShadow: isSel
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        type.icon,
                        size: 13,
                        color: isSel
                            ? AppColors.accentBlue
                            : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          type.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                            color: isSel
                                ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                                : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- WALLPAPER SWATCHES ---
  Widget _buildWallpaperSelector(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Backdrop:',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(width: 8),
        ...WallpaperBackdrop.values.map((wall) {
          final isSel = _selectedWallpaper == wall;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () => setState(() => _selectedWallpaper = wall),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [wall.startColor, wall.endColor]),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSel ? AppColors.accentBlue : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: isSel
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              ),
            ),
          );
        }),
      ],
    );
  }

  // --- PRESET CHIP ---
  Widget _buildPresetChip(String label, double value, double current, bool isDark) {
    final isSelected = (current - value).abs() < 0.05;
    return InkWell(
      onTap: () {
        ref.read(widgetSettingsProvider.notifier).updateSettings(
              ref.read(widgetSettingsProvider).copyWith(backgroundOpacity: value),
            );
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentBlue
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
          ),
        ),
      ),
    );
  }

  // --- THEME TILE ---
  Widget _buildThemeOptionTile({
    required WidgetThemeMode mode,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: Color(mode.cardBackgroundColorValue),
                shape: BoxShape.circle,
                border: Border.all(color: Color(mode.primaryColorValue), width: 2.5),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mode.displayName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    _getThemeSubtitle(mode),
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_rounded, size: 20, color: AppColors.accentBlue),
          ],
        ),
      ),
    );
  }

  String _getThemeSubtitle(WidgetThemeMode mode) {
    switch (mode) {
      case WidgetThemeMode.system:
        return 'Signature dark slate baseline';
      case WidgetThemeMode.amoled:
        return 'Pure #000000 black for OLED contrast';
      case WidgetThemeMode.midnight:
        return 'Deep obsidian neutral tone';
      case WidgetThemeMode.emerald:
        return 'Deep forest neutral baseline';
      case WidgetThemeMode.sunset:
        return 'Warm graphite neutral baseline';
      case WidgetThemeMode.rose:
        return 'Deep wine neutral baseline';
    }
  }

  // --- SWITCH TILE ---
  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
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
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: AppColors.presentGreen,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // --- STEP ROW ---
  Widget _buildStepRow(String stepNum, String text, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 18,
          height: 18,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF27282F) : const Color(0xFFE2E8F0),
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark ? const Color(0xFF2E3039) : const Color(0xFFCBD5E1),
              width: 0.8,
            ),
          ),
          child: Text(
            stepNum,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.35,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        ),
      ),
    );
  }
}
