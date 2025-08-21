import 'dart:developer';

import 'package:flutter/material.dart';
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
  DateTime selectedDate = DateUtils.dateOnly(DateTime.now());

  ({int lower, int upper}) get mealCountRange =>
      (lower: _preferences.lowerMealCount ?? 3, upper: _preferences.upperMealCount ?? 5);
  ({int lower, int upper}) get calorieRange =>
      (lower: _preferences.lowerCalories ?? 0, upper: _preferences.upperCalories ?? 5000);
  ({int lower, int upper}) get proteinRange =>
      (lower: _preferences.lowerProtein ?? 0, upper: _preferences.upperProtein ?? 1000);
  ({int lower, int upper}) get carbsRange =>
      (lower: _preferences.lowerCarbs ?? 0, upper: _preferences.upperCarbs ?? 1000);
  ({int lower, int upper}) get fatRange =>
      (lower: _preferences.lowerFat ?? 0, upper: _preferences.upperFat ?? 1000);

  Future<void> savePreferences({
    required ({int lower, int upper}) mealCountRang,
    required ({int lower, int upper}) calorieRange,
    required ({int lower, int upper}) proteinRange,
    required ({int lower, int upper}) carbsRange,
    required ({int lower, int upper}) fatRange
  }) async {
    try {
      errorMessage = null;

      if (mealCountRang.lower > mealCountRang.upper) {
        throw ArgumentError('Meal count: lower cannot exceed upper.');
      }
      void check(String name, int lo, int hi) {
        if (lo > hi) {
          throw ArgumentError('$name: lower ($lo) cannot exceed upper ($hi).');
        }
      }

      check('Calories', calorieRange.lower, calorieRange.upper);
      check('Protein', proteinRange.lower, proteinRange.upper);
      check('Carbs', carbsRange.lower, carbsRange.upper);
      check('Fat', fatRange.lower, fatRange.upper);

      await Future.wait([
        _preferences.setLowerMealCount(mealCountRang.lower),
        _preferences.setUpperMealCount(mealCountRang.upper),
        _preferences.setCaloriesRange(lower: calorieRange.lower, upper: calorieRange.upper),
        _preferences.setProteinRange(lower: proteinRange.lower, upper: proteinRange.upper),
        _preferences.setCarbsRange(lower: carbsRange.lower, upper: carbsRange.upper),
        _preferences.setFatRange(lower: fatRange.lower, upper: fatRange.upper),
      ]);

    } catch (e, s) {
      log(
        "Failed to save preferences",
        name: 'PlannerViewmodel',
        error: s,
        stackTrace: s
      );
      errorMessage = 'Failed to save preferences.';
    }
  }

  Future<void> _loadMealPlanFromDb() async {
    final planResult = await _mealPlanRepository.getLatestPlan();
    switch (planResult) {
      case RepoSuccess():
        mealPlan = planResult.data;
      case RepoError():
        errorMessage = planResult.message;
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
        calorieRange: (lower: _preferences.lowerCalories ?? 1500, upper: _preferences.upperCalories ?? 5000),
        proteinRange: (lower: _preferences.lowerProtein ?? 0, upper: _preferences.upperProtein ?? 1000),
        carbsRange: (lower: _preferences.lowerCarbs ?? 0, upper: _preferences.upperCarbs ?? 1000),
        fatRange: (lower: _preferences.lowerFat ?? 0, upper: _preferences.upperFat ?? 1000),
      ),
      currentPlan: MealPlan(
        dayZero: DateUtils.dateOnly(DateTime.now()),
        mealsPerDayRange: (lower: _preferences.lowerMealCount ?? 3, upper: _preferences.upperMealCount ?? 5),
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
      if (leftoverQuantity < 1e9) {
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

    final modifiedRecipe = slot.recipe.copyWith(
      lastTimeUsed: DateUtils.dateOnly(DateTime.now()),
      timesUsed: slot.recipe.timesUsed + 1,
    );
    final recipeResult = await _recipeRepository.updateRecipe(modifiedRecipe);
    if (recipeResult is RepoError) errorMessage = recipeResult.message;

    isLoading = false;
    notifyListeners();
  }
}