import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';
import 'app_state_provider.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(ref);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final Ref ref;
  AppDatabase get db => ref.read(databaseProvider);

  ThemeModeNotifier(this.ref) : super(ThemeMode.system) {
    loadFromDb();
  }

  Future<void> loadFromDb() async {
    try {
      final saved = await db.getSetting('theme_mode');
      if (!mounted) return;
      if (saved != null) {
        if (saved == 'light') {
          state = ThemeMode.light;
        } else if (saved == 'dark') {
          state = ThemeMode.dark;
        } else {
          state = ThemeMode.system;
        }
      }
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final modeStr = mode == ThemeMode.light
        ? 'light'
        : (mode == ThemeMode.dark ? 'dark' : 'system');
    try {
      await db.setSetting('theme_mode', modeStr);
    } catch (_) {}
  }

  Future<void> toggleTheme() async {
    if (state == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);
    } else if (state == ThemeMode.dark) {
      await setThemeMode(ThemeMode.system);
    } else {
      await setThemeMode(ThemeMode.light);
    }
  }
}
