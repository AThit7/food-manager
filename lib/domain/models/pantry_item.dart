import 'product/local_product.dart';

class PantryItem {
  final int? id;
  final LocalProduct product;
  final double quantity;
  final DateTime? expirationDate;

  PantryItem({
    this.id,
    required this.product,
    required this.quantity,
    this.expirationDate,
  });

  PantryItem copyWith({
    int? id,
    LocalProduct? product,
    double? quantity,
    DateTime? expirationDate,
  }) {
    return PantryItem(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      expirationDate: expirationDate ?? this.expirationDate,
    );
  }
}
