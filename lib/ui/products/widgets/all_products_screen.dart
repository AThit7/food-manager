import 'package:flutter/material.dart';
import 'package:food_manager/ui/products/widgets/product_screen.dart';

import '../view_models/all_products_viewmodel.dart';

// TODO: re-fetch products after Navigator.pop()
class AllProductsScreen extends StatelessWidget {
  const AllProductsScreen ({
    super.key,
    required this.viewModel,
  });

  final AllProductsViewmodel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product details')),
      body: FutureBuilder(
          future: viewModel.getProducts(),
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
              if (snapshot.data!.isEmpty) {
                return const Center(
                    child: Text('Local product database is empty'));
              }
              return ListView(
                children: [
                  for (var product in snapshot.data!)
                    Card(
                      child: ListTile(
                        title: Text(product.name),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductScreen(
                                product: product,
                              ),
                            ),
                          );
                        },
                      ),
                    )
                ],
              );
            }
            return const Center(child: Text('Unexpected state'));
          }
      ),
    );
  }
}