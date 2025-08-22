import 'dart:developer';

import 'package:food_manager/core/result/result.dart';
import 'package:food_manager/data/models/external_product.dart';
import 'package:openfoodfacts/openfoodfacts.dart';


class ExternalProductRepository {
  ExternalProductRepository() {
    OpenFoodAPIConfiguration.globalLanguages = <OpenFoodFactsLanguage>[OpenFoodFactsLanguage.ENGLISH];
  }

  Future<Result<ExternalProduct>> fetchProduct(String barcode) async {
    try {
      final productResult = await OpenFoodAPIClient.getProductV3(
        ProductQueryConfiguration(barcode, version: ProductQueryVersion.v3),
      );

      final product = productResult.product;
      ProductResultV3.statusWarning;
      if (productResult.status == ProductResultV3.statusFailure ||
          product == null) {
        return ResultFailure('Failed to find a matching product');
      }

      final match = RegExp(r'[a-zA-Z]+').firstMatch(product.servingSize ?? "");
      final size = PerSize.oneHundredGrams;
      final externalProduct = ExternalProduct(
        barcode: product.barcode,
        name: product.getBestProductName(OpenFoodFactsLanguage.ENGLISH),
        tag: product.categories
            ?.split(",")
            .last
            .trim(),
        referenceUnit: match?.group(0),
        containerSize: product.packagingQuantity,
        calories: product.nutriments?.getValue(Nutrient.energyKCal, size),
        carbs: product.nutriments?.getValue(Nutrient.carbohydrates, size),
        protein: product.nutriments?.getValue(Nutrient.proteins, size),
        fat: product.nutriments?.getValue(Nutrient.fat, size),
      );
      return ResultSuccess(externalProduct);
    } catch (e) {
      log('Error while fetching product data from API', name: 'ProductInfoService', error: e);
      return ResultError('Error while fetching product data from API: e');
    }
  }
}