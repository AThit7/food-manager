// implementation of a planner based on https://www.diva-portal.org/smash/get/diva2:1687744/FULLTEXT02

import 'dart:collection';
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
import 'package:food_manager/domain/models/recipe_ingredient.dart';
import 'package:uuid/uuid.dart';

// ############################ AUXILIARY CLASSES  ######################################

const double _epsilon = 0.001;

class _MealPlanItem {
  final String uuid;
  final LocalProduct product;
  double quantity;
  int expirationDay;
  bool isBought;
  bool isOpen;
  final int effectiveShelfLife;

  _MealPlanItem({
    required this.uuid,
    required this.product,
    required this.effectiveShelfLife,
    required this.quantity,
    required this.expirationDay,
    required this.isBought,
    required this.isOpen,
});

  double? getQuantity(String unit) => product.units.containsKey(unit)
      ? quantity / product.units[unit]!
      : null;

  double? getQuantityBase(double quantityRecipe, String unit) => product.units.containsKey(unit)
      ? quantityRecipe * product.units[unit]!
      : null;

  void setQuantity(double q, String unit) {
    if (!product.units.containsKey(unit)) return;
    quantity = q * product.units[unit]!;
  }

  _MealPlanItem copyWith({
    String? uuid,
    LocalProduct? product,
    double? quantity,
    int? expirationDay,
    bool? isBought,
    bool? isOpen,
    List<({int day, double quantity})>? uses,
    int? effectiveShelfLife,
  }) {
    return _MealPlanItem(
      effectiveShelfLife: effectiveShelfLife ?? this.effectiveShelfLife,
      expirationDay: expirationDay ?? this.expirationDay,
      quantity: quantity ?? this.quantity,
      isBought: isBought ?? this.isBought,
      product: product ?? this.product,
      isOpen: isOpen ?? this.isOpen,
      uuid: uuid ?? this.uuid,
    );
  }

  PantryItem toPantryItem(DateTime dayZero) => PantryItem.withUuid(
    uuid: uuid,
    product: product,
    quantity: product.containerSize ?? quantity,
    expirationDate: dayZero.add(Duration(days: expirationDay)),
    isOpen: isOpen,
    isBought: isBought,
  );
}

class _MealPlanSlot {
  Recipe recipe;
  double calories;
  double protein;
  double carbs;
  double fat;

  List<_MealPlanItem> items;

  _MealPlanSlot({
    required this.recipe,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.items,
  });
}

typedef _Use =  ({int day, double quantity});

class _MealPlanState {
  final DateTime dayZero;
  Map<String, Map<String, _MealPlanItem>> pantry;
  UnmodifiableMapView<String, UnmodifiableListView<LocalProduct>> products;
  UnmodifiableListView<Recipe> recipes;
  UnmodifiableMapView<String, PantryItem> boughtItems;
  List<List<_MealPlanSlot>> plan;
  Map<String, List<_Use>> uses;
  int maxRecipeRepetitions;
  Map<int, int> recipeUses;

  _MealPlanState({
    required this.dayZero,
    required this.pantry,
    required this.products,
    required this.recipes,
    required this.boughtItems,
    required this.plan,
    required this.uses,
    required this.maxRecipeRepetitions,
    required this.recipeUses,
  });

  double getWaste([int overhead = 7]) {
    final minDay = plan.length + overhead;
    final items = pantry.values.expand((e) => e.values).where((e) => e.expirationDay < minDay);
    return items.fold(0.0, (sum, e) => sum + e.quantity);
  }

  List<double> getWasteByDay([int overhead = 7]) {
    final minDay = plan.length + overhead;
    final items = pantry.values.expand((e) => e.values).where((e) => e.expirationDay < minDay);
    final res = List<double>
        .generate(plan.length, (i) => items.where((e) => e.expirationDay == i)
        .fold(0.0, (p, e) => p + e.quantity));

    return res;
  }

