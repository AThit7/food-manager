import '../../../data/repositories/local_product_repository.dart';
import '../../../domain/models/product/local_product.dart';
import '../models/product_form_model.dart';

class ProductFormViewmodel {
  const ProductFormViewmodel({
    required LocalProductRepository localProductRepository,
  }) : _localProductRepository = localProductRepository;

  final LocalProductRepository _localProductRepository;

  Future<void> addProduct(ProductFormModel form) async {
    // TODO: form to LocalProduct
    await _localProductRepository.insertProduct(product);
  }
}
