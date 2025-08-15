import 'product_schema.dart';

abstract class PantryItemSchema {
  static const table = 'items';

  static const id = 'id';
  static const uuid = 'uuid';
  static const productId = 'product_id';
  static const quantity = 'quantity';
  static const expirationDate = 'expiration_date';
  static const isOpen = 'is_open';
  static const isBought = 'is_bought';

  static const create = '''
    CREATE TABLE $table (
      $id INTEGER PRIMARY KEY,
      $uuid TEXT NOT NULL UNIQUE,
      $productId INTEGER NOT NULL,
      $quantity REAL NOT NULL CHECK ($quantity >= 0),
      $expirationDate INTEGER NOT NULL, -- in Unix time
      $isOpen INTEGER NOT NULL CHECK ($isOpen IN (0,1)),
      $isBought INTEGER NOT NULL CHECK ($isBought IN (0,1)),

      FOREIGN KEY ($productId)
        REFERENCES ${ProductSchema.table}(${ProductSchema.id})
        ON DELETE CASCADE
    )
  ''';

  static const createIndexes = [
    'CREATE INDEX idx_${table}_$productId ON $table($productId)',
  ];
}