  _MealPlanState copy() {
    final newPantry = Map.fromEntries(pantry.entries);
    for (final e in pantry.entries) {
      newPantry[e.key] = {
        for (final entry in e.value.entries) entry.key : entry.value.copyWith(),
      };
    }
    final newPlan = [
      for (final day in plan)
        [ for (final slot in day) _MealPlanSlot(
          recipe: slot.recipe,
          calories: slot.calories,
          protein: slot.protein,
          carbs: slot.carbs,
          fat: slot.fat,
          items: [ for (final it in slot.items) it.copyWith() ],
        ) ],
    ];
    
    return _MealPlanState(
      dayZero: dayZero,
      pantry: newPantry,
      products: products,
      recipes: recipes,
      boughtItems: boughtItems,
      plan: newPlan,
      uses: { for (final e in uses.entries) e.key : List.of(e.value) },
      maxRecipeRepetitions: maxRecipeRepetitions,
      recipeUses: Map.of(recipeUses),
    );
  }

  void _insertSorted(List<_Use> list, int day, double quantity) {
    int low = 0;
    int high = list.length;

    while (low < high) {
      var mid = (low + high) ~/ 2;
      if (list[mid].day < day) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }

    if (low != list.length && list[low].day == day) {
      list[low] = (day : day, quantity: quantity + list[low].quantity);
    } else {
      list.insert(low, (day : day, quantity: quantity));
    }
  }

  /// can use this item without creating  gap wider that [item.effectiveShelfLife]
  bool canUseItem(_MealPlanItem item, int day) {
    if (item.isBought && day > item.expirationDay) return false;
    final itemUses = uses[item.uuid];
    if (itemUses == null || itemUses.isEmpty) return true;
    final first = itemUses.first.day;
    final last  = itemUses.last.day;

    final newFirst = day < first ? day : first;
    final newLast  = day > last  ? day : last;

    return (newLast - newFirst) <= item.effectiveShelfLife;
  }

  void useItem(_MealPlanItem item, double quantity, int day) {
    assert(canUseItem(item, day));
    final tag = item.product.tag.name;
    final uuid = item.uuid;
    assert (pantry.containsKey(tag) && pantry[tag]!.containsKey(uuid));
    final pantryEntry = pantry[tag]![uuid]!;
    final leftover = pantryEntry.quantity - quantity;
    final anyLeft = leftover.abs() > _epsilon;
    assert (leftover > -_epsilon);

    if (anyLeft) {
      pantry[tag]![uuid]!.quantity = leftover;
    } else {
      pantry[tag]!.remove(uuid);
    }

    uses.putIfAbsent(uuid, () => []);
    _insertSorted(uses[uuid]!, day, quantity);
  }

  int consecutiveStreak(int recipeId, int day) {
    int s = 0;
    for (int d = day; d >= 0; d--) {
      if (plan[d].any((slot) => slot.recipe.id == recipeId)) {
        s++;
      } else {
        break;
      }
      for (int d = day + 1; d < plan.length; d++) {
        if (plan[d].any((slot) => slot.recipe.id == recipeId)) {
          s++;
        } else {
          break;
        }
      }
    }
    return s;
  }

  bool canUseRecipe(Recipe recipe, int day) {
    final id = recipe.id!;
    final used = recipeUses[id] ?? 0;
    if (used >= maxRecipeRepetitions) return false;
    if (day < plan.length && plan[day].any((slot) => slot.recipe.id == id)) return false;

    return consecutiveStreak(id, day - 1) < 3;
  }
}

// ################################ PLANNER ######################################

class MealPlanner {
  MealPlanner({required this.config});

  final MealPlannerConfig config;
  // TODO move to config later
  final double acceptableError = 0.05;
  final int planLength = 14;
  final int someAttemptsLimit = 20;

