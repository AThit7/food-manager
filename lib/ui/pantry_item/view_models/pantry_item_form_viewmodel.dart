import 'dart:async';
import 'dart:developer';

import 'package:food_manager/core/result/repo_result.dart';
import 'package:food_manager/domain/models/product/local_product.dart';

import '../../../data/repositories/pantry_item_repository.dart';
import '../../../domain/models/pantry_item.dart';
import '../models/pantry_item_form_model.dart';
import '../../../domain/validators/pantry_item_validator.dart';

sealed class InsertResult {}

class InsertSuccess extends InsertResult {
  final PantryItem pantryItem;

  InsertSuccess(this.pantryItem);
}

class InsertRepoFailure extends InsertResult {}

class InsertValidationFailure extends InsertResult {}

class PantryItemFormViewmodel {
  PantryItemFormViewmodel({
    required PantryItemRepository pantryItemRepository,
    required this.product
  }) : _pantryItemRepository = pantryItemRepository;

  final PantryItemRepository _pantryItemRepository;
  final LocalProduct product;

  Future<InsertResult> savePantryItem(PantryItemFormModel form) async {
    PantryItem pantryItem;
    try {
      pantryItem = PantryItem(
        id: form.id,
        product: product,
        quantity: double.parse(form.quantity!),
        expirationDate: form.expirationDate!, // TODO will it parse?
        isOpen: form.isOpen
      );
      PantryItemValidator.validate(pantryItem);
    } catch (e) {
      log(
        "Failed to validate pantry item.",
        name: "PantryItemFormViewmodel",
        error: e,
      );
      return InsertValidationFailure();
    }

    if (pantryItem.id == null) {
      final result = await _pantryItemRepository.insertItem(pantryItem);
      switch (result) {
        case RepoSuccess():
          return InsertSuccess(pantryItem.copyWith(id: result.data));
        case RepoFailure():
          return InsertRepoFailure();
        case RepoError():
          return InsertRepoFailure();
      }
    } else {
      final result = await _pantryItemRepository.updateItem(pantryItem);
      switch (result) {
        case RepoSuccess():
          return InsertSuccess(pantryItem);
        case RepoFailure():
          return InsertRepoFailure();
        case RepoError():
          return InsertRepoFailure();
      }
    }
  }
}