import 'package:flutter/cupertino.dart';
import 'package:food_manager/core/result/result.dart';
import 'package:food_manager/data/repositories/local_product_repository.dart';
import 'package:food_manager/domain/models/local_product.dart';

class ProductViewmodel extends ChangeNotifier {
  ProductViewmodel({
    required LocalProductRepository localProductRepository,
    required LocalProduct product,
  }) : _localProductRepository = localProductRepository,
        _product = product;

  final LocalProductRepository _localProductRepository;
  LocalProduct _product;
  LocalProduct get product => _product;
  String? errorMessage;
  bool? isLoading = false;

  void setProduct(LocalProduct product) {
    _product = product;
    notifyListeners();
  }

  Future<void> deleteProduct() async {
    if (product.id == null) {
      errorMessage = "Product has no id. Can't delete it.";
      throw StateError("Product has no id");
    }
    errorMessage = null;
    isLoading = true;
    notifyListeners();

    final result = await _localProductRepository.deleteProduct(product.id!);

    switch(result) {
      case ResultSuccess(): break;
      case ResultError(): errorMessage = result.message;
      case ResultFailure(): errorMessage = "Couldn't delete item.";
    }

    isLoading = false;
    notifyListeners();
  }
}