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

  factory LocalProduct.fromMap(Map<String, Object?> map) {
    return LocalProduct(
      id: map['id'] as int,
      name: map['name'] as String,
      barcode: map['barcode'] as String?,
      referenceUnit: map['referenceUnit'] as String,
      referenceValue: map['referenceValue'] as double,
      units: {},
      containerSize: map['containerSize'] as double?,
      calories: map['calories'] as double,
      carbs: map['carbs'] as double,
      protein: map['protein'] as double,
      fat: map['fat'] as double,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'units': Map.of(units),
      'referenceUnit': referenceUnit, 'referenceValue': referenceValue,
      'containerSize': containerSize, 'calories': calories, 'carbs': carbs,
      'protein': protein, 'fat': fat,
    };
  }
}