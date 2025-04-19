class LocalProduct {
  final int? id;
  final String name, referenceUnit;
  final String? barcode;
  final Map<String, double> units;
  final double referenceValue, calories, carbs, protein, fat;
  final double? containerSize;

  LocalProduct({
    required this.name,
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
  });
}