  Result<MealPlan> generatePlan({
    required List<LocalProduct> products,
    required List<PantryItem> pantryItems,
    required List<Recipe> recipes,
    required MealPlanConstraints constraints,
    required MealPlan currentPlan,
  }) {

    if (recipes.any((e) => e.id == null) || products.any((e) => e.id == null)) {
      throw ArgumentError('Invalid args');
    }
    final today = DateUtils.dateOnly(DateTime.now());
    bool isExpired(PantryItem item) => item.expirationDate.isBefore(today);
    pantryItems = UnmodifiableListView<PantryItem>(pantryItems.where((i) => i.isBought && !isExpired(i)));

    // ##################################################### prep tag-products map

    final Map<String, List<LocalProduct>> tagProductsMap = {};
    for (final product in products) {
      tagProductsMap.putIfAbsent(product.tag.name, () => []);
      tagProductsMap[product.tag.name]!.add(product);
    }

    for (final productList in tagProductsMap.values) {
      productList.sort((a, b) => (a.containerSize ?? -1).compareTo(b.containerSize ?? -1));
    }

    final tagProducts = <String, UnmodifiableListView<LocalProduct>>{};
    for (final entry in tagProductsMap.entries) {
      tagProducts[entry.key] = UnmodifiableListView<LocalProduct>(entry.value);
    }

    // ##################################################### prep pantry

    final Map<String, Map<String, _MealPlanItem>> initPantry = {};
    for (final item in pantryItems) {
      final effShelfLife = item.isOpen
          ? item.expirationDate.difference(today).inDays
          : _effectiveShelfLifeAfterOpening(item.product);
      if (effShelfLife < 0) continue;

      final mealPlanItem = _MealPlanItem(
        uuid: item.uuid,
        product: item.product,
        effectiveShelfLife: effShelfLife,
        quantity: item.quantity,
        expirationDay: item.expirationDate.difference(today).inDays,
        isBought: item.isBought,
        isOpen: item.isOpen,
      );
      initPantry.putIfAbsent(item.product.tag.name, () => {});
      initPantry[item.product.tag.name]![item.uuid] = mealPlanItem;
    }

    for (final key in tagProducts.keys) {
      initPantry.putIfAbsent(key, () => {});
    }

    // ##################################################### prep recipes

    final eligibleRecipes = recipes.where(
          (r) => r.ingredients.every(
            (i) => tagProducts.containsKey(i.tag.name)
            && tagProducts[i.tag.name]!.any((p) => p.units.containsKey(i.unit)),
      ),
    );
    recipes = List<Recipe>.unmodifiable(eligibleRecipes.map((e) => e.copyWith()));
    if (recipes.length < constraints.mealRange.lower * 2) {
      return ResultFailure('Could not find any plan satisfying requirements');
    }

    // ################# MAIN PART #######################

    _MealPlanState startingState = _MealPlanState(
      dayZero: today,
      pantry: initPantry,
      products: UnmodifiableMapView<String, UnmodifiableListView<LocalProduct>>(tagProducts),
      recipes: UnmodifiableListView(recipes),
      boughtItems: UnmodifiableMapView({ for (final e in pantryItems) e.uuid : e }),
      plan: [],
      uses: {},
      maxRecipeRepetitions: max((planLength * constraints.mealRange.upper / recipes.length).ceil(), 2) + 1, // TODO tweak?
      recipeUses: {},
    );

    // find some state that satisfies constraints
    _MealPlanState? someSolution;
    final rnd = Random();
    for(int i = 0; i < someAttemptsLimit; i++) {
      if (someSolution == null) dev.log('Getting some solution, attempt: $i', name: 'MealPlanner');
      someSolution ??= _getSome(startingState, constraints, rnd);
    }
    if (someSolution == null) return ResultFailure('Could not find any plan satisfying requirements');

    // find locally best state (neighbourhood search)
    final betterSolution = _getBest(someSolution, constraints);
    //_rebuildFromDay(betterSolution, 0);
    assert(_isValid(betterSolution, constraints));

    dev.log('Total waste in the new plan: ${betterSolution.getWaste(0)}');

    // transform state object to plan
    final resultPlan = _stateToPlan(betterSolution, constraints);

    return ResultSuccess(resultPlan);
  }


