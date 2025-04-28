import 'recipe_schema.dart';
import 'product_schema.dart';

abstract class RecipeProductSchema {
  static const table = 'recipe_products';

  static const recipeId = 'recipe_id';
  static const productId = 'product_id';
  static const quantity = 'quantity';

  static const create = '''
    CREATE TABLE $table (
      $recipeId INTEGER NOT NULL,
      $productId INTEGER NOT NULL,
      $quantity REAL NOT NULL CHECK ($quantity >= 0),

      PRIMARY KEY ($recipeId, $productId),

      FOREIGN KEY ($recipeId)
        REFERENCES ${RecipeSchema.table}(${RecipeSchema.id})
        ON DELETE CASCADE,
      FOREIGN KEY ($productId)
        REFERENCES ${ProductSchema.table}(${ProductSchema.id})
        ON DELETE CASCADE
    )
  ''';
}