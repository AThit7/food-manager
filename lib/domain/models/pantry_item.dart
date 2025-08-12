import 'package:uuid/uuid.dart';

import 'product/local_product.dart';

class PantryItem {
  final String uuid;
  final int? id;
  final LocalProduct product;
  final double quantity;
  final DateTime expirationDate;
  final bool isOpen;

  PantryItem({
    this.id,
    required this.product,
    required this.quantity,
    required this.expirationDate,
    required this.isOpen,
  }) : uuid = const Uuid().v4();

  PantryItem.withUuid({
    this.id,
    required this.uuid,
    required this.product,
    required this.quantity,
    required this.expirationDate,
    required this.isOpen,
  });

  PantryItem copyWith({
    int? id,
    LocalProduct? product,
    double? quantity,
    DateTime? expirationDate,
    bool? isOpen,
  }) {
    return PantryItem.withUuid(
      id: id ?? this.id,
      uuid: uuid,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      expirationDate: expirationDate ?? this.expirationDate,
      isOpen: isOpen ?? this.isOpen,
    );
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is PantryItem && other.uuid == uuid;

  @override
  int get hashCode => uuid.hashCode;
}
