import 'package:openfoodfacts/openfoodfacts.dart';

class AddProductViewmodel {
  AddProductViewmodel({
    required this.productBarcode,
  }) : _configuration = ProductQueryConfiguration(
          productBarcode ?? "",
          language: OpenFoodFactsLanguage.ENGLISH,
          version: ProductQueryVersion.v3,
        );

  final ProductQueryConfiguration _configuration;
  final String? productBarcode;

  Future<ProductResultV3> getProductData() async {
    if (productBarcode == null) {
      return Future.error("Barcode doesn't have a user-friendly value.");
    }
    return await OpenFoodAPIClient.getProductV3(_configuration);
  }
}