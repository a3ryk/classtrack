import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_theme_tokens.dart';
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
  mintMist('Mint Mist', Color(0xFFA8E6CF), Color(0xFFDCEDC1)),
  matchaDawn('Matcha Dawn', Color(0xFF7CB342), Color(0xFF558B2F)),
  creamSage('Cream Sage', Color(0xFFEDE8DF), Color(0xFFD4DEC7)),
  midnightSprout('Midnight Sprout', Color(0xFF13261B), Color(0xFF1B3626)),
  pureDark('AMOLED Black', Color(0xFF000000), Color(0xFF000000)),
  oceanicAurora('Oceanic Aurora', Color(0xFF0F2027), Color(0xFF203A43)),
  sunsetGlow('Sunset Glow', Color(0xFF1E1B4B), Color(0xFF4C1D95)),
  minimalSlate('Minimal Slate', Color(0xFF1E293B), Color(0xFF0F172A));

  final String label;
  final Color startColor;
  final Color endColor;
  const WallpaperBackdrop(this.label, this.startColor, this.endColor);
}

class _SproutWidgetColors {
  final Color cardBg;
  final Color cardBorder;
  final Color titleColor;
  final Color subtitleColor;
  final Color accentColor;
  final Color badgeBg;
  final Color badgeBorder;
  final Color badgeText;
  final Color pillBg;
  final Color pillBorder;

  const _SproutWidgetColors({
    required this.cardBg,
    required this.cardBorder,
    required this.titleColor,
    required this.subtitleColor,
    required this.accentColor,
    required this.badgeBg,
    required this.badgeBorder,
    required this.badgeText,
    required this.pillBg,
    required this.pillBorder,
  });
}

class WidgetCustomizationScreen extends ConsumerStatefulWidget {
  const WidgetCustomizationScreen({super.key});

  @override
  ConsumerState<WidgetCustomizationScreen> createState() => _WidgetCustomizationScreenState();
}

class _WidgetCustomizationScreenState extends ConsumerState<WidgetCustomizationScreen> {
  static const _classicWallpapers = [
    WallpaperBackdrop.oceanicAurora,
    WallpaperBackdrop.sunsetGlow,
    WallpaperBackdrop.minimalSlate,
    WallpaperBackdrop.pureDark,
  ];

  static const _sproutWallpapers = [
    WallpaperBackdrop.mintMist,
    WallpaperBackdrop.matchaDawn,
    WallpaperBackdrop.creamSage,
    WallpaperBackdrop.midnightSprout,
    WallpaperBackdrop.pureDark,
  ];

  PreviewWidgetType _selectedWidget = PreviewWidgetType.agenda;
  WallpaperBackdrop _selectedWallpaper = WallpaperBackdrop.oceanicAurora;
  bool _initializedSproutWallpaper = false;
  bool _isSyncing = false;

  Future<void> _handleSync() async {
    setState(() => _isSyncing = true);
    final ok = await ref.read(widgetSyncProvider).syncWidgets();
    if (!mounted) return;
    setState(() => _isSyncing = false);
    if (!context.mounted) return;
    if (ok) {
      AppToast.success(context, 'Home screen widgets updated successfully');
    } else {
      AppToast.info(context, 'Widget configuration saved to storage');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = ref.watch(widgetSettingsProvider);
    final stats = ref.watch(overallStatsProvider);
    final activeSem = ref.watch(activeSemesterProvider);
    final todaySessions = ref.watch(resolvedDayScheduleProvider(DateTime.now()));

    final Color groupBg = isDark ? AppColors.cardDark : Colors.white;
    final Color groupBorder = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);
    final Color dividerColor = isDark ? AppColors.borderDark.withValues(alpha: 0.6) : const Color(0xFFF1F5F9);

    if (tokens?.isCute == true) {
      return _buildSproutWidgetCustomizationView(
        context: context,
        tokens: tokens!,
        isDark: isDark,
        settings: settings,
        stats: stats,
        activeSem: activeSem,
        todaySessions: todaySessions,
      );
    }

    return _buildClassicWidgetCustomizationView(
      context: context,
      isDark: isDark,
      settings: settings,
      stats: stats,
      activeSem: activeSem,
      todaySessions: todaySessions,
      groupBg: groupBg,
      groupBorder: groupBorder,
      dividerColor: dividerColor,
    );
  }