  // ############################## GET SOME ###########################################

  _MealPlanState? _getSome(_MealPlanState state, MealPlanConstraints constraints, Random? random) {
    final rnd = random ?? Random();
    _MealPlanState current = state.copy();

    double span(num lo, num hi) => (hi - lo).abs().toDouble().clamp(1.0, double.infinity);
    double violationPenalty(double x, num lo, num hi) {
      if (x < lo) return ((lo - x) / span(lo, hi));
      if (x > hi) return ((x - hi) / span(lo, hi));
      return 0.0;
    }

    // pre-process all recipes on the same state to get stats about them
    double minK = double.infinity, minP = double.infinity, minC = double.infinity, minF = double.infinity;
    double maxK = 0, maxP = 0, maxC = 0, maxF = 0;
    {
      final probeBase = current.copy();
      for (final r in probeBase.recipes) {
        final s = _findIngredients(probeBase.copy(), r, 0);
        minK = min(minK, s.calories); maxK = max(maxK, s.calories);
        minP = min(minP, s.protein ); maxP = max(maxP, s.protein );
        minC = min(minC, s.carbs   ); maxC = max(maxC, s.carbs   );
        minF = min(minF, s.fat     ); maxF = max(maxF, s.fat     );
      }
      if (!minK.isFinite) return null; // didn't find any feasible recipes
    }

    // can the plan still be completed after adding that recipe
    bool feasibleAfter(double k, double p, double c, double f, int slotsLeft) {
      final rem = slotsLeft;
      if (k > constraints.calorieRange.upper) return false;
      if (p > constraints.proteinRange.upper) return false;
      if (c > constraints.carbsRange.upper)   return false;
      if (f > constraints.fatRange.upper)     return false;
      if (k + rem * maxK < constraints.calorieRange.lower) return false;
      if (p + rem * maxP < constraints.proteinRange.lower) return false;
      if (c + rem * maxC < constraints.carbsRange.lower)   return false;
      if (f + rem * maxF < constraints.fatRange.lower)     return false;
      if (k + rem * minK > constraints.calorieRange.upper) return false;
      if (p + rem * minP > constraints.proteinRange.upper) return false;
      if (c + rem * minC > constraints.carbsRange.upper)   return false;
      if (f + rem * minF > constraints.fatRange.upper)     return false;
      return true;
    }

    double boundPenalty(double k, double p, double c, double f) {
      double pen = 0.0;
      pen += violationPenalty(k, constraints.calorieRange.lower, constraints.calorieRange.upper);
      pen += violationPenalty(p, constraints.proteinRange.lower, constraints.proteinRange.upper);
      pen += violationPenalty(c, constraints.carbsRange.lower, constraints.carbsRange.upper);
      pen += violationPenalty(f, constraints.fatRange.lower, constraints.fatRange.upper);
      final midK = 0.5 * (constraints.calorieRange.lower + constraints.calorieRange.upper);
      pen += 0.05 * ((k - midK).abs() / span(constraints.calorieRange.lower, constraints.calorieRange.upper));
      return pen;
    }

    final mealCounts = [for (int m = constraints.mealRange.lower; m <= constraints.mealRange.upper; m++) m];

    for (int day = 0; day < planLength; day++) {
      mealCounts.shuffle(rnd);
      bool committed = false;

      for (final meals in mealCounts) {
        final tmp = current.copy();
        final daySlots = <_MealPlanSlot>[];
        final usedIds = <int>{};
        double totK = 0, totP = 0, totC = 0, totF = 0;

        for (int s = 0; s < meals; s++) {
          final candidates = tmp.recipes
              .where((r) => usedIds.contains(r.id) ? false : tmp.canUseRecipe(r, day))
              .toList();

          if (candidates.isEmpty) {
            daySlots.clear();
            break;
          }

          // approximate what would happen if we added that recipe
          final scored = <({Recipe r, double score, _MealPlanSlot slot})>[];
          for (final r in candidates) {
            final probeState = tmp.copy();
            final slot = _findIngredients(probeState, r, day);
            final k1 = totK + slot.calories;
            final p1 = totP + slot.protein;
            final c1 = totC + slot.carbs;
            final f1 = totF + slot.fat;
            final slotsLeft = meals - s - 1;
            if (!feasibleAfter(k1, p1, c1, f1, slotsLeft)) continue;
            final score = boundPenalty(k1, p1, c1, f1);
            scored.add((r: r, score: score, slot: slot));
          }

          if (scored.isEmpty) {
            daySlots.clear();
            break;
          }

          scored.sort((a, b) => a.score.compareTo(b.score));
          final k = min(4, scored.length);
          final pick = scored[rnd.nextInt(k)]; // pick random from top k

          final committedSlot = _findIngredients(tmp, pick.r, day);
          daySlots.add(committedSlot);
          usedIds.add(pick.r.id!);
          totK += committedSlot.calories;
          totP += committedSlot.protein;
          totC += committedSlot.carbs;
          totF += committedSlot.fat;
        }

        if (daySlots.length == meals && _isValidDay(daySlots, constraints)) {
          current = tmp;
          current.plan.add(daySlots);
          for (final s in daySlots) {
            final id = s.recipe.id!;
            current.recipeUses[id] = (current.recipeUses[id] ?? 0) + 1;
          }
          committed = true;
          break;
        }
      }

      if (!committed) return null;
    }

    if (!_isValid(current, constraints)) return null;
    return current;
  }

