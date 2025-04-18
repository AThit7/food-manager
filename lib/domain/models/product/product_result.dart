import 'external_product.dart';

class ProductResult {
  final ExternalProduct? product;
  final bool success;
  final String? message;

  const ProductResult(this.product, this.success, [this.message]);
}