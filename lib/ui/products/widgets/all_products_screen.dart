import 'package:flutter/material.dart';
import 'package:food_manager/ui/products/view_models/product_viewmodel.dart';
import 'package:food_manager/ui/products/widgets/product_screen.dart';
import 'package:provider/provider.dart';

import '../view_models/all_products_viewmodel.dart';

class AllProductsScreen extends StatefulWidget {
  const AllProductsScreen ({
    super.key,
    required this.viewModel,
  });

  final AllProductsViewmodel viewModel;

  @override
  State<AllProductsScreen> createState() => _AllProductsScreenState();
}

class _AllProductsScreenState extends State<AllProductsScreen> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    return Scaffold(
      appBar: AppBar(title: const Text('Product details')),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (viewModel.errorMessage != null) {
            return Center(child: Column(
              children: [
                Text('Something went wrong'),
                IconButton(
                  onPressed: viewModel.loadProducts,
                  icon: Icon(Icons.refresh),
                ),
              ],
            ));
          } else if (viewModel.products.isEmpty) {
            return const Center(
                child: Text('Local product database is empty'));
          } else {
            return ListView(
              children: [
                for (var product in viewModel.products)
                  Card(
                    child: ListTile(
                      title: Text(product.name),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              final viewModel = ProductViewmodel(
                                localProductRepository: context.read(),
                                product: product,
                              );
                              return ProductScreen(viewModel:viewModel);
                            },
                          ),
                        );
                      },
                    ),
                  )
              ],
            );
          }
        }
      ),
    );
  }
}