import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models/add_product_viewmodel.dart';
import '../view_models/product_form_viewmodel.dart';
import 'product_form_screen.dart';

class AddProductScreen extends StatelessWidget {
  const AddProductScreen ({
    super.key,
    required this.viewModel,
  });

  final AddProductViewmodel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product details')),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, child) {
          if (!viewModel.loaded) {
            viewModel.loadProductData();
            return const Center(child: CircularProgressIndicator());
          }
          else if (viewModel.product != null) {
            // TODO: check if containerSize is set and add based on that,
            //  probably new form needed
            return const Text("TODO");
          }
          else if (viewModel.form != null) {
            if (!viewModel.navigated) {
              viewModel.navigated = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          ProductFormScreen(
                            form: viewModel.form,
                            viewModel: ProductFormViewmodel(
                              localProductRepository: context.read(),
                              externalProductRepository: context.read(),
                            ),
                          )
                  ),
                );
              });
            }
            return const SizedBox();
          }
          return const Center(child: Text('Unexpected state'));
        },
      ),
    );
  }
}