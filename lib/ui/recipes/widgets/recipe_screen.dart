import 'package:flutter/material.dart';
import 'package:food_manager/domain/models/recipe.dart';
import 'package:food_manager/ui/recipes/models/recipe_form_model.dart';
import 'package:food_manager/ui/recipes/widgets/recipe_form_screen.dart';
import 'package:provider/provider.dart';

import '../view_models/recipe_form_viewmodel.dart';

class RecipeScreen extends StatefulWidget {
  const RecipeScreen ({
    super.key,
    required this.recipe,
  });

  final Recipe recipe;

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  late Recipe recipe;

  @override
  void initState() {
    recipe = widget.recipe;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
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
              if (updatedRecipe != null) {
                setState(() { recipe = updatedRecipe; });
              }
            },
          ),
        ],
      ),
      body: Text("TODO"), //TODO: display recipe info
    );
  }
}
