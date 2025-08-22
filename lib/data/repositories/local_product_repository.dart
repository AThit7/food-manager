import 'dart:async';
import 'dart:developer';

import 'package:food_manager/data/database/schema/tag_schema.dart';
import 'package:food_manager/data/repositories/tag_repository.dart';
import 'package:food_manager/domain/models/tag.dart';
import 'package:food_manager/domain/validators/local_product_validator.dart';

import '../../core/result/result.dart';
import '../../domain/models/local_product.dart';
import '../../data/services/database/database_service.dart';
import '../../data/database/schema/product_schema.dart';
import '../../data/database/schema/unit_schema.dart';

sealed class ProductEvent {}

class ProductAdded extends ProductEvent {
  final LocalProduct product;
  ProductAdded(this.product);
}

class ProductModified extends ProductEvent {
  final LocalProduct product;
  ProductModified(this.product);
}

class ProductDeleted extends ProductEvent {
  final int productId;
  ProductDeleted(this.productId);
}

// TODO: test commit(), is noResult: true be default? It looks like it isn't.
class LocalProductRepository{
  final  DatabaseService _db;
  final  TagRepository _tagRepository;
  final _productUpdates = StreamController<ProductEvent>.broadcast();

  Stream<ProductEvent> get productUpdates => _productUpdates.stream;

  LocalProductRepository(DatabaseService databaseService, TagRepository tagRepository)
      : _db = databaseService,
        _tagRepository = tagRepository;

  void dispose() {
    _productUpdates.close();
  }

  Map<String, dynamic> _localProductToMap(LocalProduct product, int tagId) {
    return {
      ProductSchema.id: product.id,
      ProductSchema.name: product.name,
      ProductSchema.tagId: tagId,
      ProductSchema.barcode: product.barcode,
      ProductSchema.referenceUnit: product.referenceUnit,
      ProductSchema.referenceValue: product.referenceValue,
      ProductSchema.containerSize: product.containerSize,
      ProductSchema.calories: product.calories,
      ProductSchema.carbs: product.carbs,
      ProductSchema.protein: product.protein,
      ProductSchema.fat: product.fat,
      ProductSchema.shelfLifeAfterOpening: product.shelfLifeAfterOpening,
      ProductSchema.expectedShelfLife: product.expectedShelfLife,
    };
  }

  List<Map<String, dynamic>> _createUnitMaps(LocalProduct product) {
    final result = <Map<String, dynamic>>[];
    for (final unit in product.units.entries) {
      result.add({
        UnitSchema.productId: product.id,
        UnitSchema.name: unit.key,
        UnitSchema.multiplier: unit.value,
      });
    }
    return result;
  }

  LocalProduct _localProductFromMap(Map<String, dynamic> productMap, Tag tag, [Map<String, double> units = const {}]) {
    return LocalProduct(
      id: productMap[ProductSchema.id] as int,
      name: productMap[ProductSchema.name] as String,
      tag: tag,
      barcode: productMap[ProductSchema.barcode] as String?,
      referenceUnit: productMap[ProductSchema.referenceUnit] as String,
      referenceValue: (productMap[ProductSchema.referenceValue] as num).toDouble(),
      units: Map.of(units),
      containerSize: (productMap[ProductSchema.containerSize] as num?)?.toDouble(),
      calories: (productMap[ProductSchema.calories] as num).toDouble(),
      carbs: (productMap[ProductSchema.carbs] as num).toDouble(),
      protein: (productMap[ProductSchema.protein] as num).toDouble(),
      fat: (productMap[ProductSchema.fat] as num).toDouble(),
      shelfLifePostOpening: productMap[ProductSchema.shelfLifeAfterOpening] as int,
      expectedShelfLife: productMap[ProductSchema.expectedShelfLife] as int,
    );
  }

