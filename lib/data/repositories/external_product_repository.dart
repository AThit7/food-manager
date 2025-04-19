import 'package:food_manager/domain/models/product/external_product.dart';

import '../services/product_info_service.dart';
import '../../core/result/repo_result.dart';

class ExternalProductRepository {
  final ProductInfoService _productInfoService;

  const ExternalProductRepository(ProductInfoService productInfoService) :
      _productInfoService = productInfoService;

  Future<RepoResult<ExternalProduct>> getProduct(String barcode) async {
    final product = await _productInfoService.fetchProduct(barcode);
    if (product.success && product.product != null) {
      return RepoSuccess(product.product!);
    }
    return RepoFailure(product.message ??
        "Failed to fetch product with barcode $barcode");
  }
}