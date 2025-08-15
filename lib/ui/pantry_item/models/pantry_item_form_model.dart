class PantryItemFormModel {
  int? id;
  String? uuid;
  String? quantity;
  DateTime? expirationDate;
  String? unit;
  bool isOpen = false;
  bool isBought;

  String get textExpirationDate => expirationDate == null
      ? ""
      : "${expirationDate!.year}-${expirationDate!.month.toString().padLeft(2, '0')}"
      "-${expirationDate!.day.toString().padLeft(2, '0')}";

  PantryItemFormModel({this.id, this.uuid, this.quantity, this.expirationDate, this.unit, required this.isOpen,
    required this.isBought});

  PantryItemFormModel copyWith({
    int? id,
    String? uuid,
    String? quantity,
    DateTime? expirationDate,
    String? unit,
    bool? isOpen,
    bool? isBought
  }) {
    return PantryItemFormModel(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      quantity: quantity ?? this.quantity,
      expirationDate: expirationDate ?? this.expirationDate,
      unit: unit ?? this.unit,
      isOpen: isOpen ?? this.isOpen,
      isBought: isBought ?? this.isBought,
    );
  }
}