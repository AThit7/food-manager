import 'product_schema.dart';

abstract class UnitSchema {
  static const table = 'units';

  static const id = 'id';
  static const name = 'name';
  static const productId = 'product_id';
  static const multiplier = 'multiplier';

  static const create = '''
    CREATE TABLE $table (
      $id INTEGER PRIMARY KEY,
      $productId INTEGER NOT NULL,
      $name TEXT NOT NULL CHECK (length(trim($name)) > 0),
      $multiplier REAL NOT NULL CHECK ($multiplier > 0),
      FOREIGN KEY($productId)
          REFERENCES ${ProductSchema.table}(${ProductSchema.id})
          ON DELETE CASCADE
    ) STRICT
  ''';
}