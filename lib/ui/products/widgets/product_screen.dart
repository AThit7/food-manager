import 'package:flutter/material.dart';
import 'package:food_manager/ui/products/models/product_form_model.dart';
import 'package:food_manager/ui/products/view_models/product_viewmodel.dart';
import 'package:food_manager/ui/products/widgets/product_form_screen.dart';
import 'package:provider/provider.dart';

import '../view_models/product_form_viewmodel.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen ({
    super.key,
    required this.viewModel,
  });

  final ProductViewmodel viewModel;

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  String _fmt(double v) {
    final i = v.truncateToDouble();
    return (v == i) ? i.toStringAsFixed(0) : v.toStringAsFixed(2);
  }

  String _days(int d) => "$d day${d == 1 ? "" : "s"}";

  Widget _labelValue(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(child: Text(k, style: const TextStyle(fontWeight: FontWeight.w500))),
        const SizedBox(width: 12),
        Text(v, textAlign: TextAlign.right),
      ],
    ),
  );

  Widget _section(String title) => Text(
    title,
    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
  );

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    final product = viewModel.product;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          final deleted = result is bool && result;
          Navigator.pop(context, deleted ? null : viewModel.product);
        }
      },
      child: Scaffold(
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
                      ),
                    ),
                  ),
                );
                if (updatedProduct != null) {
                  setState(() {
                    viewModel.setProduct(updatedProduct);
                  });
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                await viewModel.deleteProduct();

                if (!context.mounted) return;
                if(viewModel.errorMessage == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Product deleted")));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(viewModel.errorMessage!)));
                }
                Navigator.pop(context, true);
              },
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          label: Text(product.tag.name),
                          avatar: const Icon(Icons.label_outline, size: 18),
                        ),
                        Chip(
                          label: Text(product.referenceUnit),
                          avatar: const Icon(Icons.scale, size: 18),
                        ),
                        if (product.barcode != null && product.barcode!.isNotEmpty)
                          Chip(
                            label: Text(product.barcode!),
                            avatar: const Icon(Icons.qr_code, size: 18),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _labelValue("Container size",
                        product.containerSize == null ? "—" : "${_fmt(product.containerSize!)} ${product.referenceUnit}"),
                    _labelValue("Expected shelf life", _days(product.expectedShelfLife)),
                    _labelValue("Shelf life after opening", _days(product.shelfLifeAfterOpening)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // --- Units / conversions ---
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _section("Units & conversions"),
                    const SizedBox(height: 8),
                    if (product.units.isEmpty)
                      const Text("No alternative units.")
                    else
                      ...product.units.entries.map((e) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(e.key),
                        trailing: Text("1 ${e.key} = ${_fmt(e.value)} ${product.referenceUnit}"),
                      )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _section("Nutrition per ${_fmt(product.referenceValue)} ${product.referenceUnit}"),
                    const SizedBox(height: 8),
                    _labelValue("Calories", "${_fmt(product.calories)} kcal"),
                    _labelValue("Protein", "${_fmt(product.protein)} g"),
                    _labelValue("Carbs", "${_fmt(product.carbs)} g"),
                    _labelValue("Fat", "${_fmt(product.fat)} g"),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}