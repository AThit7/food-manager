import 'package:flutter/material.dart';
import 'package:food_manager/ui/recipes/widgets/recipe_screen.dart';

import '../view_models/all_recipes_viewmodel.dart';

class AllRecipesScreen extends StatefulWidget {
  const AllRecipesScreen ({
    super.key,
    required this.viewModel,
  });

  final AllRecipesViewmodel viewModel;

  @override
  State<AllRecipesScreen> createState() => _AllRecipesScreenState();
}

class _AllRecipesScreenState extends State<AllRecipesScreen> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.loadRecipes();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    return Scaffold(
      appBar: AppBar(title: const Text('Recipe details')),
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
                    onPressed: viewModel.loadRecipes,
                    icon: Icon(Icons.refresh),
                  ),
                ],
              ));
            } else if (viewModel.recipes.isEmpty) {
              return const Center(
                  child: Text('Local product database is empty'));
            } else {
              return ListView(
                children: [
                  for (final recipe in viewModel.recipes)
                    Card(
                      child: ListTile(
                        title: Text(recipe.name),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RecipeScreen(recipe: recipe),
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
