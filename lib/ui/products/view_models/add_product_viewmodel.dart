import 'package:flutter/cupertino.dart';
import 'package:food_manager/core/result/result.dart';
import 'package:food_manager/data/repositories/external_product_repository.dart';
import 'package:food_manager/data/repositories/local_product_repository.dart';
import 'package:food_manager/domain/models/local_product.dart';
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
  bool isLoaded = false;
  bool hasNavigated = false;

  Future<void> loadProductData() async {
    isLoaded = false;
    product = null;
    form = null;
    errorMessage = null;

    if (barcode == null) {
      form = ProductFormModel();
      isLoaded = true;
      notifyListeners();
      return;
    }

    final localResult = await _localProductRepository.getProductByBarcode(barcode!);
    switch (localResult) {
      case ResultError(): errorMessage = localResult.toString();
      case ResultSuccess(): {
        product = localResult.data;
        form = ProductFormModel.fromLocalProduct(product!);
      }
      case ResultFailure(): {
        final remoteResult = await _externalProductRepository.fetchProduct(barcode!);
        switch (remoteResult) {
          case ResultSuccess(): form = ProductFormModel.fromExternalProduct(remoteResult.data);
          case ResultFailure(): form = ProductFormModel(barcode: barcode);
          case ResultError(): errorMessage = remoteResult.toString();
        }
      }
    }

    isLoaded = true;
    notifyListeners();
  }
}