import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:food_manager/core/result/repo_result.dart';
import 'package:food_manager/data/repositories/local_product_repository.dart';
import 'package:food_manager/data/repositories/meal_plan_repository.dart';
import 'package:food_manager/data/repositories/pantry_item_repository.dart';
import 'package:food_manager/data/repositories/recipe_repository.dart';
import 'package:food_manager/data/services/shared_preferences_service.dart';
import 'package:food_manager/domain/models/meal_planner/meal_plan.dart';
import 'package:food_manager/domain/models/meal_planner/meal_plan_constraints.dart';
import 'package:food_manager/domain/models/pantry_item.dart';
import 'package:food_manager/domain/models/product/local_product.dart';
import 'package:food_manager/domain/models/recipe.dart';
import 'package:food_manager/domain/services/meal_planner.dart';

class PlannerViewmodel extends ChangeNotifier {
  PlannerViewmodel({
    required MealPlanner mealPlanner,
    required SharedPreferencesService sharedPreferencesService,
    required RecipeRepository recipeRepository,
    required PantryItemRepository pantryItemRepository,
    required LocalProductRepository localProductRepository,
    required MealPlanRepository mealPlanRepository,
  }) : _mealPlanner = mealPlanner,
        _preferences = sharedPreferencesService,
        _recipeRepository = recipeRepository,
        _itemRepository = pantryItemRepository,
        _localProductRepository = localProductRepository,
        _mealPlanRepository = mealPlanRepository;
  
  final MealPlanner _mealPlanner;
  final SharedPreferencesService _preferences;
  final RecipeRepository _recipeRepository;
  final PantryItemRepository _itemRepository;
  final LocalProductRepository _localProductRepository;
  final MealPlanRepository _mealPlanRepository;

  bool isLoading = false;
  String? errorMessage;
  MealPlan? mealPlan;

  Future<void> _loadMealPlanFromDb() async {
    final planResult = await _mealPlanRepository.getLatestPlan();
    switch (planResult) {
      case RepoSuccess(data: final plan):
        mealPlan = plan;
        break;
      case RepoError(message: final msg):
        errorMessage = msg;
      case RepoFailure():
    }
  }
  
  Future<void> _saveMealPlan() async {
    if (mealPlan == null) return;
    final planResult = await _mealPlanRepository.savePlan(mealPlan!);
    assert(planResult is RepoSuccess, 'Unexpected: saving meal plan failed.');
  }
  
  Future<void> loadMealPlan([bool tryDatabase = true]) async {
    isLoading = true;
    errorMessage = null;
    mealPlan = null;
    notifyListeners();
    
    if (tryDatabase) {
      await _loadMealPlanFromDb();
      if (mealPlan != null || errorMessage != null) {
        isLoading = false;
        notifyListeners();
        return;
      }
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
        calorieRange: (lower: 1500, upper: 3000),
        proteinRange: (lower: 0, upper: 3000),
        carbsRange: (lower: 0, upper: 3000),
        fatRange: (lower: 0, upper: 3000),
      ),
      currentPlan: MealPlan(
        dayZero: DateTime.now(),
        mealsPerDayRange: (lower: _preferences.lowerMealCount, upper: _preferences.upperMealCount),
        plan: [],
        waste: [],
        valid: []
      ),
    );
    
    await _saveMealPlan();

    isLoading = false;
    notifyListeners();
  }

  Future<void> consumeSlot(MealPlanSlot slot) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final pantryItemsResult = await _itemRepository.listPantryItems(); // ensure item data is up to date
    Map<String, PantryItem>? pantryItems;

    switch (pantryItemsResult) {
    case RepoSuccess(): pantryItems = Map.fromEntries(pantryItemsResult.data.map((e) => MapEntry(e.uuid, e)));
    case RepoError():
      errorMessage = pantryItemsResult.message;
      return;
    case RepoFailure(): throw StateError('Unexpected RepoFailure in loadMealPlan');
    }

    for (final comp in slot.ingredients.values.expand((list) => list)) {
      final quantity = comp.quantity;
      final item = pantryItems[comp.item.uuid];
      if (item ==  null) throw StateError("Meal Plan item not in DB.");

      final leftoverQuantity = item.quantity - quantity;
      if (leftoverQuantity < 0.000001) {
        log("Removing item from recipe ${slot.recipe.name}");
        _itemRepository.removeItem(item);
      } else {
        log("Item quantity updated from ${item.quantity} to $leftoverQuantity in recipe ${slot.recipe.name}");
        _itemRepository.updateItem(item.copyWith(quantity: leftoverQuantity));
      }
    }

    slot.eat();

    final planResult = await _mealPlanRepository.savePlan(mealPlan!);
    if (planResult is RepoError) errorMessage = planResult.message;

    isLoading = false;
    notifyListeners();
  }
}