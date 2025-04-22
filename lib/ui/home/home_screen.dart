import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../scanner/widgets/scanner_screen.dart';
import '../scanner/view_models/scanner_viewmodel.dart';
import '../products/widgets/all_products_screen.dart';
import '../products/view_models/all_products_viewmodel.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home Screen')),
      body: Center(
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) {
                        final viewModel = ScannerViewModel(
                            localProductRepository: context.read(),
                            scannerService: context.read()
                        );
                        return ScannerScreen(viewModel: viewModel);
                      }
                  ),
                );
              },
              child: const Text('Scanner'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) {
                        final viewModel = AllProductsViewmodel(
                            localProductRepository: context.read()
                        );
                        return AllProductsScreen(viewModel: viewModel);
                      }
                  ),
                );
              },
              child: const Text('All products'),
            ),
          ],
        ),
      ),
    );
  }
}
