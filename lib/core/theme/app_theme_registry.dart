import 'package:flutter/material.dart';
import '../constants/app_theme_tokens.dart';
import 'theme_asset_config.dart';

/// Navigation item definition for extensible themes
class ThemeNavItem {
  final String key;
  final String label;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String? iconAssetPath;

  const ThemeNavItem({
    required this.key,
    required this.label,
    required this.activeIcon,
    required this.inactiveIcon,
    this.iconAssetPath,
  });
}

/// Data definition for an extensible theme
class ThemeDefinition {
  final String id;
  final String title;
  final String subtitle;
  final String emoji;
  final List<Color> previewPalette;
  final AppThemeTokens lightTokens;
  final AppThemeTokens darkTokens;
  final Map<String, IconData> navIcons;
  final String mascotQuote;
  final bool isDefault;
  final ThemeAssetConfig assets;
  final List<ThemeNavItem> navItems;

  const ThemeDefinition({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.previewPalette,
    required this.lightTokens,
    required this.darkTokens,
    required this.navIcons,
    required this.mascotQuote,
    this.isDefault = false,
    this.assets = ThemeAssetConfig.classic,
    this.navItems = const [],
  });
}

/// Centralized registry of themes available in Attendly
class AppThemeRegistry {
  AppThemeRegistry._();

  static const String defaultThemeId = 'classic_indigo';

  static const List<ThemeDefinition> registeredThemes = [
    ThemeDefinition(
      id: 'classic_indigo',
      title: 'Classic Attendly',
      subtitle: 'Minimalist slate & indigo design tokens',
      emoji: '⚡',
      previewPalette: [Color(0xFF6366F1), Color(0xFF3B82F6), Color(0xFF0F172A)],
      lightTokens: AppThemeTokens.classicLight,
      darkTokens: AppThemeTokens.classicDark,
      navIcons: {
        'today': Icons.space_dashboard_rounded,
        'today_unselected': Icons.space_dashboard_outlined,
        'analytics': Icons.insights_rounded,
        'analytics_unselected': Icons.insights_outlined,
        'timetable': Icons.calendar_view_week_rounded,
        'timetable_unselected': Icons.calendar_view_week_outlined,
        'calendar': Icons.calendar_month_rounded,
        'calendar_unselected': Icons.calendar_month_outlined,
      },
      mascotQuote: 'Back to classic mode! Clean and focused ⚡',
      isDefault: true,
      assets: ThemeAssetConfig.classic,
      navItems: [
        ThemeNavItem(
          key: 'today',
          label: 'Today',
          activeIcon: Icons.space_dashboard_rounded,
          inactiveIcon: Icons.space_dashboard_outlined,
        ),
        ThemeNavItem(
          key: 'analytics',
          label: 'Analytics',
          activeIcon: Icons.insights_rounded,
          inactiveIcon: Icons.insights_outlined,
        ),
        ThemeNavItem(
          key: 'timetable',
          label: 'Timetable',
          activeIcon: Icons.calendar_view_week_rounded,
          inactiveIcon: Icons.calendar_view_week_outlined,
        ),
        ThemeNavItem(
          key: 'calendar',
          label: 'Calendar',
          activeIcon: Icons.calendar_month_rounded,
          inactiveIcon: Icons.calendar_month_outlined,
        ),
      ],
    ),
    ThemeDefinition(
      id: 'cute_sprout',
      title: 'Sprout & Mochi',
      subtitle: 'Sweet matcha green, marshmallow cream & rosy blush',
      emoji: '🌱',
      previewPalette: [Color(0xFF7CB342), Color(0xFFFFAAA6), Color(0xFFFAF7F2), Color(0xFF1B382B)],
      lightTokens: AppThemeTokens.cuteSproutLight,
      darkTokens: AppThemeTokens.cuteSproutDark,
      navIcons: {
        'today': Icons.spa_rounded,
        'today_unselected': Icons.spa_outlined,
        'analytics': Icons.donut_large_rounded,
        'analytics_unselected': Icons.donut_large_outlined,
        'timetable': Icons.auto_stories_rounded,
        'timetable_unselected': Icons.auto_stories_outlined,
        'calendar': Icons.event_note_rounded,
        'calendar_unselected': Icons.event_note_outlined,
      },
      mascotQuote: "Yay! Sprout mode activated! Let's track some classes together! 🌱",
      isDefault: false,
      assets: ThemeAssetConfig.cuteSprout,
      navItems: [
        ThemeNavItem(
          key: 'home',
          label: 'Home',
          activeIcon: Icons.home_rounded,
          inactiveIcon: Icons.home_outlined,
          iconAssetPath: 'assets/themes/sprout/navbar/nav_home.png',
        ),
        ThemeNavItem(
          key: 'timetable',
          label: 'Timetable',
          activeIcon: Icons.calendar_view_week_rounded,
          inactiveIcon: Icons.calendar_view_week_outlined,
          iconAssetPath: 'assets/themes/sprout/navbar/nav_timetable.png',
        ),
        ThemeNavItem(
          key: 'calendar',
          label: 'Calendar',
          activeIcon: Icons.calendar_month_rounded,
          inactiveIcon: Icons.calendar_month_outlined,
          iconAssetPath: 'assets/themes/sprout/navbar/nav_calendar.png',
        ),
        ThemeNavItem(
          key: 'analytics',
          label: 'Analytics',
          activeIcon: Icons.insights_rounded,
          inactiveIcon: Icons.insights_outlined,
          iconAssetPath: 'assets/themes/sprout/navbar/nav_analytics.png',
        ),
        ThemeNavItem(
          key: 'settings',
          label: 'Settings',
          activeIcon: Icons.settings_rounded,
          inactiveIcon: Icons.settings_outlined,
          iconAssetPath: 'assets/themes/sprout/navbar/nav_settings.png',
        ),
      ],
    ),
  ];

  static ThemeDefinition getTheme(String id) {
    return registeredThemes.firstWhere(
      (t) => t.id == id,
      orElse: () => registeredThemes.first,
    );
  }

  static bool isCute(String id) => id == 'cute_sprout';
}
