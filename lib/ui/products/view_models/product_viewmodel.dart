import 'package:flutter/material.dart';

import '../../../data/services/database/database_service.dart';
import '../../../domain/models/product/local_product.dart';

class ProductViewmodel extends ChangeNotifier {
  ProductViewmodel({
    required LocalProduct product
  }) : _product = product;

  final LocalProduct _product;
  String get productName => _product.name;
//final DatabaseService _databaseService;
}