import 'dart:developer';

import 'package:food_manager/data/database/schema/tag_schema.dart';
import 'package:food_manager/data/database/schema/unit_schema.dart';
import 'package:food_manager/domain/models/tag.dart';

import '../../core/result/result.dart';
import '../../domain/models/pantry_item.dart';
import '../../domain/models/local_product.dart';
import '../../domain/validators/pantry_item_validator.dart';
import '../../data/services/database/database_service.dart';
import '../../data/database/schema/pantry_item_schema.dart';
import '../../data/database/schema/product_schema.dart';

class PantryItemRepository{
  final  DatabaseService _db;

  PantryItemRepository(this._db);

  int boolToSql(bool v) => v ? 1 : 0;

  bool boolFromSql(Object? v) => (v as int) == 1;

  Map<String, dynamic> pantryItemToMap(PantryItem item) {
    return {
      PantryItemSchema.id: item.id,
      PantryItemSchema.uuid: item.uuid,
      PantryItemSchema.productId: item.product.id,
      PantryItemSchema.quantity: item.quantity,
      PantryItemSchema.expirationDate: item.expirationDate.millisecondsSinceEpoch,
      PantryItemSchema.isOpen: boolToSql(item.isOpen),
      PantryItemSchema.isBought: boolToSql(item.isBought),
    };
  }

  PantryItem pantryItemFromMap(Map<String, dynamic> itemMap, LocalProduct product) {
    return PantryItem.withUuid(
      id: itemMap[PantryItemSchema.id] as int,
      uuid: itemMap[PantryItemSchema.uuid] as String,
      product: product,
      quantity: itemMap[PantryItemSchema.quantity] as double,
      expirationDate: DateTime.fromMillisecondsSinceEpoch(itemMap[PantryItemSchema.expirationDate] as int),
      isOpen: boolFromSql(itemMap[PantryItemSchema.isOpen]),
      isBought: boolFromSql(itemMap[PantryItemSchema.isBought]),
    );
  }

  Future<Result<int>> insertItem(PantryItem item) async {
    if (!PantryItemValidator.isValid(item)) {
      throw ArgumentError('Pantry item has invalid fields.');
    }
    try {
      final itemMap = pantryItemToMap(item);

      final batch = _db.batch();
      batch.insert(
        PantryItemSchema.table,
        itemMap,
      );
      final results = await batch.commit();

      if (results.isEmpty || results[0] is! int) {
        return ResultError('Insert did not return expected ID.');
      }

      return ResultSuccess(results[0] as int);
    } catch (e, s) {
      log(
        'Unexpected error when inserting pantry item.',
        name: 'PantryItemRepository',
        error: e,
        stackTrace: s,
        level: 1200,
      );
      return ResultError('Unexpected error when inserting pantry item.', e);
    }
  }

  Future<Result<int>> updateItem(PantryItem item) async {
    if (item.id == null) {
      throw ArgumentError('Product must have an ID when updating.');
    }
    if (!PantryItemValidator.isValid(item)) {
      throw ArgumentError('Pantry item has invalid fields.');
    }

    try {
      final itemMap = pantryItemToMap(item);

      final batch = _db.batch();
      batch.update(
        PantryItemSchema.table,
        itemMap,
        where: '${PantryItemSchema.id} = ?',
        whereArgs: [item.id],
      );
      final results = await batch.commit();

      if (results.isEmpty || results[0] is! int) {
        return ResultError('Insert did not return expected ID.');
      }
      return ResultSuccess(results[0] as int);
    } catch (e, s) {
      log(
        'Unexpected error when updating pantry item.',
        name: 'PantryItemRepository',
        error: e,
        stackTrace: s,
        level: 1200,
      );
      return ResultError('Unexpected error when updating pantry item.', e);
    }
  }

