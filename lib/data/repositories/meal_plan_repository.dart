import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:collection/collection.dart';
import 'package:food_manager/core/result/result.dart';
import 'package:food_manager/data/database/schema/meal_plan_schema.dart';
import 'package:food_manager/data/database/schema/pantry_item_schema.dart';
import 'package:food_manager/data/repositories/pantry_item_repository.dart';
import 'package:food_manager/data/repositories/recipe_repository.dart';
import 'package:food_manager/data/services/database/database_service.dart';
import 'package:food_manager/domain/models/meal_plan.dart';
import 'package:food_manager/domain/models/pantry_item.dart';
import 'package:food_manager/domain/models/recipe.dart';
import 'package:food_manager/domain/validators/pantry_item_validator.dart';

sealed class MealPlanEvent {}

class MealPlanSaved extends MealPlanEvent {
  final MealPlan plan;
  MealPlanSaved(this.plan);
}

class MealPlanCleared extends MealPlanEvent {}

// TODO keep track of issues with plan? probably better to do in a validator
class MealPlanRepository {
  final DatabaseService _db;
  final RecipeRepository _recipeRepository;
  final PantryItemRepository _pantryItemRepository;
  final _mealPlanUpdates = StreamController<MealPlanEvent>.broadcast();

  Stream<MealPlanEvent> get mealPlanUpdates => _mealPlanUpdates.stream;

  MealPlanRepository({
    required DatabaseService databaseService,
    required RecipeRepository recipeRepository,
    required PantryItemRepository pantryItemRepository,
  }) : _db = databaseService,
        _recipeRepository = recipeRepository,
        _pantryItemRepository = pantryItemRepository;

  void dispose() {
    _mealPlanUpdates.close();
  }

  // plan shape saved in JSON:
  // [
  //   [ // day 0
  //     { "recipeId": 1,
  //       "calories": 500, "protein": 30, "carbs": 60, "fat": 15,
  //       "ingredients": { "tagName": [ { "itemId": 123, "itemUuid": "...", "qty": 42.0 }, ... ] }
  //     },
  //     ... // more meals that day
  //   ],
  //   ... // other days
  // ]

  // JSON field names
  static const _recipeId = "recipe_id";
  static const _calories = "calories";
  static const _protein = "protein";
  static const _carbs = "carbs";
  static const _fat = "fat";
  static const _ingredients = "ingredients";
  static const _itemId = "item_id";
  static const _itemUuid = "item_uuid";
  static const _quantity = "quantity";
  static const _isEaten = "is_eaten";

  List<List<Map<String, Object?>>> _encodePlanGrid(MealPlan plan) {
    return plan.plan.map((day) {
      return day.map((slot) {
        assert (slot.recipe.id != null);
        return {
          _recipeId: slot.recipe.id,
          _calories: slot.calories,
          _protein: slot.protein,
          _carbs: slot.carbs,
          _fat: slot.fat,
          _isEaten: slot.isEaten,
          _ingredients:  slot.ingredients.map((tag, comps) {
            final list = comps.map((c) => {
              _itemId: c.item.id,
              _itemUuid: c.item.uuid,
              _quantity: c.quantity,
            }).toList();
            return MapEntry(tag, list);
          }),
        };
      }).toList();
    }).toList();
  }