  // ############################## GET BEST #####################################################

  _MealPlanState _getBest(_MealPlanState state, MealPlanConstraints constraints) {
    int steps = 0;
    int improves = 0;
    bool improved = false;
    bool mixUp = false;
    final rnd = Random();

    do {
      improved = false;
      double bestScore = double.infinity;
      _MealPlanState? bestState;
      final plan = state.plan;

      // try swapping some recipes for others
      for (int i = 0; i < plan.length ; i++) {
        for (int j = 0; j < plan[i].length; j++) {
          for (final recipe in state.recipes) {
            if (recipe.id == plan[i][j].recipe.id || !state.canUseRecipe(recipe, i)) continue;
            final newState = _swapRecipe(state, recipe, i, j);
            if (!_isValid(newState, constraints)) continue;
            final newScore = _scoreState(newState);
            if (newScore < bestScore) {
              bestScore = newScore;
              bestState = newState;
            }
            if (mixUp && rnd.nextDouble() < 0.05) state = newState;
          }
        }
      }

      // try swapping each two meals with each other
      for (int i = 0; i < plan.length ; i++) {
        for (int j = 0; j < plan[i].length; j++) {
          for (int k = 0; k < plan.length ; k++) {
            for (int l = 0; l < plan[k].length; l++) {
              final recipeA = plan[i][j].recipe;
              final recipeB = plan[k][l].recipe;
              if (recipeB.id == recipeA.id || !state.canUseRecipe(recipeA, k) || !state.canUseRecipe(recipeB, i)) continue;
              final newState = _swapMeals(state, i, j, k, l);
              if (!_isValid(newState, constraints)) continue;
              final newScore = _scoreState(newState);
              if (newScore < bestScore) {
                bestScore = newScore;
                bestState = newState;
              }
              if (mixUp && rnd.nextDouble() < 0.05) state = newState;
            }
          }
        }
      }

      steps++;
      dev.log('Steps: $steps', name: 'MealPlanner');
      if (mixUp) {
        mixUp = false;
        improved = true;
      } else if (bestState != null && bestScore < _scoreState(state)) {
        state = bestState;
        improves++;
        improved = true;
      }
    } while (improved == true);

    dev.log('Found solution after $steps iterations', name: 'MealPlanner');
    dev.log('Improved $improves times', name: 'MealPlanner');
    return state;
  }

