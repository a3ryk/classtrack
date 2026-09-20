import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_theme_tokens.dart';
import '../../../core/theme/app_theme_registry.dart';
import '../../../core/ui/app_toast.dart';
import '../../../core/ui/theme_transition_wrapper.dart';
import '../../../domain/entities/attendance_stats.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/app_theme_style_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/attendance_ring_widget.dart';
import 'widget_customization_screen.dart';

/// Data structure representing an aesthetic template theme
class AestheticTheme {
  final String id;
  final String title;
  final String subtitle;
  final String icon;
  final List<Color> palette;
  final bool isDefault;

  const AestheticTheme({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.palette,
    this.isDefault = false,
  });
}

class AppearanceScreen extends ConsumerStatefulWidget {
  const AppearanceScreen({super.key});

  @override
  ConsumerState<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends ConsumerState<AppearanceScreen> {
  String _activeThemeId = 'classic_indigo';
  final Set<String> _unlockedThemeIds = {'classic_indigo'};
  bool _pureOledBlack = false;
  static const bool _showAestheticTemplates = false;

  static const List<AestheticTheme> _curatedThemes = [
    AestheticTheme(
      id: 'classic_indigo',
      title: 'Classic Indigo',
      subtitle: 'Signature Attendly aesthetic',
      icon: '🎓',
      palette: [Color(0xFF6366F1), Color(0xFF3B82F6), Color(0xFF0F172A)],
      isDefault: true,
    ),
    AestheticTheme(
      id: 'sakura_blossom',
      title: 'Sakura Blossom',
      subtitle: 'Cute soft rose & pastel tones',
      icon: '🌸',
      palette: [Color(0xFFF43F5E), Color(0xFFFB7185), Color(0xFFFFF1F2)],
    ),
    AestheticTheme(
      id: 'matcha_study',
      title: 'Matcha Study',
      subtitle: 'Calm sage green & warm cream',
      icon: '🍵',
      palette: [Color(0xFF10B981), Color(0xFF34D399), Color(0xFFECFDF5)],
    ),
    AestheticTheme(
      id: 'cozy_mocha',
      title: 'Cozy Mocha',
      subtitle: 'Warm coffee latte & sepia notes',
      icon: '☕',
      palette: [Color(0xFFD97706), Color(0xFFF59E0B), Color(0xFFFEF3C7)],
    ),
    AestheticTheme(
      id: 'cyber_neon',
      title: 'Cyber Neon',
      subtitle: 'Electric violet & cyan OLED dark',
      icon: '🌌',
      palette: [Color(0xFF8B5CF6), Color(0xFF06B6D4), Color(0xFF090D16)],
    ),
  ];

  void _showThemeUnlockDialog(AestheticTheme theme, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Theme icon badge
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: theme.palette[0].withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.palette[0].withValues(alpha: 0.3)),
                ),
                alignment: Alignment.center,
                child: Text(theme.icon, style: const TextStyle(fontSize: 28)),
              ),
              const SizedBox(height: 14),

              Text(
                theme.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                theme.subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 20),

              // Palette swatches
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: theme.palette.map((color) {
                  return Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black.withValues(alpha: 0.1), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Ad unlock button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.play_circle_fill_rounded, size: 20),
                  label: const Text('Watch Short Ad to Unlock Theme'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    setState(() {
                      _unlockedThemeIds.add(theme.id);
                      _activeThemeId = theme.id;
                    });
                    AppToast.success(context, '✨ "${theme.title}" theme unlocked successfully!');
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>();
    final isCute = tokens?.isCute ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isCute && tokens != null) {
      return _buildSproutAppearanceView(context, tokens, isDark);
    }
    return _buildClassicAppearanceView(context, isDark);
  }

  Widget _buildClassicAppearanceView(BuildContext context, bool isDark) {
    final currentThemeMode = ref.watch(themeModeProvider);
    final overallStats = ref.watch(overallStatsProvider);

    final activeStyleId = ref.watch(appThemeStyleProvider);

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
          'Appearance',
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
          // 1. LIVE PREVIEW HERO CARD
          _buildSectionHeader('Live Preview', isDark),
          _buildLivePreviewHero(overallStats, isDark),

          const SizedBox(height: 24),

          // 2. COLOR MODE (VISUAL 3-CARD SELECTOR)
          _buildSectionHeader('Color Mode', isDark),
          _buildVisualThemeCards(currentThemeMode, isDark),

          const SizedBox(height: 24),

          // 3. THEME STYLES & AESTHETIC TEMPLATES (Disabled in UI until custom theme engine is built)
          if (_showAestheticTemplates) ...[
            _buildSectionHeader('Aesthetic Templates', isDark),
            RepaintBoundary(
              child: Container(
                decoration: BoxDecoration(
                  color: groupBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: groupBorder, width: 0.8),
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < _curatedThemes.length; i++) ...[
                      _buildAestheticThemeTile(_curatedThemes[i], isDark),
                      if (i < _curatedThemes.length - 1)
                        Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // 4. THEME STYLE (EXTENSIBLE REGISTRY)
          _buildSectionHeader('Theme Style', isDark),
          _buildThemeStyleCards(activeStyleId, isDark),

          const SizedBox(height: 24),

          // 5. DISPLAY & WIDGETS
          _buildSectionHeader('Display & Widgets', isDark),
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
                    title: 'Pure OLED Black',
                    subtitle: 'Uses true #000000 in dark mode for AMOLED battery savings',
                    value: _pureOledBlack,
                    isDark: isDark,
                    onChanged: (val) {
                      setState(() => _pureOledBlack = val);
                      AppToast.info(context, 'Pure OLED black ${val ? "enabled" : "disabled"}');
                    },
                  ),
                  Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                  _buildSwitchTile(
                    title: 'Match Device Appearance',
                    subtitle: 'Automatically syncs with phone light/dark schedule',
                    value: currentThemeMode == ThemeMode.system,
                    isDark: isDark,
                    onChanged: (val) {
                      ref.read(themeModeProvider.notifier).setThemeMode(
                            val ? ThemeMode.system : (isDark ? ThemeMode.dark : ThemeMode.light),
                          );
                    },
                  ),
                  Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const WidgetCustomizationScreen()),
                        );
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Home Screen Widgets',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Configure live previews, themes, and transparency',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
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
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSproutAppearanceView(
    BuildContext context,
    AppThemeTokens tokens,
    bool isDark,
  ) {
    final currentThemeMode = ref.watch(themeModeProvider);
    final overallStats = ref.watch(overallStatsProvider);
    final activeStyleId = ref.watch(appThemeStyleProvider);

    final Color cardBg = isDark ? const Color(0xFF1B3626) : Colors.white;
    final Color cardBorder = isDark ? const Color(0xFF274C37) : const Color(0xFFE4ECE0);
    final Color dividerColor = isDark ? const Color(0xFF274C37) : const Color(0xFFF0ECE1);
    final Color scaffoldBg = tokens.scaffoldBg;

    void navigateBack() {
      if (Navigator.of(context).canPop()) {
        ref.read(mainShellTabProvider.notifier).state = 4;
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        navigateBack();
      },
      child: Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(
          backgroundColor: scaffoldBg,
          elevation: 0,
          scrolledUnderElevation: 0,
          leadingWidth: 100,
          leading: InkWell(
            onTap: navigateBack,
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
          'Appearance',
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
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          // 1. LIVE PREVIEW (No emoji in heading)
          _buildSproutSectionHeader('Live Preview', tokens, topPadding: 4),
          _buildSproutLivePreviewHero(overallStats, tokens, cardBg, cardBorder, isDark),

          // 2. COLOR MODE (Visual 3-Card Selector with preserved transition ripple)
          _buildSproutSectionHeader('Color Mode', tokens),
          _buildSproutVisualThemeCards(currentThemeMode, tokens, isDark),

          // 3. THEME STYLE (Extensible Registry with preserved transition ripple)
          _buildSproutSectionHeader('Theme Style', tokens),
          _buildSproutThemeStyleCards(activeStyleId, tokens, isDark),

          // 4. DISPLAY & WIDGETS (Unified Card with 56px indented dividers & smooth switches)
          _buildSproutSectionHeader('Display & Widgets', tokens),
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
                  icon: Icons.nightlight_round,
                  iconBg: isDark ? const Color(0xFF2E1065).withValues(alpha: 0.5) : const Color(0xFFEDE9FE),
                  iconColor: isDark ? const Color(0xFFC084FC) : const Color(0xFF7C3AED),
                  title: 'Pure OLED Black',
                  subtitle: 'True #000000 in dark mode for battery savings',
                  badge: 'AMOLED',
                  value: _pureOledBlack,
                  tokens: tokens,
                  isDark: isDark,
                  onChanged: (val) {
                    setState(() => _pureOledBlack = val);
                    AppToast.info(context, 'Pure OLED black ${val ? "enabled" : "disabled"}');
                  },
                ),
                Divider(height: 1, indent: 56, endIndent: 16, color: dividerColor),
                _buildSproutSwitchTile(
                  icon: Icons.schedule_rounded,
                  iconBg: isDark ? const Color(0xFF3B2D12) : const Color(0xFFFEF3C7),
                  iconColor: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                  title: 'Match System Schedule',
                  subtitle: 'Sync automatically with device day & night mode',
                  value: currentThemeMode == ThemeMode.system,
                  tokens: tokens,
                  isDark: isDark,
                  onChanged: (val) {
                    ref.read(themeModeProvider.notifier).setThemeMode(
                          val ? ThemeMode.system : (isDark ? ThemeMode.dark : ThemeMode.light),
                        );
                  },
                ),
                Divider(height: 1, indent: 56, endIndent: 16, color: dividerColor),
                _buildSproutActionTile(
                  icon: Icons.widgets_rounded,
                  iconBg: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                  iconColor: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                  title: 'Home Screen Widgets',
                  subtitle: 'Configure live previews, styles & transparency',
                  tokens: tokens,
                  isDark: isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const WidgetCustomizationScreen()),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 36),
        ],
      ),
    ),
  );
}

  Widget _buildSproutSectionHeader(
    String title,
    AppThemeTokens tokens, {
    double topPadding = 20,
    double bottomPadding = 8,
  }) {
    return Padding(
      padding: EdgeInsets.only(left: 4, top: topPadding, bottom: bottomPadding),
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

  Widget _buildSproutLivePreviewHero(
    OverallAttendanceStats stats,
    AppThemeTokens tokens,
    Color cardBg,
    Color cardBorder,
    bool isDark,
  ) {
    final double displayPercentage = stats.totalHeld == 0 ? 100.0 : stats.overallPercentage;
    final double targetPercentage = stats.targetPercentage;
    final bool isAboveTarget = displayPercentage >= targetPercentage;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cardBorder, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AttendanceRingWidget(
                percentage: displayPercentage,
                targetPercentage: targetPercentage,
                size: 64,
                isDataEmpty: false,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${displayPercentage.toStringAsFixed(1)}% Overall',
                      style: GoogleFonts.quicksand(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isAboveTarget ? tokens.presentColor : const Color(0xFFEF4444),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            isAboveTarget
                                ? 'Above ${targetPercentage.toInt()}% target · Thriving 🌱'
                                : 'Needs attendance catch-up',
                            style: GoogleFonts.quicksand(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: isAboveTarget ? tokens.presentColor : const Color(0xFFEF4444),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Sample class session card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF163424) : const Color(0xFFFAF7F2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF274C37) : const Color(0xFFE4ECE0),
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 28,
                  decoration: BoxDecoration(
                    color: tokens.primaryAccent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CS201 · Operating Systems',
                        style: GoogleFonts.quicksand(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: tokens.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 1.5),
                      Text(
                        '10:00 AM – 11:00 AM · Hall 4',
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF164130) : const Color(0xFFEAF8E7),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isDark ? const Color(0xFF2C5B45) : const Color(0xFFD7F0D6),
                      width: 1.0,
                    ),
                  ),
                  child: Text(
                    'Present',
                    style: GoogleFonts.quicksand(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? const Color(0xFFEAF8EA) : const Color(0xFF1E6B3F),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSproutVisualThemeCards(ThemeMode currentMode, AppThemeTokens tokens, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildSproutVisualThemeCard(
            title: 'Light',
            mode: ThemeMode.light,
            isSelected: currentMode == ThemeMode.light,
            tokens: tokens,
            isDark: isDark,
            mockBg: const Color(0xFFFAF7F2),
            mockCardBg: Colors.white,
            mockAccent: const Color(0xFF7CB342),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSproutVisualThemeCard(
            title: 'Dark',
            mode: ThemeMode.dark,
            isSelected: currentMode == ThemeMode.dark,
            tokens: tokens,
            isDark: isDark,
            mockBg: const Color(0xFF13261B),
            mockCardBg: const Color(0xFF1B3626),
            mockAccent: const Color(0xFF8BC34A),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSproutVisualThemeCard(
            title: 'System',
            mode: ThemeMode.system,
            isSelected: currentMode == ThemeMode.system,
            tokens: tokens,
            isDark: isDark,
            isSplit: true,
            mockBg: const Color(0xFFFAF7F2),
            mockCardBg: Colors.white,
            mockAccent: const Color(0xFF7CB342),
          ),
        ),
      ],
    );
  }

  Widget _buildSproutVisualThemeCard({
    required String title,
    required ThemeMode mode,
    required bool isSelected,
    required AppThemeTokens tokens,
    required bool isDark,
    required Color mockBg,
    required Color mockCardBg,
    required Color mockAccent,
    bool isSplit = false,
  }) {
    final cardBg = isDark ? const Color(0xFF1B3626) : Colors.white;
    final borderColor = isSelected ? tokens.primaryAccent : (isDark ? const Color(0xFF274C37) : const Color(0xFFE4ECE0));

    return Builder(
      builder: (cardContext) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) {
            if (ThemeTransition.isAnimating) return;
            final currentMode = ref.read(themeModeProvider);
            if (mode != currentMode) {
              Offset? center;
              final box = cardContext.findRenderObject() as RenderBox?;
              if (box != null && box.hasSize) {
                final pos = box.localToGlobal(Offset.zero);
                center = Offset(pos.dx + box.size.width / 2, pos.dy + box.size.height / 2);
              }

              ThemeTransition.switchTheme(
                context,
                ref,
                mode,
                origin: center,
              );
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: borderColor,
                width: isSelected ? 2.0 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? tokens.primaryAccent.withValues(alpha: isDark ? 0.3 : 0.15)
                      : Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: isSelected ? 8 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Mini viewport
                Container(
                  height: 68,
                  decoration: BoxDecoration(
                    color: mockBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF274C37) : const Color(0xFFE4ECE0),
                      width: 0.8,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: isSplit
                      ? Row(
                          children: [
                            // Light half
                            Expanded(
                              child: Container(
                                color: const Color(0xFFFAF7F2),
                                padding: const EdgeInsets.all(6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E3526),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFFE4ECE0), width: 0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Dark half
                            Expanded(
                              child: Container(
                                color: const Color(0xFF13261B),
                                padding: const EdgeInsets.all(6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEAF8EA),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1B3626),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFF274C37), width: 0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : Padding(
                          padding: const EdgeInsets.all(7),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 22,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: (isDark ? const Color(0xFFEAF8EA) : const Color(0xFF1E3526)).withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                height: 26,
                                decoration: BoxDecoration(
                                  color: mockCardBg,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: (isDark ? const Color(0xFF274C37) : const Color(0xFFE4ECE0)),
                                    width: 0.8,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  width: 3,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: mockAccent,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 8),

                // Radio & Label
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? tokens.primaryAccent : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? tokens.primaryAccent : tokens.textMuted,
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: isSelected
                          ? const Icon(Icons.check, size: 10, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      title,
                      style: GoogleFonts.quicksand(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? tokens.textPrimary : tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSproutThemeStyleCards(String activeStyleId, AppThemeTokens tokens, bool isDark) {
    final themes = AppThemeRegistry.registeredThemes;

    return Column(
      children: [
        for (int i = 0; i < themes.length; i++) ...[
          _buildSproutThemeStyleCard(themes[i], activeStyleId == themes[i].id, tokens, isDark),
          if (i < themes.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildSproutThemeStyleCard(ThemeDefinition theme, bool isSelected, AppThemeTokens tokens, bool isDark) {
    final primaryColor = theme.previewPalette.first;
    final cardBg = isDark ? const Color(0xFF1B3626) : Colors.white;
    final borderColor = isSelected
        ? tokens.primaryAccent
        : (isDark ? const Color(0xFF274C37) : const Color(0xFFE4ECE0));

    return Builder(
      builder: (cardContext) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) {
            if (ThemeTransition.isAnimating) return;
            final activeStyleId = ref.read(appThemeStyleProvider);
            if (theme.id != activeStyleId) {
              Offset? center;
              final box = cardContext.findRenderObject() as RenderBox?;
              if (box != null && box.hasSize) {
                final pos = box.localToGlobal(Offset.zero);
                center = Offset(pos.dx + box.size.width / 2, pos.dy + box.size.height / 2);
              }

              ThemeTransition.switchThemeStyle(
                context,
                ref,
                theme.id,
                origin: center,
              );
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: borderColor,
                width: isSelected ? 2.0 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? tokens.primaryAccent.withValues(alpha: isDark ? 0.3 : 0.12)
                      : Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: isSelected ? 8 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Mascot or Icon Badge
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 46,
                    height: 46,
                    color: theme.id == 'cute_sprout'
                        ? const Color(0xFFFAF7F2)
                        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF2FF)),
                    alignment: Alignment.center,
                    child: theme.id == 'cute_sprout'
                        ? Image.asset(
                            'assets/images/mascot_sprout.jpg',
                            fit: BoxFit.cover,
                            width: 46,
                            height: 46,
                            errorBuilder: (context, error, stackTrace) => Text(
                              theme.emoji,
                              style: const TextStyle(fontSize: 22),
                            ),
                          )
                        : Text(
                            theme.emoji,
                            style: const TextStyle(fontSize: 22),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                // Title and details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              theme.title,
                              style: GoogleFonts.quicksand(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: tokens.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? primaryColor.withValues(alpha: 0.15)
                                  : (isDark ? const Color(0xFF163424) : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              theme.id == 'cute_sprout' ? 'Cute 🌱' : 'Default ⚡',
                              style: GoogleFonts.quicksand(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? primaryColor
                                    : tokens.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        theme.subtitle,
                        style: GoogleFonts.quicksand(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: tokens.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Palette color swatches
                      Row(
                        children: [
                          for (final color in theme.previewPalette) ...[
                            Container(
                              width: 13,
                              height: 13,
                              margin: const EdgeInsets.only(right: 5),
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark ? Colors.white24 : Colors.black12,
                                  width: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Radio indicator
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? tokens.primaryAccent : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? tokens.primaryAccent
                          : (isDark ? const Color(0xFF274C37) : const Color(0xFFCBD5E1)),
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: isSelected
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSproutSwitchTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required AppThemeTokens tokens,
    required bool isDark,
    required ValueChanged<bool> onChanged,
    String? badge,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(13),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: GoogleFonts.quicksand(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: tokens.textPrimary,
                        ),
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2E1065) : const Color(0xFFF3E8FF),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          badge,
                          style: GoogleFonts.quicksand(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: isDark ? const Color(0xFFC084FC) : const Color(0xFF7E22CE),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 1.5),
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
            activeThumbColor: Colors.white,
            activeTrackColor: tokens.primaryAccent,
            onChanged: (val) {
              HapticFeedback.lightImpact();
              onChanged(val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSproutActionTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required AppThemeTokens tokens,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(13),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.quicksand(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 1.5),
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
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: tokens.textMuted,
              ),
            ],
          ),
        ),
      ),
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
          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
        ),
      ),
    );
  }

  Widget _buildLivePreviewHero(OverallAttendanceStats stats, bool isDark) {
    final double displayPercentage = stats.totalHeld == 0 ? 100.0 : stats.overallPercentage;
    final double targetPercentage = stats.targetPercentage;
    final bool isAboveTarget = displayPercentage >= targetPercentage;
    final tokens = Theme.of(context).extension<AppThemeTokens>();
    final isCute = tokens?.isCute ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(isCute ? 20 : 16),
        border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AttendanceRingWidget(
                percentage: displayPercentage,
                targetPercentage: targetPercentage,
                size: 64,
                isDataEmpty: false,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${displayPercentage.toStringAsFixed(1)}% Overall',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isAboveTarget
                          ? '● Above ${targetPercentage.toInt()}% target'
                          : '▲ Needs attendance catch-up',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isAboveTarget
                            ? (isCute ? (tokens?.presentColor ?? AppColors.presentGreen) : AppColors.presentGreen)
                            : const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Sample class session card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(isCute ? 14 : 10),
              border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0), width: 0.8),
            ),
            child: Row(
              children: [
                Container(
                  width: isCute ? 4 : 3,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isCute ? (tokens?.primaryAccent ?? const Color(0xFF7CB342)) : AppColors.accentIndigoLight,
                    borderRadius: BorderRadius.circular(isCute ? 999 : 1.5),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CS201 · Operating Systems',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 1.5),
                      Text(
                        '10:00 AM – 11:00 AM · Room 402',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: (isCute ? (tokens?.presentColor ?? AppColors.presentGreen) : AppColors.presentGreen).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(isCute ? 999 : 6),
                  ),
                  child: Text(
                    'Present',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: isCute ? (tokens?.presentColor ?? AppColors.presentGreen) : AppColors.presentGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeStyleCards(String activeStyleId, bool isDark) {
    final themes = AppThemeRegistry.registeredThemes;

    return Column(
      children: [
        for (int i = 0; i < themes.length; i++) ...[
          _buildThemeStyleCard(themes[i], activeStyleId == themes[i].id, isDark),
          if (i < themes.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildThemeStyleCard(ThemeDefinition theme, bool isSelected, bool isDark) {
    final primaryColor = theme.previewPalette.first;
    final cardBg = isDark ? AppColors.cardDark : Colors.white;
    final borderColor = isSelected
        ? primaryColor
        : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0));

    return Builder(
      builder: (cardContext) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (ThemeTransition.isAnimating) return;
            final activeStyleId = ref.read(appThemeStyleProvider);
            if (theme.id != activeStyleId) {
              Offset? center;
              final box = cardContext.findRenderObject() as RenderBox?;
              if (box != null && box.hasSize) {
                final pos = box.localToGlobal(Offset.zero);
                center = Offset(pos.dx + box.size.width / 2, pos.dy + box.size.height / 2);
              }

              ThemeTransition.switchThemeStyle(
                context,
                ref,
                theme.id,
                origin: center,
              );
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: isSelected ? 1.8 : 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? primaryColor.withValues(alpha: isDark ? 0.25 : 0.12)
                      : Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                  blurRadius: isSelected ? 8 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Mascot or Icon Badge
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 46,
                    height: 46,
                    color: theme.id == 'cute_sprout'
                        ? const Color(0xFFFAF7F2)
                        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF2FF)),
                    alignment: Alignment.center,
                    child: theme.id == 'cute_sprout'
                        ? Image.asset(
                            'assets/images/mascot_sprout.jpg',
                            fit: BoxFit.cover,
                            width: 46,
                            height: 46,
                            errorBuilder: (context, error, stackTrace) => Text(
                              theme.emoji,
                              style: const TextStyle(fontSize: 22),
                            ),
                          )
                        : Text(
                            theme.emoji,
                            style: const TextStyle(fontSize: 22),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                // Title and details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              theme.title,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? primaryColor.withValues(alpha: 0.15)
                                  : (isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              theme.id == 'cute_sprout' ? 'Cute 🌱' : 'Default ⚡',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? primaryColor
                                    : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        theme.subtitle,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Palette color swatches
                      Row(
                        children: [
                          for (final color in theme.previewPalette) ...[
                            Container(
                              width: 13,
                              height: 13,
                              margin: const EdgeInsets.only(right: 5),
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark ? Colors.white24 : Colors.black12,
                                  width: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Radio / Checkmark indicator
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? primaryColor : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? primaryColor
                          : (isDark ? AppColors.textMutedDark : const Color(0xFFCBD5E1)),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 15, color: Colors.white)
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVisualThemeCards(ThemeMode currentMode, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildVisualThemeCard(
            title: 'Light',
            mode: ThemeMode.light,
            isSelected: currentMode == ThemeMode.light,
            isDark: isDark,
            mockBg: const Color(0xFFF8FAFC),
            mockCardBg: Colors.white,
            mockText: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildVisualThemeCard(
            title: 'Dark',
            mode: ThemeMode.dark,
            isSelected: currentMode == ThemeMode.dark,
            isDark: isDark,
            mockBg: const Color(0xFF0B0F17),
            mockCardBg: const Color(0xFF161E2E),
            mockText: Colors.white,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildVisualThemeCard(
            title: 'System',
            mode: ThemeMode.system,
            isSelected: currentMode == ThemeMode.system,
            isDark: isDark,
            isSplit: true,
            mockBg: const Color(0xFFF8FAFC),
            mockCardBg: Colors.white,
            mockText: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildVisualThemeCard({
    required String title,
    required ThemeMode mode,
    required bool isSelected,
    required bool isDark,
    required Color mockBg,
    required Color mockCardBg,
    required Color mockText,
    bool isSplit = false,
  }) {
    return Builder(
      builder: (cardContext) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) {
            if (ThemeTransition.isAnimating) return;
            final currentMode = ref.read(themeModeProvider);
            if (mode != currentMode) {
              Offset? center;
              final box = cardContext.findRenderObject() as RenderBox?;
              if (box != null && box.hasSize) {
                final pos = box.localToGlobal(Offset.zero);
                center = Offset(pos.dx + box.size.width / 2, pos.dy + box.size.height / 2);
              }

              ThemeTransition.switchTheme(
                context,
                ref,
                mode,
                origin: center,
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? AppColors.accentIndigoLight : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? AppColors.accentIndigoLight.withValues(alpha: isDark ? 0.25 : 0.15)
                      : Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Mini preview viewport
                Container(
                  height: 68,
                  decoration: BoxDecoration(
                    color: mockBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0), width: 0.5),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: isSplit
                      ? Row(
                          children: [
                            // Light half
                            Expanded(
                              child: Container(
                                color: const Color(0xFFF8FAFC),
                                padding: const EdgeInsets.all(6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(width: 16, height: 4, decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(2))),
                                    const SizedBox(height: 6),
                                    Container(height: 20, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                                  ],
                                ),
                              ),
                            ),
                            // Dark half
                            Expanded(
                              child: Container(
                                color: const Color(0xFF0B0F17),
                                padding: const EdgeInsets.all(6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(width: 16, height: 4, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2))),
                                    const SizedBox(height: 6),
                                    Container(height: 20, decoration: BoxDecoration(color: const Color(0xFF161E2E), borderRadius: BorderRadius.circular(4))),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : Padding(
                          padding: const EdgeInsets.all(7),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 22,
                                height: 4,
                                decoration: BoxDecoration(color: mockText.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(2)),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                height: 26,
                                decoration: BoxDecoration(
                                  color: mockCardBg,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: mockText.withValues(alpha: 0.1), width: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 8),

                // Radio & Label
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      size: 15,
                      color: isSelected ? AppColors.accentIndigoLight : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? (isDark ? Colors.white : const Color(0xFF0F172A))
                            : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAestheticThemeTile(AestheticTheme theme, bool isDark) {
    final isUnlocked = _unlockedThemeIds.contains(theme.id);
    final isActive = _activeThemeId == theme.id;

    return InkWell(
      onTap: () {
        if (isUnlocked) {
          setState(() => _activeThemeId = theme.id);
          AppToast.info(context, 'Theme "${theme.title}" selected');
        } else {
          _showThemeUnlockDialog(theme, isDark);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Emoji badge
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: theme.palette[0].withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(theme.icon, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 12),

            // Title & subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    theme.title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    theme.subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),

            // Palette swatches
            Row(
              mainAxisSize: MainAxisSize.min,
              children: theme.palette.map((c) {
                return Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black.withValues(alpha: 0.1), width: 0.5),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(width: 10),

            // Badge (Active / Ad Unlock)
            if (isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: AppColors.presentGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Active',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.presentGreen,
                  ),
                ),
              )
            else if (!isUnlocked)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline_rounded, size: 11, color: Color(0xFFD97706)),
                    SizedBox(width: 3),
                    Text(
                      'Unlock',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

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
}
