class PantryItemFormModel {
  int? id;
  String? quantity;
  DateTime? expirationDate;
  String? unit;

  String get textExpirationDate => expirationDate == null
      ? ""
      : "${expirationDate!.year}-${expirationDate!.month.toString().padLeft(2, '0')}"
      "-${expirationDate!.day.toString().padLeft(2, '0')}";

  PantryItemFormModel({this.id, this.quantity, this.expirationDate, this.unit});

  PantryItemFormModel copyWith({
    int? id,
    String? quantity,
    DateTime? expirationDate,
    String? unit,
  }) {
    return PantryItemFormModel(
      id: id ?? this.id,
      quantity: quantity ?? this.quantity,
      expirationDate: expirationDate ?? this.expirationDate,
      unit: unit ?? this.unit,
    );
  }
}
