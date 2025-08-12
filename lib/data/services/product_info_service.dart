import 'package:openfoodfacts/openfoodfacts.dart';

import '../../domain/models/product/external_product.dart';
import '../../domain/models/product/product_result.dart';

class ProductInfoService{
  void init(){
    OpenFoodAPIConfiguration.globalLanguages = <OpenFoodFactsLanguage>[
      OpenFoodFactsLanguage.ENGLISH,
    ];
  }

  Future<ProductResult> fetchProduct(String barcode) async {
    final productResult = await OpenFoodAPIClient.getProductV3(
      ProductQueryConfiguration(barcode, version: ProductQueryVersion.v3),
    );

    final product = productResult.product;
    if (productResult.status == ProductResultV3.statusFailure ||
        product == null) {
      return ProductResult(null, false);
    }

    final match = RegExp(r'[a-zA-Z]+').firstMatch(product.servingSize ?? "");
    final size = PerSize.oneHundredGrams;
    final externalProduct = ExternalProduct(
      barcode:  product.barcode,
      name: product.getBestProductName(OpenFoodFactsLanguage.ENGLISH),
      tag: product.categories?.split(", ").last, // TODO is this field good?
      referenceUnit: match?.group(0),
      containerSize: product.packagingQuantity,
      calories: product.nutriments?.getValue(Nutrient.energyKCal, size),
      carbs: product.nutriments?.getValue(Nutrient.carbohydrates, size),
      protein: product.nutriments?.getValue(Nutrient.proteins, size),
      fat: product.nutriments?.getValue(Nutrient.fat, size),
    );
    return ProductResult(externalProduct, true);
  }
}