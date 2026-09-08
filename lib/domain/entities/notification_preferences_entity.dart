class NotificationPreferencesEntity {
  final bool enabled;
  final bool enableClassStart;
  final int startLeadMinutes; // 0, 5, 10, 15, 30
  final bool enableClassEnd;
  final int endLeadMinutes; // 0, 5, 10
  final bool enableQuickActions; // Present, Absent, Cancelled actions
  final bool vibrate;
  final bool sound;

  const NotificationPreferencesEntity({
    this.enabled = true,
    this.enableClassStart = true,
    this.startLeadMinutes = 5,
    this.enableClassEnd = true,
    this.endLeadMinutes = 0,
    this.enableQuickActions = true,
    this.vibrate = true,
    this.sound = true,
  });

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'enableClassStart': enableClassStart,
    'startLeadMinutes': startLeadMinutes,
    'enableClassEnd': enableClassEnd,
    'endLeadMinutes': endLeadMinutes,
    'enableQuickActions': enableQuickActions,
    'vibrate': vibrate,
    'sound': sound,
  };

  factory NotificationPreferencesEntity.fromJson(Map<String, dynamic> json) {
    return NotificationPreferencesEntity(
      enabled: json['enabled'] as bool? ?? true,
      enableClassStart: json['enableClassStart'] as bool? ?? true,
      startLeadMinutes: json['startLeadMinutes'] as int? ?? 5,
      enableClassEnd: json['enableClassEnd'] as bool? ?? true,
      endLeadMinutes: json['endLeadMinutes'] as int? ?? 0,
      enableQuickActions: json['enableQuickActions'] as bool? ?? true,
      vibrate: json['vibrate'] as bool? ?? true,
      sound: json['sound'] as bool? ?? true,
    );
  }

  NotificationPreferencesEntity copyWith({
    bool? enabled,
    bool? enableClassStart,
    int? startLeadMinutes,
    bool? enableClassEnd,
    int? endLeadMinutes,
    bool? enableQuickActions,
    bool? vibrate,
    bool? sound,
  }) {
    return NotificationPreferencesEntity(
      enabled: enabled ?? this.enabled,
      enableClassStart: enableClassStart ?? this.enableClassStart,
      startLeadMinutes: startLeadMinutes ?? this.startLeadMinutes,
      enableClassEnd: enableClassEnd ?? this.enableClassEnd,
      endLeadMinutes: endLeadMinutes ?? this.endLeadMinutes,
      enableQuickActions: enableQuickActions ?? this.enableQuickActions,
      vibrate: vibrate ?? this.vibrate,
      sound: sound ?? this.sound,
    );
  }
}
