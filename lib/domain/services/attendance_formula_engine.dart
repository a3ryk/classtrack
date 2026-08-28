import 'dart:math' as math;

enum RoundingStrategy { round, floor, ceil }

class AttendanceFormulaConfig {
  final bool includeDutyLeaveInPresent;
  final bool creditCancelledAsPresent;
  final int graceClassesCount;
  final double defaultTargetPercentage;
  final Map<String, double> categoryTargets;
  final RoundingStrategy roundingStrategy;

  const AttendanceFormulaConfig({
    this.includeDutyLeaveInPresent = true,
    this.creditCancelledAsPresent = false,
    this.graceClassesCount = 0,
    this.defaultTargetPercentage = 75.0,
    this.categoryTargets = const {
      'MAJOR': 75.0,
      'MINOR': 75.0,
      'LAB': 80.0,
      'VAC': 60.0,
      'SEC': 60.0,
      'AEC': 75.0,
    },
    this.roundingStrategy = RoundingStrategy.round,
  });

  AttendanceFormulaConfig copyWith({
    bool? includeDutyLeaveInPresent,
    bool? creditCancelledAsPresent,
    int? graceClassesCount,
    double? defaultTargetPercentage,
    Map<String, double>? categoryTargets,
    RoundingStrategy? roundingStrategy,
  }) {
    return AttendanceFormulaConfig(
      includeDutyLeaveInPresent: includeDutyLeaveInPresent ?? this.includeDutyLeaveInPresent,
      creditCancelledAsPresent: creditCancelledAsPresent ?? this.creditCancelledAsPresent,
      graceClassesCount: graceClassesCount ?? this.graceClassesCount,
      defaultTargetPercentage: defaultTargetPercentage ?? this.defaultTargetPercentage,
      categoryTargets: categoryTargets ?? this.categoryTargets,
      roundingStrategy: roundingStrategy ?? this.roundingStrategy,
    );
  }
}

class AttendanceFormulaEngine {
  AttendanceFormulaEngine._();

  /// Calculates percentage based on formula config
  static double calculatePercentage({
    required int attended,
    required int held,
    int dutyLeave = 0,
    int cancelled = 0,
    required AttendanceFormulaConfig config,
  }) {
    int effectiveAttended = attended;
    if (config.includeDutyLeaveInPresent) {
      effectiveAttended += dutyLeave;
    }
    if (config.creditCancelledAsPresent) {
      effectiveAttended += cancelled;
    }
    effectiveAttended += config.graceClassesCount;

    int effectiveHeld = held;
    if (config.creditCancelledAsPresent) {
      effectiveHeld += cancelled;
    }

    if (effectiveHeld <= 0) return 100.0;

    final rawPct = (effectiveAttended / effectiveHeld) * 100.0;

    switch (config.roundingStrategy) {
      case RoundingStrategy.floor:
        return (rawPct * 10).floorToDouble() / 10;
      case RoundingStrategy.ceil:
        return (rawPct * 10).ceilToDouble() / 10;
      case RoundingStrategy.round:
        return (rawPct * 10).roundToDouble() / 10;
    }
  }

  /// Calculates margin classes a student can miss ($M$)
  static int calculateClassesCanMiss({
    required int attended,
    required int held,
    int dutyLeave = 0,
    int cancelled = 0,
    required double targetPct,
    required AttendanceFormulaConfig config,
  }) {
    int effectiveAttended = attended;
    if (config.includeDutyLeaveInPresent) effectiveAttended += dutyLeave;
    if (config.creditCancelledAsPresent) effectiveAttended += cancelled;
    effectiveAttended += config.graceClassesCount;

    int effectiveHeld = held;
    if (config.creditCancelledAsPresent) effectiveHeld += cancelled;

    if (effectiveHeld <= 0) return 0;

    final targetDecimal = targetPct / 100.0;
    final double maxMiss = (effectiveAttended - (targetDecimal * effectiveHeld)) / targetDecimal;

    return math.max(0, maxMiss.floor());
  }

  /// Calculates minimum consecutive classes a student must attend ($N$)
  static int calculateClassesMustAttend({
    required int attended,
    required int held,
    int dutyLeave = 0,
    int cancelled = 0,
    required double targetPct,
    required AttendanceFormulaConfig config,
  }) {
    int effectiveAttended = attended;
    if (config.includeDutyLeaveInPresent) effectiveAttended += dutyLeave;
    if (config.creditCancelledAsPresent) effectiveAttended += cancelled;
    effectiveAttended += config.graceClassesCount;

    int effectiveHeld = held;
    if (config.creditCancelledAsPresent) effectiveHeld += cancelled;

    if (effectiveHeld <= 0) return 0;

    final targetDecimal = targetPct / 100.0;
    if (targetDecimal >= 1.0) return 0;

    final double currentPct = (effectiveAttended / effectiveHeld) * 100.0;
    if (currentPct >= targetPct) return 0;

    final double mustAttend = ((targetDecimal * effectiveHeld) - effectiveAttended) / (1.0 - targetDecimal);

    return math.max(0, mustAttend.ceil());
  }
}
