import 'package:flutter/material.dart';
import 'package:food_manager/ui/products/view_models/add_product_viewmodel.dart';
import 'package:food_manager/ui/products/widgets/add_product_screen.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({
    super.key,
  });

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

// TODO: change to stateless
class _ScannerScreenState extends State<ScannerScreen> {
  Barcode? _barcode;
  final MobileScannerController scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    detectionTimeoutMs: 500,
  );

  bool _isHandling = false;

  Widget _buildBarcode(Barcode? value) {
    if (value == null) {
      return const Text(
        'Scan something',
        overflow: TextOverflow.fade,
        style: TextStyle(color: Colors.white),
      );
    }

    return Text(
      value.displayValue ?? 'No display value.',
      overflow: TextOverflow.fade,
      style: const TextStyle(color: Colors.white),
    );
  }

  void Function(BarcodeCapture)? _handleBarcode(BuildContext context) =>
          (BarcodeCapture barcodes) async {
        if (!mounted || _isHandling) return;
        _isHandling = true;

        setState(() {
          _barcode = barcodes.barcodes.firstOrNull;
        });

        String? barcode = barcodes.barcodes.first.displayValue;
        if (barcode == null) {
          _isHandling = false;
          return;
        }

        Navigator.pushReplacement(
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
      };

  @override
  void dispose() {
    scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Simple scanner')),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: scannerController,
            onDetect: _handleBarcode(context),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              alignment: Alignment.bottomCenter,
              height: 100,
              color: const Color.fromRGBO(0, 0, 0, 0.4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(child: Center(child: _buildBarcode(_barcode))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}