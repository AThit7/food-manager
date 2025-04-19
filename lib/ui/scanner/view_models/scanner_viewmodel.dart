import 'package:flutter/material.dart';
import 'package:food_manager/domain/models/product/local_product.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../data/services/scanner_service.dart';
import '../../../data/repositories/local_product_repository.dart';
import '../../products/widgets/add_product_screen.dart';
import '../../products/view_models/add_product_viewmodel.dart';
import '../../products/widgets/product_screen.dart';

class ScannerViewModel extends ChangeNotifier {
  final ScannerService _scannerService;
  final LocalProductRepository _localProductRepository;

  String? _scannedData;
  String? get scannedData => _scannedData;

  ScannerViewModel({
    required ScannerService scannerService,
    required LocalProductRepository localProductRepository,
  })
      : _scannerService = scannerService,
        _localProductRepository = localProductRepository;

  MobileScannerController get controller => _scannerService.controller;

  Future<void> handleBarcode(BuildContext context, String barcode) async {
    LocalProduct? product = await _localProductRepository.getProductByBarcode(barcode);
    if (!context.mounted) return;
    if (product != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductScreen(
              product: product,
            ),
          ),
        );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddProductScreen(
              viewModel: AddProductViewmodel(productBarcode: barcode),
          ),
        ),
      );
    }
  }

  void updateScannedData(String? data) {
    _scannedData = data;
    notifyListeners();
  }

  void startScanner() {
    _scannerService.startScanning();
  }

  void stopScanner() {
    _scannerService.stopScanning();
  }

  @override
  void dispose() {
    _scannerService.dispose();
    super.dispose();
  }
}