import '../../../data/services/database/database_service.dart';
import '../../../domain/models/product/local_product.dart';

class ProductFormViewmodel {
  const ProductFormViewmodel({
    required DatabaseService databaseService,
  }) : _databaseService = databaseService;

  final DatabaseService _databaseService;

  Future<void> addProduct(LocalProduct product) async {
    await _databaseService.insertProduct(product);
  }
}
