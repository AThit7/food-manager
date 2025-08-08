import 'dart:math';

import 'package:food_manager/domain/models/meal_planner/meal_plan.dart';
import 'package:food_manager/domain/models/meal_planner/meal_plan_constraints.dart';
import 'package:food_manager/domain/models/meal_planner/meal_planner_config.dart';
import 'package:food_manager/domain/models/pantry_item.dart';
import 'package:food_manager/domain/models/product/local_product.dart';
import 'package:food_manager/domain/models/recipe.dart';
import 'package:collection/collection.dart';


double _pantryItemScore(PantryItem item, DateTime date, int maxShelfLifeDays) {
  int expires;

  if (item.isOpen) {
    expires = item.expirationDate.difference(date).inDays;
  } else {
    expires = item.product.shelfLifeAfterOpening ?? maxShelfLifeDays;
  }

  final penaltyA = item.isOpen ? 1.0 : 0.9;

  final score = penaltyA / expires;

  return score;
}

// _PlanStep should be lightweight as we'll have many of those, _PantryState and _PlanState can be bloated
class _PantryState {
  final Map<String, List<PantryItem>> _items;

  _PantryState._(this._items);

  factory _PantryState.from(Map<String, List<PantryItem>> source) =>
      _PantryState._(source.map((k, v) => MapEntry(k, List.of(v))));

  _PantryState clone() => _PantryState.from(_items);

  List<PantryItem>? getItems(String tag) => _items[tag];

  _PantryState copyAndUpdate(Map<PantryItem, double> items, double epsilon, DateTime date, int maxShelfLifeDays) {
    final newItems = {for (final entry in _items.entries) entry.key: List.of(entry.value)};

    for (final entry in items.entries) {
      final tag = entry.key.product.tag.name;
      final tagItems = newItems[tag];
      final match = (tagItems ?? []).where((item) => item == entry.key); // TODO: can be change to firstWhere
      assert(match.length < 2);

      if (match.isNotEmpty) {
        tagItems!.remove(match.first);
      }

      final remainingQuantity = entry.key.quantity - entry.value;
      if (remainingQuantity > epsilon) {
        final newItem = entry.key.copyWith(quantity: remainingQuantity);
        if (tagItems == null) {
          newItems[tag] = [newItem];
        } else {
          final currentScore = _pantryItemScore(newItem, date, maxShelfLifeDays);
          final index = tagItems.indexWhere((e) => _pantryItemScore(e, date, maxShelfLifeDays) < currentScore);
          tagItems.insert(index >= 0 ? index : tagItems.length, newItem);
        }
      }
    }

    return _PantryState._(newItems);
  }

  double removeExpired(DateTime date) {
    double waste = 0;

    for (final items in _items.values) {
      for (final item in items) {
        if(item.expirationDate.isBefore(date)) waste += item.quantity;
      }
    }

    for (final items in _items.values) {
      items.removeWhere((item) => item.expirationDate.isBefore(date));
    }

    return waste;
  }
}

