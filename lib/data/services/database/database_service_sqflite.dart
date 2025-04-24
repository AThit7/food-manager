import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'database_service.dart';
import '../../database/schema/product_schema.dart';
import '../../database/schema/unit_schema.dart';

final Map<DbConflictAlgorithm, ConflictAlgorithm> _conflictMap = const {
  DbConflictAlgorithm.replace: ConflictAlgorithm.replace
};

class DatabaseServiceSqflite implements DatabaseService {
  late final Database _db;

  @override
  Future<void> init() async {
    final dbPath = join(await getDatabasesPath(), 'user_data.db');
    await deleteDatabase(dbPath); // TODO: remove later
    _db = await openDatabase(
      dbPath,
      onConfigure: (db) async {
        await db.execute("PRAGMA foreign_keys = ON");
      },
      onCreate: _onCreate,
      version: 1,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();
    batch.execute(ProductSchema.create);
    batch.execute(UnitSchema.create);
    await batch.commit();
  }

  @override
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    DbConflictAlgorithm? conflictAlgorithm,
  }) {
    return _db.insert(table, values, nullColumnHack: nullColumnHack,
        conflictAlgorithm: _conflictMap[conflictAlgorithm]);
  }

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) {
    return _db.query(table, columns:  columns, where: where,
        whereArgs: whereArgs, groupBy: groupBy, having: having,
        orderBy: orderBy, limit: limit, offset: offset);
  }

  @override
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) {
    return _db.delete(table, where: where, whereArgs: whereArgs);
  }

  @override
  DbBatch batch() => _DbBatchSqflite(_db.batch());
}

class _DbBatchSqflite implements DbBatch{
  final Batch _batch;

  _DbBatchSqflite(this._batch);


  @override
  Future<List<Object?>> commit({
    bool? exclusive,
    bool? noResult,
    bool? continueOnError
  }) {
    return _batch.commit(exclusive: exclusive, noResult: noResult,
        continueOnError: continueOnError);
  }

  @override
  void delete(String table, {String? where, List<Object?>? whereArgs}) {
    _batch.delete(table, where: where, whereArgs: whereArgs);
  }

  @override
  void insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    DbConflictAlgorithm? conflictAlgorithm,
  }) {
    _batch.insert(table, values, nullColumnHack: nullColumnHack,
        conflictAlgorithm: _conflictMap[conflictAlgorithm]);
  }

  @override
  void query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) {
    return _batch.query(table, columns:  columns, where: where,
        whereArgs: whereArgs, groupBy: groupBy, having: having,
        orderBy: orderBy, limit: limit, offset: offset);
  }
}