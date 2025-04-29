import 'package:flutter/material.dart';
import 'package:food_manager/domain/models/product/local_product.dart';
import 'package:food_manager/ui/products/models/product_form_model.dart';
import 'package:food_manager/ui/products/widgets/product_form_screen.dart';
import 'package:provider/provider.dart';

import '../view_models/product_form_viewmodel.dart';

class ProductScreen extends StatelessWidget {
  const ProductScreen ({
    super.key,
    required this.product,
  });

  final LocalProduct product;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(product.name),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductFormScreen(
                      form: ProductFormModel.fromLocalProduct(product),
                      viewModel: ProductFormViewmodel(
                        localProductRepository: context.read(),
                        externalProductRepository: context.read(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: Text("TODO") //TODO: display product info
    );
  }
}