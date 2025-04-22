import 'package:flutter/material.dart';
import 'package:food_manager/core/result/repo_result.dart';

import '../../../data/repositories/local_product_repository.dart';
import '../../../domain/models/product/local_product.dart';
import '../models/product_form_model.dart';
import '../../../data/repositories/external_product_repository.dart';
import '../../../domain/validators/local_product_validator.dart';

class ProductFormViewmodel {
  const ProductFormViewmodel({
    required LocalProductRepository localProductRepository,
    required ExternalProductRepository externalProductRepository,
  }) : _localProductRepository = localProductRepository,
        _externalProductRepository = externalProductRepository;

  final LocalProductRepository _localProductRepository;
  final ExternalProductRepository _externalProductRepository;

  Future<void> addProduct(ProductFormModel form) async {
    try {
      final product = LocalProduct(
        name: form.name!,
        units: Map.of(form.units!),
        referenceUnit: form.referenceUnit!,
        referenceValue: double.tryParse(form.referenceValue ?? "")!,
        calories: double.tryParse(form.calories ?? "")!,
        carbs: double.tryParse(form.carbs ?? "")!,
        protein: double.tryParse(form.protein ?? "")!,
        fat: double.tryParse(form.fat ?? "")!,
      );
      ProductValidator.validate(product);
      await _localProductRepository.insertProduct(product);
    } catch (e) {
      // TODO: show SnackBar
    }
  }

  Future<ProductFormModel> fetchProductForm(String barcode) async {
    // TODO: plan use cases, should db check be tightly couples with api fetch?
    final result = await _externalProductRepository.getProduct(barcode);
    switch (result) {
      case RepoSuccess():
        return ProductFormModel.fromExternalProduct(result.data);
      case RepoFailure(): return ProductFormModel(barcode: barcode);
    }
  }
}
