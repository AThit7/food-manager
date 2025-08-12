class PantryItemFormModel {
  int? id;
  String? quantity;
  DateTime? expirationDate;
  String? unit;
  bool isOpen = false;

  String get textExpirationDate => expirationDate == null
      ? ""
      : "${expirationDate!.year}-${expirationDate!.month.toString().padLeft(2, '0')}"
      "-${expirationDate!.day.toString().padLeft(2, '0')}";

  PantryItemFormModel({this.id, this.quantity, this.expirationDate, this.unit, required this.isOpen});

  PantryItemFormModel copyWith({
    int? id,
    String? quantity,
    DateTime? expirationDate,
    String? unit,
    bool? isOpen,
  }) {
    return PantryItemFormModel(
      id: id ?? this.id,
      quantity: quantity ?? this.quantity,
      expirationDate: expirationDate ?? this.expirationDate,
      unit: unit ?? this.unit,
      isOpen: isOpen ?? this.isOpen,
    );
  }
}