  Future<({List<List<MealPlanSlot>> grid, List<bool> valid})> _decodePlanGrid(List<dynamic> grid) async {
    final result = <List<MealPlanSlot>>[];
    final daysValid = <bool>[];

    final itemsResult = await _pantryItemRepository.listPantryItems();
    if (itemsResult is! ResultSuccess<List<PantryItem>>) {
      throw StateError("Failed to fetch items.");
    }
    final recipeResult = await _recipeRepository.listRecipes();
    if (recipeResult is! ResultSuccess<List<Recipe>>) {
      throw StateError("Failed to fetch recipes.");
    }

    final itemMapById = Map.fromEntries(itemsResult.data.map((e) => MapEntry(e.id, e)));
    final itemMapByUuid = Map.fromEntries(itemsResult.data.map((e) => MapEntry(e.uuid, e)));
    final recipeMapById = Map.fromEntries(recipeResult.data.map((e) => MapEntry(e.id!, e)));

    for (final day in grid) {
      bool isValidDay = true;
      final dayList = <MealPlanSlot>[];
      for (final slot in (day as List)) {
        bool isValidSlot = true;
        final slotMap = (slot as Map).cast<String, dynamic>();

        final recipe = recipeMapById[slotMap[_recipeId] as int];
        if (recipe == null) {
          isValidDay = false;
          continue;
        }

        final ingredientsMap = <String, List<({PantryItem item, double quantity})>>{};
        final ingredientRows = (slotMap[_ingredients] as Map).cast<String, dynamic>();

        for (final MapEntry(key: tag, value: compsRaw) in ingredientRows.entries) {
          final comps = <({PantryItem item, double quantity})>[];
          for (final compRaw in (compsRaw as List)) {
            final comp = (compRaw as Map).cast<String, dynamic>();
            final itemId = comp[_itemId] as int?;
            final itemUuid = comp[_itemUuid] as String;
            final quantity = (comp[_quantity] as num).toDouble();

            PantryItem? item = itemMapByUuid[itemUuid] ?? (itemId != null ? itemMapById[itemId] : null);
            if (item == null) {
              log("Missing pantry item (id=$itemId, uuid=$itemUuid).", name: "MealPlanRepository");
              isValidSlot = false;
              continue;
            }

            comps.add((item: item, quantity: quantity));
          }
          ingredientsMap[tag] = comps;
        }

        dayList.add(MealPlanSlot(
          recipe: recipe,
          ingredients: ingredientsMap,
          calories: (slotMap[_calories] as num).toDouble(),
          protein: (slotMap[_protein] as num).toDouble(),
          carbs: (slotMap[_carbs] as num).toDouble(),
          fat: (slotMap[_fat] as num).toDouble(),
          isValid: isValidSlot,
          isEaten: (slotMap[_isEaten] as bool),
        ));
      }
      result.add(dayList);
      daysValid.add(isValidDay);
    }

    return (grid: result, valid: daysValid);
  }

  Future<Map<String, Object?>> _toRow(MealPlan plan) async {
    final planJson = jsonEncode(_encodePlanGrid(plan));
    final wasteJson = jsonEncode(plan.waste);

    return {
      MealPlanSchema.dayZero: plan.dayZero.millisecondsSinceEpoch,
      MealPlanSchema.mealsCountLow: plan.mealsPerDayRange.lower,
      MealPlanSchema.mealsCountHigh: plan.mealsPerDayRange.upper,
      MealPlanSchema.planJson: planJson,
      MealPlanSchema.wasteJson: wasteJson,
      MealPlanSchema.updatedAt: DateTime.now().millisecondsSinceEpoch,
    };
  }

  Future<MealPlan?> _fromRow(Map<String, Object?> row) async {
    try {
      final dayZeroMs = row[MealPlanSchema.dayZero] as int;
      final low = row[MealPlanSchema.mealsCountLow] as int;
      final high = row[MealPlanSchema.mealsCountHigh] as int;
      final planJson = row[MealPlanSchema.planJson] as String;
      final wasteJson = row[MealPlanSchema.wasteJson] as String;

      final planGridRaw = (jsonDecode(planJson) as List).cast<dynamic>();
      final waste = ((jsonDecode(wasteJson) as List).cast<num>()).map((e) => e.toDouble()).toList();

      final planGrid = await _decodePlanGrid(planGridRaw);

      return MealPlan(
        dayZero: DateTime.fromMillisecondsSinceEpoch(dayZeroMs),
        mealsPerDayRange: (lower: low, upper: high),
        plan: planGrid.grid,
        waste: waste,
        valid: planGrid.valid,
      );
    } catch (e) {
      log(
        "Failed to parse plan row: $e",
        name: "MealPlanRepository",
        level: 1000,
      );
      return null;
    }
  }

  Future<Result<List<MealPlan>>> listPlans() async {
    try {
      final rows = await _db.query(MealPlanSchema.table, orderBy: '${MealPlanSchema.updatedAt} DESC');

      final plans = <MealPlan>[];
      for (final row in rows) {
        final plan = await _fromRow(row);
        if (plan != null) plans.add(plan);
      }

      return ResultSuccess(plans);
    } catch (e, s) {
      log(
        "Unexpected error when fetching plans.",
        name: "MealPlanRepository",
        error: e,
        stackTrace: s,
        level: 1200,
      );
      return ResultError("Unexpected error when fetching plans.", e);
    }
  }

  Future<Result<MealPlan?>> getLatestPlan() async {
    final result = await listPlans();
    if (result is ResultSuccess<List<MealPlan>>) {
      return ResultSuccess(result.data.isEmpty ? null : result.data.first);
    } else if (result is ResultError<List<MealPlan>>) {
      return ResultError(result.message, result.exception);
    } else if (result is ResultFailure<List<MealPlan>>) {
      return ResultFailure(result.message);
    }
    throw StateError("Could not match the listPlan()'s type.");
  }

