abstract class TagSchema {
  static const table = 'tags';

  static const id = 'id';
  static const name = 'name';

  static const create = '''
    CREATE TABLE $table (
      $id INTEGER PRIMARY KEY,
      $name TEXT NOT NULL UNIQUE CHECK (length(trim($name)) > 0)
    )
  ''';
}