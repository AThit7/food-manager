import 'package:food_manager/domain/models/recipe_ingredient.dart';
import 'package:food_manager/domain/validators/tag_validator.dart';
import '../../core/exceptions/exceptions.dart';

class RecipeIngredientValidator {
  static bool _isValidDouble(double value, [bool canBeZero = false]) => 
      value.isFinite && !value.isNegative && (canBeZero || value > 0);

  static void validate(RecipeIngredient recipeIngredient) {
    if (recipeIngredient.unit.trim().isEmpty) throw ValidationError("Unit name can't be empty.");
    if (!_isValidDouble(recipeIngredient.amount)) throw ValidationError("Invalid ingredient amount.");
    TagValidator.validate(recipeIngredient.tag);
  }

  static bool isValid(RecipeIngredient recipeIngredient) {
    try {
      validate(recipeIngredient);
      return true;
    } catch (_) {
      return false;
    }
  }
}