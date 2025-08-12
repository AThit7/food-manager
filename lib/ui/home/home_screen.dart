import 'package:flutter/material.dart';
import 'package:food_manager/ui/planner/view_models/planner_viewmodel.dart';
import 'package:food_manager/ui/planner/widgets/planner_screen.dart';
import 'package:food_manager/ui/recipes/view_models/all_recipes_viewmodel.dart';
import 'package:food_manager/ui/recipes/view_models/recipe_form_viewmodel.dart';
import 'package:food_manager/ui/recipes/widgets/all_recipes_screen.dart';
import 'package:food_manager/ui/recipes/widgets/recipe_form_screen.dart';
import 'package:provider/provider.dart';

import '../scanner/widgets/scanner_screen.dart';
import '../scanner/view_models/scanner_viewmodel.dart';
import '../products/widgets/all_products_screen.dart';
import '../products/view_models/all_products_viewmodel.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home Screen')),
      body: Center(
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) {
                        final viewModel = ScannerViewModel(localProductRepository: context.read());
                        return ScannerScreen(viewModel: viewModel);
                      }
                  ),
                );
              },
              child: const Text('Scanner'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) {
                        final viewModel = RecipeFormViewmodel(
                          recipeRepository: context.read(),
                          tagRepository: context.read(),
                        );
                        return RecipeFormScreen(viewModel: viewModel);
                      }
                  ),
                );
              },
              child: const Text('Add recipe'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) {
                        final viewModel = AllProductsViewmodel(localProductRepository: context.read());
                        return AllProductsScreen(viewModel: viewModel);
                      }
                  ),
                );
              },
              child: const Text('All products'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) {
                        final viewModel = AllRecipesViewmodel(recipeRepository: context.read());
                        return AllRecipesScreen(viewModel: viewModel);
                      }
                  ),
                );
              },
              child: const Text('All recipes'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) {
                        final viewModel = PlannerViewmodel(
                          mealPlanner: context.read(),
                          localProductRepository: context.read(),
                          pantryItemRepository: context.read(),
                          recipeRepository: context.read(),
                        );
                        return PlannerScreen(viewModel: viewModel);
                      }
                  ),
                );
              },
              child: const Text('Meal plan'),
            ),
          ],
        ),
      ),
    );
  }
}
