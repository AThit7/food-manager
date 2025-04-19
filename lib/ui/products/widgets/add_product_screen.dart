import 'package:flutter/material.dart';
import 'package:json_view/json_view.dart';
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
      body: FutureBuilder(
          future: viewModel.getProductData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Column(
                children: [
                  Text('Something went wrong'),
                  Text(snapshot.error.toString()),
                ],
              ));
            }
            if (snapshot.hasData) {
              if (snapshot.data!.status != 'success') {
                return Column(
                  children: [
                    Expanded(child: JsonView(json: snapshot.data!.toJson())),
                    Expanded(
                      child: Center(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ProductFormScreen (
                                    product: null,
                                    barcode: snapshot.data!.barcode,
                                    viewModel: ProductFormViewmodel(
                                      localProductRepository: context.read(),
                                    ),
                                  )
                              ),
                            );
                          },
                          child: const Text('Create item'),
                        ),
                      ),
                    )
                  ],
                );
              }
              else {
                return ProductFormScreen(
                  product: snapshot.data!.product,
                  barcode: snapshot.data!.barcode,
                  viewModel: ProductFormViewmodel(
                    localProductRepository: context.read(),
                  ),
                );
              }
            }
            return const Center(child: Text('Unexpected state'));
          }
      ),
    );
  }
}