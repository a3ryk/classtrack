# Attendly Theme Customization & Asset Management Guide

Attendly features a modular, configuration-driven theme and asset system. Developers can introduce complete custom themes—including custom 3D navigation icons, screen-specific mascot illustrations, and fine-grained color palettes—without editing core widget code.

---

## 1. Architecture Overview

Themes in Attendly are configured through four decoupled components:

```
                  ┌──────────────────────────────┐
                  │       ThemeDefinition        │
                  ├──────────────────────────────┤
                  │ • id                         │
                  │ • title & subtitle           │
                  │ • previewPalette             │
                  │ • mascotQuote                │
                  └───────┬───────────────┬──────┘
                          │               │
            ┌─────────────┴─────┐   ┌─────┴──────────────────┐
            │   AppThemeTokens  │   │    ThemeAssetConfig    │
            ├───────────────────┤   ├────────────────────────┤
            │ • scaffoldBg      │   │ • todayMascot          │
            │ • cardBg / border │   │ • calendarMascot       │
            │ • primaryAccent   │   │ • analyticsMascot      │
            │ • navBgColor      │   │ • settingsMascot       │
            │ • navActivePill   │   │ • holidayMascot        │
            │ • ...             │   │ • emptyStateMascot     │
            └───────────────────┘   │ • navHome, navTimetable│
                                    └────────────────────────┘
```

1. **`AppThemeTokens`** (`lib/core/constants/app_theme_tokens.dart`):  
   Defines color palettes, border radii, navigation capsule colors, and elevation tokens for both Light and Dark modes.
2. **`ThemeAssetConfig`** (`lib/core/theme/theme_asset_config.dart`):  
   Typed registry for screen-specific mascot artwork and 3D navigation icons.
3. **`ThemeNavItem`** (`lib/core/theme/app_theme_registry.dart`):  
   Defines tab items with labels, vector fallbacks, and 3D asset paths.
4. **`AppThemeRegistry`** (`lib/core/theme/app_theme_registry.dart`):  
   Central catalog of themes registered in the app.

---

## 2. Directory Structure Convention

To prevent asset clutter and naming collisions, all theme assets are strictly organized into designated theme folders:

```
assets/
└── themes/
    ├── sprout/
    │   ├── mascots/
    │   │   ├── mascot_sprout.jpg       # Today header mascot
    │   │   ├── mascot_calendar.png     # (Optional) Calendar mascot
    │   │   └── mascot_holiday.png      # (Optional) Holiday banner mascot
    │   └── navbar/
    │       ├── nav_home.png            # 3D Home tab icon
    │       ├── nav_timetable.png       # 3D Timetable tab icon
    │       ├── nav_calendar.png        # 3D Calendar tab icon
    │       ├── nav_analytics.png       # 3D Analytics tab icon
    │       └── nav_settings.png        # 3D Settings tab icon
    └── {new_theme_id}/
        ├── mascots/
        └── navbar/
```

### Registering Assets in `pubspec.yaml`
When creating a new theme folder, add directory entries to `pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/images/
    - assets/themes/sprout/navbar/
    - assets/themes/sprout/mascots/
    - assets/themes/{new_theme_id}/navbar/
    - assets/themes/{new_theme_id}/mascots/
```

---

## 3. Configuring Screen-Specific Assets (`ThemeAssetConfig`)

Different screens can display unique theme artwork. The slots in `ThemeAssetConfig` allow you to customize each screen individually:

| Slot | Destination | Default Fallback |
| :--- | :--- | :--- |
| `todayMascot` | Header greeting on the **Today** screen | Seedling emoji (`🌱`) |
| `calendarMascot` | Header or empty state on **Calendar** | `todayMascot` |
| `analyticsMascot` | Overview card on **Analytics** | `todayMascot` |
| `settingsMascot` | Profile card on **Settings** | `todayMascot` |
| `holidayMascot` | Banner shown on active college holidays | Holiday emoji (`🏖️`) |
| `emptyStateMascot` | Card shown when no classes are scheduled | `todayMascot` |
| `peekMascot` | Interactive side-peek slide-in overlay | `todayMascot` |
| `navHome` | Tab 1 3D Navigation Icon | Vector `Icons.home_rounded` |
| `navTimetable` | Tab 2 3D Navigation Icon | Vector `Icons.calendar_view_week` |
| `navCalendar` | Tab 3 3D Navigation Icon | Vector `Icons.calendar_month` |
| `navAnalytics` | Tab 4 3D Navigation Icon | Vector `Icons.insights` |
| `navSettings` | Tab 5 3D Navigation Icon | Vector `Icons.settings` |

