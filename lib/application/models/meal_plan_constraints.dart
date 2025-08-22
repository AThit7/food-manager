class MealPlanConstraints {
  final ({int lower, int upper}) calorieRange;
  final ({int lower, int upper}) proteinRange;
  final ({int lower, int upper}) carbsRange;
  final ({int lower, int upper}) fatRange;

  MealPlanConstraints({
    required this.calorieRange,
    required this.proteinRange,
    required this.carbsRange,
    required this.fatRange,
  });
}