import 'package:food_manager/domain/models/pantry_item.dart';

class ShoppingListEntry {
  final DateTime earliestDateToBuy;
  final DateTime firstUsedOn;
  final PantryItem pantryItem;

  String get tag => pantryItem.product.tag.name;
  String get name => pantryItem.product.name;
  String get unit => pantryItem.product.referenceUnit;
  double get quantity => pantryItem.quantity;

  ShoppingListEntry({
    required this.earliestDateToBuy,
    required this.firstUsedOn,
    required this.pantryItem,
  }) {
    if (pantryItem.product.containerSize != pantryItem.quantity) {
      throw StateError("Item in the shopping list is partially consumed");
    }
  }
}