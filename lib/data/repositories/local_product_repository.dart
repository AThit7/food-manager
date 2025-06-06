import 'dart:async';
import 'dart:developer';

import 'package:food_manager/domain/validators/local_product_validator.dart';

import '../../core/result/repo_result.dart';
import '../../domain/models/product/local_product.dart';
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
  final _productUpdates = StreamController<ProductEvent>.broadcast();

  Stream<ProductEvent> get productUpdates => _productUpdates.stream;

  LocalProductRepository(this._db);

  void dispose() {
    _productUpdates.close();
  }

  Map<String, dynamic> _localProductToMap(LocalProduct product) {
    return {
      ProductSchema.id: product.id,
      ProductSchema.name: product.name,
      ProductSchema.tag: product.tag,
      ProductSchema.barcode: product.barcode,
      ProductSchema.referenceUnit: product.referenceUnit,
      ProductSchema.referenceValue: product.referenceValue,
      ProductSchema.containerSize: product.containerSize,
      ProductSchema.calories: product.calories,
      ProductSchema.carbs: product.carbs,
      ProductSchema.protein: product.protein,
      ProductSchema.fat: product.fat,
      ProductSchema.shelfLifeAfterOpening: product.shelfLifeAfterOpening,
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

  LocalProduct _localProductFromMap(Map<String, dynamic> productMap) {
    return LocalProduct(
      id: productMap[ProductSchema.id] as int,
      name: productMap[ProductSchema.name] as String,
      tag: productMap[ProductSchema.tag] as String,
      barcode: productMap[ProductSchema.barcode] as String?,
      referenceUnit: productMap[ProductSchema.referenceUnit] as String,
      referenceValue: (productMap[ProductSchema.referenceValue] as num).toDouble(),
      units: {},
      containerSize: (productMap[ProductSchema.containerSize] as num?)?.toDouble(),
      calories: (productMap[ProductSchema.calories] as num).toDouble(),
      carbs: (productMap[ProductSchema.carbs] as num).toDouble(),
      protein: (productMap[ProductSchema.protein] as num).toDouble(),
      fat: (productMap[ProductSchema.fat] as num).toDouble(),
      shelfLifeAfterOpening: productMap[ProductSchema.shelfLifeAfterOpening] as int?,
    );
  }

  Future<RepoResult<int>> insertProduct(LocalProduct product) async {
    if (!ProductValidator.isValid(product)) {
      throw ArgumentError('Product has invalid fields.');
    }

    try {
      final productMap = _localProductToMap(product);
      final unitMaps = _createUnitMaps(product);

      final batch = _db.batch();
      batch.insert(ProductSchema.table, productMap);
      for (final unitMap in unitMaps) {
        batch.insert(UnitSchema.table, unitMap);
      }
      final results = await batch.commit();

      if (results.isEmpty || results[0] is! int) {
        return RepoError('Insert did not return expected ID.');
      }

      final productId = results[0] as int;
      _productUpdates.add(ProductAdded(product.copyWith(id: productId)));
      return RepoSuccess(productId);
    } catch (e, s) {
      log(
        'Unexpected error when inserting product.',
        name: 'LocalProductRepository',
        error: e,
        stackTrace: s,
        level: 1200,
      );
      return RepoError('Unexpected error when inserting product.', e);
    }
  }

  Future<RepoResult<void>> updateProduct(LocalProduct product) async {
    if (product.id == null) {
      throw ArgumentError('Product must have an ID when updating.');
    }
    if (!ProductValidator.isValid(product)) {
      throw ArgumentError('Product has invalid fields.');
    }

    int count;
    try {
      final productMap = _localProductToMap(product);
      final unitMaps = _createUnitMaps(product);

      final batch = _db.batch();
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
      final results = await batch.commit();
      count = results[0] as int;
    } catch (e, s) {
      log(
        'Unexpected error when updating product.',
        name: 'LocalProductRepository',
        error: e,
        stackTrace: s,
        level: 1200,
      );
      return RepoError('Unexpected error when updating product.', e);
    }

    if (count == 0) {
      return RepoFailure("No product found with id ${product.id}.");
    }
    if (count == 1) {
      _productUpdates.add(ProductModified(product));
      return RepoSuccess(null);
    }

    throw StateError(
      'Unexpected update count: $count for id ${product.id}. '
          'Expected 0 or 1. Data may be corrupted.',
    );
  }

  Future<RepoResult<void>> deleteProduct(int productId) async {
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
      return RepoError('Unexpected error when deleting product.', e);
    }

    if (count == 0) return RepoFailure("No product found with id $productId.");
    if (count == 1) {
      _productUpdates.add(ProductDeleted(productId));
      return RepoSuccess(null);
    }

    throw StateError('Unexpected delete count: $count for id $productId. Expected 0 or 1. Data may be corrupted.',
    );
  }

  Future<RepoResult<List<LocalProduct>>> listProducts() async {
    const String unitNameColumn = 'unit_name';
    const String unitMultiplierColumn = 'unit_multiplier';

    try {
      final rows = await _db.rawQuery('''
        SELECT 
          p.*,
          u.${UnitSchema.name} AS $unitNameColumn,
          u.${UnitSchema.multiplier} AS $unitMultiplierColumn
        FROM ${ProductSchema.table} p
        LEFT JOIN ${UnitSchema.table} u
          ON p.${ProductSchema.id} = u.${UnitSchema.productId}
      ''');

      final productsMap = <int, LocalProduct>{};

      for (final row in rows) {
        final productId = row[ProductSchema.id] as int;

        productsMap.putIfAbsent(productId, () => _localProductFromMap(row));

        final unitName = row[unitNameColumn] as String?;
        final unitMultiplier = row[unitMultiplierColumn] as num?;
        if (unitName != null && unitMultiplier != null) {
          productsMap[productId]!.units[unitName] = unitMultiplier.toDouble();
        }
      }

      return RepoSuccess(productsMap.values.toList());
    } catch (e, s) {
      log(
        'Unexpected error when fetching all products.',
        name: 'LocalProductRepository',
        error: e,
        stackTrace: s,
        level: 1200,
      );
      return RepoError('Unexpected error when fetching all products: $e');
    }
  }

  // TODO units
  Future<RepoResult<LocalProduct?>> getProduct(int id) async {
    try {
      final List<Map<String, Object?>> productMaps = await _db.query(
        ProductSchema.table,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (productMaps.isEmpty) {
        return RepoFailure('No product with id $id.');
      }
      return RepoSuccess(_localProductFromMap(productMaps.first));
    } catch (e, s) {
      log(
        'Unexpected error when fetching product with id $id.',
        name: 'LocalProductRepository',
        error: e,
        stackTrace: s,
        level: 1200,
      );
      return RepoError(
          'Unexpected error when fetching product with id $id: $e');
    }
  }

  Future<RepoResult<Map<String, double>>> getProductUnits(int id) async {
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

      return RepoSuccess(result);
    } catch (e, s) {
      log(
        'Unexpected error when fetching product units.',
        name: 'LocalProductRepository',
        error: e,
        stackTrace: s,
        level: 1200,
      );
      return RepoError('Unexpected error when fetching product units: $e');
    }
  }

  // TODO units
  Future<RepoResult<LocalProduct?>> getProductByBarcode(String barcode) async {
    try {
      final List<Map<String, Object?>> productMaps = await _db.query(
        ProductSchema.table,
        where: '${ProductSchema.barcode} = ?',
        whereArgs: [barcode],
      );

      if (productMaps.isEmpty) {
        return RepoFailure('No product with barcode $barcode.');
      }
      return RepoSuccess(_localProductFromMap(productMaps.first));
    } catch (e, s) {
      log(
        'Unexpected error when fetching product by barcode ($barcode).',
        name: 'LocalProductRepository',
        error: e,
        stackTrace: s,
        level: 1200,
      );
      return RepoError('Unexpected error when fetching product by barcode: $e');
    }
  }
}