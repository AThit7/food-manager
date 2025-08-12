import 'package:food_manager/data/database/schema/tag_schema.dart';

abstract class ProductSchema {
  static const table = 'products';

  static const id = 'id';
  static const tagId = 'tag_id';
  static const name = 'name';
  static const barcode = 'barcode';
  static const referenceUnit = 'reference_unit';
  static const referenceValue = 'reference_value';
  static const containerSize = 'container_size';
  static const calories = 'calories';
  static const carbs = 'carbs';
  static const protein = 'protein';
  static const fat = 'fat';
  static const shelfLifeAfterOpening = 'shelf_life_after_opening';
  static const expectedShelfLife = 'expected_shelf_life';

  static const create = '''
    CREATE TABLE $table (
      $id INTEGER PRIMARY KEY,
      $tagId INTEGER NOT NULL,
      $barcode TEXT CHECK (length(trim($barcode)) > 0),
      $name TEXT NOT NULL CHECK (length(trim($name)) > 0),
      $referenceUnit TEXT NOT NULL CHECK (length(trim($referenceUnit)) > 0),
      $referenceValue REAL NOT NULL CHECK ($referenceValue > 0),
      $containerSize REAL CHECK ($containerSize > 0),
      $calories REAL NOT NULL CHECK ($calories >= 0),
      $carbs REAL NOT NULL CHECK ($carbs >= 0),
      $protein REAL NOT NULL CHECK ($protein >= 0),
      $fat REAL NOT NULL CHECK ($fat >= 0),
      $shelfLifeAfterOpening INTEGER NOT NULL CHECK ($shelfLifeAfterOpening >= 0),
      $expectedShelfLife INTEGER NOT NULL CHECK ($expectedShelfLife >= 0),

      FOREIGN KEY($tagId)
        REFERENCES ${TagSchema.table}(${TagSchema.id})
        ON DELETE RESTRICT
    )
  ''';
}