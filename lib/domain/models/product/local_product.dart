import 'package:food_manager/domain/models/tag.dart';

class LocalProduct {
  final int? id, shelfLifeAfterOpening;
  final String name, referenceUnit;
  final Tag tag;
  final String? barcode;
  final Map<String, double> units;
  final double referenceValue, calories, carbs, protein, fat;
  final double? containerSize;

  const LocalProduct({
    required this.name,
    required this.tag,
    required this.units,
    required this.referenceUnit,
    required this.referenceValue,
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.fat,
    this.id,
    this.barcode,
    this.containerSize,
    this.shelfLifeAfterOpening,
  });

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
    );
  }
}