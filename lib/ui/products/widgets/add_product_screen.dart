import 'package:flutter/material.dart';
import 'package:food_manager/ui/pantry_item/view_models/pantry_item_form_viewmodel.dart';
import 'package:food_manager/ui/pantry_item/widgets/pantry_item_form_screen.dart';
import 'package:provider/provider.dart';

import '../view_models/add_product_viewmodel.dart';
import '../view_models/product_form_viewmodel.dart';
import 'product_form_screen.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen ({
    super.key,
    required this.viewModel,
  });

  final AddProductViewmodel viewModel;

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  @override
  void initState() {
    widget.viewModel.loadProductData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    return Scaffold(
      appBar: AppBar(title: const Text('Product details')),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, child) {
          if (!viewModel.isLoaded) {
            viewModel.loadProductData();
            return const Center(child: CircularProgressIndicator());
          } else if (viewModel.errorMessage != null) {
            return Center(
              child: Column(
                children: [
                  Text("Unexpected error."),
                  IconButton(
                    onPressed: viewModel.loadProductData,
                    icon: Icon(Icons.refresh),
                  ),
                ],
              ),
            );
          } else if (viewModel.product != null) {
            // TODO: check if containerSize is set and add based on that, probably new form needed...
            //  or just prefill amount field? idk
            if (!viewModel.hasNavigated) {
              viewModel.hasNavigated = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          PantryItemFormScreen( // TODO new form (did i forgot to delete this?)
                            viewModel: PantryItemFormViewmodel(
                              pantryItemRepository: context.read(),
                              product: viewModel.product!
                            ),
                          )
                  ),
                );
              });
            }
            return const SizedBox();
          } else if (viewModel.form != null) {
            // TODO: is this necessary?
            if (!viewModel.hasNavigated) {
              viewModel.hasNavigated = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          ProductFormScreen(
                            form: viewModel.form,
                            viewModel: ProductFormViewmodel(
                              localProductRepository: context.read(),
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