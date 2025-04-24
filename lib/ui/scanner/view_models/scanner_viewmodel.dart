import 'package:flutter/material.dart';
import 'package:food_manager/core/result/repo_result.dart';
import 'package:provider/provider.dart';
import '../../../data/repositories/local_product_repository.dart';
import '../../products/widgets/add_product_screen.dart';
import '../../products/view_models/add_product_viewmodel.dart';
import '../../products/widgets/product_screen.dart';

class ScannerViewModel extends ChangeNotifier {
  final LocalProductRepository _localProductRepository;

  String? _scannedData;
  String? get scannedData => _scannedData;

  ScannerViewModel({
    required LocalProductRepository localProductRepository,
  }) : _localProductRepository = localProductRepository;

  Future<void> handleBarcode(BuildContext context, String barcode) async {
    RepoResult? result = await _localProductRepository.getProductByBarcode(
        barcode);
    if (!context.mounted) return;
    if (result is RepoSuccess) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductScreen(
              product: result.data,
            ),
          ),
        );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddProductScreen(
            viewModel: AddProductViewmodel(
              barcode: barcode,
              localProductRepository: context.read(),
              externalProductRepository: context.read(),
            ),
          ),
        ),
      );
    }
  }
}