---

## 4. Step-by-Step: Adding a New Custom Theme

Follow these 3 steps to create a new theme:

### Step 1: Add Assets
Create `assets/themes/{my_theme}/navbar/` and `assets/themes/{my_theme}/mascots/` and place high-resolution PNGs/JPGs (256×256 recommended for navbar icons).

### Step 2: Define `ThemeAssetConfig`
In `lib/core/theme/theme_asset_config.dart`, create your asset preset:

```dart
static const ThemeAssetConfig myTheme = ThemeAssetConfig(
  todayMascot: 'assets/themes/my_theme/mascots/mascot.png',
  emptyStateMascot: 'assets/themes/my_theme/mascots/mascot_rest.png',
  navHome: 'assets/themes/my_theme/navbar/nav_home.png',
  navTimetable: 'assets/themes/my_theme/navbar/nav_timetable.png',
  navCalendar: 'assets/themes/my_theme/navbar/nav_calendar.png',
  navAnalytics: 'assets/themes/my_theme/navbar/nav_analytics.png',
  navSettings: 'assets/themes/my_theme/navbar/nav_settings.png',
);
```

### Step 3: Register in `AppThemeRegistry`
In `lib/core/theme/app_theme_registry.dart`, append your theme definition to `registeredThemes`:

```dart
ThemeDefinition(
  id: 'my_theme',
  title: 'My Custom Theme',
  subtitle: 'Fresh aesthetic and playful 3D icons',
  emoji: '✨',
  previewPalette: [Color(0xFF...), Color(0xFF...)],
  lightTokens: AppThemeTokens(
    themeStyleId: 'my_theme',
    isCute: true,
    scaffoldBg: Color(0xFFFBFBFD),
    cardBg: Colors.white,
    cardBorder: Color(0xFFE2E8F0),
    cardRadius: 20.0,
    buttonRadius: 12.0,
    sheetRadius: 24.0,
    primaryAccent: Color(0xFF6366F1),
    secondaryAccent: Color(0xFF3B82F6),
    textPrimary: Color(0xFF1E293B),
    textSecondary: Color(0xFF64748B),
    textMuted: Color(0xFF94A3B8),
    presentColor: Color(0xFF22C55E),
    presentContainer: Color(0xFFDCFCE7),
    absentColor: Color(0xFFEF4444),
    absentContainer: Color(0xFFFEE2E2),
    cancelledColor: Color(0xFF8B5CF6),
    cancelledContainer: Color(0xFFEDE9FE),
    safeBadgeBg: Color(0xFFDCFCE7),
    safeBadgeText: Color(0xFF15803D),
    navBgColor: Color(0xFFFFFFFF),
    navActivePillColor: Color(0xFFEEF2FF),
    navPillBorderColor: Color(0xFFC7D2FE),
    navBorderColor: Color(0xFFE2E8F0),
    navActiveTextColor: Color(0xFF4F46E5),
    navInactiveTextColor: Color(0xFF94A3B8),
    navActiveIconColor: Color(0xFF4F46E5),
    navInactiveIconColor: Color(0xFF94A3B8),
    navShadowColor: Color(0x0F000000),
  ),
  darkTokens: ...,
  assets: ThemeAssetConfig.myTheme,
  navItems: [
    ThemeNavItem(
      key: 'home',
      label: 'Home',
      activeIcon: Icons.home_rounded,
      inactiveIcon: Icons.home_outlined,
      iconAssetPath: 'assets/themes/my_theme/navbar/nav_home.png',
    ),
    // ...
  ],
  mascotQuote: 'Ready to study together! ✨',
)
```

The app will automatically surface the theme in the theme selector, switch the navigation layout, render the 3D icons, and display the mascot illustrations across all supported screens.
