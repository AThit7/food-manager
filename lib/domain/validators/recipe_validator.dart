import 'package:food_manager/domain/models/recipe.dart';
import '../../core/exceptions/exceptions.dart';

class RecipeValidator{
  static bool _isValidDouble(double value, [bool canBeZero = false]) {
    return value.isFinite && !value.isNaN && !value.isNegative &&
        (canBeZero || value > 0);
  }

  // TODO finish
  static void validate(Recipe recipe) {
    throw ValidationError("Not implemented.");
    if (recipe.name.isEmpty) {
      throw ValidationError("Name can't be empty");
    }
  }

  static bool isValid(Recipe recipe) {
    try {
      validate(recipe);
      return true;
    } catch (_) {
      return false;
    }
  }
}
