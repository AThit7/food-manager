import 'package:flutter/cupertino.dart';
import 'package:food_manager/core/result/repo_result.dart';
import 'package:food_manager/data/repositories/local_product_repository.dart';
import 'package:food_manager/data/repositories/pantry_item_repository.dart';
import 'package:food_manager/data/repositories/recipe_repository.dart';
import 'package:food_manager/domain/models/meal_planner/meal_plan.dart';
import 'package:food_manager/domain/models/meal_planner/meal_plan_constraints.dart';
import 'package:food_manager/domain/models/pantry_item.dart';
import 'package:food_manager/domain/models/product/local_product.dart';
import 'package:food_manager/domain/models/recipe.dart';
import 'package:food_manager/domain/services/meal_planner.dart';

class PlannerViewmodel extends ChangeNotifier {
  PlannerViewmodel({
    required MealPlanner mealPlanner,
    required RecipeRepository recipeRepository,
    required PantryItemRepository pantryItemRepository,
    required LocalProductRepository localProductRepository,
  }) : _mealPlanner = mealPlanner,
        _recipeRepository = recipeRepository,
        _itemRepository = pantryItemRepository,
        _localProductRepository = localProductRepository;
  
  final MealPlanner _mealPlanner;
  final RecipeRepository _recipeRepository;
  final PantryItemRepository _itemRepository;
  final LocalProductRepository _localProductRepository;

  bool isLoading = false;
  String? errorMessage;
  MealPlan? mealPlan;

  Future<void> _loadMealPlanFromDb() async {
    // TODO implement meal plan saving to and loading from db
    return;
  }
  
  Future<void> loadMealPlan() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    
    await _loadMealPlanFromDb();
    if (isLoading != false) {
      isLoading = false;
      notifyListeners();
      return;
    }

    final productsResult = await _localProductRepository.listProducts();
    final pantryItemsResult = await _itemRepository.listPantryItems();
    final recipesResult = await _recipeRepository.listRecipes();

    List<LocalProduct>? products;
    List<PantryItem>? pantryItems;
    List<Recipe>? recipes;

    switch (productsResult) {
      case RepoSuccess(): products = productsResult.data;
      case RepoError(): errorMessage = productsResult.message;
      case RepoFailure(): throw StateError('Unexpected RepoFailure in loadMealPlan');
    }

    switch (pantryItemsResult) {
      case RepoSuccess(): pantryItems = pantryItemsResult.data;
      case RepoError(): errorMessage = pantryItemsResult.message;
      case RepoFailure(): throw StateError('Unexpected RepoFailure in loadMealPlan');
    }

    switch (recipesResult) {
      case RepoSuccess(): recipes = recipesResult.data;
      case RepoError(): errorMessage = recipesResult.message;
      case RepoFailure(): throw StateError('Unexpected RepoFailure in loadMealPlan');
    }

    if (products == null || pantryItems == null || recipes == null) {
      isLoading = false;
      notifyListeners();
      return;
    }

    mealPlan = _mealPlanner.generatePlan(
      products: products,
      pantryItems: pantryItems,
      recipes: recipes,
      constraints: MealPlanConstraints(
        calorieRange: (lower: 2000, upper: 3000),
        proteinRange: (lower: 0, upper: 3000),
        carbsRange: (lower: 0, upper: 3000),
        fatRange: (lower: 0, upper: 3000),
      ),
      currentPlan: MealPlan(
        dayZero: DateTime.now(),
        mealsPerDay: 3,
        plan: [],
      ),
    );

    isLoading = false;
    notifyListeners();
  }
}