  Future<Result<List<PantryItem>>> listPantryItems() async {
    try {
      const String itemId = "item_id";
      const String productId = "product_id";
      const String tagId = "tag_id";
      const String tagName = "tag_name";
      const String unitName = "unit_name";

      final List<Map<String, Object?>> rows = await _db.rawQuery('''
      SELECT 
        i.${PantryItemSchema.id} AS $itemId,
        i.${PantryItemSchema.uuid},
        i.${PantryItemSchema.quantity},
        i.${PantryItemSchema.expirationDate},
        i.${PantryItemSchema.isOpen},
        i.${PantryItemSchema.isBought},
        p.${ProductSchema.id} AS $productId,
        p.${ProductSchema.name},
        p.${ProductSchema.barcode},
        p.${ProductSchema.referenceUnit},
        p.${ProductSchema.referenceValue},
        p.${ProductSchema.containerSize},
        p.${ProductSchema.calories},
        p.${ProductSchema.carbs},
        p.${ProductSchema.protein},
        p.${ProductSchema.fat},
        p.${ProductSchema.expectedShelfLife},
        p.${ProductSchema.shelfLifeAfterOpening},
        t.${TagSchema.id} AS $tagId,
        t.${TagSchema.name} AS $tagName,
        u.${UnitSchema.name} AS $unitName,
        u.${UnitSchema.multiplier}
      FROM ${PantryItemSchema.table} i
      INNER JOIN ${ProductSchema.table} p
        ON i.${PantryItemSchema.productId} = p.${ProductSchema.id} 
      INNER JOIN ${TagSchema.table} t
        ON p.${ProductSchema.tagId} = t.${TagSchema.id} 
      INNER JOIN ${UnitSchema.table} u
        ON p.${ProductSchema.id} = u.${UnitSchema.productId} 
    ''');

      final items = <int, PantryItem>{};
      for (final row in rows) {
        final id = row[itemId] as int;
        var item = items[id];

        if (item == null) {
          final product = LocalProduct(
            id: row[productId] as int,
            barcode: row[ProductSchema.barcode] as String?,
            name: row[ProductSchema.name] as String,
            tag: Tag(id: row[tagId] as int, name: row[tagName] as String),
            referenceUnit: row[ProductSchema.referenceUnit] as String,
            referenceValue: row[ProductSchema.referenceValue] as double,
            containerSize: row[ProductSchema.containerSize] as double?,
            calories: row[ProductSchema.calories] as double,
            carbs: row[ProductSchema.carbs] as double,
            protein: row[ProductSchema.protein] as double,
            fat: row[ProductSchema.fat] as double,
            shelfLifePostOpening: row[ProductSchema.shelfLifeAfterOpening] as int,
            expectedShelfLife: row[ProductSchema.expectedShelfLife] as int,
            units: {},
          );
          item = PantryItem.withUuid(
            id: id,
            uuid: row[PantryItemSchema.uuid] as String,
            product: product,
            quantity: row[PantryItemSchema.quantity] as double,
            expirationDate: DateTime.fromMillisecondsSinceEpoch(row[PantryItemSchema.expirationDate] as int),
            isOpen: boolFromSql(row[PantryItemSchema.isOpen]),
            isBought: boolFromSql(row[PantryItemSchema.isBought]),
          );
          items[id] = item;
        }
        item.product.units[row[unitName] as String] = row[UnitSchema.multiplier] as double;
      }

      return ResultSuccess(items.values.toList());
    } catch (e, s) {
      log(
        'Unexpected error when listing pantry items.',
        name: 'PantryItemRepository',
        error: e,
        stackTrace: s,
        level: 1200,
      );
      return ResultError('Unexpected error when listing pantry items.', e);
    }
  }

