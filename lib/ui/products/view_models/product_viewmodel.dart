import 'package:flutter/material.dart';

import '../../../domain/models/product/local_product.dart';
import '../models/product_form_model.dart';

class ProductViewmodel extends ChangeNotifier {
  final LocalProduct _product;
  String get productName => _product.name;

  ProductViewmodel({
    required LocalProduct product
  }) : _product = product;

  Future<ProductFormModel> fetchProductForm(String barcode) {
    // TODO: plan use cases, should db check be tightly couples with api fetch?

  }
}