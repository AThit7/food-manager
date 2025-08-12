import 'package:food_manager/domain/models/tag.dart';

class LocalProduct {
  final int? id;
  final String name, referenceUnit;
  final Tag tag;
  final String? barcode;
  final Map<String, double> units;
  final double referenceValue, calories, carbs, protein, fat;
  final double? containerSize;
  final int expectedShelfLife, shelfLifeAfterOpening;

  LocalProduct({
    required this.name,
    required this.tag,
    required this.units,
    required this.referenceUnit,
    required this.referenceValue,
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.expectedShelfLife,
    this.id,
    this.barcode,
    this.containerSize,
    int? shelfLifePostOpening,
  }) : shelfLifeAfterOpening = shelfLifePostOpening ?? expectedShelfLife;

  LocalProduct copyWith({int? id}) {
    return LocalProduct(
      id: id ?? this.id,
      name: name,
      tag: tag,
      units: units,
      referenceUnit: referenceUnit,
      referenceValue: referenceValue,
      calories: calories,
      carbs: carbs,
      protein: protein,
      fat: fat,
      barcode: barcode,
      containerSize: containerSize,
      shelfLifePostOpening: shelfLifeAfterOpening,
      expectedShelfLife: expectedShelfLife,
    );
  }
}