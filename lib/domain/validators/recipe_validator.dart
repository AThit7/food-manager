import 'package:food_manager/domain/models/recipe.dart';
import 'package:food_manager/domain/validators/recipe_ingredient_validator.dart';
import '../../core/exceptions/exceptions.dart';

class RecipeValidator{
  static bool _isValidDouble(double value, [bool canBeZero = false]) {
    return value.isFinite && !value.isNaN && !value.isNegative &&
        (canBeZero || value > 0);
  }

  // TODO validate instruction?
  static void validate(Recipe recipe) {
    if (recipe.name.trim().isEmpty) throw ValidationError("Name can't be empty");
    if  (!recipe.preparationTime.isFinite || recipe.preparationTime.isNegative) {
      throw ValidationError("Invalid preparation time.");
    }
    for (final recipeIngredient in recipe.ingredients) {
      RecipeIngredientValidator.validate(recipeIngredient);
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