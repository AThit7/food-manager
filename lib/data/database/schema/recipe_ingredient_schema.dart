import 'recipe_schema.dart';
import 'tag_schema.dart';

abstract class RecipeIngredientSchema {
  static const table = 'recipe_ingredient';

  static const recipeId = 'recipe_id';
  static const tagId = 'tag_id';
  static const amount = 'amount';
  static const unit = 'unit';

  static const create = '''
    CREATE TABLE $table (
      $recipeId INTEGER NOT NULL,
      $tagId INTEGER NOT NULL,
      $amount REAL NOT NULL CHECK ($amount >= 0),
      $unit TEXT NOT NULL CHECK (length(trim($unit)) > 0),
      
      FOREIGN KEY($recipeId)
        REFERENCES ${RecipeSchema.table}(${RecipeSchema.id})
        ON DELETE CASCADE,
      FOREIGN KEY($tagId)
        REFERENCES ${TagSchema.table}(${TagSchema.id})
        ON DELETE RESTRICT,
      PRIMARY KEY ($recipeId, $tagId)
    )
  ''';
}