  // ############################## STATE MANIPULATION ###########################################

  // TODO more heuristics
  double _scoreState(_MealPlanState state) {
    return state.getWaste();
  }

  bool _isValidDay(List<_MealPlanSlot> day, MealPlanConstraints constraints) {
    bool inRange(num value, ({num lower, num upper}) range) =>
        range.lower <= value && value <= range.upper;
    final constraintsList = constraints.toList;

    final metrics = day.fold([0, 0.0, 0.0, 0.0, 0.0], (sums, e) {
      sums[0]++;
      sums[1] += e.calories;
      sums[2] += e.protein;
      sums[3] += e.carbs;
      sums[4] += e.fat;
      return sums;
    });

    assert(metrics.length == constraintsList.length);
    for (int i = 0; i < metrics.length; i++) {
      if (!inRange(metrics[i], constraintsList[i])) return false;
    }

    return true;
  }

  bool _isValid(_MealPlanState state, MealPlanConstraints constraints) =>
      state.plan.fold(true, (p, e) => p && _isValidDay(e, constraints));

  _MealPlanState _swapRecipe(_MealPlanState state, Recipe recipe, int i, int j) {
    final newState = state.copy();
    final slot = newState.plan[i][j];
    newState.recipeUses[slot.recipe.id!] = max(0, (newState.recipeUses[slot.recipe.id!] ?? 0) - 1);
    newState.recipeUses[recipe.id!] = (newState.recipeUses[recipe.id!] ?? 0) + 1;

    newState.plan[i][j] = _MealPlanSlot(recipe: recipe, calories: 0, protein: 0, carbs: 0, fat: 0, items: const []);

    _rebuildFromDay(newState, i);
    return newState;
  }

  _MealPlanState _swapMeals(_MealPlanState state, int i, int j, int k, int l) {
    final newState = state.copy();
    final recA = newState.plan[i][j].recipe;
    final recB = newState.plan[k][l].recipe;

    newState.plan[i][j] = _MealPlanSlot(
        recipe: recB, calories: 0, protein: 0, carbs: 0, fat: 0, items: const []);
    newState.plan[k][l] = _MealPlanSlot(
        recipe: recA, calories: 0, protein: 0, carbs: 0, fat: 0, items: const []);

    _rebuildFromDay(newState, min(i, k));
    return newState;
  }

  // ############################## AUXILIARY FUNCTIONS ###########################################

  void _rebuildFromDay(_MealPlanState state, int firstDay) {
    final length = state.plan.length;
    for (int i = firstDay; i < length; i++) {
      for (final slot in state.plan[i]) {
        for (final it in slot.items) {
          _removeItem(state, it, i);
        }
      }
      
      state.plan[i] = [for (final s in state.plan[i]) _MealPlanSlot(
        recipe: s.recipe, calories: 0, protein: 0, carbs: 0, fat: 0, items: const [],
      )];
    }

    for (int i = firstDay; i < length; i++) {
      for (int j = 0; j < state.plan[i].length ; j++) {
        final recipe = state.plan[i][j].recipe;
        state.plan[i][j] = _findIngredients(state, recipe, i);
      }
    }
  }

  _MealPlanSlot _findIngredients(_MealPlanState state, Recipe recipe, int i) {
    final items = <_MealPlanItem>[];
    for (final ingredient in recipe.ingredients) {
      items.addAll(_findItems(state, ingredient, i));
    }

    final metrics = items.fold([0.0, 0.0, 0.0, 0.0], (sums, e) {
      final p = e.product, q = e.quantity;
      sums[0] += q * p.caloriesPerUnit;
      sums[1] += q * p.proteinPerUnit;
      sums[2] += q * p.carbsPerUnit;
      sums[3] += q * p.fatPerUnit;
      return sums;
    });

    return _MealPlanSlot(
      recipe: recipe,
      calories: metrics[0],
      protein: metrics[1],
      carbs: metrics[2],
      fat: metrics[3],
      items: items,
    );
  }