  Future<Result<int>> insertProduct(LocalProduct product) async {
    if (!ProductValidator.isValid(product)) {
      throw ArgumentError('Product has invalid fields.');
    }

    try {
      final unitMaps = _createUnitMaps(product);

      final productId = await _db.transaction((txn) async {
        final tagId = await _tagRepository.getOrCreateTagByNameTxn(product.tag.name, txn);
        final productMap = _localProductToMap(product, tagId);

        final id = await txn.insert(ProductSchema.table, productMap);
        final batch = txn.batch();
        for (final unitMap in unitMaps) {
          unitMap[UnitSchema.productId] = id;
          batch.insert(UnitSchema.table, unitMap);
        }
        await batch.commit();
        return id;
      });

      _productUpdates.add(ProductAdded(product.copyWith(id: productId)));
      return ResultSuccess(productId);
    } catch (e, s) {
      log(
        'Unexpected error when inserting product.',
        name: 'LocalProductRepository',
        error: e,
        stackTrace: s,
        level: 1200,
      );
      return ResultError('Unexpected error when inserting product.', e);
    }
  }

  Future<Result<void>> updateProduct(LocalProduct product) async {
    if (product.id == null) {
      throw ArgumentError('Product must have an ID when updating.');
    }
    if (!ProductValidator.isValid(product)) {
      throw ArgumentError('Product has invalid fields.');
    }

    int count;
    try {
      final unitMaps = _createUnitMaps(product);

      final results = await _db.transaction((txn) async {
        final tagId = await _tagRepository.getOrCreateTagByNameTxn(product.tag.name, txn);
        final productMap = _localProductToMap(product, tagId);
        
        final batch = txn.batch();
        batch.update(
          ProductSchema.table,
          productMap,
          where: '${ProductSchema.id} = ?',
          whereArgs: [product.id],
        );
        batch.delete(
            UnitSchema.table,
            where: '${UnitSchema.productId} = ?',
            whereArgs: [product.id]
        );
        for (final unitMap in unitMaps) {
          batch.insert(UnitSchema.table, unitMap);
        }
        return await batch.commit();
      });
      count = results[0] as int;
    } catch (e, s) {
      log(
        'Unexpected error when updating product.',
        name: 'LocalProductRepository',
        error: e,
        stackTrace: s,
        level: 1200,
      );
      return ResultError('Unexpected error when updating product.', e);
    }

    if (count == 0) {
      return ResultFailure("No product found with id ${product.id}.");
    }
    if (count == 1) {
      _productUpdates.add(ProductModified(product));
      return ResultSuccess(null);
    }

    throw StateError(
      'Unexpected update count: $count for id ${product.id}. '
          'Expected 0 or 1. Data may be corrupted.',
    );
  }

  Future<Result<void>> deleteProduct(int productId) async {
    int count;
    try {
      count = await _db.delete(
        ProductSchema.table,
        where: '${ProductSchema.id} = ?',
        whereArgs: [productId],
      );
    } catch (e, s) {
      log(
        'Unexpected error when deleting product.',
        name: 'LocalProductRepository',
        error: e,
        stackTrace: s,
        level: 1200,
      );
      return ResultError('Unexpected error when deleting product.', e);
    }

    if (count == 0) return ResultFailure("No product found with id $productId.");
    if (count == 1) {
      _productUpdates.add(ProductDeleted(productId));
      return ResultSuccess(null);
    }

    throw StateError('Unexpected delete count: $count for id $productId. Expected 0 or 1. Data may be corrupted.',
    );
  }

  Future<Result<List<LocalProduct>>> listProducts() async {
    const String productTable = 'product_table';
    const String unitTable = 'unit_table';
    const String tagTable = 'tag_table';
    const String unitNameColumn = 'unit_name_column';
    const String unitMultiplierColumn = 'unit_multiplier_column';
    const String tagIdColumn = 'tag_id_column';
    const String tagNameColumn = 'tag_name_column';

    try {
      final rows = await _db.rawQuery('''
        SELECT 
          $productTable.*,
          $unitTable.${UnitSchema.name} AS $unitNameColumn,
          $unitTable.${UnitSchema.multiplier} AS $unitMultiplierColumn,
          $tagTable.${TagSchema.id} AS $tagIdColumn,
          $tagTable.${TagSchema.name} AS $tagNameColumn
        FROM ${ProductSchema.table} $productTable
        LEFT JOIN ${UnitSchema.table} $unitTable
          ON $productTable.${ProductSchema.id} = $unitTable.${UnitSchema.productId}
        LEFT JOIN ${TagSchema.table} $tagTable
          ON $productTable.${ProductSchema.tagId} = $tagTable.${TagSchema.id}
      ''');

      final productsMap = <int, LocalProduct>{};

      for (final row in rows) {
        final productId = row[ProductSchema.id] as int;

        final tag = Tag(id: row[tagIdColumn] as int, name: row[tagNameColumn] as String);
        productsMap.putIfAbsent(productId, () => _localProductFromMap(row, tag));

        final unitName = row[unitNameColumn] as String?;
        final unitMultiplier = row[unitMultiplierColumn] as num?;
        if (unitName != null && unitMultiplier != null) {
          productsMap[productId]!.units[unitName] = unitMultiplier.toDouble();
        }
      }

      return ResultSuccess(productsMap.values.toList());
    } catch (e, s) {
      log(
        'Unexpected error when fetching all products.',
        name: 'LocalProductRepository',
        error: e,
        stackTrace: s,
        level: 1200,
      );
      return ResultError('Unexpected error when fetching all products: $e');
    }
  }

