import 'dart:developer';

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
    if (pantryItem.isBought) {
      log('Item already bought', name: 'ShoppingListEntry');
      throw StateError('Item already bought');
    }
    if (pantryItem.product.containerSize != null && pantryItem.product.containerSize != pantryItem.quantity) {
      log('Item in the shopping list is partially consumed: quantity=${pantryItem.quantity} expected=${pantryItem.product.containerSize}', name: 'ShoppingListEntry');
      throw StateError('Item in the shopping list is partially consumed');
    }
  }
}