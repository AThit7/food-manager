import 'package:flutter/material.dart';

import '../../../domain/models/product/local_product.dart';

class ProductViewmodel extends ChangeNotifier {
  final LocalProduct _product;
  String get productName => _product.name;

  ProductViewmodel({
    required LocalProduct product
  }) : _product = product;
}