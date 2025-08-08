import 'dart:math';

import 'package:food_manager/domain/models/pantry_item.dart';
import 'package:food_manager/domain/models/recipe.dart';

class MealPlan {
  DateTime dayZero;
  int mealsPerDay;
  List<MealPlanSlot> plan;

  MealPlan({
    required this.dayZero,
    required this.mealsPerDay,
    required this.plan,
  });

  void clearPastDays(DateTime newDayZero) {
    final diff = newDayZero.difference(dayZero).inDays;
    plan = plan.sublist(diff);
    plan.addAll(List.generate(14 - plan.length, (_) => MealPlanSlot(recipes: [])));
    dayZero = newDayZero;
  }

  // TODO: do we need those?
  double getKcalDate(DateTime date) => getKcalDay(date.difference(dayZero).inDays);

  double getKcalDay(int day) {
    if (day < 0 || day > plan.length) throw ArgumentError("Date out of bounds.");

    return plan[day].totalKcal;
  }
}

class MealPlanSlot {
  final List<({Recipe recipe, Map<String, List<({PantryItem item, double quantity})>> ingredients})> _recipes;
  double totalKcal = 0;
  double totalProtein = 0;
  double totalFat = 0;
  double totalCarbs = 0;
  double totalQuantity = 0;

  List<({Recipe recipe, Map<String, List<({PantryItem item, double quantity})>> ingredients})> get recipes =>
      List.unmodifiable(_recipes);

  MealPlanSlot({
    required List<({Recipe recipe, Map<String, List<({PantryItem item, double quantity})>> ingredients})> recipes,
  }) : _recipes = recipes {
    for (final entry in _recipes) {
      for (final recipeIngredient in entry.recipe.ingredients) {
        final ingredientComponents = entry.ingredients[recipeIngredient.tag.name];
        if (ingredientComponents == null) throw ArgumentError("Ingredient list doesn't match recipe.");

        for (final component in ingredientComponents) {
          final product = component.item.product;
          totalKcal += product.calories * component.quantity / recipeIngredient.amount;
          totalProtein += product.protein * component.quantity / recipeIngredient.amount;
          totalFat += product.fat * component.quantity / recipeIngredient.amount;
          totalCarbs += product.carbs * component.quantity / recipeIngredient.amount;
          totalQuantity += component.quantity;
        }
      }
    }
  }

  void addRecipe(Recipe recipe, Map<String, List<({PantryItem item, double quantity})>> ingredients) {
    for (final recipeIngredient in recipe.ingredients) {
      final ingredientComponents = ingredients[recipeIngredient.tag.name];
      if (ingredientComponents == null) throw ArgumentError("Ingredient list doesn't match recipe.");

      for (final component in ingredientComponents) {
        final product = component.item.product;
        totalKcal += product.calories * component.quantity / recipeIngredient.amount;
        totalProtein += product.protein * component.quantity / recipeIngredient.amount;
        totalFat += product.fat * component.quantity / recipeIngredient.amount;
        totalCarbs += product.carbs * component.quantity / recipeIngredient.amount;
        totalQuantity += component.quantity;
      }
    }

    _recipes.add((recipe: recipe, ingredients: ingredients));
  }

  void removeRecipe(({Recipe recipe, Map<String, List<({PantryItem item, double quantity})>> ingredients}) value) {
    for (final recipeIngredient in value.recipe.ingredients) {
      final ingredientComponents = value.ingredients[recipeIngredient.tag.name];
      if (ingredientComponents == null) throw ArgumentError("Ingredient list doesn't match recipe.");

      for (final component in ingredientComponents) {
        final product = component.item.product;
        totalKcal -= product.calories * component.quantity / recipeIngredient.amount;
        totalProtein -= product.protein * component.quantity / recipeIngredient.amount;
        totalFat -= product.fat * component.quantity / recipeIngredient.amount;
        totalCarbs -= product.carbs * component.quantity / recipeIngredient.amount;
        totalQuantity -= component.quantity;
      }
    }

    // probably unnecessary
    totalKcal = max(totalKcal, 0);
    totalProtein = max(totalProtein, 0);
    totalFat = max(totalFat, 0);
    totalCarbs = max(totalCarbs, 0);

    _recipes.remove(value);
  }
}