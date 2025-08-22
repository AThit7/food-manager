import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:food_manager/core/result/result.dart';

import '../../../data/repositories/local_product_repository.dart';
import '../../../domain/models/local_product.dart';

class AllProductsViewmodel extends ChangeNotifier {
  AllProductsViewmodel ({
    required LocalProductRepository localProductRepository,
  }) : _localProductRepository = localProductRepository {
    _subscription = _localProductRepository.productUpdates.listen(_onProductEvent);
  }

  final LocalProductRepository _localProductRepository;
  late final StreamSubscription<ProductEvent> _subscription;
  List<LocalProduct> _products = [];
  String? errorMessage;
  bool isLoading = false;

  List<LocalProduct> get products => List.unmodifiable(_products.sorted((a, b) => a.name.compareTo(b.name)));

  void _onProductEvent(ProductEvent event) {
    switch (event) {
      case ProductAdded(): _products.add(event.product);
      case ProductDeleted():
        _products.removeWhere((p) => p.id == event.productId);
      case ProductModified(): {
        final index = _products.indexWhere((p) => p.id == event.product.id);
        if (index != -1) _products[index] = event.product;
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  Future<void> loadProducts() async {
    isLoading = true;
    final result =  await _localProductRepository.listProducts();
    errorMessage = null;
    _products = [];

    switch (result) {
      case ResultSuccess(): _products = result.data;
      case ResultError(): errorMessage = result.message;
      case ResultFailure():
        throw StateError('Unexpected RepoFailure in loadProducts');
    }

    isLoading = false;
    notifyListeners();
  }
}