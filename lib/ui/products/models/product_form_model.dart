import '../../../domain/models/product/external_product.dart';
import '../../../domain/models/product/local_product.dart';

class ProductFormModel {
  int? id;
  String? barcode, name, tag, referenceUnit, referenceValue,
      containerSize, calories, carbs, protein, fat, shelfLifeAfterOpening;
  Map<String, double>? units;

  ProductFormModel({this.id, this. barcode, this.name, this.tag,
    this.referenceUnit, this.referenceValue, this.containerSize, this.calories,
    this.carbs, this.protein, this.fat, this.shelfLifeAfterOpening,
    this.units});

  // TODO add some tag?
  ProductFormModel.fromExternalProduct(ExternalProduct product) {
    barcode = product.barcode;
    name = product.name;
    referenceUnit = product.referenceUnit ?? "g";
    referenceValue = (100.0).toString();
    containerSize = product.containerSize?.toString();
    calories = product.calories?.toString();
    carbs = product.carbs?.toString();
    protein = product.protein?.toString();
    fat = product.fat?.toString();
    units = {};
  }

  ProductFormModel.fromLocalProduct(LocalProduct product) {
    id = product.id;
    barcode = product.barcode;
    name = product.name;
    tag = product.tag;
    referenceUnit = product.referenceUnit;
    referenceValue = product.referenceValue.toString();
    containerSize = product.containerSize?.toString();
    calories = product.calories.toString();
    carbs = product.carbs.toString();
    protein = product.protein.toString();
    fat = product.fat.toString();
    shelfLifeAfterOpening = product.shelfLifeAfterOpening?.toString();
    units = Map.of(product.units);
  }

  ProductFormModel copyWith({
    int? id,
    String? barcode,
    String? name,
    String? tag,
    String? referenceUnit,
    String? referenceValue,
    String? containerSize,
    String? calories,
    String? carbs,
    String? protein,
    String? fat,
    String? shelfLifeAfterOpening,
    Map<String, double>? units,
  }) {
    return ProductFormModel(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      tag : tag ?? this.tag,
      referenceUnit: referenceUnit ?? this.referenceUnit,
      referenceValue: referenceValue ?? this.referenceValue,
      containerSize: containerSize ?? this.containerSize,
      calories: calories ?? this.calories,
      carbs: carbs ?? this.carbs,
      protein: protein ?? this.protein,
      fat: fat ?? this.fat,
      shelfLifeAfterOpening:shelfLifeAfterOpening ??
          this.shelfLifeAfterOpening,
      units: units ?? (this.units != null ? Map.of(this.units!) : null),
    );
  }
}