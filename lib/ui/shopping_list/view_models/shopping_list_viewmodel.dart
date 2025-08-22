import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:food_manager/core/result/result.dart';
import 'package:food_manager/data/repositories/meal_plan_repository.dart';
import 'package:food_manager/data/repositories/pantry_item_repository.dart';
import 'package:food_manager/domain/models/meal_plan.dart';
import 'package:food_manager/application/models/shopping_list_entry.dart';
import 'package:food_manager/application/shopping_list_generator.dart';
import 'package:food_manager/domain/validators/pantry_item_validator.dart';

class ShoppingListViewmodel extends ChangeNotifier {
  ShoppingListViewmodel({
    required ShoppingListGenerator shoppingListGenerator,
    required PantryItemRepository pantryItemRepository,
    required MealPlanRepository mealPlanRepository,
  }) : _shoppingListGenerator = shoppingListGenerator,
        _itemRepository = pantryItemRepository,
        _mealPlanRepository = mealPlanRepository;

  final ShoppingListGenerator _shoppingListGenerator;
  final PantryItemRepository _itemRepository;
  final MealPlanRepository _mealPlanRepository;

  bool isLoading = false;
  String? errorMessage;
  MealPlan? mealPlan;
  List<ShoppingListEntry>? entries;

  List<({String? tag, DateTime? date,  List<ShoppingListEntry> entries})> getGroupedEntries(
      DateTime until, {
        bool groupByTag = false,
      }) {
    // groupByDate = !groupByTag
    if (entries == null) return [];
    final entriesUntil = entries!.whereNot((e) => e.earliestDateToBuy.isAfter(until));

    Iterable<({String? tag, DateTime? date,  List<ShoppingListEntry> entries})> result;
    int compareName(ShoppingListEntry a, ShoppingListEntry b) => a.name.compareTo(b.name);
    if (groupByTag) {
      final grouped = entriesUntil.groupListsBy((e) => e.tag);
      result = grouped.entries.map((e) => (tag: e.key, date: null, entries: e.value.sorted(compareName)));
      return result.sorted((a, b) => a.tag!.compareTo(b.tag!));
    } else {
      final grouped = entriesUntil.groupListsBy((e) => e.firstUsedOn);
      result = grouped.entries.map((e) => (tag: null, date: e.key, entries: e.value.sorted(compareName)));
      return result.sorted((a, b) => a.date!.compareTo(b.date!));
    }
  }

  Future<void> _fetchMealPlan() async {
    final planResult = await _mealPlanRepository.getLatestPlan();
    switch (planResult) {
      case ResultSuccess(data: final plan):
        mealPlan = plan;
      case ResultError(message: final msg):
        errorMessage = msg;
      case ResultFailure():
    }
  }

  Future<void> getShoppingList() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    if (mealPlan == null) {
      await _fetchMealPlan();
    }
    if (mealPlan == null) {
      errorMessage ??= "No meal plan to generate the shopping list for.";
      isLoading = false;
      notifyListeners();
      return;
    }

    entries = _shoppingListGenerator.generateList(plan: mealPlan!);

    isLoading = false;
    notifyListeners();
  }

  Future<String?> _buyItems(List<ShoppingListEntry> entries) async {
    if (entries.isEmpty) {
      return "Can't buy items if the list is empty";
    }
    final items = entries.map((e) => e.pantryItem);
    if (!items.every(PantryItemValidator.isValid)) {
      return "Can't buy items if the list is empty";
    }

    final updateResult = await _itemRepository.buyItems(items);
    switch (updateResult) {
      case ResultSuccess(): break;
      case ResultError(): {
        return "Error: failed to buy the items";
      }
      case ResultFailure():
        return "Unexpected: not all items were bought correctly.";
    }

    await _fetchMealPlan();
    if (mealPlan == null) {
      return errorMessage ?? "No meal plan to generate the shopping list for.";
    }

    this.entries = _shoppingListGenerator.generateList(plan: mealPlan!);

    return null;
  }

  Future<void> buyItems(List<ShoppingListEntry> entries) async {
    isLoading = true;
    errorMessage = null;
    this.entries = null;
    notifyListeners();

    errorMessage = await _buyItems(entries);

    isLoading = false;
    notifyListeners();
  }
}