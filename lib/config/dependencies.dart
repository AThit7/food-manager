import 'package:food_manager/data/repositories/meal_plan_repository.dart';
import 'package:food_manager/data/repositories/pantry_item_repository.dart';
import 'package:food_manager/data/repositories/recipe_repository.dart';
import 'package:food_manager/data/repositories/tag_repository.dart';
import 'package:food_manager/data/services/database/database_service.dart';
import 'package:food_manager/application/config/meal_planner_config.dart';
import 'package:food_manager/application/meal_planner_new2.dart';
import 'package:food_manager/application/shopping_list_generator.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../data/services/shared_preferences_service.dart';
import '../data/services/database/database_service_sqflite.dart';
import '../data/repositories/external_product_repository.dart';
import '../data/repositories/local_product_repository.dart';

Future<List<SingleChildWidget>> initProviders() async {
  final mealPlannerConfig = MealPlannerConfig();

  final sharedPreferencesService = SharedPreferencesService();
  await sharedPreferencesService.init();
  final DatabaseService databaseService = DatabaseServiceSqflite();
  await databaseService.init();
  final tagRepository = TagRepository(databaseService);
  final recipeRepository = RecipeRepository(databaseService, tagRepository);
  final pantryItemRepository = PantryItemRepository(databaseService);

  return [
    Provider.value(value: sharedPreferencesService),
    Provider.value(value: databaseService),
    Provider.value(value: tagRepository),
    Provider.value(value: recipeRepository),
    Provider.value(value: pantryItemRepository),
    Provider(create: (context) => LocalProductRepository(databaseService, tagRepository)),
    Provider(create: (context) => ExternalProductRepository()),
    Provider(create: (context) => MealPlanRepository(
      databaseService: databaseService,
      pantryItemRepository: pantryItemRepository,
      recipeRepository: recipeRepository,
    )),
    Provider(create: (context) => MealPlanner(config: mealPlannerConfig)),
    Provider(create: (context) => ShoppingListGenerator()),
  ];
}