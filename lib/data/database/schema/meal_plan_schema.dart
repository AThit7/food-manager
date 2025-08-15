abstract class MealPlanSchema {
  static const table = 'meal_plan';

  static const id = 'id';
  static const dayZero = 'day_zero';
  static const mealsCountLow = 'meals_per_day_low';
  static const mealsCountHigh = 'meals_per_day_high';
  static const planJson = 'plan_json';
  static const wasteJson = 'waste_json';
  static const updatedAt = 'updated_at'; // TODO do we need this?

  static const create = '''
    CREATE TABLE $table (
      $id INTEGER PRIMARY KEY,
      $dayZero INTEGER NOT NULL CHECK ($dayZero >= 0),
      $mealsCountLow INTEGER NOT NULL CHECK ($mealsCountLow >= 0),
      $mealsCountHigh INTEGER NOT NULL CHECK ($mealsCountHigh >= $mealsCountLow),
      $planJson TEXT NOT NULL CHECK (length(trim($planJson)) > 0),
      $wasteJson TEXT NOT NULL CHECK (length(trim($wasteJson)) > 0),
      $updatedAt INTEGER NOT NULL
    )
  ''';
}