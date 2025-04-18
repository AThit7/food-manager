import 'package:flutter/material.dart';
import 'package:openfoodfacts/openfoodfacts.dart';

class ProductDetailsViewmodel extends ChangeNotifier {
  ProductDetailsViewmodel({required String? productBarcode})
      : _productBarcode = productBarcode,
        configuration = ProductQueryConfiguration(
          productBarcode ?? "",
          language: OpenFoodFactsLanguage.ENGLISH,
          fields: [ProductField.ALL],
          version: ProductQueryVersion.v3,
        );

  final ProductQueryConfiguration configuration;
  final String? _productBarcode;
  String? get productBarcode => _productBarcode;

  Future<ProductResultV3> getProductData() async {
    if (_productBarcode == null) {
      return Future.error("Barcode doesn't have a user-friendly value.");
    }
    return await OpenFoodAPIClient.getProductV3(configuration);
  }
}