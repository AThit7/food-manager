import 'dart:developer';

import 'package:food_manager/domain/models/meal_plan.dart';
import 'package:food_manager/application/models/shopping_list_entry.dart';

class ShoppingListGenerator {
  List<ShoppingListEntry> generateList({
    required MealPlan plan,
  }) {
    final processedItems = <String>{};
    final result = <ShoppingListEntry>[];

    for (final (i, day) in plan.plan.indexed) {
      log('Generating for day; $i');
      for (final slot in day) {
        for (final comp in slot.ingredients.values.expand((list) => list)) {
          final item = comp.item;
          if (!item.isBought && !processedItems.contains(item.uuid)) {
            final actualShelfLife = item.product.expectedShelfLife;
            // where planner thinks the item expires - actual shelf life = time for the user to but the item
            final earliestDateToBuy = item.expirationDate.subtract(Duration(days: actualShelfLife));
            result.add(ShoppingListEntry(
              earliestDateToBuy: earliestDateToBuy,
              firstUsedOn: plan.dayZero.add(Duration(days: i)),
              pantryItem: item,
            ));
            processedItems.add(item.uuid);
          }
        }
      }
    }

    return result;
  }
}
