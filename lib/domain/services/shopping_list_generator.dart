import 'package:food_manager/domain/models/meal_planner/meal_plan.dart';
import 'package:food_manager/domain/models/pantry_item.dart';
import 'package:food_manager/domain/models/shopping_list/shopping_list_entry.dart';

class ShoppingListGenerator {
  List<ShoppingListEntry> generateList({
    required MealPlan plan,
  }) {
    final processedItems = <PantryItem>{}; // hashCode uses uuid
    final result = <ShoppingListEntry>[];

    for (final (i, day) in plan.plan.indexed) {
      for (final slot in day) {
        for (final comp in slot.ingredients.values.expand((list) => list)) {
          final item = comp.item;
          if (!item.isBought && !processedItems.contains(item)) {
            final actualShelfLife = item.product.expectedShelfLife;
            // where planner thinks the item expires - actual shelf life = time for the user to but the item
            final earliestDateToBuy = item.expirationDate.subtract(Duration(days: actualShelfLife));
            result.add(ShoppingListEntry(
              earliestDateToBuy: earliestDateToBuy,
              firstUsedOn: plan.dayZero.add(Duration(days: i)),
              pantryItem: item,
            ));
          }
        }
      }
    }

    return result;
  }
}
