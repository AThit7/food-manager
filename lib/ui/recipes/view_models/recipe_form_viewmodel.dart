import 'dart:async';
import 'dart:developer';

import 'package:food_manager/core/result/repo_result.dart';

import '../../../data/repositories/recipe_repository.dart';
import '../../../domain/models/recipe.dart';
import '../models/recipe_form_model.dart';
import '../../../domain/validators/recipe_validator.dart';

sealed class InsertResult {}

class InsertSuccess extends InsertResult {
  final Recipe recipe;

  InsertSuccess(this.recipe);
}

class InsertRepoFailure extends InsertResult {}

class InsertValidationFailure extends InsertResult {}

class RecipeFormViewmodel {
  RecipeFormViewmodel({
    required RecipeRepository recipeRepository,
  }) : _recipeRepository = recipeRepository;

  final RecipeRepository _recipeRepository;

  Future<InsertResult> saveRecipe(RecipeFormModel form) async {
    Recipe recipe;
    try {
      recipe = Recipe(
        id: form.id,
        name: form.name!,
      );
      RecipeValidator.validate(recipe);
    } catch (e) {
      log(
        "Failed to validate recipe.",
        name: "RecipeFormViewmodel",
        error: e,
      );
      return InsertValidationFailure();
    }

    if (recipe.id == null) {
      final result = await _recipeRepository.insertRecipe(recipe);
      switch (result) {
        case RepoSuccess():
          return InsertSuccess(recipe.copyWith(id: result.data));
        case RepoFailure():
          return InsertRepoFailure();
        case RepoError():
          return InsertRepoFailure();
      }
    } else {
      final result = await _recipeRepository.updateRecipe(recipe);
      switch (result) {
        case RepoSuccess():
          return InsertSuccess(recipe);
        case RepoFailure():
          return InsertRepoFailure();
        case RepoError():
          return InsertRepoFailure();
      }
    }
  }
}
