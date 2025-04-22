import 'package:flutter/material.dart';
import 'package:food_manager/core/result/repo_result.dart';

import '../../../data/repositories/local_product_repository.dart';
import '../../../domain/models/product/local_product.dart';

class AllProductsViewmodel extends ChangeNotifier {
  AllProductsViewmodel ({
    required LocalProductRepository localProductRepository,
  }) : _localProductRepository = localProductRepository;

  final LocalProductRepository _localProductRepository;

  Future<List<LocalProduct>> getProducts() async {
    final result =  await _localProductRepository.listProducts();
    switch (result) {
      case RepoSuccess(): result.data;
      case RepoFailure(): [];
    }
    return []; // TODO: ??
  }
}