  // TODO units and tag
  Future<Result<LocalProduct?>> getProduct(int id) async {
    try {
      final List<Map<String, Object?>> productMaps = await _db.query(
        ProductSchema.table,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (productMaps.isEmpty) {
        return ResultFailure('No product with id $id.');
      }
      return ResultSuccess(_localProductFromMap(productMaps.first, Tag(name: "TODO")));
    } catch (e, s) {
      log(
        'Unexpected error when fetching product with id $id.',
        name: 'LocalProductRepository',
        error: e,
        stackTrace: s,
        level: 1200,
      );
      return ResultError(
          'Unexpected error when fetching product with id $id: $e');
    }
  }

  Future<Result<Map<String, double>>> getProductUnits(int id) async {
    try {
      final List<Map<String, Object?>> rows = await _db.query(
        UnitSchema.table,
        where: '${UnitSchema.productId} = ?',
        whereArgs: [id],
      );

      final result = <String, double>{};
      for (final row in rows) {
        final name = row[UnitSchema.name] as String;
        final value = (row[UnitSchema.multiplier] as num).toDouble();
        result[name] = value;
      }

      return ResultSuccess(result);
    } catch (e, s) {
      log(
        'Unexpected error when fetching product units.',
        name: 'LocalProductRepository',
        error: e,
        stackTrace: s,
        level: 1200,
      );
      return ResultError('Unexpected error when fetching product units: $e');
    }
  }

  // TODO units and tag
  Future<Result<LocalProduct?>> getProductByBarcode(String barcode) async {
    try {
      final product = await _db.transaction((txn) async {
        final List<Map<String, Object?>> productMaps = await txn.query(
          ProductSchema.table,
          where: '${ProductSchema.barcode} = ?',
          whereArgs: [barcode],
        );
        if (productMaps.isEmpty) return null;
        final batch = txn.batch();
        batch.query(
          TagSchema.table,
          where: '${TagSchema.id} = ?',
          whereArgs: [productMaps.first[ProductSchema.tagId]],
        );
        batch.query(
          UnitSchema.table,
          where: '${UnitSchema.productId} = ?',
          whereArgs: [productMaps.first[ProductSchema.id]],
        );
        final results = await batch.commit();
        final tagMap = (results.first as List<Map<String, Object?>>).first;
        final tag = Tag(id: tagMap[TagSchema.id] as int, name: tagMap[TagSchema.name] as String);
        final unitsMap = Map.fromEntries(
            (results[1] as List<Map<String, Object?>>).map(
                    (row) => MapEntry(
                      row[UnitSchema.name] as String,
                      (row[UnitSchema.multiplier] as num).toDouble(),
                    )
            )
        );
        return _localProductFromMap(productMaps.first, tag, unitsMap);
      });

      if (product == null) {
        return ResultFailure('No product with barcode $barcode.');
      }
      return ResultSuccess(product);
    } catch (e, s) {
      log(
        'Unexpected error when fetching product by barcode ($barcode).',
        name: 'LocalProductRepository',
        error: e,
        stackTrace: s,
        level: 1200,
      );
      return ResultError('Unexpected error when fetching product by barcode: $e');
    }
  }
}