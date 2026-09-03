import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/ui/app_toast.dart';
import '../../../core/ui/theme_transition_wrapper.dart';
import '../../../domain/entities/attendance_stats.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/attendance_ring_widget.dart';

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
      subtitle: 'Signature ClassTrack aesthetic',
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentThemeMode = ref.watch(themeModeProvider);
    final overallStats = ref.watch(overallStatsProvider);

    final Color groupBg = isDark ? AppColors.cardDark : Colors.white;
    final Color groupBorder = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);
    final Color dividerColor = isDark ? AppColors.borderDark.withValues(alpha: 0.6) : const Color(0xFFF1F5F9);

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF8FAFC),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 22),
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          onPressed: () => Navigator.pop(context),
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

          // 4. DISPLAY OPTIONS
          _buildSectionHeader('Display Options', isDark),
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
                ],
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
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
                percentage: stats.overallPercentage,
                targetPercentage: stats.targetPercentage,
                size: 64,
                isDataEmpty: stats.totalHeld == 0,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${stats.overallPercentage.toStringAsFixed(1)}% Overall',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      stats.overallPercentage >= stats.targetPercentage
                          ? '● Above ${stats.targetPercentage.toInt()}% target'
                          : '▲ Needs attendance catch-up',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: stats.overallPercentage >= stats.targetPercentage
                            ? AppColors.presentGreen
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
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0), width: 0.8),
            ),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.accentIndigoLight,
                    borderRadius: BorderRadius.circular(1.5),
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
                    color: AppColors.presentGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Present',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.presentGreen,
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
