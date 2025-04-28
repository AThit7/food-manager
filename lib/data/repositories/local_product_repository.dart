import '../../core/result/repo_result.dart';
import '../../domain/models/product/local_product.dart';
import '../../data/services/database/database_service.dart';
import '../../data/database/schema/product_schema.dart';
import '../../data/database/schema/unit_schema.dart';

class LocalProductRepository{
  final  DatabaseService _db;

  LocalProductRepository(this._db);

  Map<String, dynamic> _localProductToMap(LocalProduct product) {
    return {
      ProductSchema.id: product.id,
      ProductSchema.name: product.name,
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

  LocalProduct _localProductFromMap(Map<String, dynamic> productMap) {
    return LocalProduct(
      id: productMap[ProductSchema.id] as int,
      name: productMap[ProductSchema.name] as String,
      barcode: productMap[ProductSchema.barcode] as String?,
      referenceUnit: productMap[ProductSchema.referenceUnit] as String,
      referenceValue: productMap[ProductSchema.referenceValue] as double,
      units: {},
      containerSize: productMap[ProductSchema.containerSize] as double?,
      calories: productMap[ProductSchema.calories] as double,
      carbs: productMap[ProductSchema.carbs] as double,
      protein: productMap[ProductSchema.protein] as double,
      fat: productMap[ProductSchema.fat] as double,
    );

  }

  Future<void> insertProduct(LocalProduct product) async {
    final productMap = _localProductToMap(product);
    final unitsMap = Map.of(product.units);

      final batch = _db.batch();
      batch.insert(
        ProductSchema.table,
        productMap,
        conflictAlgorithm: DbConflictAlgorithm.replace,
      );
      batch.insert(
        UnitSchema.table,
        unitsMap,
        conflictAlgorithm: DbConflictAlgorithm.replace,
      );
      batch.commit();
  }

  Future<RepoResult<List<LocalProduct>>> listProducts() async {
    final List<Map<String, Object?>> productMaps = await _db.query(
        ProductSchema.table);

    return RepoSuccess(productMaps.map(_localProductFromMap).toList());
  }

  Future<RepoResult<LocalProduct?>> getProduct(int id) async {
    final List<Map<String, Object?>> productMaps = await _db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (productMaps.firstOrNull == null) {
      return RepoFailure("No product with id $id");
    }
    return RepoSuccess(_localProductFromMap(productMaps.firstOrNull!));
  }

  Future<RepoResult<Map<String, double>>> getProductUnits(int id) async {
    final List<Map<String, Object?>> unitMaps = await _db.query(
      UnitSchema.table,
      where: '${UnitSchema.productId} = ?',
      whereArgs: [id],
    );

    final result = <String, double>{};
    for (final map in unitMaps) {
      final name = map[UnitSchema.name] as String;
      final value = map[UnitSchema.multiplier] as double;
      result[name] = value;
    }

    return RepoSuccess(result);
  }

  Future<RepoResult<LocalProduct?>> getProductByBarcode(String barcode) async {
    final List<Map<String, Object?>> productMaps = await _db.query(
      ProductSchema.table,
      where: '${ProductSchema.barcode} = ?',
      whereArgs: [barcode],
    );

    if (productMaps.firstOrNull == null) {
      return RepoFailure("No product with barcode $barcode");
    }
    return RepoSuccess(_localProductFromMap(productMaps.firstOrNull!));
  }
}