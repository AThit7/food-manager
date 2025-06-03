import 'product_schema.dart';

abstract class PantryItemSchema {
  static const table = 'items';

  static const id = 'id';
  static const productId = 'product_id';
  static const quantity = 'quantity';
  static const expirationDate = 'expiration_date';

  static const create = '''
    CREATE TABLE $table (
      $id INTEGER PRIMARY KEY,
      $productId INTEGER NOT NULL,
      $quantity REAL NOT NULL CHECK ($quantity >= 0),
      $expirationDate INTEGER NOT NULL CHECK ($expirationDate > 0), -- in Unix time
      
      FOREIGN KEY ($productId)
        REFERENCES ${ProductSchema.table}(${ProductSchema.id})
        ON DELETE CASCADE
    )
  ''';
}