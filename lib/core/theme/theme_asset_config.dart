/// Configurable illustration and 3D navigation asset slots for themes
class ThemeAssetConfig {
  /// Mascot artwork displayed on the Today screen header
  final String todayMascot;

  /// Mascot artwork displayed on the Timetable screen
  final String? timetableMascot;

  /// Mascot artwork displayed on the Calendar screen
  final String? calendarMascot;

  /// Mascot artwork displayed on the Analytics screen
  final String? analyticsMascot;

  /// Mascot artwork displayed on the Settings screen
  final String? settingsMascot;

  /// Mascot artwork displayed when a holiday is active
  final String? holidayMascot;

  /// Mascot artwork displayed when no classes are scheduled
  final String? emptyStateMascot;

  /// Mascot artwork displayed on the side-peek overlay
  final String? peekMascot;

  /// Mascot artwork displayed during evening hours
  final String? eveningMascot;

  /// Mascot artwork displayed during night hours
  final String? nightMascot;

  /// 3D navigation icon asset paths (falls back to Material Icon if null)
  final String? navHome;
  final String? navTimetable;
  final String? navCalendar;
  final String? navAnalytics;
  final String? navSettings;

  const ThemeAssetConfig({
    required this.todayMascot,
    this.eveningMascot,
    this.nightMascot,
    this.timetableMascot,
    this.calendarMascot,
    this.analyticsMascot,
    this.settingsMascot,
    this.holidayMascot,
    this.emptyStateMascot,
    this.peekMascot,
    this.navHome,
    this.navTimetable,
    this.navCalendar,
    this.navAnalytics,
    this.navSettings,
  });

  /// Default asset config for classic theme
  static const ThemeAssetConfig classic = ThemeAssetConfig(
    todayMascot: '',
  );

  /// Asset config for Sprout & Mochi theme
  static const ThemeAssetConfig cuteSprout = ThemeAssetConfig(
    todayMascot: 'assets/themes/sprout/mascots/sprout_home_wave.png',
    eveningMascot: 'assets/themes/sprout/mascots/sprout_home_evening.png',
    nightMascot: 'assets/themes/sprout/mascots/sprout_home_night.png',
    timetableMascot: 'assets/themes/sprout/mascots/sprout_timetable_clock.png',
    analyticsMascot: 'assets/themes/sprout/mascots/sprout_analytics_graph.png',
    settingsMascot: 'assets/themes/sprout/mascots/sprout_settings_reading.png',
    holidayMascot: 'assets/themes/sprout/mascots/sprout_home_star.png',
    emptyStateMascot: 'assets/themes/sprout/mascots/sprout_home_checklist.png',
    peekMascot: 'assets/themes/sprout/mascots/sprout_home_wave.png',
    navHome: 'assets/themes/sprout/navbar/nav_home.png',
    navTimetable: 'assets/themes/sprout/navbar/nav_timetable.png',
    navCalendar: 'assets/themes/sprout/navbar/nav_calendar.png',
    navAnalytics: 'assets/themes/sprout/navbar/nav_analytics.png',
    navSettings: 'assets/themes/sprout/navbar/nav_settings.png',
  );
}