  // ===========================================================================
  // SPROUTS THEME VIEW (Strictly isolated to tokens?.isCute == true)
  // ===========================================================================
  Widget _buildSproutWidgetCustomizationView({
    required BuildContext context,
    required AppThemeTokens tokens,
    required bool isDark,
    required WidgetSettingsEntity settings,
    required dynamic stats,
    required dynamic activeSem,
    required dynamic todaySessions,
  }) {
    final cardBg = isDark ? const Color(0xFF1B3626) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF274C37) : const Color(0xFFE4ECE0);
    final subCardBg = isDark ? const Color(0xFF163424) : const Color(0xFFFAF7F2);
    final dividerColor = isDark ? const Color(0xFF274C37) : const Color(0xFFF0ECE1);

    if (!_initializedSproutWallpaper) {
      _selectedWallpaper = WallpaperBackdrop.mintMist;
      _initializedSproutWallpaper = true;
    }

    return Scaffold(
      backgroundColor: tokens.scaffoldBg,
      appBar: AppBar(
        backgroundColor: tokens.scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 100,
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 14),
              Icon(Icons.chevron_left_rounded, size: 22, color: tokens.primaryAccent),
              Text(
                'Back',
                style: GoogleFonts.quicksand(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: tokens.primaryAccent,
                ),
              ),
            ],
          ),
        ),
        title: Text(
          'Home Screen Widgets',
          style: GoogleFonts.quicksand(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: tokens.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // 1. LIVE PREVIEW STAGE (Zero emojis)
          _buildSproutSectionHeader('LIVE PREVIEW', tokens),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: cardBorder, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                // Form-Factor Switcher (with size hints matching preview)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: subCardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cardBorder, width: 1.0),
                  ),
                  child: Row(
                    children: [
                      _buildSproutFormFactorChip(
                        type: PreviewWidgetType.agenda,
                        subHint: '(4×2)',
                        isSelected: _selectedWidget == PreviewWidgetType.agenda,
                        tokens: tokens,
                        onTap: () => setState(() => _selectedWidget = PreviewWidgetType.agenda),
                      ),
                      const SizedBox(width: 4),
                      _buildSproutFormFactorChip(
                        type: PreviewWidgetType.pill,
                        subHint: '(2×1)',
                        isSelected: _selectedWidget == PreviewWidgetType.pill,
                        tokens: tokens,
                        onTap: () => setState(() => _selectedWidget = PreviewWidgetType.pill),
                      ),
                      const SizedBox(width: 4),
                      _buildSproutFormFactorChip(
                        type: PreviewWidgetType.gauge,
                        subHint: '(2×2)',
                        isSelected: _selectedWidget == PreviewWidgetType.gauge,
                        tokens: tokens,
                        onTap: () => setState(() => _selectedWidget = PreviewWidgetType.gauge),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Framed Sprout Widget Canvas (Simulates Android Launcher Screen)
                _buildSproutWidgetStageCanvas(
                  settings: settings,
                  statsPercentage: stats.overallPercentage,
                  safeBunks: stats.marginClassesToMiss,
                  isUnsetSemester: activeSem.isUnset,
                  hasClassesToday: todaySessions.isNotEmpty,
                  sampleClassTitle: todaySessions.isNotEmpty ? todaySessions.first.subjectName : 'Machine Learning',
                  sampleClassRoom: todaySessions.isNotEmpty ? (todaySessions.first.room ?? 'Room 302') : 'Room 302',
                  tokens: tokens,
                  isDark: isDark,
                ),

                const SizedBox(height: 12),

                // Backdrop Wallpaper Swatches (Sprout-Native Palette)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Backdrop Wallpaper:',
                        style: GoogleFonts.quicksand(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: tokens.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Row(
                        children: _sproutWallpapers.map((wall) {
                          final isSel = _selectedWallpaper == wall;
                          return Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: InkWell(
                              onTap: () => setState(() => _selectedWallpaper = wall),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [wall.startColor, wall.endColor]),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSel ? tokens.primaryAccent : Colors.white,
                                    width: isSel ? 2.5 : 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 3,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 2. BACKGROUND TRANSPARENCY (Zero emojis)
          _buildSproutSectionHeader('BACKGROUND TRANSPARENCY', tokens),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(tokens.cardRadius),
              border: Border.all(color: cardBorder, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withValues(alpha: 0.25) : const Color(0xFF5A7260).withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Widget Card Opacity',
                            style: GoogleFonts.quicksand(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: tokens.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Adjust background blur & transparency',
                            style: GoogleFonts.quicksand(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: tokens.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: tokens.primaryAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: tokens.primaryAccent.withValues(alpha: 0.25), width: 1.0),
                      ),
                      child: Text(
                        '${(settings.backgroundOpacity * 100).round()}%',
                        style: GoogleFonts.quicksand(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: tokens.primaryAccent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: tokens.primaryAccent,
                    thumbColor: tokens.primaryAccent,
                    inactiveTrackColor: isDark ? const Color(0xFF274C37) : const Color(0xFFF0ECE1),
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Steppers [-] and [+]
                    Row(
                      children: [
                        InkWell(
                          onTap: () {
                            final current = settings.backgroundOpacity;
                            final newVal = ((current - 0.05) * 20).round() / 20;
                            ref.read(widgetSettingsProvider.notifier).updateSettings(
                                  settings.copyWith(backgroundOpacity: newVal.clamp(0.0, 1.0)),
                                );
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: subCardBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: cardBorder),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '−',
                              style: GoogleFonts.quicksand(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: tokens.primaryAccent,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () {
                            final current = settings.backgroundOpacity;
                            final newVal = ((current + 0.05) * 20).round() / 20;
                            ref.read(widgetSettingsProvider.notifier).updateSettings(
                                  settings.copyWith(backgroundOpacity: newVal.clamp(0.0, 1.0)),
                                );
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: subCardBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: cardBorder),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '+',
                              style: GoogleFonts.quicksand(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: tokens.primaryAccent,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 6),
                    // Presets
                    Flexible(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildSproutPresetChip('0%', 0.0, settings.backgroundOpacity, tokens, isDark),
                            const SizedBox(width: 4),
                            _buildSproutPresetChip('25%', 0.25, settings.backgroundOpacity, tokens, isDark),
                            const SizedBox(width: 4),
                            _buildSproutPresetChip('50%', 0.50, settings.backgroundOpacity, tokens, isDark),
                            const SizedBox(width: 4),
                            _buildSproutPresetChip('75%', 0.75, settings.backgroundOpacity, tokens, isDark),
                            const SizedBox(width: 4),
                            _buildSproutPresetChip('100%', 1.0, settings.backgroundOpacity, tokens, isDark),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 3. COLOR THEME & PALETTE (Zero emojis)
          _buildSproutSectionHeader('COLOR THEME & PALETTE', tokens),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: cardBorder, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildSproutThemeOptionTile(
                  mode: WidgetThemeMode.system,
                  isSelected: settings.themeMode == WidgetThemeMode.system,
                  tokens: tokens,
                  isDark: isDark,
                  onTap: () {
                    ref.read(widgetSettingsProvider.notifier).updateSettings(
                          settings.copyWith(themeMode: WidgetThemeMode.system),
                        );
                  },
                ),
                Divider(height: 1, indent: 56, endIndent: 16, color: dividerColor),
                _buildSproutThemeOptionTile(
                  mode: WidgetThemeMode.emerald,
                  isSelected: settings.themeMode == WidgetThemeMode.emerald,
                  tokens: tokens,
                  isDark: isDark,
                  onTap: () {
                    ref.read(widgetSettingsProvider.notifier).updateSettings(
                          settings.copyWith(themeMode: WidgetThemeMode.emerald),
                        );
                  },
                ),
                Divider(height: 1, indent: 56, endIndent: 16, color: dividerColor),
                _buildSproutThemeOptionTile(
                  mode: WidgetThemeMode.amoled,
                  isSelected: settings.themeMode == WidgetThemeMode.amoled,
                  tokens: tokens,
                  isDark: isDark,
                  onTap: () {
                    ref.read(widgetSettingsProvider.notifier).updateSettings(
                          settings.copyWith(themeMode: WidgetThemeMode.amoled),
                        );
                  },
                ),
                if (settings.themeMode != WidgetThemeMode.system &&
                    settings.themeMode != WidgetThemeMode.emerald &&
                    settings.themeMode != WidgetThemeMode.amoled) ...[
                  Divider(height: 1, indent: 56, endIndent: 16, color: dividerColor),
                  _buildSproutThemeOptionTile(
                    mode: settings.themeMode,
                    isSelected: true,
                    tokens: tokens,
                    isDark: isDark,
                    onTap: () {},
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 4. INFORMATION & PRIVACY (Zero emojis)
          _buildSproutSectionHeader('INFORMATION & PRIVACY', tokens),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: cardBorder, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildSproutSwitchTile(
                  title: 'Privacy Shield',
                  subtitle: 'Masks attendance percentage as ***%',
                  value: settings.privacyMode,
                  tokens: tokens,
                  onChanged: (val) {
                    ref.read(widgetSettingsProvider.notifier).updateSettings(
                          settings.copyWith(privacyMode: val),
                        );
                  },
                ),
                Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                _buildSproutSwitchTile(
                  title: 'Show Room Numbers',
                  subtitle: 'Displays classroom & hall badges',
                  value: settings.showRoomNumber,
                  tokens: tokens,
                  onChanged: (val) {
                    ref.read(widgetSettingsProvider.notifier).updateSettings(
                          settings.copyWith(showRoomNumber: val),
                        );
                  },
                ),
                Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                _buildSproutSwitchTile(
                  title: '24-Hour Time Format',
                  subtitle: 'Display 14:00 instead of 2:00 PM',
                  value: settings.use24HourFormat,
                  tokens: tokens,
                  onChanged: (val) {
                    ref.read(widgetSettingsProvider.notifier).updateSettings(
                          settings.copyWith(use24HourFormat: val),
                        );
                  },
                ),
                Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                _buildSproutSwitchTile(
                  title: '1-Tap Direct Attendance',
                  subtitle: 'Mark Present/Absent right from widget',
                  value: settings.directAttendanceMarking,
                  tokens: tokens,
                  onChanged: (val) {
                    ref.read(widgetSettingsProvider.notifier).updateSettings(
                          settings.copyWith(directAttendanceMarking: val),
                        );
                  },
                ),
                Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                _buildSproutSwitchTile(
                  title: 'Show Tomorrow\'s First Class',
                  subtitle: 'Previews next morning\'s class when today is done',
                  value: settings.showTomorrowPreviewWhenDone,
                  tokens: tokens,
                  onChanged: (val) {
                    ref.read(widgetSettingsProvider.notifier).updateSettings(
                          settings.copyWith(showTomorrowPreviewWhenDone: val),
                        );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 5. HOW TO ADD WIDGETS (Zero emojis)
          _buildSproutSectionHeader('HOW TO ADD WIDGETS', tokens),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: cardBorder, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSproutStepRow('1', 'Long-press any empty space on your Android home screen', tokens),
                const SizedBox(height: 10),
                _buildSproutStepRow('2', 'Select "Widgets" from the launcher pop-up menu', tokens),
                const SizedBox(height: 10),
                _buildSproutStepRow('3', 'Scroll to "Attendly" and pick your preferred size (Agenda, Next Up, or Gauge)', tokens),
                const SizedBox(height: 10),
                _buildSproutStepRow('4', 'Drag and drop it wherever you want', tokens),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 6. FORCE SYNC ALL WIDGETS
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isSyncing ? null : _handleSync,
              icon: _isSyncing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.sync_rounded, size: 18),
              label: Text(
                _isSyncing ? 'Syncing...' : 'Force Sync All Widgets',
                style: GoogleFonts.quicksand(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: tokens.primaryAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ===========================================================================
  // CLASSIC VIEW (Byte-for-byte preserved for classic theme)
  // ===========================================================================
  Widget _buildClassicWidgetCustomizationView({
    required BuildContext context,
    required bool isDark,
    required WidgetSettingsEntity settings,
    required dynamic stats,
    required dynamic activeSem,
    required dynamic todaySessions,
    required Color groupBg,
    required Color groupBorder,
    required Color dividerColor,
  }) {
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
              onPressed: _isSyncing ? null : _handleSync,
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
        ..._classicWallpapers.map((wall) {
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

  // ===========================================================================
  // SPROUTS HELPER BUILDERS
  // ===========================================================================
  Widget _buildSproutSectionHeader(String title, AppThemeTokens tokens) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.quicksand(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: tokens.textMuted,
        ),
      ),
    );
  }

  Widget _buildSproutFormFactorChip({
    required PreviewWidgetType type,
    required String subHint,
    required bool isSelected,
    required AppThemeTokens tokens,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? tokens.primaryAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: tokens.primaryAccent.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      type.title,
                      style: GoogleFonts.quicksand(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                        color: isSelected ? Colors.white : tokens.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      subHint,
                      style: GoogleFonts.quicksand(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white.withValues(alpha: 0.8) : tokens.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _SproutWidgetColors _getSproutWidgetColors({
    required WidgetSettingsEntity settings,
    required AppThemeTokens tokens,
    required bool isDark,
  }) {
    switch (settings.themeMode) {
      case WidgetThemeMode.amoled:
        return const _SproutWidgetColors(
          cardBg: Color(0xFF000000),
          cardBorder: Color(0xFF274C37),
          titleColor: Color(0xFFE4ECE0),
          subtitleColor: Color(0xFFA3B899),
          accentColor: Color(0xFF8BC34A),
          badgeBg: Color(0xFF163424),
          badgeBorder: Color(0xFF274C37),
          badgeText: Color(0xFF8BC34A),
          pillBg: Color(0xFF13261B),
          pillBorder: Color(0xFF274C37),
        );
      case WidgetThemeMode.emerald:
        return const _SproutWidgetColors(
          cardBg: Colors.white,
          cardBorder: Color(0xFFE4ECE0),
          titleColor: Color(0xFF1E3526),
          subtitleColor: Color(0xFF5B7362),
          accentColor: Color(0xFF7CB342),
          badgeBg: Color(0xFFEAF8E7),
          badgeBorder: Color(0xFFD7F0D6),
          badgeText: Color(0xFF1E6B3F),
          pillBg: Color(0xFFFAF7F2),
          pillBorder: Color(0xFFE4ECE0),
        );
      case WidgetThemeMode.system:
        if (isDark) {
          return const _SproutWidgetColors(
            cardBg: Color(0xFF1B3626),
            cardBorder: Color(0xFF274C37),
            titleColor: Color(0xFFE4ECE0),
            subtitleColor: Color(0xFFA3B899),
            accentColor: Color(0xFF8BC34A),
            badgeBg: Color(0xFF163424),
            badgeBorder: Color(0xFF274C37),
            badgeText: Color(0xFF8BC34A),
            pillBg: Color(0xFF13261B),
            pillBorder: Color(0xFF274C37),
          );
        } else {
          return const _SproutWidgetColors(
            cardBg: Colors.white,
            cardBorder: Color(0xFFE4ECE0),
            titleColor: Color(0xFF1E3526),
            subtitleColor: Color(0xFF5B7362),
            accentColor: Color(0xFF7CB342),
            badgeBg: Color(0xFFEAF8E7),
            badgeBorder: Color(0xFFD7F0D6),
            badgeText: Color(0xFF1E6B3F),
            pillBg: Color(0xFFFAF7F2),
            pillBorder: Color(0xFFE4ECE0),
          );
        }
      case WidgetThemeMode.midnight:
        return const _SproutWidgetColors(
          cardBg: Color(0xFF0F172A),
          cardBorder: Color(0xFF334155),
          titleColor: Colors.white,
          subtitleColor: Color(0xFF94A3B8),
          accentColor: Color(0xFF60A5FA),
          badgeBg: Color(0xFF1E293B),
          badgeBorder: Color(0xFF334155),
          badgeText: Color(0xFF60A5FA),
          pillBg: Color(0xFF1E293B),
          pillBorder: Color(0xFF334155),
        );
      case WidgetThemeMode.rose:
        return const _SproutWidgetColors(
          cardBg: Color(0xFF1C1118),
          cardBorder: Color(0xFF4C2034),
          titleColor: Colors.white,
          subtitleColor: Color(0xFFE2A8BF),
          accentColor: Color(0xFFFB7185),
          badgeBg: Color(0xFF2A1620),
          badgeBorder: Color(0xFF4C2034),
          badgeText: Color(0xFFFB7185),
          pillBg: Color(0xFF2A1620),
          pillBorder: Color(0xFF4C2034),
        );
      case WidgetThemeMode.sunset:
        return const _SproutWidgetColors(
          cardBg: Color(0xFF1C1510),
          cardBorder: Color(0xFF4C341F),
          titleColor: Colors.white,
          subtitleColor: Color(0xFFD4A574),
          accentColor: Color(0xFFF59E0B),
          badgeBg: Color(0xFF2A1E14),
          badgeBorder: Color(0xFF4C341F),
          badgeText: Color(0xFFF59E0B),
          pillBg: Color(0xFF2A1E14),
          pillBorder: Color(0xFF4C341F),
        );
    }
  }

  Widget _buildSproutWidgetStageCanvas({
    required WidgetSettingsEntity settings,
    required double statsPercentage,
    required int safeBunks,
    required bool isUnsetSemester,
    required bool hasClassesToday,
    required String sampleClassTitle,
    required String sampleClassRoom,
    required AppThemeTokens tokens,
    required bool isDark,
  }) {
    final activeWallpaper = _sproutWallpapers.contains(_selectedWallpaper)
        ? _selectedWallpaper
        : WallpaperBackdrop.mintMist;

    final isDarkWallpaper = activeWallpaper == WallpaperBackdrop.midnightSprout ||
        activeWallpaper == WallpaperBackdrop.pureDark ||
        activeWallpaper == WallpaperBackdrop.matchaDawn;

    final watermarkColor = isDarkWallpaper
        ? Colors.white.withValues(alpha: 0.6)
        : const Color(0xFF1E3526).withValues(alpha: 0.45);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 170),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [activeWallpaper.startColor, activeWallpaper.endColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Stack(
        clipBehavior: Clip.antiAlias,
        children: [
          // Launcher Clock and Title Watermark (top corners)
          Positioned(
            top: 2,
            left: 2,
            child: Text(
              settings.use24HourFormat ? '10:45 • Wed, Aug 26' : '10:45 AM • Wed, Aug 26',
              style: GoogleFonts.quicksand(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: watermarkColor,
              ),
            ),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: Text(
              'Attendly Widget',
              style: GoogleFonts.quicksand(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: watermarkColor.withValues(alpha: 0.35),
              ),
            ),
          ),

          // Selected Widget Preview
          Padding(
            padding: const EdgeInsets.only(top: 22, bottom: 2),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.96, end: 1.0).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _buildSproutSelectedWidget(
                  type: _selectedWidget,
                  settings: settings,
                  statsPercentage: statsPercentage,
                  safeBunks: safeBunks,
                  isUnsetSemester: isUnsetSemester,
                  hasClassesToday: hasClassesToday,
                  sampleClassTitle: sampleClassTitle,
                  sampleClassRoom: sampleClassRoom,
                  tokens: tokens,
                  isDark: isDark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSproutSelectedWidget({
    required PreviewWidgetType type,
    required WidgetSettingsEntity settings,
    required double statsPercentage,
    required int safeBunks,
    required bool isUnsetSemester,
    required bool hasClassesToday,
    required String sampleClassTitle,
    required String sampleClassRoom,
    required AppThemeTokens tokens,
    required bool isDark,
  }) {
    switch (type) {
      case PreviewWidgetType.agenda:
        return _buildSproutAgendaWidget(
          settings: settings,
          statsPercentage: statsPercentage,
          safeBunks: safeBunks,
          sampleClassTitle: sampleClassTitle,
          sampleClassRoom: sampleClassRoom,
          tokens: tokens,
          isDark: isDark,
        );
      case PreviewWidgetType.pill:
        return _buildSproutPillWidget(
          settings: settings,
          statsPercentage: statsPercentage,
          sampleClassTitle: sampleClassTitle,
          sampleClassRoom: sampleClassRoom,
          tokens: tokens,
          isDark: isDark,
        );
      case PreviewWidgetType.gauge:
        return _buildSproutGaugeWidget(
          settings: settings,
          statsPercentage: statsPercentage,
          safeBunks: safeBunks,
          tokens: tokens,
          isDark: isDark,
        );
    }
  }

  Widget _buildSproutAgendaWidget({
    required WidgetSettingsEntity settings,
    required double statsPercentage,
    required int safeBunks,
    required String sampleClassTitle,
    required String sampleClassRoom,
    required AppThemeTokens tokens,
    required bool isDark,
  }) {
    final colors = _getSproutWidgetColors(
      settings: settings,
      tokens: tokens,
      isDark: isDark,
    );

    final title = sampleClassTitle.isNotEmpty ? sampleClassTitle : 'Machine Learning';
    final timeStr = settings.use24HourFormat ? '10:00 - 11:30' : '10:00 - 11:30 AM';
    final roomStr = sampleClassRoom.isNotEmpty ? sampleClassRoom : 'Room 302';
    final pctText = settings.privacyMode ? '***%' : '${statsPercentage.toStringAsFixed(0)}%';

    final effectiveBg = colors.cardBg.withValues(alpha: settings.backgroundOpacity.clamp(0.0, 1.0));
    final borderColor = colors.cardBorder.withValues(alpha: settings.backgroundOpacity.clamp(0.2, 1.0));

    return Container(
      key: const ValueKey('preview_agenda'),
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Pulsing green dot, Next Class Today, Pct Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.accentColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'NEXT CLASS TODAY',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.quicksand(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: colors.accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: colors.badgeBg,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: colors.badgeBorder, width: 1.0),
                ),
                child: Text(
                  '$pctText Attendance',
                  style: GoogleFonts.quicksand(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: colors.badgeText,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Subject Title & Room
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.quicksand(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: colors.titleColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 6,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          timeStr,
                          style: GoogleFonts.quicksand(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: colors.subtitleColor,
                          ),
                        ),
                        if (settings.showRoomNumber && roomStr.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: colors.pillBg,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: colors.pillBorder),
                            ),
                            child: Text(
                              roomStr,
                              style: GoogleFonts.quicksand(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: colors.badgeText,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'SAFE BUFFER',
                    style: GoogleFonts.quicksand(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: colors.accentColor,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '$safeBunks bunks left',
                    style: GoogleFonts.quicksand(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: colors.subtitleColor,
                    ),
                  ),
                ],
              ),
            ],
          ),

          if (settings.directAttendanceMarking) ...[
            const SizedBox(height: 10),
            Container(
              height: 1,
              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => AppToast.success(context, 'Marked Present via Widget!'),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 28,
                      decoration: BoxDecoration(
                        color: colors.accentColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '✓ Present',
                        style: GoogleFonts.quicksand(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => AppToast.info(context, 'Marked Absent via Widget!'),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 28,
                      decoration: BoxDecoration(
                        color: colors.pillBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colors.pillBorder),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Absent',
                        style: GoogleFonts.quicksand(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: colors.subtitleColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSproutPillWidget({
    required WidgetSettingsEntity settings,
    required double statsPercentage,
    required String sampleClassTitle,
    required String sampleClassRoom,
    required AppThemeTokens tokens,
    required bool isDark,
  }) {
    final colors = _getSproutWidgetColors(
      settings: settings,
      tokens: tokens,
      isDark: isDark,
    );

    final title = sampleClassTitle.isNotEmpty ? sampleClassTitle : 'Machine Learning';
    final timeStr = settings.use24HourFormat ? '10:00' : '10:00 AM';
    final roomStr = sampleClassRoom.isNotEmpty ? sampleClassRoom : 'Room 302';
    final pctText = settings.privacyMode ? '***%' : '${statsPercentage.toStringAsFixed(1)}%';
    final initial = title.length >= 2 ? title.substring(0, 2).toUpperCase() : 'ML';

    final effectiveBg = colors.cardBg.withValues(alpha: settings.backgroundOpacity.clamp(0.0, 1.0));
    final borderColor = colors.cardBorder.withValues(alpha: settings.backgroundOpacity.clamp(0.2, 1.0));

    return Container(
      key: const ValueKey('preview_pill'),
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colors.badgeBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colors.badgeBorder, width: 1.0),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: GoogleFonts.quicksand(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: colors.badgeText,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.quicksand(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: colors.titleColor,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        settings.showRoomNumber && roomStr.isNotEmpty
                            ? '$timeStr • $roomStr'
                            : timeStr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.quicksand(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: colors.subtitleColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.badgeBg,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: colors.badgeBorder, width: 1.0),
                ),
                child: Text(
                  pctText,
                  style: GoogleFonts.quicksand(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: colors.badgeText,
                  ),
                ),
              ),
              if (settings.directAttendanceMarking) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => AppToast.success(context, 'Marked Present via Widget!'),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: colors.accentColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.check, size: 14, color: Colors.white),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSproutGaugeWidget({
    required WidgetSettingsEntity settings,
    required double statsPercentage,
    required int safeBunks,
    required AppThemeTokens tokens,
    required bool isDark,
  }) {
    final colors = _getSproutWidgetColors(
      settings: settings,
      tokens: tokens,
      isDark: isDark,
    );

    final pctText = settings.privacyMode ? '***%' : '${statsPercentage.toStringAsFixed(1)}%';
    final effectiveBg = colors.cardBg.withValues(alpha: settings.backgroundOpacity.clamp(0.0, 1.0));
    final borderColor = colors.cardBorder.withValues(alpha: settings.backgroundOpacity.clamp(0.2, 1.0));

    return InkWell(
      onTap: () => AppToast.info(context, 'Attendance target: 75%'),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        key: const ValueKey('preview_gauge'),
        width: 170,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: effectiveBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Circular progress ring
            SizedBox(
              width: 64,
              height: 64,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: (statsPercentage / 100.0).clamp(0.0, 1.0),
                    strokeWidth: 4.5,
                    strokeCap: StrokeCap.round,
                    color: colors.accentColor,
                    backgroundColor: colors.badgeBg,
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        pctText,
                        style: GoogleFonts.quicksand(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: colors.titleColor,
                        ),
                      ),
                      Text(
                        'ACTIVE',
                        style: GoogleFonts.quicksand(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: colors.accentColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Overall Care',
              style: GoogleFonts.quicksand(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: colors.titleColor,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              '$safeBunks safe misses',
              style: GoogleFonts.quicksand(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: colors.subtitleColor,
              ),
            ),

            const SizedBox(height: 8),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: colors.pillBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.pillBorder),
              ),
              alignment: Alignment.center,
              child: Text(
                'Target: 75%',
                style: GoogleFonts.quicksand(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: colors.accentColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSproutPresetChip(String label, double value, double current, AppThemeTokens tokens, bool isDark) {
    final isSelected = (current - value).abs() < 0.05;
    return InkWell(
      onTap: () {
        ref.read(widgetSettingsProvider.notifier).updateSettings(
              ref.read(widgetSettingsProvider).copyWith(backgroundOpacity: value),
            );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? tokens.primaryAccent
              : (isDark ? const Color(0xFF163424) : const Color(0xFFFAF7F2)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? tokens.primaryAccent : (isDark ? const Color(0xFF274C37) : const Color(0xFFE4ECE0)),
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.quicksand(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : tokens.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSproutThemeOptionTile({
    required WidgetThemeMode mode,
    required bool isSelected,
    required AppThemeTokens tokens,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final String letter;
    final Color badgeBg;
    final Color badgeText;
    final Color badgeBorder;
    final String title;
    final String subtitle;

    switch (mode) {
      case WidgetThemeMode.system:
        letter = 'A';
        badgeBg = isDark ? const Color(0xFF1B3A28) : const Color(0xFFEAF8E7);
        badgeText = tokens.primaryAccent;
        badgeBorder = isDark ? const Color(0xFF2D5A3E) : const Color(0xFFD7F0D6);
        title = 'Follow App Theme';
        subtitle = 'Sync with Cream/Forest Sprouts mode';
        break;
      case WidgetThemeMode.emerald:
        letter = 'L';
        badgeBg = isDark ? const Color(0xFF223528) : const Color(0xFFFAF7F2);
        badgeText = tokens.primaryAccent;
        badgeBorder = isDark ? const Color(0xFF2F4E3A) : const Color(0xFFE4ECE0);
        title = 'Always Light';
        subtitle = 'Clean porcelain & pastel green background';
        break;
      case WidgetThemeMode.amoled:
        letter = 'D';
        badgeBg = isDark ? const Color(0xFF0F1A12) : const Color(0xFF13261B);
        badgeText = const Color(0xFF8BC34A);
        badgeBorder = isDark ? const Color(0xFF1F3524) : const Color(0xFF274C37);
        title = 'Pure AMOLED Dark';
        subtitle = 'Deep forest black for OLED battery saving';
        break;
      case WidgetThemeMode.midnight:
        letter = 'M';
        badgeBg = const Color(0xFF1E293B);
        badgeText = const Color(0xFF60A5FA);
        badgeBorder = const Color(0xFF334155);
        title = 'Midnight Obsidian';
        subtitle = 'Deep night obsidian palette';
        break;
      case WidgetThemeMode.rose:
        letter = 'R';
        badgeBg = const Color(0xFF2A1620);
        badgeText = const Color(0xFFFB7185);
        badgeBorder = const Color(0xFF4C2034);
        title = 'Rose Velvet';
        subtitle = 'Pastel blush & wine accents';
        break;
      case WidgetThemeMode.sunset:
        letter = 'S';
        badgeBg = const Color(0xFF2A1E14);
        badgeText = const Color(0xFFF59E0B);
        badgeBorder = const Color(0xFF4C341F);
        title = 'Sunset Amber';
        subtitle = 'Warm terracotta & golden dawn';
        break;
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: badgeBorder, width: 1.0),
              ),
              child: Text(
                letter,
                style: GoogleFonts.quicksand(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: badgeText,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.quicksand(
                      fontSize: 13.5,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                      color: tokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: GoogleFonts.quicksand(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: tokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? tokens.primaryAccent : const Color(0xFFCBD5E1),
                  width: 2.0,
                ),
              ),
              padding: const EdgeInsets.all(2.5),
              child: isSelected
                  ? Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: tokens.primaryAccent,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSproutSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required AppThemeTokens tokens,
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
                  style: GoogleFonts.quicksand(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.quicksand(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: tokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: tokens.primaryAccent,
            activeTrackColor: tokens.primaryAccent.withValues(alpha: 0.4),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSproutStepRow(String stepNum, String text, AppThemeTokens tokens) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: tokens.primaryAccent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: tokens.primaryAccent.withValues(alpha: 0.25), width: 1.0),
          ),
          child: Text(
            stepNum,
            style: GoogleFonts.quicksand(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: tokens.primaryAccent,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.quicksand(
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w600,
              color: tokens.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
