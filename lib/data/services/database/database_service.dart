enum DbConflictAlgorithm { replace, ignore }

abstract class _DatabaseServiceCore {
  Future<int> insert(
      String table,
      Map<String, Object?> values, {
        String? nullColumnHack,
        DbConflictAlgorithm? conflictAlgorithm,
      });

  Future<int> update(
      String table,
      Map<String, Object?> values, {
        String? where,
        List<Object?>? whereArgs,
        DbConflictAlgorithm? conflictAlgorithm,
      });

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
      });

  Future<List<Map<String, Object?>>> rawQuery(String sql, [List<Object?>? arguments]);

  Future<int> rawDelete(String sql, [List<Object?>? arguments]);

  Future<int> rawUpdate(String sql, [List<Object?>? arguments]);

  Future<int> delete(String table, {String? where, List<Object?>? whereArgs});

  DbBatch batch();
}

abstract class DatabaseService extends _DatabaseServiceCore {
  Future<void> init();

  Future<T> transaction<T>(Future<T> Function(DbTransaction txn) action, {bool? exclusive});
}

abstract class DbBatch {
  void insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    DbConflictAlgorithm? conflictAlgorithm,
  });

  void update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    DbConflictAlgorithm? conflictAlgorithm,
  });

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
  });

  void rawQuery(String sql, [List<Object?>? arguments]);

  void rawDelete(String sql, [List<Object?>? arguments]);

  void rawUpdate(String sql, [List<Object?>? arguments]);

  void delete(String table, {String? where, List<Object?>? whereArgs});

  Future<List<Object?>> commit({
    bool? exclusive,
    bool? noResult,
    bool? continueOnError,
  });
}

abstract class DbTransaction extends _DatabaseServiceCore {}
