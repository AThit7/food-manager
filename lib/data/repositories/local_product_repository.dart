import '../../domain/models/product/local_product.dart';
import '../../data/services/database/database_service.dart';
import '../../data/database/schema/product_schema.dart';
import '../../data/database/schema/unit_schema.dart';

class LocalProductRepository{
  final  DatabaseService _db;

  LocalProductRepository(this._db);

  Map<String, dynamic> _localProductToMap(LocalProduct product) {
    return {
      'id': product.id,
      'name': product.name,
      'barcode': product.barcode,
      'referenceUnit': product.referenceUnit,
      'referenceValue': product.referenceValue,
      'containerSize': product.containerSize,
      'calories': product.calories,
      'carbs': product.carbs,
      'protein': product.protein,
      'fat': product.fat,
    };
  }

  LocalProduct _localProductFromMap(Map<String, dynamic> productMap) {
    return LocalProduct(
      id: productMap['id'] as int,
      name: productMap['name'] as String,
      barcode: productMap['barcode'] as String?,
      referenceUnit: productMap['referenceUnit'] as String,
      referenceValue: productMap['referenceValue'] as double,
      units: {},
      containerSize: productMap['containerSize'] as double?,
      calories: productMap['calories'] as double,
      carbs: productMap['carbs'] as double,
      protein: productMap['protein'] as double,
      fat: productMap['fat'] as double,
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

  Future<List<LocalProduct>> listProducts() async {
    final List<Map<String, Object?>> productMaps = await _db.query(
        ProductSchema.table);

    return productMaps.map(_localProductFromMap).toList();
  }

  Future<LocalProduct?> getProduct(int id) async {
    final List<Map<String, Object?>> productMaps = await _db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (productMaps.firstOrNull == null) {
      return null;
    }
    return _localProductFromMap(productMaps.firstOrNull!);
  }

  Future<Map<String, double>> getProductUnits(int id) async {
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

    return result;
  }

  Future<LocalProduct?> getProductByBarcode(String barcode) async {
    final List<Map<String, Object?>> productMaps = await _db.query(
      ProductSchema.table,
      where: '${ProductSchema.barcode} = ?',
      whereArgs: [barcode],
    );

    if (productMaps.firstOrNull == null) {
      return null;
    }
    return _localProductFromMap(productMaps.firstOrNull!);
  }
}