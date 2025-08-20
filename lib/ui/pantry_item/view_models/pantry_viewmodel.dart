import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:food_manager/core/result/repo_result.dart';
import 'package:food_manager/data/repositories/pantry_item_repository.dart';
import 'package:food_manager/domain/models/pantry_item.dart';

class PantryViewmodel extends ChangeNotifier {
  PantryViewmodel ({required PantryItemRepository pantryItemRepository})
      : _pantryItemRepository = pantryItemRepository;

  final PantryItemRepository _pantryItemRepository;
  List<PantryItem> _items = [];
  String? errorMessage;
  bool isLoading = false;

  List<PantryItem> get items => List<PantryItem>.unmodifiable(_items);

  Future<void> loadPantryItems() async {
    isLoading = true;
    final result =  await _pantryItemRepository.listPantryItems();
    errorMessage = null;
    _items = [];

    switch (result) {
      case RepoSuccess(): _items = result.data.where((e) => e.isBought)
          .sorted((a, b) => a.product.name.compareTo(b.product.name));
      case RepoError(): errorMessage = result.message;
      case RepoFailure():
        throw StateError('Unexpected RepoFailure in loadPantryItems');
    }

    isLoading = false;
    notifyListeners();
  }

  Future<String> removeItem(PantryItem item) async {
    _items.remove(item);
    final result = await _pantryItemRepository.removeItem(item);

    notifyListeners();
    switch (result) {
      case RepoSuccess(): return 'Item deleted';
      case RepoFailure(): return 'Item already deleted';
      case RepoError(): return 'Something went wrong';
    }
  }
}