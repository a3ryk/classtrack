import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';
import '../providers/app_state_provider.dart';
import '../../core/theme/app_theme_registry.dart';

final appThemeStyleProvider = StateNotifierProvider<AppThemeStyleNotifier, String>((ref) {
  return AppThemeStyleNotifier(ref);
});

class AppThemeStyleNotifier extends StateNotifier<String> {
  final Ref ref;
  AppDatabase get db => ref.read(databaseProvider);

  AppThemeStyleNotifier(this.ref) : super(AppThemeRegistry.defaultThemeId) {
    loadFromDb();
  }

  Future<void> loadFromDb() async {
    try {
      final saved = await db.getSetting('active_theme_style');
      if (!mounted) return;
      if (saved != null && saved.isNotEmpty) {
        state = saved;
      }
    } catch (_) {}
  }

  Future<void> setThemeStyle(String themeId) async {
    state = themeId;
    try {
      await db.setSetting('active_theme_style', themeId);
    } catch (_) {}
  }

  Future<void> toggleThemeStyle() async {
    if (state == 'classic_indigo') {
      await setThemeStyle('cute_sprout');
    } else {
      await setThemeStyle('classic_indigo');
    }
  }

  bool get isCute => AppThemeRegistry.isCute(state);
}
