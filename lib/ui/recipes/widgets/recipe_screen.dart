import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:food_manager/ui/recipes/models/recipe_form_model.dart';
import 'package:food_manager/ui/recipes/view_models/recipe_viewmodel.dart';
import 'package:food_manager/ui/recipes/widgets/recipe_form_screen.dart';
import 'package:provider/provider.dart';

import '../view_models/recipe_form_viewmodel.dart';

class RecipeScreen extends StatefulWidget {
  const RecipeScreen ({
    super.key,
    required this.viewModel,
  });

  final RecipeViewmodel viewModel;

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
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
    final recipe = viewModel.recipe;

    return Scaffold(
      appBar: AppBar(
        title: Text(recipe.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final updatedRecipe = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RecipeFormScreen(
                    form: RecipeFormModel.fromRecipe(recipe),
                    viewModel: RecipeFormViewmodel(
                      recipeRepository: context.read(),
                      tagRepository: context.read(),
                    ),
                  ),
                ),
              );
              if (updatedRecipe != null) viewModel.setRecipe(updatedRecipe);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              await viewModel.deleteRecipe();

              if (!context.mounted) return;
              if(viewModel.errorMessage == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Recipe deleted")));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(viewModel.errorMessage!)));
              }
              Navigator.pop(context);
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
                  _section('Summary'),
                  const SizedBox(height: 8),
                  _labelValue("Preparation time", "${recipe.preparationTime} min"),
                  _labelValue("Times used", recipe.timesUsed.toString()),
                  _labelValue("Last used", _fmtDate(recipe.lastTimeUsed)),
                  _labelValue("Ingredients", recipe.ingredients.length.toString()),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _section('Ingredients'),
                  const SizedBox(height: 8),
                  if (recipe.ingredients.isEmpty)
                    const Text('No ingredients.')
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: recipe.ingredients.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final ing = recipe.ingredients[i];
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.label_outline),
                          title: Text(ing.tag.name),
                          trailing: Text('${_fmt(ing.amount)} ${ing.unit}'),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          if ((recipe.instructions ?? '').trim().isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _section('Instructions'),
                        const Spacer(),
                        IconButton(
                          icon: Icon(Icons.copy),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: recipe.instructions!));
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(content: Text("Instructions copied")));
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      recipe.instructions!.trim(),
                      textAlign: TextAlign.start,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
