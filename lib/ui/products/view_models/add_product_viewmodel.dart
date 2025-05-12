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
  String? errorMessage;
  bool loaded = false;
  bool navigated = false;

  Future<void> loadProductData() async {
    loaded = false;
    product = null;
    form = null;
    errorMessage = null;
    log('Loading product data for barcode $barcode');
    if (barcode == null) {
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
      case RepoError(): {
        errorMessage = localResult.toString();
      }
      case RepoFailure(): {
        log('Querying remote API');
        final remoteResult = await _externalProductRepository.getProduct(
            barcode!);
        switch (remoteResult) {
          case RepoSuccess(): {
            form = ProductFormModel.fromExternalProduct(remoteResult.data);
          }
          case RepoFailure(): {
            form = ProductFormModel(barcode: barcode);
          }
          case RepoError(): {
            errorMessage = remoteResult.toString();
          }
        }
      }
    }
    loaded = true;
    log('Loading done.');
    notifyListeners();
  }
}