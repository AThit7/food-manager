import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../view_models/scanner_viewmodel.dart';
import '../../products/view_models/add_product_viewmodel.dart';
import '../../products/widgets/add_product_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({
    super.key,
    required this.viewModel,
  });

  final ScannerViewModel viewModel;

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  Barcode? _barcode;
  final MobileScannerController scannerController = MobileScannerController();

  Widget _buildBarcode(Barcode? value) {
    if (value == null) {
      return const Text(
        'Scan something!',
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
            if (!mounted) return;

            setState(() {
              _barcode = barcodes.barcodes.firstOrNull;
            });

            String? barcode = barcodes.barcodes.first.displayValue;
            if (barcode == null) return;

            Navigator.pop(context);
            widget.viewModel.handleBarcode(context, barcode);
          };

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

class _ScannerScreenStateBkp extends State<ScannerScreen> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.startScanner();
  }

  @override
  void dispose() {
    widget.viewModel.stopScanner();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scanner Screen')),
      body: Center(
        child: Column(
          children: [
            Stack(
              children: [
                // Add MobileScanner widget here
                MobileScanner(
                  controller: widget.viewModel.controller,
                  onDetect: (BarcodeCapture capture) {
                    if (capture.barcodes.isNotEmpty) {
                      final barcodeValue = capture.barcodes.first.displayValue;
                      widget.viewModel.updateScannedData(barcodeValue);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) {
                              final viewModel = AddProductViewmodel(
                                  productBarcode :
                                  capture.barcodes.first.displayValue,
                              );
                              return AddProductScreen(viewModel: viewModel);
                            }
                        ),
                      );                    }
                  },
                  fit: BoxFit.contain,
                ),
                if (widget.viewModel.scannedData != null)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      color: Colors.black.withOpacity(0.7),
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        widget.viewModel.scannedData!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
