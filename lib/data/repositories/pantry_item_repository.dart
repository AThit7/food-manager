import 'dart:developer';

import '../../core/result/repo_result.dart';
import '../../domain/models/product/pantry_item.dart';
import '../../domain/models/product/local_product.dart';
import '../../domain/validators/pantry_item_validator.dart';
import '../../data/services/database/database_service.dart';
import '../../data/database/schema/pantry_item_schema.dart';
import '../../data/database/schema/product_schema.dart';

class PantryItemRepository{
  final  DatabaseService _db;

  PantryItemRepository(this._db);

  Map<String, dynamic> _pantryItemToMap(PantryItem item) {
    return {
      PantryItemSchema.id: item.id,
      PantryItemSchema.productId: item.product.id,
      PantryItemSchema.quantity: item.quantity,
      PantryItemSchema.expirationDate:
        item.expirationDate?.millisecondsSinceEpoch,
    };
  }

  PantryItem _pantryItemFromMap(Map<String, dynamic> itemMap,
      LocalProduct product) {
    return PantryItem(
      id: itemMap[PantryItemSchema.id] as int,
      product: product,
      quantity: itemMap[PantryItemSchema.quantity] as double,
      expirationDate: DateTime.fromMillisecondsSinceEpoch(
          itemMap[PantryItemSchema.expirationDate] as int),
    );
  }

  Future<RepoResult<int>> insertItem(PantryItem item) async {
    if (PantryItemValidator.isValid(item)) {
      throw ArgumentError('Pantry item has invalid fields.');
    }
    try {
      final itemMap = _pantryItemToMap(item);

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
    if (PantryItemValidator.isValid(item)) {
      throw ArgumentError('Pantry item has invalid fields.');
    }

    try {
      final itemMap = _pantryItemToMap(item);

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
      final List<Map<String, Object?>> rows = await _db.rawQuery('''
      SELECT 
        i.${PantryItemSchema.id} AS $itemId,
        i.${PantryItemSchema.quantity},
        i.${PantryItemSchema.expirationDate},
        p.${ProductSchema.id} AS $productId,
        p.${ProductSchema.name},
        p.${ProductSchema.barcode},
        p.${ProductSchema.referenceUnit},
        p.${ProductSchema.referenceValue},
        p.${ProductSchema.containerSize},
        p.${ProductSchema.calories},
        p.${ProductSchema.carbs},
        p.${ProductSchema.protein},
        p.${ProductSchema.fat}
      FROM ${PantryItemSchema.table} i
      INNER JOIN ${ProductSchema.table} p
        ON i.${PantryItemSchema.productId} = p.${ProductSchema.id} 
    ''');

      final List<PantryItem> pantryItems = rows.map((row) {
        final product = LocalProduct(
          id: row[itemId] as int,
          barcode: row[ProductSchema.barcode] as String?,
          name: row[ProductSchema.name] as String,
          tag: row[ProductSchema.tag] as String,
          referenceUnit: row[ProductSchema.referenceUnit] as String,
          referenceValue: row[ProductSchema.referenceValue] as double,
          containerSize: row[ProductSchema.containerSize] as double?,
          calories: row[ProductSchema.calories] as double,
          carbs: row[ProductSchema.carbs] as double,
          protein: row[ProductSchema.protein] as double,
          fat: row[ProductSchema.fat] as double,
          shelfLifeAfterOpening: row[ProductSchema
              .shelfLifeAfterOpening] as int?,
          units: {},
        );

        return PantryItem(
          id: row[itemId] as int,
          product: product,
          quantity: row[PantryItemSchema.quantity] as double,
          expirationDate: DateTime.fromMillisecondsSinceEpoch(
              row[PantryItemSchema.expirationDate] as int),
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

  Future<RepoResult<PantryItem>> getPantryItem(int id) async {
    try {
      const String itemId = "item_id";
      const String productId = "product_id";
      final List<Map<String, Object?>> rows = await _db.rawQuery('''
      SELECT 
        i.${PantryItemSchema.id} AS $itemId,
        i.${PantryItemSchema.quantity},
        i.${PantryItemSchema.expirationDate},
        p.${ProductSchema.id} AS $productId,
        p.${ProductSchema.name},
        p.${ProductSchema.barcode},
        p.${ProductSchema.referenceUnit},
        p.${ProductSchema.referenceValue},
        p.${ProductSchema.containerSize},
        p.${ProductSchema.calories},
        p.${ProductSchema.carbs},
        p.${ProductSchema.protein},
        p.${ProductSchema.fat}
      FROM ${PantryItemSchema.table} i
      INNER JOIN ${ProductSchema.table} p
        ON i.${PantryItemSchema.productId} = p.${ProductSchema.id} 
      WHERE
        i.${PantryItemSchema.id} = ?
    ''', [id]);

      final row = rows.firstOrNull;
      if (row == null) {
        return RepoFailure('No product with id $id.');
      }

      final product = LocalProduct(
        id: row[itemId] as int,
        barcode: row[ProductSchema.barcode] as String?,
        name: row[ProductSchema.name] as String,
        tag: row[ProductSchema.tag] as String,
        referenceUnit: row[ProductSchema.referenceUnit] as String,
        referenceValue: row[ProductSchema.referenceValue] as double,
        containerSize: row[ProductSchema.containerSize] as double?,
        calories: row[ProductSchema.calories] as double,
        carbs: row[ProductSchema.carbs] as double,
        protein: row[ProductSchema.protein] as double,
        fat: row[ProductSchema.fat] as double,
        shelfLifeAfterOpening: row[ProductSchema.shelfLifeAfterOpening] as int?,
        units: {},
      );

      return RepoSuccess(_pantryItemFromMap(rows.firstOrNull!, product));
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
}
