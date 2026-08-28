import 'dart:math';
import '../entities/attendance_stats.dart';

/// Pure Mathematical Service for Attendance Metrics & Predictions
class AttendanceMathService {
  AttendanceMathService._();

  /// Calculates attendance percentage
  static double calculatePercentage(int attended, int held) {
    if (held <= 0) return 100.0;
    final pct = (attended / held) * 100.0;
    return double.parse(pct.toStringAsFixed(1));
  }

  /// Calculates max future consecutive classes student can miss while remaining at/above target %
  static int calculateClassesCanMiss({
    required int attended,
    required int held,
    required double targetPct,
  }) {
    if (held <= 0) return 0;
    final currentPct = (attended / held) * 100.0;
    if (currentPct < targetPct) return 0;

    final targetDecimal = targetPct / 100.0;
    // Formula: (attended / (held + M)) >= targetDecimal => M <= (attended - target * held) / target
    final maxMiss = ((attended - (targetDecimal * held)) / targetDecimal).floor();
    return max(0, maxMiss);
  }

  /// Calculates minimum future consecutive classes student must attend to reach target %
  static int calculateClassesMustAttend({
    required int attended,
    required int held,
    required double targetPct,
  }) {
    if (held <= 0) return 0;
    final currentPct = (attended / held) * 100.0;
    if (currentPct >= targetPct) return 0;

    final targetDecimal = targetPct / 100.0;
    if (targetDecimal >= 1.0) return 999; // Mathematically impossible if target is 100% and missed > 0

    // Formula: (attended + N) / (held + N) >= targetDecimal => N >= (target * held - attended) / (1 - target)
    final minAttend = (((targetDecimal * held) - attended) / (1.0 - targetDecimal)).ceil();
    return max(0, minAttend);
  }

  /// Resolves attendance status enum
  static SubjectAttendanceStatus resolveStatus(double currentPct, double targetPct) {
    if (currentPct >= targetPct) {
      return SubjectAttendanceStatus.safe;
    } else if (currentPct >= (targetPct - 5.0)) {
      return SubjectAttendanceStatus.warning;
    } else {
      return SubjectAttendanceStatus.critical;
    }
  }

  /// Simulates future leave impact
  static double simulateLeave({
    required int currentAttended,
    required int currentHeld,
    required int leaveSessionCount,
  }) {
    final newHeld = currentHeld + leaveSessionCount;
    if (newHeld <= 0) return 100.0;
    return calculatePercentage(currentAttended, newHeld);
  }
}
