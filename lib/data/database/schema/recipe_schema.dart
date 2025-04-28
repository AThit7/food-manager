abstract class RecipeSchema {
  static const table = 'recipes';

  static const id = 'id';
  static const name = 'name';
  static const preparationTime = 'preparation_time';
  static const instructions = 'instructions';

  static const create = '''
    CREATE TABLE $table (
      $id INTEGER PRIMARY KEY,
      $name TEXT NOT NULL CHECK (length(trim($name)) > 0),
      $preparationTime INTEGER NOT NULL CHECK ($preparationTime >= 0),
      $instructions STRING
    )
  ''';
}