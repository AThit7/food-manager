import '../../domain/models/product/local_product.dart';
import '../../data/services/database/database_service.dart';
import '../../data/database/schema/product_schema.dart';
import '../../data/database/schema/unit_schema.dart';

class LocalProductRepository{
  final  DatabaseService _db;

  LocalProductRepository(this._db);

  Map<String, dynamic> localProductToMap(LocalProduct product) {
    
  }

  Future<void> insertProduct(LocalProduct product) async {
    final productMap = product.toMap();
    productMap.remove('units');
    final unitsMap = Map.of(product.units);

      final batch = _db.batch();
      batch.insert(
        'products',
        productMap,
        conflictAlgorithm: DbConflictAlgorithm.replace,
      );
      batch.insert(
        'units',
        unitsMap,
        conflictAlgorithm: DbConflictAlgorithm.replace,
      );
      batch.commit();
  }

  Future<List<LocalProduct>> listProducts() async {
    final List<Map<String, Object?>> productMaps = await _db.query('products');

    return productMaps.map(LocalProduct.fromMap).toList();
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
    return LocalProduct.fromMap(productMaps.firstOrNull!);
  }

  Future<Map<String, double>> getProductUnits(int id) async {
    final List<Map<String, Object?>> unitMaps = await _db.query(
      'units',
      where: 'product_id = ?',
      whereArgs: [id],
    );

    final result = <String, double>{};
    for (final map in unitMaps) {
      final name = map['name'] as String;
      final value = map['value'] as double;
      result[name] = value;
    }

    return result;
  }

  Future<LocalProduct?> getProductByBarcode(String barcode) async {
    final List<Map<String, Object?>> productMaps = await _db.query(
      'products',
      where: 'barcode = ?',
      whereArgs: [barcode],
    );

    if (productMaps.firstOrNull == null) {
      return null;
    }
    return LocalProduct.fromMap(productMaps.firstOrNull!);
  }
}