import 'dart:async';

import 'package:mobile_scanner/mobile_scanner.dart';

abstract class ScannerService {
  MobileScannerController get controller;
  void startScanning();
  void stopScanning();
  void dispose();
}

class ScannerMLKitService implements ScannerService{
  final MobileScannerController _controller = MobileScannerController();

  @override
  MobileScannerController get controller => _controller;

  @override
  void startScanning() {
    unawaited(_controller.start());
  }

  @override
  void stopScanning() {
    _controller.stop();
  }

  @override
  void dispose() {
    _controller.dispose();
  }
}

class ScannerFactory {
  static ScannerService getScanner(String? scannerType) {
    switch (scannerType) {
      case 'ml-kit':
      default:
        return ScannerMLKitService();
    }
  }
}