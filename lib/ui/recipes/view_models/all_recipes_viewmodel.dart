import 'dart:async';

import 'package:flutter/material.dart';
import 'package:food_manager/core/result/repo_result.dart';
import 'package:food_manager/data/repositories/recipe_repository.dart';
import 'package:food_manager/domain/models/recipe.dart';

class AllRecipesViewmodel extends ChangeNotifier {
  AllRecipesViewmodel ({required RecipeRepository recipeRepository})
      : _recipeRepository = recipeRepository {
    _subscription = _recipeRepository.recipeUpdates.listen(_onRecipeEvent);
  }

  final RecipeRepository _recipeRepository;
  late final StreamSubscription<RecipeEvent> _subscription;
  List<Recipe> _recipes = [];
  String? errorMessage;
  bool isLoading = false;

  List<Recipe> get recipes => List.unmodifiable(_recipes);

  void _onRecipeEvent(RecipeEvent event) {
    switch (event) {
      case RecipeAdded(): _recipes.add(event.recipe);
      case RecipeDeleted(): _recipes.removeWhere((r) => r.id == event.recipeId);
      case RecipeModified(): {
        final index = _recipes.indexWhere((p) => p.id == event.recipe.id);
        if (index != -1) _recipes[index] = event.recipe;
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  Future<void> loadRecipes() async {
    isLoading = true;
    final result =  await _recipeRepository.listRecipes();
    errorMessage = null;
    _recipes = [];

    switch (result) {
      case RepoSuccess(): _recipes = result.data;
      case RepoError(): errorMessage = result.message;
      case RepoFailure():
        throw StateError('Unexpected RepoFailure in loadRecipes');
    }

    isLoading = false;
    notifyListeners();
  }
}