class _PlanState {
  final Set<Recipe> chosenRecipes;
  final _PantryState pantry;
  final double waste;
  final double score;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  _PlanState({
    required this.chosenRecipes,
    required this.pantry,
    required this.waste,
    required this.score,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory _PlanState.fromStep(_PlanStep step, _PantryState pantry, double epsilon, DateTime date, int maxShelfLife) {
    final items = <PantryItem, double>{};
    final recipes = <Recipe>{};
    double totalScore = 0;
    double calories = 0;
    double protein = 0;
    double carbs = 0;
    double fat = 0;

    for (_PlanStep? currentStep = step; currentStep != null; currentStep = currentStep.parent) {
      assert(step.recipe != null);
      if (currentStep.recipe == null) continue;

      recipes.add(currentStep.recipe!);
      totalScore += currentStep.score;

      for (final entry in currentStep.usedItems) {
        final quantity = entry.quantity;
        final product = entry.item.product;

        items[entry.item] = (items[entry.item] ?? 0) + quantity;

        calories += product.calories * quantity;
        protein += product.protein * quantity;
        carbs += product.carbs * quantity;
        fat += product.fat * quantity;
      }
    }

    final newPantry = pantry.copyAndUpdate(items, epsilon, date, maxShelfLife);
    final waste = newPantry.removeExpired(date);

    return _PlanState(
      chosenRecipes: recipes,
      pantry: newPantry,
      waste: waste,
      score: totalScore,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
    );
  }
}

class _PlanStep {
  final _PlanStep? parent;
  final Recipe? recipe;
  final double score;

  final List<({PantryItem item, double quantity})> usedItems;

  _PlanStep({
    required this.parent,
    required this.recipe,
    required this.usedItems,
    required this.score,
  });
}

class MealPlanner {
  MealPlanner({required this.config});

  final MealPlannerConfig config;
  final int maxRecipePoolSize = 20;
  final int planLength = 14;
  final int wasteArrayLength = 10;
  final double acceptableError = 0.05;
  final int maxShelfLifeDays = 99999;
  final double epsilon = 0.005;
  final double frequencyWeight = 0;
  final double recencyWeight = 0;
  final double bestScoreSimilarityThreshold = 0.2;
  final double requirementsLowerMargin = 0.9;
  final double requirementsUpperMargin = 1.1;

  MealPlan generatePlan({
    required List<LocalProduct> products,
    required List<PantryItem> pantryItems,
    required List<Recipe> recipes,
    required MealPlanConstraints constraints,
    required MealPlan currentPlan,
  }) {
    final today = DateTime.now();
    // TODO:
    // add recipe.last_time_used
    // add tag-product map
    // add tag-pantry_item(s) map
    // days_before-expires-{qt_sum, [{quantity, item}]} map
    // deep copy the currentPLan first?
    // remove expired pantry items?

    // ##################################################### PREPARE AUXILIARY TAG-[PRODUCT] MAP

    final Map<String, List<LocalProduct>> tagProductsMap = {};
    for (final product in products) {
      if (tagProductsMap.containsKey(product.tag.name)) {
        tagProductsMap[product.tag.name]!.add(product);
      } else {
        tagProductsMap[product.tag.name] = [product];
      }
    }

    // ##################################################### PREPARE AUXILIARY TAG-[PANTRY ITEM] MAP

    final Map<String, List<PantryItem>> tagPantryItemsMap = {};
    for (final item in pantryItems) {
      if (tagProductsMap.containsKey(item.product.tag.name)) {
        tagPantryItemsMap[item.product.tag.name]!.add(item);
      } else {
        tagPantryItemsMap[item.product.tag.name] = [item];
      }
    }

    for (final pantryItemList in tagPantryItemsMap.values) {
      pantryItemList.sort((a, b) {
        int expiresA;
        int expiresB;

        if (a.isOpen) {
          expiresA = a.expirationDate.difference(currentPlan.dayZero).inDays;
        } else {
          expiresA = a.product.shelfLifeAfterOpening ?? maxShelfLifeDays;
        }

        if (b.isOpen) {
          expiresB = b.expirationDate.difference(currentPlan.dayZero).inDays;
        } else {
          expiresB = b.product.shelfLifeAfterOpening ?? maxShelfLifeDays;
        }

        final penaltyA = a.isOpen ? 1.0 : 0.9;
        final penaltyB = b.isOpen ? 1.0 : 0.9;

        final scoreA = penaltyA / expiresA;
        final scoreB = penaltyB / expiresB;

        return scoreB.compareTo(scoreA); // descending order
      });
    }

    // ##################################################### PREPARE AUXILIARY PRODUCT-[PANTRY ITEM] MAP

    final Map<int, List<PantryItem>> productPantryItemsMap = {};
    for (final pantryItem in pantryItems) {
      if (pantryItem.product.id == null) {
        throw ArgumentError("Product without an id was used.");
      }

      if (productPantryItemsMap.containsKey(pantryItem.product.id)) {
        productPantryItemsMap[pantryItem.product.id]!.add(pantryItem);
      } else {
        productPantryItemsMap[pantryItem.product.id!] = [pantryItem];
      }
    }

    for (final pantryItemList in productPantryItemsMap.values) {
      pantryItemList.sort((a, b) => a.expirationDate.compareTo(b.expirationDate));
    }

    // ##################################################### POPULATE WASTE ARRAY
    // TODO: how to incorporate it in the scoring? so far it's useless

    // remove days before today and add new ones
    currentPlan.clearPastDays(today);

    // add all the expiring products to the waste table
    final List<double> wasteByDay = List.generate(wasteArrayLength + 1, (_) => 0);
    for (final pantryItem in pantryItems) {
      final expiresIn = pantryItem.expirationDate.difference(today).inDays;
      final index = min(expiresIn, wasteArrayLength);
      wasteByDay[index] += pantryItem.quantity;
    }

    // go over the plan and subtract the items that will be used as they won't be wasted
    for (int day = 0; day < currentPlan.plan.length; day++) {
      wasteByDay[day] -= currentPlan.plan[day].totalQuantity;
    }

    // ##################################################### RANK RECIPES

    List<_PlanStep> expandPlan(_PlanState planState) {
      final recipeRanking = <({double score, Recipe recipe, List<({PantryItem item, double quantity})> pickedItems})>[];
      double bestScore = double.negativeInfinity;
      final pantry = planState.pantry.clone();

      recipesLoop:
      for (final recipe in recipes) {
        if (planState.chosenRecipes.contains(recipe)) continue;
        double wasteScore = 0;
        final pickedItems = <({PantryItem item, double quantity})>[];

        for (final recipeIngredient in recipe.ingredients) {
          final products = tagProductsMap[recipeIngredient.tag.name];
          final pantryItems = pantry.getItems(recipeIngredient.tag.name) ?? [];

          if (products == null) continue recipesLoop; // a recipe with missing ingredients can't be used

          double totalQuantity = 0;
          double totalScore = 0;

          bool lowerBoundSatisfied = false;

          // pick the item(s) that maximizes the cost reduction, they're already sorted
          for (final pantryItem in pantryItems) {
            final unitConversionRatio = pantryItem.product.units[recipeIngredient.unit];
            if (unitConversionRatio == null) continue;

            final expiresIn = pantryItem.isOpen || pantryItem.product.shelfLifeAfterOpening == null
                ? currentPlan.dayZero
                .difference(pantryItem.expirationDate)
                .inDays
                : pantryItem.product.shelfLifeAfterOpening!;

            assert(expiresIn >= 0);
            if (expiresIn < 0) continue;

            final convertedQuantity = pantryItem.quantity / unitConversionRatio;
            double quantity = min(convertedQuantity, (recipeIngredient.amount - totalQuantity));

            // if the leftover is negligible, just use the whole item
            if (totalQuantity + convertedQuantity <= recipeIngredient.amount * (1 + acceptableError)) {
              quantity = convertedQuantity;
            }

            pickedItems.add((item: pantryItem, quantity: quantity * unitConversionRatio));
            totalScore += quantity / (expiresIn + 1);
            totalQuantity += quantity;

            if (totalQuantity >= recipeIngredient.amount * (1 - acceptableError)) {
              if (lowerBoundSatisfied) {
                break;
              } else {
                lowerBoundSatisfied = true;
                continue;
              }
            }
          }

          // TODO we don't want to remove it here yet, do it after picking recipe for the slot, already done?
          if (pickedItems.isNotEmpty) {
            assert(pickedItems.length <= pantryItems.length, 'Picked more items than exist in pantry');
            // remove used up items, if the last item wasn't used up fully change its quantity, otherwise, remove it
            final lastItemRemainingQuantity = pickedItems.last.item.quantity - pickedItems.last.quantity;
            if (lastItemRemainingQuantity > epsilon) {
              pantryItems.removeRange(0, pickedItems.length - 1);
              pantryItems[0] = pantryItems[0].copyWith(quantity: lastItemRemainingQuantity);
            } else {
              pantryItems.removeRange(0, pickedItems.length);
            }
          }

          // if the total quantity is too small pick the best product that will fill in the gap
          if (totalQuantity < recipeIngredient.amount * (1 - acceptableError)) {
            final itemsToBuy = <({PantryItem item, double quantity})>[];

            for (final product in products) {
              // TODO
            }
          }

          wasteScore = totalScore;
        }

        // TODO
        final recencyPenalty = 0;
        final frequencyPenalty = 0;

        final finalScore = wasteScore + recencyPenalty + frequencyPenalty;
        recipeRanking.add((score: finalScore, recipe: recipe, pickedItems: pickedItems));

        bestScore = max(bestScore, finalScore); // TODO remove?
        return [];
      }

      return [];
    }

    final pantry = _PantryState._(tagPantryItemsMap);
    DateTime currentDay = today.subtract(Duration(days: 1));

    for (final day in currentPlan.plan) {
      currentDay = currentDay.add(Duration(days: 1));

      // TODO: read current plan first

      final startingStep = _PlanStep(
        parent: null,
        recipe: null,
        usedItems: [],
        score: 0,
      );

      final planQueue = PriorityQueue<_PlanStep>((a, b) => a.score.compareTo(b.score));
      planQueue.add(startingStep);

      while(planQueue.isNotEmpty) {
        final currentStep = planQueue.first;
        planQueue.removeFirst();
        final currentState = _PlanState.fromStep(currentStep, pantry, epsilon, currentDay, maxShelfLifeDays);

        bool inRange(double value, ({double lower, double upper}) range) =>
            range.lower <= value && value < range.upper;

        // if plan is a valid final plan
        if (inRange(currentState.calories, constraints.calorieRange) &&
            inRange(currentState.protein, constraints.proteinRange) &&
            inRange(currentState.carbs, constraints.carbsRange) &&
            inRange(currentState.fat, constraints.fatRange)) {

          for (_PlanStep? step = currentStep; step != null; step = step.parent) {
            assert(step.recipe != null);
            if(step.recipe == null) continue;
            final tagIngredientsMap = <String, List<({PantryItem item, double quantity})>>{};

            for (final entry in step.usedItems) {
              final tagName = entry.item.product.tag.name;
              if (tagIngredientsMap.containsKey(tagName)) {
                tagIngredientsMap[entry.item.product.tag.name]?.add((item: entry.item, quantity: entry.quantity));
              } else {
                tagIngredientsMap[entry.item.product.tag.name] = [(item: entry.item, quantity: entry.quantity)];
              }
            }

            day.addRecipe(step.recipe!, tagIngredientsMap);
          }

        }

        final newSteps = expandPlan(currentState);
        planQueue.addAll(newSteps);
      }
    }

    return currentPlan;
  }
}