  List<_MealPlanItem> _findItems(_MealPlanState state, RecipeIngredient ingredient, int i) {
    final tag = ingredient.tag.name;
    final unit = ingredient.unit;
    final matchingItems = state.pantry[tag]?.values
        .where((e) => e.product.units.containsKey(unit))
        .sorted(_compareItems(i)) ?? [];
    final matchingProducts = state.products[tag]?.where((e) => e.units.containsKey(unit)).toList();
    if (matchingProducts == null || matchingProducts.isEmpty) return [];

    final result = <_MealPlanItem>[];
    final target = ingredient.amount;
    final targetUpper = ingredient.amount * (1 + acceptableError);
    double totalWeight = 0; // RECIPE UNITS!

    // use up existing ingredients first, greedy, sorted by date
    for (final item in matchingItems) {
      if (!state.canUseItem(item, i)) continue;
      final qty = item.getQuantity(unit)!;
      final take = item.copyWith();

      if (qty + totalWeight < targetUpper) {
        totalWeight += qty;
        state.useItem(take, take.quantity, i);
      } else {
        final leftover = qty + totalWeight - target;
        totalWeight = target;
        take.quantity -= take.getQuantityBase(leftover, unit)!;
        state.useItem(take, take.quantity, i);
      }

      result.add(take);
      if (_isNear(totalWeight, target)) return result;
    }

    final flexibleProduct = matchingProducts.where((e) => e.containerSize == null).firstOrNull;
    // no container size case, just take target - totalWeight
    if (flexibleProduct != null) {
      final eff = _effectiveShelfLifeAfterOpening(flexibleProduct);
      final uuid = Uuid().v4();
      final qty = (target - totalWeight) * flexibleProduct.units[unit]!;
      final newItem = _MealPlanItem(
        uuid: uuid,
        product: flexibleProduct,
        effectiveShelfLife: eff,
        quantity: qty,
        expirationDay: i + eff,
        isBought: false,
        isOpen: true,
      );
      state.uses[uuid] = [(day: i, quantity: qty)];
      result.add(newItem);
      totalWeight = target;
    }

    if (_isNear(totalWeight, target)) return result;

    // buy ingredients in containers, greedy with improvements
    double bestOverflow = double.infinity;
    final bestComp = ListQueue<LocalProduct>();
    double remaining = target - totalWeight;

    for (final product in matchingProducts.reversed.where((e) => e.containerSize != null)) {
      final size = product.containerSize! / product.units[unit]!;
      final minPcs = (remaining * (1 - acceptableError) / size).clamp(1, double.infinity).ceil();
      assert(minPcs > 0);
      final overflow = minPcs * size - remaining;

      if(overflow < bestOverflow) {
        bestOverflow = overflow;
        if (bestComp.isNotEmpty) bestComp.removeLast();
        remaining -= size * (minPcs - 1);
        bestComp.addAll(Iterable.generate(minPcs, (_) => product));
      }

      if (_isNear(overflow, 0)) break;
    }

    // add the combination
    for (final product in bestComp) {
      final eff = _effectiveShelfLifeAfterOpening(product);
      final uuid = Uuid().v4();
      final remainingQty = (targetUpper - totalWeight) * product.units[unit]!;
      final qty = min(remainingQty, product.containerSize!);
      final newItem = _MealPlanItem(
        uuid: uuid,
        product: product,
        effectiveShelfLife: eff,
        quantity: qty,
        expirationDay: i + eff,
        isBought: false,
        isOpen: true,
      );
      state.uses[uuid] = [(day: i, quantity: qty)];
      result.add(newItem);
      totalWeight += qty / product.units[unit]!;
      if (qty != product.containerSize!) {
        state.pantry[tag]![uuid] = newItem.copyWith(quantity: product.containerSize! - qty); // add leftovers to pantry
        break;
      }
    }

    return result;
  }

