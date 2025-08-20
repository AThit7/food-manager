import 'package:flutter/material.dart';
import 'package:food_manager/ui/pantry_item/view_models/pantry_viewmodel.dart';

class PantryScreen extends StatefulWidget {
  const PantryScreen ({
    super.key,
    required this.viewModel,
  });

  final PantryViewmodel viewModel;

  @override
  State<PantryScreen> createState() => _PantryScreen();
}

class _PantryScreen extends State<PantryScreen> {
  String _fmt(double v) {
    final i = v.truncateToDouble();
    return (v == i) ? i.toStringAsFixed(0) : v.toStringAsFixed(2);
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return '—';
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$dd-$mm-${d.year}';
  }

  @override
  void initState() {
    super.initState();
    widget.viewModel.loadPantryItems();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    return Scaffold(
      appBar: AppBar(title: const Text('Pantry')),
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
                  onPressed: viewModel.loadPantryItems,
                  icon: Icon(Icons.refresh),
                ),
              ],
            ));
          } else if (viewModel.items.isEmpty) {
            return const Center(child: Text('Pantry is empty'));
          } else {
            return ListView(
              children: [
                for (final item in viewModel.items)
                  Card(
                    child: ListTile(
                      title: Text(item.product.name),
                      subtitle: Text('Expires on: ${_fmtDate(item.expirationDate)}\n'
                          'Remaining quantity: ${_fmt(item.quantity)} ${item.product.referenceUnit}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () async {
                              final msg = await viewModel.removeItem(item);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).clearSnackBars();
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                              }
                            },
                            icon: const Icon(Icons.delete),
                          ),
                        ],
                      ),
                    ),
                  )
              ],
            );
          }
        },
      ),
    );
  }
}
