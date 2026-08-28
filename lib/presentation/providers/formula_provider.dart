import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/attendance_formula_engine.dart';

final formulaConfigProvider = StateNotifierProvider<FormulaConfigNotifier, AttendanceFormulaConfig>((ref) {
  return FormulaConfigNotifier();
});

class FormulaConfigNotifier extends StateNotifier<AttendanceFormulaConfig> {
  FormulaConfigNotifier() : super(const AttendanceFormulaConfig());

  void setPresetStandard() {
    state = const AttendanceFormulaConfig();
  }

  void setPresetDutyLeave() {
    state = state.copyWith(
      includeDutyLeaveInPresent: true,
      creditCancelledAsPresent: false,
    );
  }

  void setPresetNEP2020() {
    state = state.copyWith(
      categoryTargets: const {
        'MAJOR': 75.0,
        'MINOR': 75.0,
        'LAB': 80.0,
        'VAC': 60.0,
        'SEC': 60.0,
        'AEC': 75.0,
      },
    );
  }

  void toggleDutyLeave(bool value) {
    state = state.copyWith(includeDutyLeaveInPresent: value);
  }

  void toggleCreditCancelled(bool value) {
    state = state.copyWith(creditCancelledAsPresent: value);
  }

  void setGraceClasses(int count) {
    state = state.copyWith(graceClassesCount: count);
  }

  void setCategoryTarget(String category, double target) {
    final newTargets = Map<String, double>.from(state.categoryTargets);
    newTargets[category] = target;
    state = state.copyWith(categoryTargets: newTargets);
  }

  void setRoundingStrategy(RoundingStrategy strategy) {
    state = state.copyWith(roundingStrategy: strategy);
  }
}