  Future<Result<void>> savePlan(MealPlan plan) async {
    final items = <PantryItem>{};
    for (final day in plan.plan) {
      for (final slot in day) {
        assert(!slot.isEaten || slot.ingredients.values.every((l) => l.isEmpty));
        items.addAll(slot.ingredients.values.expand((list) => list).map((e) => e.item).where((e) => !e.isBought));
      }
    }

    final badItem = items.firstWhereOrNull((e) => !PantryItemValidator.isValid(e));
    if (badItem != null) {
      throw ArgumentError("Invalid pantry item (id=${badItem.id}, uuid=${badItem.uuid}).");
    }

    final unboughtUuidsNew = items.map((e) => e.uuid).toSet();

    try {
      await _db.transaction((txn) async {
        final uuidsRaw = await txn.query(
          PantryItemSchema.table,
          columns: [PantryItemSchema.uuid, PantryItemSchema.isBought],
        );
        final uuidsDb = uuidsRaw.map((r) => r[PantryItemSchema.uuid] as String).toSet();
        final unboughtUuidsDb = uuidsRaw
            .where((r) => 0 == (r[PantryItemSchema.isBought] as num))
            .map((r) => r[PantryItemSchema.uuid] as String)
            .toSet();

        final toDelete = unboughtUuidsDb.difference(unboughtUuidsNew);
        final toInsertUuids = unboughtUuidsNew.difference(uuidsDb);

        final batch = txn.batch();

        for (final uuid in toDelete) {
          batch.delete(PantryItemSchema.table, where: "${PantryItemSchema.uuid} = ?", whereArgs: [uuid]);
        }

        for (final item in items.where((e) => toInsertUuids.contains(e.uuid))) {
          final map = _pantryItemRepository.pantryItemToMap(item);
          map.remove(PantryItemSchema.id); // safer that way
          batch.insert(PantryItemSchema.table, map);
        }

        batch.delete(MealPlanSchema.table);
        batch.insert(MealPlanSchema.table, await _toRow(plan));

        await batch.commit(noResult: true);
      });

      _mealPlanUpdates.add(MealPlanSaved(plan));
      return ResultSuccess(null);
    } catch (e, s) {
      log(
        "Unexpected error when saving plan.",
        name: "MealPlanRepository",
        error: e,
        stackTrace: s,
        level: 1200,
      );
      return ResultError("Unexpected error when saving plan.", e);
    }
  }

  Future<Result<void>> consumeAndSave({
    required MealPlan plan,
    required List<({String itemUuid, double quantity})> newItemQuantities,
  }) async {
    if (newItemQuantities.where((e) => e.quantity < 0).isNotEmpty) {
      throw ArgumentError("New quantities must be non negative");
    }

    try {
      final batch = _db.batch();

      const epsilon = 1e-6;
      final toDelete = newItemQuantities.where((e) => e.quantity <= epsilon);
      final toUpdate = newItemQuantities.where((e) => e.quantity > epsilon);

      for (final e in toUpdate) {
        batch.rawUpdate('''
          UPDATE ${PantryItemSchema.table}
            SET ${PantryItemSchema.quantity} = ?
            WHERE ${PantryItemSchema.uuid} = ?
          ''',
          [e.quantity, e.itemUuid],
        );
      }
      for (final e in toDelete) {
        batch.delete(
          PantryItemSchema.table,
          where: "${PantryItemSchema.uuid} = ?" ,
          whereArgs: [e.itemUuid],
        );
      }

      final map = await _toRow(plan);
      batch.delete(MealPlanSchema.table);
      batch.insert(MealPlanSchema.table, map);

      await batch.commit(noResult: true);

      _mealPlanUpdates.add(MealPlanSaved(plan));
      return ResultSuccess(null);
    } catch (e, s) {
      log(
        "consumeAndSave failed",
        name: "MealPlanRepository",
        error: e,
        stackTrace: s,
        level: 1200,
      );
      return ResultError("Unexpected error when saving and consuming", e);
    }
  }

  Future<Result<void>> clearPlans() async {
    try {
      final batch = _db.batch();
      batch.delete(MealPlanSchema.table);
      batch.delete(PantryItemSchema.table, where: "${PantryItemSchema.isBought} = 0");
      await batch.commit(noResult: true);

      _mealPlanUpdates.add(MealPlanCleared());
      return ResultSuccess(null);
    } catch (e, s) {
      log(
        "Unexpected error when clearing plans.",
        name: "MealPlanRepository",
        error: e,
        stackTrace: s,
        level: 1200,
      );
      return ResultError("Unexpected error when clearing plans.", e);
    }
  }
}