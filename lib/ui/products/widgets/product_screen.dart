import 'package:flutter/material.dart';
import 'package:food_manager/domain/models/product/local_product.dart';
import 'package:food_manager/ui/products/models/product_form_model.dart';
import 'package:food_manager/ui/products/widgets/product_form_screen.dart';
import 'package:provider/provider.dart';

import '../view_models/product_form_viewmodel.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen ({
    super.key,
    required this.product,
  });

  final LocalProduct product;

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  late LocalProduct product;

  @override
  void initState() {
    product = widget.product;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final updatedProduct = await Navigator.push(
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
              if (updatedProduct != null) {
                setState(() { product = updatedProduct; });
              }
            },
          ),
        ],
      ),
      body: Text("TODO"), //TODO: display product info
    );
  }
}