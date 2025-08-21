import 'dart:math';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:food_manager/domain/models/meal_planner/meal_plan.dart';
import 'package:food_manager/domain/models/meal_planner/meal_plan_constraints.dart';
import 'package:food_manager/domain/models/meal_planner/meal_planner_config.dart';
import 'package:food_manager/domain/models/pantry_item.dart';
import 'package:food_manager/domain/models/product/local_product.dart';
import 'package:food_manager/domain/models/recipe.dart';
import 'package:collection/collection.dart';


int _leadDays(int d) {
  if (d == 0) return 0;
  if (d <= 3)  return 1;
  if (d <= 7)  return 2;
  if (d <= 14) return 4;
  if (d <= 30) return 7;
  return 14;
}

int _effectiveShelfLifeAfterOpening(int afterOpen, int expected) {
  final needsLead = (afterOpen == expected) && afterOpen > 0;
  if (!needsLead) return afterOpen;
  final lead = _leadDays(afterOpen);
  assert(lead <= afterOpen);
  return afterOpen - lead;
}

double _pantryItemScore(PantryItem item, DateTime date) {
  final unopenedDaysLeft = max(0, item.expirationDate.difference(date).inDays);
  final afterOpen = item.product.shelfLifeAfterOpening;

  // effective days left if we were to use it now
  final effectiveDaysLeft = item.isOpen
      ? unopenedDaysLeft                  // already opened: exp is post-open
      : min(unopenedDaysLeft, afterOpen); // unopened: opening can't extend life

  // prefer opened items, but keep unopened urgency meaningful
  final coeff = item.isOpen ? 1.0 : 0.4;

  return coeff / (1 + effectiveDaysLeft);
}

// _PlanStep should be lightweight as we'll have many of those, _PantryState and _PlanState can be bloated
class _PantryState {
  final Map<String, List<PantryItem>> _items;

  _PantryState._(this._items);

  factory _PantryState.from(Map<String, List<PantryItem>> source) =>
      _PantryState._(source.map((k, v) => MapEntry(k, List.of(v))));

  _PantryState clone() => _PantryState.from(_items);

  List<PantryItem>? getItems(String tag) => _items[tag];

  _PantryState copyAndUpdate(Map<PantryItem, double> items, double epsilon, DateTime date) {
    final newItems = {for (final entry in _items.entries) entry.key: List.of(entry.value)};

    for (final entry in items.entries) {
      final tag = entry.key.product.tag.name;
      final tagItems = newItems[tag];
      final i = tagItems?.indexWhere((it) => it == entry.key) ?? -1; // faster than removeWhere because items are unique
      if (i >= 0) tagItems!.removeAt(i);

      final remainingQuantity = entry.key.quantity - entry.value;
      if (remainingQuantity > epsilon) {
        final expirationDateAfterOpening = date.add(Duration(days: entry.key.product.shelfLifeAfterOpening));
        final newExpirationDate = entry.key.isOpen
            ? entry.key.expirationDate
            : (entry.key.expirationDate.isBefore(expirationDateAfterOpening)
                ? entry.key.expirationDate
                : expirationDateAfterOpening);

        final newItem = entry.key.copyWith(
          quantity: remainingQuantity,
          isOpen: true,
          expirationDate: newExpirationDate,
        );

        if (tagItems == null) {
          newItems[tag] = [newItem];
        } else {
          final currentScore = _pantryItemScore(newItem, date);
          final index = tagItems.indexWhere((e) => _pantryItemScore(e, date) < currentScore);
          tagItems.insert(index >= 0 ? index : tagItems.length, newItem);
        }
      }
    }

    return _PantryState._(newItems);
  }

  // remove items expiring before the date; items expiring on date are still good
  double removeExpired(DateTime date) {
    double waste = 0;

    for (final items in _items.values) {
      for (final item in items) {
        if(item.expirationDate.isBefore(date)) waste += item.quantity;
      }
      items.removeWhere((item) => item.expirationDate.isBefore(date));
    }

    return waste;
  }
}

