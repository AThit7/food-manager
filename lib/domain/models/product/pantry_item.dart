import 'local_product.dart';

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
}
