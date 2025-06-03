import 'package:food_manager/data/repositories/pantry_item_repository.dart';
import 'package:food_manager/data/repositories/recipe_repository.dart';
import 'package:food_manager/data/repositories/tag_repository.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../data/services/shared_preferences_service.dart';
import '../data/services/product_info_service.dart';
import '../data/services/database/database_service.dart';
import '../data/services/database/database_service_sqflite.dart';
import '../data/repositories/external_product_repository.dart';
import '../data/repositories/local_product_repository.dart';

Future<List<SingleChildWidget>> initProviders() async {
  final sharedPreferencesService = SharedPreferencesService();
  await sharedPreferencesService.init();
  final DatabaseService databaseService = DatabaseServiceSqflite();
  await databaseService.init();
  final productInfoService = ProductInfoService();

  return [
    Provider.value(value: sharedPreferencesService),
    Provider.value(value: databaseService),
    Provider(create: (context) => TagRepository(databaseService)),
    Provider(create: (context) => PantryItemRepository(databaseService)),
    Provider(create: (context) => RecipeRepository(databaseService)),
    Provider(create: (context) => LocalProductRepository(databaseService)),
    Provider(create: (context) =>
        ExternalProductRepository(productInfoService)),
  ];
}