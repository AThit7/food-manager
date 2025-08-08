import 'product/local_product.dart';

// TODO add isOpen to repo, expirationDate is not null now
class PantryItem {
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
  });

  PantryItem copyWith({
    int? id,
    LocalProduct? product,
    double? quantity,
    DateTime? expirationDate,
    bool? isOpen,
  }) {
    return PantryItem(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      expirationDate: expirationDate ?? this.expirationDate,
      isOpen: isOpen ?? this.isOpen,
    );
  }
}
