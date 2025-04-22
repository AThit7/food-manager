import '../../../domain/models/product/external_product.dart';
import '../../../domain/models/product/local_product.dart';

class ProductFormModel {
  String? barcode, name, referenceUnit, referenceValue,
      containerSize, calories, carbs, protein, fat;
  Map<String, double>? units;

  ProductFormModel({this. barcode, this.name, this.referenceUnit,
    this.referenceValue, this.containerSize, this.calories, this.carbs,
  this.protein, this.fat});

  ProductFormModel.fromExternalProduct(ExternalProduct product) {
    barcode = product.barcode;
    name = product.name;
    referenceUnit = product.referenceUnit;
    referenceValue = (100.0).toString();
    containerSize = product.containerSize.toString();
    calories = product.calories.toString();
    carbs = product.carbs.toString();
    protein = product.protein.toString();
    fat = product.fat.toString();
    units = {};
  }

  ProductFormModel.fromLocalProduct(LocalProduct product) {
    barcode = product.barcode;
    name = product.name;
    referenceUnit = product.referenceUnit;
    referenceValue = product.referenceValue.toString();
    containerSize = product.containerSize.toString();
    calories = product.calories.toString();
    carbs = product.carbs.toString();
    protein = product.protein.toString();
    fat = product.fat.toString();
    units = Map.of(product.units);
  }
}