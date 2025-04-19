import 'package:flutter/material.dart';

import '../../../data/repositories/local_product_repository.dart';
import '../../../domain/models/product/local_product.dart';

class AllProductsViewmodel extends ChangeNotifier {
  AllProductsViewmodel ({
    required LocalProductRepository localProductRepository,
  }) : _localProductRepository = localProductRepository;

  final LocalProductRepository _localProductRepository;

  Future<List<LocalProduct>> getProducts() async {
    return await _localProductRepository.listProducts();
  }
}