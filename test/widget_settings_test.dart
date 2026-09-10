import 'package:flutter_test/flutter_test.dart';
import 'package:classtrack/domain/entities/widget_settings_entity.dart';

void main() {
  group('WidgetSettingsEntity Serialization & Defaults Tests', () {
    test('Default values match expected production baseline', () {
      const settings = WidgetSettingsEntity();
      expect(settings.backgroundOpacity, 0.85);
      expect(settings.themeMode, WidgetThemeMode.system);
      expect(settings.showRoomNumber, true);
      expect(settings.showTeacherName, false);
      expect(settings.privacyMode, false);
      expect(settings.showTomorrowPreviewWhenDone, true);
      expect(settings.use24HourFormat, false);
      expect(settings.directAttendanceMarking, true);
    });

    test('copyWith clamps opacity strictly within 0.0 and 1.0', () {
      const settings = WidgetSettingsEntity();

      final tooHigh = settings.copyWith(backgroundOpacity: 1.5);
      expect(tooHigh.backgroundOpacity, 1.0);

      final tooLow = settings.copyWith(backgroundOpacity: -0.2);
      expect(tooLow.backgroundOpacity, 0.0);
    });

    test('Serializes to JSON and deserializes back cleanly', () {
      const original = WidgetSettingsEntity(
        backgroundOpacity: 0.40,
        themeMode: WidgetThemeMode.emerald,
        showRoomNumber: false,
        showTeacherName: true,
        privacyMode: true,
        showTomorrowPreviewWhenDone: false,
        use24HourFormat: true,
        directAttendanceMarking: false,
      );

      final jsonStr = original.toJson();
      final restored = WidgetSettingsEntity.fromJson(jsonStr);

      expect(restored, equals(original));
      expect(restored.themeMode, WidgetThemeMode.emerald);
      expect(restored.backgroundOpacity, 0.40);
      expect(restored.privacyMode, true);
      expect(restored.directAttendanceMarking, false);
    });

    test('Malformed JSON falls back gracefully to default settings without throwing', () {
      final restored = WidgetSettingsEntity.fromJson('invalid-json');
      expect(restored.backgroundOpacity, 0.85);
      expect(restored.themeMode, WidgetThemeMode.system);
    });
  });
}
