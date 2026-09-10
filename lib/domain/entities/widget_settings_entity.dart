import 'dart:convert';

enum WidgetThemeMode {
  system,
  amoled,
  midnight,
  emerald,
  rose,
  sunset;

  String get displayName {
    switch (this) {
      case WidgetThemeMode.system:
        return 'System Dynamic (Material You)';
      case WidgetThemeMode.amoled:
        return 'AMOLED Pitch Black';
      case WidgetThemeMode.midnight:
        return 'Midnight Obsidian';
      case WidgetThemeMode.emerald:
        return 'Emerald Forest';
      case WidgetThemeMode.rose:
        return 'Rose Velvet';
      case WidgetThemeMode.sunset:
        return 'Sunset Amber';
    }
  }

  int get primaryColorValue {
    switch (this) {
      case WidgetThemeMode.system:
        return 0xFF3B82F6; // Accent Blue
      case WidgetThemeMode.amoled:
        return 0xFFF8FAFC; // Clean White on OLED
      case WidgetThemeMode.midnight:
        return 0xFF60A5FA; // Light Blue
      case WidgetThemeMode.emerald:
        return 0xFF10B981; // ClassTrack Emerald
      case WidgetThemeMode.rose:
        return 0xFFFB7185; // Soft Rose
      case WidgetThemeMode.sunset:
        return 0xFFF59E0B; // Warm Amber
    }
  }

  int get cardBackgroundColorValue {
    switch (this) {
      case WidgetThemeMode.system:
        return 0xFF1C1D22; // ClassTrack Card Dark
      case WidgetThemeMode.amoled:
        return 0xFF000000; // Pitch Black
      case WidgetThemeMode.midnight:
        return 0xFF111827; // Deep Obsidian Neutral
      case WidgetThemeMode.emerald:
        return 0xFF0A1F18; // Deep Forest Neutral
      case WidgetThemeMode.rose:
        return 0xFF1F1216; // Deep Wine Neutral
      case WidgetThemeMode.sunset:
        return 0xFF1F1812; // Deep Warm Graphite Neutral
    }
  }
}

class WidgetSettingsEntity {
  final double backgroundOpacity;
  final WidgetThemeMode themeMode;
  final bool showRoomNumber;
  final bool showTeacherName;
  final bool privacyMode;
  final bool showTomorrowPreviewWhenDone;
  final bool use24HourFormat;
  final bool directAttendanceMarking;

  const WidgetSettingsEntity({
    this.backgroundOpacity = 0.85,
    this.themeMode = WidgetThemeMode.system,
    this.showRoomNumber = true,
    this.showTeacherName = false,
    this.privacyMode = false,
    this.showTomorrowPreviewWhenDone = true,
    this.use24HourFormat = false,
    this.directAttendanceMarking = true,
  });

  WidgetSettingsEntity copyWith({
    double? backgroundOpacity,
    WidgetThemeMode? themeMode,
    bool? showRoomNumber,
    bool? showTeacherName,
    bool? privacyMode,
    bool? showTomorrowPreviewWhenDone,
    bool? use24HourFormat,
    bool? directAttendanceMarking,
  }) {
    return WidgetSettingsEntity(
      backgroundOpacity: (backgroundOpacity ?? this.backgroundOpacity).clamp(0.0, 1.0),
      themeMode: themeMode ?? this.themeMode,
      showRoomNumber: showRoomNumber ?? this.showRoomNumber,
      showTeacherName: showTeacherName ?? this.showTeacherName,
      privacyMode: privacyMode ?? this.privacyMode,
      showTomorrowPreviewWhenDone: showTomorrowPreviewWhenDone ?? this.showTomorrowPreviewWhenDone,
      use24HourFormat: use24HourFormat ?? this.use24HourFormat,
      directAttendanceMarking: directAttendanceMarking ?? this.directAttendanceMarking,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'backgroundOpacity': backgroundOpacity,
      'themeMode': themeMode.name,
      'showRoomNumber': showRoomNumber,
      'showTeacherName': showTeacherName,
      'privacyMode': privacyMode,
      'showTomorrowPreviewWhenDone': showTomorrowPreviewWhenDone,
      'use24HourFormat': use24HourFormat,
      'directAttendanceMarking': directAttendanceMarking,
    };
  }

  String toJson() => jsonEncode(toMap());

  factory WidgetSettingsEntity.fromMap(Map<String, dynamic> map) {
    return WidgetSettingsEntity(
      backgroundOpacity: (map['backgroundOpacity'] is num)
          ? (map['backgroundOpacity'] as num).toDouble().clamp(0.0, 1.0)
          : 0.85,
      themeMode: WidgetThemeMode.values.firstWhere(
        (e) => e.name == map['themeMode'],
        orElse: () => WidgetThemeMode.system,
      ),
      showRoomNumber: map['showRoomNumber'] as bool? ?? true,
      showTeacherName: map['showTeacherName'] as bool? ?? false,
      privacyMode: map['privacyMode'] as bool? ?? false,
      showTomorrowPreviewWhenDone: map['showTomorrowPreviewWhenDone'] as bool? ?? true,
      use24HourFormat: map['use24HourFormat'] as bool? ?? false,
      directAttendanceMarking: map['directAttendanceMarking'] as bool? ?? true,
    );
  }

  factory WidgetSettingsEntity.fromJson(String source) {
    try {
      return WidgetSettingsEntity.fromMap(jsonDecode(source) as Map<String, dynamic>);
    } catch (_) {
      return const WidgetSettingsEntity();
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WidgetSettingsEntity &&
          runtimeType == other.runtimeType &&
          backgroundOpacity == other.backgroundOpacity &&
          themeMode == other.themeMode &&
          showRoomNumber == other.showRoomNumber &&
          showTeacherName == other.showTeacherName &&
          privacyMode == other.privacyMode &&
          showTomorrowPreviewWhenDone == other.showTomorrowPreviewWhenDone &&
          use24HourFormat == other.use24HourFormat &&
          directAttendanceMarking == other.directAttendanceMarking;

  @override
  int get hashCode =>
      backgroundOpacity.hashCode ^
      themeMode.hashCode ^
      showRoomNumber.hashCode ^
      showTeacherName.hashCode ^
      privacyMode.hashCode ^
      showTomorrowPreviewWhenDone.hashCode ^
      use24HourFormat.hashCode ^
      directAttendanceMarking.hashCode;
}
