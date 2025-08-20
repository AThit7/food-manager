import 'package:flutter/material.dart';
import 'package:food_manager/ui/meal_plan/view_models/planner_viewmodel.dart';
import 'package:food_manager/ui/meal_plan/widgets/planner_screen.dart';
import 'package:food_manager/ui/pantry_item/view_models/pantry_viewmodel.dart';
import 'package:food_manager/ui/pantry_item/widgets/pantry_screen.dart';
import 'package:food_manager/ui/products/view_models/all_products_viewmodel.dart';
import 'package:food_manager/ui/products/view_models/product_form_viewmodel.dart';
import 'package:food_manager/ui/products/widgets/all_products_screen.dart';
import 'package:food_manager/ui/products/widgets/product_form_screen.dart';
import 'package:food_manager/ui/recipes/view_models/all_recipes_viewmodel.dart';
import 'package:food_manager/ui/recipes/view_models/recipe_form_viewmodel.dart';
import 'package:food_manager/ui/recipes/widgets/all_recipes_screen.dart';
import 'package:food_manager/ui/recipes/widgets/recipe_form_screen.dart';
import 'package:food_manager/ui/scanner/widgets/scanner_screen.dart';
import 'package:food_manager/ui/settings/view_models/settings_viewmodel.dart';
import 'package:food_manager/ui/settings/widgets/settings_screen.dart';
import 'package:food_manager/ui/shopping_list/view_models/shopping_list_viewmodel.dart';
import 'package:food_manager/ui/shopping_list/widgets/shopping_list_screen.dart';
import 'package:provider/provider.dart';

class _ActionsGrid extends StatelessWidget {
  const _ActionsGrid({required this.children});

  final List<_ActionCard> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 1.15,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          children: children,
        );
      },
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: theme.colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ActionsGrid(children: [
                _ActionCard(
                  label: 'Shopping list',
                  icon: Icons.shopping_cart_outlined,
                  onTap: () {
                    final viewModel = ShoppingListViewmodel(
                      shoppingListGenerator: context.read(),
                      pantryItemRepository: context.read(),
                      mealPlanRepository: context.read(),
                    );
                    Navigator.push(context, MaterialPageRoute(builder: (_) =>
                        ShoppingListScreen(viewModel: viewModel)));
                  },
                ),
                _ActionCard(
                  label: 'Meal plan',
                  icon: Icons.calendar_month,
                  onTap: () {
                    final viewModel = PlannerViewmodel(
                      mealPlanner: context.read(),
                      sharedPreferencesService: context.read(),
                      localProductRepository: context.read(),
                      pantryItemRepository: context.read(),
                      recipeRepository: context.read(),
                      mealPlanRepository: context.read(),
                    );
                    Navigator.push(context, MaterialPageRoute(builder: (_) => PlannerScreen(viewModel: viewModel)));
                  },
                ),
                _ActionCard(
                  label: 'Scanner',
                  icon: Icons.qr_code_scanner,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ScannerScreen()));
                  },
                ),
                _ActionCard(
                  label: 'Pantry',
                  icon: Icons.kitchen_outlined,
                  onTap: () {
                    final viewModel = PantryViewmodel(pantryItemRepository: context.read());
                    Navigator.push(context, MaterialPageRoute(builder: (_) => PantryScreen(viewModel: viewModel)));
                  },
                ),
                _ActionCard(
                  label: 'Add product',
                  icon: Icons.add_box_outlined,
                  onTap: () {
                    final viewModel = ProductFormViewmodel(localProductRepository: context.read());
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ProductFormScreen(viewModel: viewModel)));
                  },
                ),
                _ActionCard(
                  label: 'Add recipe',
                  icon: Icons.restaurant_menu,
                  onTap: () {
                    final viewModel = RecipeFormViewmodel(
                      recipeRepository: context.read(),
                      tagRepository: context.read(),
                    );
                    Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeFormScreen(viewModel: viewModel)));
                  },
                ),
                _ActionCard(
                  label: 'All products',
                  icon: Icons.inventory_2_outlined,
                  onTap: () {
                    final viewModel = AllProductsViewmodel(localProductRepository: context.read());
                    Navigator.push(context, MaterialPageRoute(builder: (_) => AllProductsScreen(viewModel: viewModel)));
                  },
                ),
                _ActionCard(
                  label: 'All recipes',
                  icon: Icons.menu_book_outlined,
                  onTap: () {
                    final viewModel = AllRecipesViewmodel(recipeRepository: context.read());
                    Navigator.push(context, MaterialPageRoute(builder: (_) => AllRecipesScreen(viewModel: viewModel)));
                  },
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}