class _PlanState {
  final Set<Recipe> chosenRecipes;
  final _PantryState pantry;
  final _PlanStep lastStep;
  final DateTime date;
  final double waste;
  final double score;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  _PlanState({
    required this.chosenRecipes,
    required this.pantry,
    required this.lastStep,
    required this.date,
    required this.waste,
    required this.score,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory _PlanState.fromStep(_PlanStep step, _PantryState pantry, double epsilon, DateTime date) {
    final items = <PantryItem, double>{};
    final recipes = <Recipe>{};
    double totalScore = 0;
    double calories = 0;
    double protein = 0;
    double carbs = 0;
    double fat = 0;

    for (_PlanStep? currentStep = step; currentStep != null; currentStep = currentStep.parent) {
      assert(currentStep.parent == null || currentStep.recipe != null); // recipe can only be null in root step
      if (currentStep.recipe == null) continue;

      recipes.add(currentStep.recipe!);
      totalScore += currentStep.score;

      for (final entry in currentStep.usedItems) {
        final quantity = entry.quantity;
        final product = entry.item.product;

        items[entry.item] = (items[entry.item] ?? 0) + quantity;

        calories += product.caloriesPerUnit * quantity;
        protein += product.proteinPerUnit * quantity;
        carbs += product.carbsPerUnit * quantity;
        fat += product.fatPerUnit * quantity;
      }
    }

    final newPantry = pantry.copyAndUpdate(items, epsilon, date);
    final waste = newPantry.removeExpired(date);

    return _PlanState(
      chosenRecipes: recipes,
      pantry: newPantry,
      lastStep: step,
      date: date,
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

// TODO:
// maybe add Result wrapper like for repos?
class MealPlanner {
  MealPlanner({required this.config});

  // TODO move this to the config class later
  final MealPlannerConfig config;
  final int planLength = 14;
  final double acceptableError = 0.05;
  final double epsilon = 0.0001; // we're cooking not launching a rocket

  MealPlan generatePlan({
    required List<LocalProduct> products,
    required List<PantryItem> pantryItems,
    required List<Recipe> recipes,
    required MealPlanConstraints constraints,
    required MealPlan currentPlan,
  }) {
    // ##################################################### PREPARE SOME GENERAL VALUES
    final today = DateUtils.dateOnly(DateTime.now());
    currentPlan.clearPastDays(today, planLength);

    pantryItems = pantryItems.where((i) => i.isBought).toList();
    recipes = recipes.map((e) => e.copyWith()).toList(growable: false);
    final recipesUsedTemp = Map.fromEntries(recipes.map((e) => MapEntry(e.id!, e.timesUsed)));
    final recipesLastUsedTemp = Map.fromEntries(recipes.map((e) => MapEntry(e.id!, e.lastTimeUsed)));

    // ##################################################### PREPARE AUXILIARY TAG-[PRODUCT] MAP

    final Map<String, List<LocalProduct>> tagProductsMap = {};
    for (final product in products) {
      if (tagProductsMap.containsKey(product.tag.name)) {
        tagProductsMap[product.tag.name]!.add(product);
      } else {
        tagProductsMap[product.tag.name] = [product];
      }
    }

    for (final productList in tagProductsMap.values) {
      productList.sort((a, b) => (a.containerSize ?? -1).compareTo(b.containerSize ?? -1));
    }

    // ##################################################### PREPARE AUXILIARY TAG-[PANTRY ITEM] MAP

    final Map<String, List<PantryItem>> tagPantryItemsMap = {};
    for (final item in pantryItems) {
      if (tagPantryItemsMap.containsKey(item.product.tag.name)) {
        tagPantryItemsMap[item.product.tag.name]!.add(item);
      } else {
        tagPantryItemsMap[item.product.tag.name] = [item];
      }
    }

    for (final pantryItemList in tagPantryItemsMap.values) {
      pantryItemList.sort((a, b) => _pantryItemScore(b, today).compareTo(_pantryItemScore(a, today)));  // desc. order
    }

    // ##################################################### RANK RECIPES

    List<_PlanStep> expandPlan(_PlanState planState) {
      final pantry = planState.pantry.clone();
      final resultList = <_PlanStep>[];

      recipesLoop:
      for (final recipe in recipes) {
        if (planState.chosenRecipes.contains(recipe)) continue;

        final pickedItems = <({PantryItem item, double quantity})>[];
        final itemsToBuy = <({PantryItem item, double quantity})>[];
        double totalScore = 0;

        for (final recipeIngredient in recipe.ingredients) {
          final matchingProducts = tagProductsMap[recipeIngredient.tag.name]?.where(
                  (e) => e.units.containsKey(recipeIngredient.unit)).toList() ?? [];
          final pantryItems = pantry.getItems(recipeIngredient.tag.name)
              ?.where((e) => e.product.units.containsKey(recipeIngredient.unit)) ?? [];

          // a recipe with missing ingredients can't be used
          if (matchingProducts.isEmpty) continue recipesLoop;

          double totalQuantity = 0;

          // pick the item(s) that maximizes the cost reduction, they're already sorted
          for (final pantryItem in pantryItems) {
            final ratio = pantryItem.product.units[recipeIngredient.unit]!;
            final unopenedDaysLeft = max(0, pantryItem.expirationDate.difference(planState.date).inDays);
            final afterOpenDays = pantryItem.product.shelfLifeAfterOpening;

            final daysLeftNow = pantryItem.isOpen
                ? unopenedDaysLeft                      // already opened: exp is post opening
                : min(unopenedDaysLeft, afterOpenDays); // unopened: opening can't extend

            final convertedQuantity = pantryItem.quantity / ratio; // in recipe units
            double need = recipeIngredient.amount - totalQuantity;
            double takeRecipeUnits = min(convertedQuantity, need);

            if (totalQuantity + convertedQuantity <= recipeIngredient.amount * (1 + acceptableError)) {
              takeRecipeUnits = convertedQuantity; // finish the item if it's within tolerance
            }

            final usedBase = takeRecipeUnits * ratio; // g/ml
            final leftoverBase = pantryItem.quantity - usedBase;

            pickedItems.add((item: pantryItem, quantity: usedBase));

            if (pantryItem.isOpen) {
              totalScore += usedBase / (1 + daysLeftNow);
            } else {
              final potentialWaste = max(0.0, leftoverBase); // FP safety
              totalScore -= potentialWaste / (1 + daysLeftNow);
            }

            totalQuantity += takeRecipeUnits;
          }

          double remainingQuantityLow = recipeIngredient.amount * (1 - acceptableError) - totalQuantity;
          double remainingQuantityHigh = recipeIngredient.amount * (1 + acceptableError) - totalQuantity;
          double remainingQuantity = recipeIngredient.amount - totalQuantity;

          // if the total quantity is too small pick the best product that will fill in the gap

          // add variable weight
          if (remainingQuantityLow > 0) {
            for (final product in matchingProducts) {
              assert (product.units[recipeIngredient.unit] != null);
              final unitConversionRatio = product.units[recipeIngredient.unit]!;

              // no container size means we can just pick the remaining quantity
              if (product.containerSize != null) break;

              final effectiveShelfLife = _effectiveShelfLifeAfterOpening(
                product.shelfLifeAfterOpening,
                product.expectedShelfLife,
              );
              final expirationDate = planState.date.add(Duration(days: effectiveShelfLife));

              itemsToBuy.add((
                item: PantryItem(
                  product: product,
                  quantity: remainingQuantity * unitConversionRatio,
                  expirationDate: expirationDate,
                  isOpen: true,
                  isBought: false,
                ),
                quantity: remainingQuantity * unitConversionRatio,
              ));

              remainingQuantityLow -= remainingQuantity;
              totalQuantity += remainingQuantity;

              break;
            }
          }

          // add full containers while they fit
          if (remainingQuantityLow > 0) {
            // because containerSize == null products should precede others
            final idx = matchingProducts.indexWhere((e) => e.containerSize != null);
            final productsWithContainerSize = idx == -1 ? const <LocalProduct>[] : matchingProducts.sublist(idx);

            for (final product in productsWithContainerSize.reversed) {
              assert(product.containerSize != null);
              final unitConversionRatio = product.units[recipeIngredient.unit];
              if (unitConversionRatio == null) continue;

              final convertedQuantity = product.containerSize! / unitConversionRatio;

              if (convertedQuantity > remainingQuantityHigh) continue;

              final effectiveShelfLife = _effectiveShelfLifeAfterOpening(
                product.shelfLifeAfterOpening,
                product.expectedShelfLife,
              );
              final expirationDate = planState.date.add(Duration(days: effectiveShelfLife));

              final count = (remainingQuantity / convertedQuantity).floor();

              itemsToBuy.addAll(
                List.generate(count, (_) => (
                  item: PantryItem(
                    product: product,
                    quantity: product.containerSize!,
                    expirationDate: expirationDate,
                    isOpen: true,
                    isBought: false,
                  ),
                  quantity: product.containerSize!,
                )),
              );

              final usedUp = convertedQuantity * count;
              remainingQuantityLow -= usedUp;
              remainingQuantity -= usedUp;
              remainingQuantityHigh -= usedUp;

              totalQuantity += usedUp;
            }

            // fill in with containers even if they don't fit
            if (remainingQuantityLow > 0) {
              if (productsWithContainerSize.isEmpty) continue recipesLoop;
              final product = productsWithContainerSize.first;

              assert(product.containerSize != null);
              final unitConversionRatio = product.units[recipeIngredient.unit]!;

              final effectiveShelfLife = _effectiveShelfLifeAfterOpening(
                product.shelfLifeAfterOpening,
                product.expectedShelfLife,
              );
              final expirationDate = planState.date.add(Duration(days: effectiveShelfLife));

              itemsToBuy.add((
                item: PantryItem(
                  product: product,
                  quantity: product.containerSize!,
                  expirationDate: expirationDate,
                  isOpen: true,
                  isBought: false,
                ),
                quantity: remainingQuantity * unitConversionRatio,
              ));

              final usedNow = remainingQuantity * unitConversionRatio;
              final potentialWaste = max(0, product.containerSize! - usedNow);
              totalScore -= potentialWaste / (effectiveShelfLife + 1);
              totalQuantity += remainingQuantity;
            }
          }
        }

        // TODO tweak penalties?
        const double weightFreq = 1.2;
        const double weightRec = 50;
        final timesUsed = recipe.timesUsed + (recipesUsedTemp[recipe.id] ?? 0);
        final DateTime? lastTimeUsed = recipesLastUsedTemp[recipe.id] ?? recipe.lastTimeUsed;

        final recencyPenalty = (lastTimeUsed == null)
            ? 0.0
            : (planState.date.difference(lastTimeUsed).inDays < 2 ? weightRec : 0.0);

        final over = max(0, timesUsed - 2);
        final frequencyPenalty = weightFreq * over * over;

        final finalScore = totalScore - recencyPenalty * frequencyPenalty;

        pickedItems.addAll(itemsToBuy);
        resultList.add(
          _PlanStep(
            parent: planState.lastStep,
            recipe: recipe,
            usedItems: pickedItems,
            score: finalScore,
          ),
        );
      }

      resultList.sort((a, b) => a.score.compareTo(b.score));
      dev.log('MAX:${resultList.last.score}\tMIN:${resultList.first.score}');
      return resultList;
    }

    // ##################################################### FIND BEST PLAN

    var pantry = _PantryState.from(tagPantryItemsMap);

    mainLoop:
    for (int i = 0; i < currentPlan.length; i++) {
      final day = currentPlan.plan[i];
      final currentDayDate = today.add(Duration(days: i));

      dev.log('Generating plan for ${currentDayDate.toString().split(" ").firstOrNull}', name: 'MealPlanner');

      // ############ LOAD RECIPES FROM THE PLAN
      _PlanStep parentStep = _PlanStep(parent: null, recipe: null, usedItems: [], score: 0);

      for (final slot in day) {
        parentStep = _PlanStep(
          parent: parentStep,
          recipe: slot.recipe,
          usedItems: slot.ingredients.values.flattenedToList,
          score: 0,
        );
      }

      // ############ INITIALIZE THE QUEUE
      final planQueue = PriorityQueue<_PlanStep>((a, b) => b.score.compareTo(a.score));
      final startingStep = parentStep;
      planQueue.add(startingStep);

      // ############ BEST FIRST SEARCH
      while(planQueue.isNotEmpty) {
        // ############ LOAD AND RECREATE THE PlanState
        final currentStep = planQueue.first;
        planQueue.removeFirst();
        final currentState = _PlanState.fromStep(currentStep, pantry, epsilon, currentDayDate);

        //dev.log("current state: [${currentState.calories} kcal]");

        bool inRange(num value, ({num lower, num upper}) range) =>
            range.lower <= value && value <= range.upper;

        // ############ IF THE DAILY PLAN SATISFIES THE CRITERIA ADD IT TO THE FINAL PLAN
        if (inRange(currentState.chosenRecipes.length, currentPlan.mealsPerDayRange) &&
            inRange(currentState.calories, constraints.calorieRange) &&
            inRange(currentState.protein, constraints.proteinRange) &&
            inRange(currentState.carbs, constraints.carbsRange) &&
            inRange(currentState.fat, constraints.fatRange)) {

          // ############ CREATE A LIST OF SLOTS FROM CURRENT STATE
          final slots = <MealPlanSlot>[];

          for (_PlanStep? step = currentStep; step != null; step = step.parent) {
            assert(step.recipe != null || step.parent == null);
            if(step.recipe == null) continue;
            final tagIngredientsMap = <String, List<({PantryItem item, double quantity})>>{};
            double calories = 0;
            double protein = 0;
            double carbs = 0;
            double fat = 0;

            final normalizedByUuid = <String, PantryItem>{};

            for (final entry in step.usedItems) {
              final item = entry.item;
              final product = item.product;
              final tagName = product.tag.name;
              final quantity = entry.quantity;
              PantryItem normalizedItem = item.isBought || product.containerSize == null
                  ? item
                  : item.copyWith(quantity: product.containerSize);
              normalizedItem = !item.isBought && product.expectedShelfLife != product.shelfLifeAfterOpening
                  ? normalizedItem.copyWith(isOpen: false)
                  : normalizedItem;

              final fromMap = normalizedByUuid[item.uuid];
              if (fromMap != null) {
                normalizedItem = fromMap;
              } else {
                normalizedByUuid[item.uuid] = normalizedItem;
              }

              if (tagIngredientsMap.containsKey(tagName)) {
                tagIngredientsMap[product.tag.name]?.add((item: normalizedItem, quantity: quantity));
              } else {
                tagIngredientsMap[product.tag.name] = [(item: normalizedItem, quantity: quantity)];
              }

              calories += product.caloriesPerUnit * quantity;
              protein += product.proteinPerUnit * quantity;
              carbs += product.carbsPerUnit * quantity;
              fat += product.fatPerUnit * quantity;

              assert(item.isBought || product.containerSize == null || quantity <= product.containerSize! + epsilon);
            }

            final used = recipesUsedTemp[step.recipe!.id!];
            assert(used != null);
            recipesUsedTemp[step.recipe!.id!] = (used ?? 0) + 1;
            recipesLastUsedTemp[step.recipe!.id!] = currentDayDate;

            // ############ ADD THE DAILY PLAN TO FINAL RESULT
            slots.add(MealPlanSlot(
              recipe: step.recipe!,
              ingredients: tagIngredientsMap,
              calories: calories,
              protein: protein,
              carbs: carbs,
              fat: fat,
              isEaten: false,
              isValid: true,
            ));
          }
          currentPlan.plan[i] = slots;
          currentPlan.waste[i] = currentState.waste;

          pantry = currentState.pantry;
          continue mainLoop;
        }
        // TODO add more conditions?
        if (currentState.chosenRecipes.length >= currentPlan.mealsPerDayRange.upper) continue;

        // ############ LOAD AND RECREATE THE PlanState
        final newSteps = expandPlan(currentState);
        planQueue.addAll(newSteps); // TODO quickselect top 50 to limit max branching factor?
      }
      // TODO failed to generate a plan for this day, fail loudly?
    }

    // ##################################################### RETURN RESULT

    return currentPlan;
  }
}