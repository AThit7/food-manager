import 'package:flutter/material.dart';
import 'package:food_manager/ui/meal_plan/view_models/planner_viewmodel.dart';
import 'package:food_manager/ui/meal_plan/widgets/planner_screen.dart';
import 'package:food_manager/ui/pantry_item/view_models/pantry_viewmodel.dart';
import 'package:food_manager/ui/pantry_item/widgets/pantry_screen.dart';
import 'package:food_manager/ui/products/view_models/product_form_viewmodel.dart';
import 'package:food_manager/ui/products/widgets/product_form_screen.dart';
import 'package:food_manager/ui/recipes/view_models/all_recipes_viewmodel.dart';
import 'package:food_manager/ui/recipes/view_models/recipe_form_viewmodel.dart';
import 'package:food_manager/ui/recipes/widgets/all_recipes_screen.dart';
import 'package:food_manager/ui/recipes/widgets/recipe_form_screen.dart';
import 'package:food_manager/ui/settings/view_models/settings_viewmodel.dart';
import 'package:food_manager/ui/settings/widgets/settings_screen.dart';
import 'package:food_manager/ui/shopping_list/view_models/shopping_list_viewmodel.dart';
import 'package:food_manager/ui/shopping_list/widgets/shopping_list_screen.dart';
import 'package:provider/provider.dart';

import '../scanner/widgets/scanner_screen.dart';
import '../products/widgets/all_products_screen.dart';
import '../products/view_models/all_products_viewmodel.dart';

class HomeScreenSimple extends StatelessWidget {
  const HomeScreenSimple({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Screen'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    final viewModel = SettingsViewmodel(databaseService: context.read());
                    return SettingsScreen(viewModel: viewModel);
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return ScannerScreen();
                    },
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
                      final viewModel = ProductFormViewmodel(localProductRepository: context.read());
                      return ProductFormScreen(viewModel: viewModel);
                    },
                  ),
                );
              },
              child: const Text('Add product'),
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
                    },
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
                    },
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
                    },
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
                        sharedPreferencesService: context.read(),
                        localProductRepository: context.read(),
                        pantryItemRepository: context.read(),
                        recipeRepository: context.read(),
                        mealPlanRepository: context.read(),
                      );
                      return PlannerScreen(viewModel: viewModel);
                    },
                  ),
                );
              },
              child: const Text('Meal plan'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      final viewModel = ShoppingListViewmodel(
                        shoppingListGenerator: context.read(),
                        pantryItemRepository: context.read(),
                        mealPlanRepository: context.read(),
                      );
                      return ShoppingListScreen(viewModel: viewModel);
                    },
                  ),
                );
              },
              child: const Text('Shopping list'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      final viewModel = PantryViewmodel(
                        pantryItemRepository: context.read(),
                      );
                      return PantryScreen(viewModel: viewModel);
                    },
                  ),
                );
              },
              child: const Text('Pantry'),
            ),
          ],
        ),
      ),
    );
  }
}