  void _removeItem(_MealPlanState state, _MealPlanItem item, int day) {
    final tag  = item.product.tag.name;
    final uuid = item.uuid;
    final containerSize   = item.product.containerSize;

    // undo uses
    final uses = state.uses[uuid];
    if (uses != null) {
      final idx = uses.binarySearch((day: day, quantity: 0), (a,b) => a.day.compareTo(b.day));
      if (idx >= 0) {
        final qtyLeft = uses[idx].quantity - item.quantity;
        if (qtyLeft.abs() < _epsilon) {
          uses.removeAt(idx);
          if (uses.isEmpty) state.uses.remove(uuid);
        } else {
          uses[idx] = (day: day, quantity: qtyLeft);
        }
      }
    }

    // return to pantry
    state.pantry.putIfAbsent(tag, () => <String,_MealPlanItem>{});
    final bucket = state.pantry[tag]!;
    final entry  = bucket[uuid] ?? item.copyWith();
    entry.quantity += item.quantity;

    // if full, close or retract simulated buying
    if (containerSize != null && (containerSize - entry.quantity).abs() < _epsilon) {
      final original = state.boughtItems[uuid];
      if (original != null) {
        entry.isOpen = false;
        entry.expirationDay = original.expirationDate.difference(state.dayZero).inDays;
      } else {
        bucket.remove(uuid);
      }
    } else if (containerSize != null && !entry.isBought) {
      bucket.remove(uuid);
    }
  }

  Comparator<_MealPlanItem> _compareItems(int i) => (_MealPlanItem a, _MealPlanItem b) {
    final aScore = a.isOpen ? a.expirationDay : min(i + a.effectiveShelfLife, a.expirationDay);
    final bScore = b.isOpen ? b.expirationDay : min(i + b.effectiveShelfLife, b.expirationDay);
    final res = aScore.compareTo(bScore);
    if (res == 0) return a.quantity.compareTo(b.quantity);
    return res;
  };

  bool _isNear(double value, double target, [double error = 0.05]) =>
      target == 0 ? value.abs() < _epsilon : (target - value).abs() / target < error;

  int _leadDays(int d) {
    if (d == 0) return 0;
    if (d <= 3)  return 1;
    if (d <= 7)  return 2;
    if (d <= 14) return 4;
    if (d <= 30) return 7;
    return 14;
  }

  int _effectiveShelfLifeAfterOpening(LocalProduct product) {
    final afterOpen = product.shelfLifeAfterOpening;
    final expected = product.expectedShelfLife;
    final needsLead = (afterOpen == expected) && afterOpen > 0;
    if (!needsLead) return afterOpen;
    final lead = _leadDays(afterOpen);
    assert(lead <= afterOpen);
    return afterOpen - lead;
  }

  // ################################### CONVERTER ###################################

  MealPlan _stateToPlan(_MealPlanState state, MealPlanConstraints constraints) {
    final plan = <List<MealPlanSlot>>[];
    for (final day in state.plan) {
      final slots = <MealPlanSlot>[];

      for (final s in day) {
        final ingredients = <String, List<({PantryItem item, double quantity})>>{};
        for (final item in s.items) {
          final pantryItem = item.toPantryItem(state.dayZero);
          final tag = pantryItem.product.tag.name;
          ingredients.putIfAbsent(tag, () => []);
          ingredients[tag]!.add((item: pantryItem, quantity: item.quantity));
        }

        final slot = MealPlanSlot(
          recipe: s.recipe,
          ingredients: ingredients,
          calories: s.calories,
          protein: s.protein,
          carbs: s.carbs,
          fat: s.fat,
          isValid: true,
          isEaten: false,
        );
        slots.add(slot);
      }

      plan.add(slots);
    }

    return MealPlan(
      dayZero: state.dayZero,
      mealsPerDayRange: constraints.mealRange,
      plan: plan,
      waste: state.getWasteByDay(),
      valid: List.generate(state.plan.length, (_) => true),
    );
  }
}