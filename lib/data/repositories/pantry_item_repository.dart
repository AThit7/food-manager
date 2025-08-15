import 'dart:developer';

import 'package:food_manager/data/database/schema/tag_schema.dart';
import 'package:food_manager/domain/models/tag.dart';

import '../../core/result/repo_result.dart';
import '../../domain/models/pantry_item.dart';
import '../../domain/models/product/local_product.dart';
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

  Future<RepoResult<int>> insertItem(PantryItem item) async {
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
        return RepoError('Insert did not return expected ID.');
      }

      return RepoSuccess(results[0] as int);
    } catch (e, s) {
      log(
        'Unexpected error when inserting pantry item.',
        name: 'PantryItemRepository',
        error: e,
        stackTrace: s,
        level: 1200,
      );
      return RepoError('Unexpected error when inserting pantry item.', e);
    }
  }

  Future<RepoResult<int>> updateItem(PantryItem item) async {
    if (item.id == null) {
      throw ArgumentError('Product must have an ID when updating.');
    }
    if (!PantryItemValidator.isValid(item)) {
      log(pantryItemToMap(item).toString());
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
        return RepoError('Insert did not return expected ID.');
      }
      return RepoSuccess(results[0] as int);
    } catch (e, s) {
      log(
        'Unexpected error when updating pantry item.',
        name: 'PantryItemRepository',
        error: e,
        stackTrace: s,
        level: 1200,
      );
      return RepoError('Unexpected error when updating pantry item.', e);
    }
  }

  Future<RepoResult<List<PantryItem>>> listPantryItems() async {
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
        p.${ProductSchema.expectedShelfLife},
        p.${ProductSchema.shelfLifeAfterOpening},
        t.${TagSchema.id} AS $tagId,
        t.${TagSchema.name} AS $tagName
      FROM ${PantryItemSchema.table} i
      INNER JOIN ${ProductSchema.table} p
        ON i.${PantryItemSchema.productId} = p.${ProductSchema.id} 
      INNER JOIN ${TagSchema.table} t
        ON p.${ProductSchema.tagId} = t.${TagSchema.id} 
    ''');

      final List<PantryItem> pantryItems = rows.map((row) {
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

        return PantryItem.withUuid(
          id: row[itemId] as int,
          uuid: row[PantryItemSchema.uuid] as String,
          product: product,
          quantity: row[PantryItemSchema.quantity] as double,
          expirationDate: DateTime.fromMillisecondsSinceEpoch(row[PantryItemSchema.expirationDate] as int),
          isOpen: boolFromSql(row[PantryItemSchema.isOpen]),
          isBought: boolFromSql(row[PantryItemSchema.isBought]),
        );
      }).toList();

      return RepoSuccess(pantryItems);
    } catch (e, s) {
      log(
        'Unexpected error when listing pantry items.',
        name: 'PantryItemRepository',
        error: e,
        stackTrace: s,
        level: 1200,
      );
      return RepoError('Unexpected error when listing pantry items.', e);
    }
  }

  // TODO fetch units too
  Future<RepoResult<PantryItem>> getPantryItem(int id) async {
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
        return RepoFailure('No product with id $id.');
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

      return RepoSuccess(pantryItemFromMap(rows.firstOrNull!, product));
    } catch (e, s) {
      log(
        'Unexpected error when fetching pantry item with id $id.',
        name: 'PantryItemRepository',
        error: e,
        stackTrace: s,
        level: 1200,
      );
      return RepoError('Unexpected error when fetching pantry item.', e);
    }
  }

  Future<RepoResult<void>> removeItem(PantryItem item) async {
    if (item.id == null) {
      throw ArgumentError("item.id can't be null");
    }

    try {
      final count = await _db.delete(PantryItemSchema.table, where: "${PantryItemSchema.id} = ?", whereArgs: [item.id!]);

      if (count == 1) return RepoSuccess(null);
      if (count == 0) return RepoFailure("No item witch matching id.");
      throw StateError("More than one item deleted.");
    } catch (e, s) {
      log(
        'Unexpected error when deleting PantryItem.',
        name: 'PantryItemRepository',
        error: e,
        stackTrace: s,
        level: 1200,
      );
      return RepoError('Unexpected error when fetching pantry item.', e);
    }
  }
}
