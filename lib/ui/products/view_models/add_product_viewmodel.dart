import 'package:openfoodfacts/openfoodfacts.dart';

import '../../../data/services/database/database_service.dart';
import '../../../domain/models/product/local_product.dart';

class AddProductViewmodel {
  AddProductViewmodel({
    required this.productBarcode,
    required DatabaseService databaseService,
  }) : _databaseService = databaseService,
        _configuration = ProductQueryConfiguration(
          productBarcode ?? "",
          language: OpenFoodFactsLanguage.ENGLISH,
          version: ProductQueryVersion.v3,
        );

  final ProductQueryConfiguration _configuration;
  final String? productBarcode;
  final DatabaseService _databaseService;

  Future<ProductResultV3> getProductData() async {
    if (productBarcode == null) {
      return Future.error("Barcode doesn't have a user-friendly value.");
    }
    return await OpenFoodAPIClient.getProductV3(_configuration);
  }
}