class MealPlanConstraints {
  final ({double lower, double upper}) calorieRange;
  final ({double lower, double upper}) proteinRange;
  final ({double lower, double upper}) carbsRange;
  final ({double lower, double upper}) fatRange;

  MealPlanConstraints({
    required this.calorieRange,
    required this.proteinRange,
    required this.carbsRange,
    required this.fatRange,
  });
}