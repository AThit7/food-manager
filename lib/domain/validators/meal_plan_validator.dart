import "package:food_manager/core/exceptions/exceptions.dart";
import "package:food_manager/domain/models/meal_planner/meal_plan.dart";
import "package:food_manager/domain/validators/recipe_validator.dart";

// TODO review this
class MealPlanValidator {
  static bool _isValidDouble(double value, [bool canBeZero = false]) =>
      value.isFinite && !value.isNaN && !value.isNegative && (canBeZero || value > 0);

  static void validate(MealPlan plan) {
    final lower = plan.mealsPerDayRange.lower;
    final upper = plan.mealsPerDayRange.upper;

    if (plan.plan.length != plan.waste.length) {
      throw ValidationError(
          "plan.length (${plan.plan.length}) must equal waste.length (${plan.waste.length})."
      );
    }
    if (lower < 0) {
      throw ValidationError("mealsPerDayRange.lower must be ≥ 0 (got $lower).");
    }
    if (upper < lower) {
      throw ValidationError("mealsPerDayRange.upper ($upper) must be ≥ lower ($lower).");
    }

    for (var d = 0; d < plan.plan.length; d++) {
      final slots = plan.plan[d];

      final wasteVal = plan.waste[d];
      if (!_isValidDouble(wasteVal)) {
        throw ValidationError("waste[$d] must be a finite, non-negative number (got $wasteVal).");
      }

      for (var i = 0; i < slots.length; i++) {
        final s = slots[i];

        if (!_isValidDouble(s.calories)) {
          throw ValidationError("Day $d slot $i: calories must be finite and ≥ 0 (got ${s.calories}).");
        }
        if (!_isValidDouble(s.protein)) {
          throw ValidationError("Day $d slot $i: protein must be finite and ≥ 0 (got ${s.protein}).");
        }
        if (!_isValidDouble(s.carbs)) {
          throw ValidationError("Day $d slot $i: carbs must be finite and ≥ 0 (got ${s.carbs}).");
        }
        if (!_isValidDouble(s.fat)) {
          throw ValidationError("Day $d slot $i: fat must be finite and ≥ 0 (got ${s.fat}).");
        }

        RecipeValidator.validate(s.recipe);

        if (s.ingredients.isEmpty) {
          throw ValidationError("Day $d slot $i: ingredients map cannot be empty.");
        }

        for (final entry in s.ingredients.entries) {
          final key = entry.key;
          final uses = entry.value;

          if (key.trim().isEmpty) {
            throw ValidationError("Day $d slot $i: ingredient key cannot be empty.");
          }
          if (uses.isEmpty) {
            throw ValidationError('Day $d slot $i: ingredient "$key" has an empty usage list.');
          }

          for (var j = 0; j < uses.length; j++) {
            final use = uses[j];
            if (!_isValidDouble(use.quantity)) {
              throw ValidationError(
                  'Day $d slot $i: ingredient "$key" usage[$j] quantity must be finite and > 0 (got ${use.quantity}).'
              );
            }
          }
        }
      }
    }
  }

  static bool isValid(MealPlan plan) {
    try {
      validate(plan);
      return true;
    } catch (_) {
      return false;
    }
  }
}