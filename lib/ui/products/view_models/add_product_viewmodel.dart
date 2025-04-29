import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:food_manager/core/result/repo_result.dart';
import 'package:food_manager/data/repositories/external_product_repository.dart';
import 'package:food_manager/data/repositories/local_product_repository.dart';
import 'package:food_manager/domain/models/product/local_product.dart';
import 'package:food_manager/ui/products/models/product_form_model.dart';

class AddProductViewmodel extends ChangeNotifier {
  AddProductViewmodel({
    required this.barcode,
    required ExternalProductRepository externalProductRepository,
    required LocalProductRepository localProductRepository,
  }) : _externalProductRepository = externalProductRepository,
        _localProductRepository = localProductRepository;

  final ExternalProductRepository _externalProductRepository;
  final LocalProductRepository _localProductRepository;
  final String? barcode;
  LocalProduct? product;
  ProductFormModel? form;
  bool loaded = false;
  bool navigated = false;

  Future<void> loadProductData() async {
    loaded = false;
    log('Loading product data for barcode $barcode');
    if (barcode == null) {
      product = null;
      form = ProductFormModel();
      loaded = true;
      notifyListeners();
      return;
    }
    log('Querying local database');
    final localResult = await _localProductRepository.getProductByBarcode(
        barcode!);
    switch (localResult) {
      case RepoSuccess(): {
        product = localResult.data;
        form = ProductFormModel.fromLocalProduct(product!);
      }
      case RepoFailure(): {
        log('Querying remote API');
        final remoteResult = await _externalProductRepository.getProduct(
            barcode!);
        switch (remoteResult) {
          case RepoSuccess(): {
            product = null;
            form = ProductFormModel.fromExternalProduct(remoteResult.data);
          }
          case RepoFailure(): {
            product = null;
            form = ProductFormModel(barcode: barcode);
          }
        }
      }
    }
    loaded = true;
    log('Loading done.');
    notifyListeners();
  }
}