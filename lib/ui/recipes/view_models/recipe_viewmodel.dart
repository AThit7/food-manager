import 'package:flutter/cupertino.dart';
import 'package:food_manager/core/result/result.dart';
import 'package:food_manager/data/repositories/recipe_repository.dart';
import 'package:food_manager/domain/models/recipe.dart';

class RecipeViewmodel extends ChangeNotifier {
  RecipeViewmodel({
    required RecipeRepository recipeRepository,
    required Recipe recipe,
  }) : _recipeRepository = recipeRepository,
        _recipe = recipe;

  final RecipeRepository _recipeRepository;
  Recipe _recipe;
  Recipe get recipe => _recipe;
  String? errorMessage;
  bool? isLoading = false;

  void setRecipe(Recipe recipe) {
    _recipe = recipe;
    notifyListeners();
  }

  Future<void> deleteRecipe() async {
    if (recipe.id == null) {
      errorMessage = "Recipe has no id. Can't delete it.";
      throw StateError("Recipe has no id");
    }
    errorMessage = null;
    isLoading = true;
    notifyListeners();

    final result = await _recipeRepository.deleteRecipe(recipe.id!);

    switch(result) {
      case ResultSuccess(): break;
      case ResultError(): errorMessage = result.message;
      case ResultFailure(): errorMessage = "Couldn't delete recipe.";
    }

    isLoading = false;
    notifyListeners();
  }
}
