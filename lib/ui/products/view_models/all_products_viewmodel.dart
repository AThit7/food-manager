import 'package:flutter/material.dart';

import '../../../data/services/database/database_service.dart';
import '../../../domain/models/product/local_product.dart';

class AllProductsViewmodel extends ChangeNotifier {
  AllProductsViewmodel ({
    required DatabaseService databaseService,
  }) : _databaseService = databaseService;

  final DatabaseService _databaseService;

  Future<List<LocalProduct>> getProducts() async {
    return await _databaseService.listProducts();
  }
}
