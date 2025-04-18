import 'package:flutter/material.dart';
import 'package:json_view/json_view.dart';
import 'package:openfoodfacts/openfoodfacts.dart';

import '../view_models/product_details_viewmodel.dart';

class ProductDetailsScreen extends StatelessWidget {
  const ProductDetailsScreen ({
    super.key,
    required this.viewModel,
  });

  final ProductDetailsViewmodel viewModel;

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
              return JsonView(json: snapshot.data!.product!.toJson());
            }
            return const Center(child: Text('Unexpected state'));
          }
      ),
    );
  }
}