import 'dart:developer';

import 'package:food_manager/data/database/schema/pantry_item_schema.dart';
import 'package:food_manager/data/database/schema/recipe_ingredient_schema.dart';
import 'package:food_manager/data/database/schema/recipe_schema.dart';
import 'package:food_manager/data/database/schema/tag_schema.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'database_service.dart';
import '../../database/schema/product_schema.dart';
import '../../database/schema/unit_schema.dart';

final Map<DbConflictAlgorithm, ConflictAlgorithm> _conflictMap = const {
  DbConflictAlgorithm.replace: ConflictAlgorithm.replace,
  DbConflictAlgorithm.ignore: ConflictAlgorithm.ignore
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

    try {
      final result = await _db.rawQuery('SELECT sqlite_version()');
      if (result.isNotEmpty && result.first.values.isNotEmpty) {
        final version = result.first.values.first;
        log(
          'Opened SQLite database. SQLite version: $version',
          name: 'DatabaseService',
        );
      } else {
        log(
          'Opened SQLite database, but failed to retrieve SQLite version.',
          name: 'DatabaseService',
        );
      }
    } catch (e) {
      log(
        'Failed to query SQLite version',
        name: 'DatabaseService',
        error: e,
        level: 1200,
      );
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();
    batch.execute(TagSchema.create);
    batch.execute(ProductSchema.create);
    batch.execute(RecipeSchema.create);
    batch.execute(UnitSchema.create);
    batch.execute(PantryItemSchema.create);
    batch.execute(RecipeIngredientSchema.create);
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
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    DbConflictAlgorithm? conflictAlgorithm,
  }) {
    return _db.update(table, values, where: where, whereArgs: whereArgs,
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
    return _db.query(table, columns:  columns, where: where, whereArgs: whereArgs, groupBy: groupBy, having: having,
        orderBy: orderBy, limit: limit, offset: offset);
  }

  @override
  Future<List<Map<String, Object?>>> rawQuery(
    String sql, [
    List<Object?>? arguments
  ]) {
    return _db.rawQuery(sql, arguments);
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
    return _batch.commit(exclusive: exclusive, noResult: noResult, continueOnError: continueOnError);
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
    _batch.insert(table, values, nullColumnHack: nullColumnHack, conflictAlgorithm: _conflictMap[conflictAlgorithm]);
  }

  @override
  void update(
      String table,
      Map<String, Object?> values, {
        String? where,
        List<Object?>? whereArgs,
        DbConflictAlgorithm? conflictAlgorithm,
      }) {
    _batch.update(table, values, where: where, whereArgs: whereArgs,
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
    _batch.query(table, columns:  columns, where: where, whereArgs: whereArgs, groupBy: groupBy, having: having,
        orderBy: orderBy, limit: limit, offset: offset);
  }

  @override
  void rawQuery(
    String sql, [
    List<Object?>? arguments
  ]) {
    _batch.rawQuery(sql, arguments);
  }
}