  // TODO fetch units too
  Future<Result<PantryItem>> getPantryItem(int id) async {
    try {
      const String itemId = "item_id";
      const String productId = "product_id";
      const String tagId = "tag_id";
      const String tagName = "tag_name";

      final List<Map<String, Object?>> rows = await _db.rawQuery('''
      SELECT 
        i.${PantryItemSchema.id} AS $itemId,
        i.${PantryItemSchema.uuid},
        i.${PantryItemSchema.quantity},
        i.${PantryItemSchema.expirationDate},
        i.${PantryItemSchema.isOpen},
        i.${PantryItemSchema.isBought},
        p.${ProductSchema.id} AS $productId,
        p.${ProductSchema.name},
        p.${ProductSchema.barcode},
        p.${ProductSchema.referenceUnit},
        p.${ProductSchema.referenceValue},
        p.${ProductSchema.containerSize},
        p.${ProductSchema.calories},
        p.${ProductSchema.carbs},
        p.${ProductSchema.protein},
        p.${ProductSchema.fat},
        t.${TagSchema.id} AS $tagId,
        t.${TagSchema.name} AS $tagName
      FROM ${PantryItemSchema.table} i
      INNER JOIN ${ProductSchema.table} p
        ON i.${PantryItemSchema.productId} = p.${ProductSchema.id} 
      INNER JOIN ${TagSchema.table} t
        ON p.${ProductSchema.tagId} = t.${TagSchema.id} 
      WHERE
        i.${PantryItemSchema.id} = ?
    ''', [id]);

      final row = rows.firstOrNull;
      if (row == null) {
        return ResultFailure('No product with id $id.');
      }

      final product = LocalProduct(
        id: row[productId] as int,
        barcode: row[ProductSchema.barcode] as String?,
        name: row[ProductSchema.name] as String,
        tag: Tag(id: row[tagId] as int, name: row[tagName] as String),
        referenceUnit: row[ProductSchema.referenceUnit] as String,
        referenceValue: row[ProductSchema.referenceValue] as double,
        containerSize: row[ProductSchema.containerSize] as double?,
        calories: row[ProductSchema.calories] as double,
        carbs: row[ProductSchema.carbs] as double,
        protein: row[ProductSchema.protein] as double,
        fat: row[ProductSchema.fat] as double,
        shelfLifePostOpening: row[ProductSchema.shelfLifeAfterOpening] as int,
        expectedShelfLife: row[ProductSchema.expectedShelfLife] as int,
        units: {},
      );

      return ResultSuccess(pantryItemFromMap(rows.firstOrNull!, product));
    } catch (e, s) {
      log(
        'Unexpected error when fetching pantry item with id $id.',
        name: 'PantryItemRepository',
        error: e,
        stackTrace: s,
        level: 1200,
      );
      return ResultError('Unexpected error when fetching pantry item.', e);
    }
  }

  Future<Result<void>> removeItem(PantryItem item) async {
    if (item.id == null) {
      throw ArgumentError("item.id can't be null");
    }

    try {
      final count = await _db.delete(PantryItemSchema.table, where: "${PantryItemSchema.id} = ?", whereArgs: [item.id!]);

      if (count == 1) return ResultSuccess(null);
      if (count == 0) return ResultFailure("No item witch matching id.");
      throw StateError("More than one item deleted.");
    } catch (e, s) {
      log(
        'Unexpected error when deleting PantryItem.',
        name: 'PantryItemRepository',
        error: e,
        stackTrace: s,
        level: 1200,
      );
      return ResultError('Unexpected error when fetching pantry item.', e);
    }
  }

  Future<Result<void>> buyItems(Iterable<PantryItem> items) async {
    if (items.isEmpty) {
      throw ArgumentError("The item list can't be empty.");
    }
    if (!items.every(PantryItemValidator.isValid)) {
      throw ArgumentError('At least one item has invalid fields.');
    }
    if (items.any((i) => i.isBought)) {
      throw ArgumentError('At least one item is already bought.');
    }
    final uuids = items.map((e) => e.uuid).toSet();
    if (items.length != uuids.length) {
      throw ArgumentError('Items must be unique (uuid wise).');
    }

    try {
      return await _db.transaction<Result<void>>((txn) async {
        final placeholders = List.filled(uuids.length, '?').join(',');
        final sql = '''
        UPDATE ${PantryItemSchema.table}
        SET ${PantryItemSchema.isBought} = 1
        WHERE ${PantryItemSchema.isBought} = 0
          AND ${PantryItemSchema.uuid} IN ($placeholders)
      ''';
        final count = await txn.rawUpdate(sql, uuids.toList(growable: false));

        if (count != uuids.length) {
          return ResultFailure('Updated $count of ${uuids.length} items.'
              'Some UUIDs may not exist or were already bought.');
        }
        return ResultSuccess(null);
      });
    } catch (e, s) {
      log(
        'Unexpected error when buying pantry items.',
        name: 'PantryItemRepository',
        error: e,
        stackTrace: s,
        level: 1200,
      );
      return ResultError('Unexpected error when buying pantry items.', e);
    }
  }
}
