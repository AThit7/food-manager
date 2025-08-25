// cleaned up version of meal_planner.dart, in progress

import 'dart:math';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:food_manager/core/result/result.dart';
import 'package:food_manager/domain/models/meal_plan.dart';
import 'package:food_manager/application/models/meal_plan_constraints.dart';
import 'package:food_manager/application/config/meal_planner_config.dart';
import 'package:food_manager/domain/models/pantry_item.dart';
import 'package:food_manager/domain/models/local_product.dart';
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

  /// remove items expiring before the [date]; items expiring on [date] are still good
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
  final _PlanNode lastStep;
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

  factory _PlanState.fromStep(_PlanNode step, _PantryState pantry, double epsilon, DateTime date) {
    final items = <PantryItem, double>{};
    final recipes = <Recipe>{};
    double totalScore = 0;
    double calories = 0;
    double protein = 0;
    double carbs = 0;
    double fat = 0;

    for (_PlanNode? currentStep = step; currentStep is _PlanStep; currentStep = currentStep.parent) {
      recipes.add(currentStep.recipe);
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

sealed class _PlanNode implements Comparable<_PlanNode> {
  @override
  int compareTo(_PlanNode other) {
    if (this is _PlanRoot && other is _PlanStep) return -1;
    if (this is _PlanStep && other is _PlanRoot) return 1;
    if (this is _PlanRoot && other is _PlanRoot) return 0;

    final a = this as _PlanStep;
    final b = other as _PlanStep;
    return a.score.compareTo(b.score);
  }
}

class _PlanRoot extends _PlanNode {}

class _PlanStep extends _PlanNode {
  final _PlanNode parent;
  final Recipe recipe;
  final double score;

  final List<({PantryItem item, double quantity})> usedItems;

  _PlanStep({
    required this.parent,
    required this.recipe,
    required this.usedItems,
    required this.score,
  });
}

bool _isValidSolution (_PlanState state, MealPlanConstraints constraints) {
  bool inRange(num value, ({num lower, num upper}) range) =>
      range.lower <= value && value <= range.upper;

  return (inRange(state.chosenRecipes.length, constraints.fatRange) && // TODO add calorie range to constraints
      inRange(state.calories, constraints.calorieRange) &&
      inRange(state.protein, constraints.proteinRange) &&
      inRange(state.carbs, constraints.carbsRange) &&
      inRange(state.fat, constraints.fatRange));
}

List<MealPlanSlot> _buildDayFromState() => [];

class MealPlanner {
  MealPlanner({required this.config});

  final MealPlannerConfig config;
  final double acceptableError = 0.05;
  final double epsilon = 0.0001;
  final int planLength = 14;

  Result<MealPlan> generatePlan({
    required List<LocalProduct> products,
    required List<PantryItem> pantryItems,
    required List<Recipe> recipes,
    required MealPlanConstraints constraints,
    required MealPlan currentPlan,
  }) {
    final today = DateUtils.dateOnly(DateTime.now());
    currentPlan.clearPastDays(today, planLength);
    pantryItems = pantryItems.where((i) => i.isBought).toList();
    recipes = recipes.map((e) => e.copyWith()).toList(growable: false);
    final recipesUsedTemp = Map.fromEntries(recipes.map((e) => MapEntry(e.id!, e.timesUsed)));
    final recipesLastUsedTemp = Map.fromEntries(recipes.map((e) => MapEntry(e.id!, e.lastTimeUsed)));

    // #####################################################

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

    // #####################################################

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

    // ################# MAIN PART #######################

    var pantry = _PantryState.from(tagPantryItemsMap);

    for (int i = 0; i < currentPlan.length; i++) {
      final currentDayDate = today.add(Duration(days: i));
      dev.log('Generating plan for ${currentDayDate.toString().split(" ").firstOrNull}', name: 'MealPlanner');

      // init queue
      final planQueue = PriorityQueue<_PlanNode>();
      final startingStep = _PlanRoot();
      planQueue.add(startingStep);

      // time constraints
      final deadline = DateTime.now().add(const Duration(milliseconds: 300));
      int visited = 0, maxVisited = 500000000;

      while(planQueue.isNotEmpty) {
        if(DateTime.now().isAfter(deadline) || visited >= maxVisited) break;
        maxVisited++;

        final currentStep = planQueue.removeFirst();
        final currentState = _PlanState.fromStep(currentStep, pantry, epsilon, currentDayDate);

        if (_isValidSolution(currentState, constraints)) {
          currentPlan.plan[i] = _buildDayFromState(currentState);
          currentPlan.waste[i] = currentState.waste;
          break;
        }

        if (_shouldPrune(currentState)) continue;

        final newSteps = _expandPlan(currentState, recipes);
        planQueue.addAll(newSteps);
      }
      return ResultFailure("Could not generate plan for day ${currentDayDate.toString().split(" ").firstOrNull}");
    }

    return ResultSuccess(currentPlan);
  }

  List<MealPlanSlot> _buildDayFromState(_PlanState state) => [];

  bool _shouldPrune(_PlanState state) => false;

  List<_PlanStep> _expandPlan(_PlanState state, List<Recipe> recipes) {
    return [];
  }
}