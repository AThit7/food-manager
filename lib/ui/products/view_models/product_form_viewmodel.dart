import 'dart:async';
import 'dart:developer';

import 'package:food_manager/core/result/repo_result.dart';
import 'package:food_manager/domain/models/tag.dart';

import '../../../data/repositories/local_product_repository.dart';
import '../../../domain/models/product/local_product.dart';
import '../models/product_form_model.dart';
import '../../../domain/validators/local_product_validator.dart';

sealed class InsertResult {}

class InsertSuccess extends InsertResult {
  final LocalProduct product;

  InsertSuccess(this.product);
}

class InsertRepoFailure extends InsertResult {}

class InsertValidationFailure extends InsertResult {}

class ProductFormViewmodel {
  ProductFormViewmodel({
    required LocalProductRepository localProductRepository,
  }) : _localProductRepository = localProductRepository;

  final LocalProductRepository _localProductRepository;

  Future<InsertResult> saveProduct(ProductFormModel form) async {
    LocalProduct product;
    try {
      product = LocalProduct(
        id: form.id,
        name: form.name!,
        tag: Tag(name: form.tag!),
        barcode: form.barcode,
        units: Map.of(form.units!),
        referenceUnit: form.referenceUnit!,
        referenceValue: double.parse(form.referenceValue!),
        containerSize: form.containerSize != null
            ? double.parse(form.containerSize!) : null ,
        calories: double.parse(form.calories!),
        carbs: double.parse(form.carbs!),
        protein: double.parse(form.protein!),
        fat: double.parse(form.fat!),
        shelfLifePostOpening: int.parse(form.shelfLifeAfterOpening!),
        expectedShelfLife: int.parse(form.expectedShelfLife!),
      );
      ProductValidator.validate(product);
    } catch (e) {
      log(
        "Failed to validate product.",
        name: "ProductFormViewmodel",
        error: e,
      );
      return InsertValidationFailure();
    }

    if (product.id == null) {
      final result = await _localProductRepository.insertProduct(product);
      switch (result) {
        case RepoSuccess():
          return InsertSuccess(product.copyWith(id: result.data));
        case RepoFailure():
          return InsertRepoFailure();
        case RepoError():
          return InsertRepoFailure();
      }
    } else {
      final result = await _localProductRepository.updateProduct(product);
      switch (result) {
        case RepoSuccess():
          return InsertSuccess(product);
        case RepoFailure():
          return InsertRepoFailure();
        case RepoError():
          return InsertRepoFailure();
      }
    }
  }
}
