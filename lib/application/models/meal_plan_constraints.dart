class MealPlanConstraints {
  final ({int lower, int upper}) mealRange;
  final ({int lower, int upper}) calorieRange;
  final ({int lower, int upper}) proteinRange;
  final ({int lower, int upper}) carbsRange;
  final ({int lower, int upper}) fatRange;

  List<({int lower, int upper})> get toList => [mealRange, calorieRange, proteinRange, carbsRange, fatRange];

  MealPlanConstraints({
    required this.mealRange,
    required this.calorieRange,
    required this.proteinRange,
    required this.carbsRange,
    required this.fatRange,
  });

  MealPlanConstraints copyWith({
    ({int lower, int upper})? mealRange,
    ({int lower, int upper})? calorieRange,
    ({int lower, int upper})? proteinRange,
    ({int lower, int upper})? carbsRange,
    ({int lower, int upper})? fatRange,
  }) {
    return MealPlanConstraints(
      mealRange: mealRange ?? this.mealRange,
      calorieRange: calorieRange ?? this.calorieRange,
      proteinRange: proteinRange ?? this.proteinRange,
      carbsRange: carbsRange ?? this.carbsRange,
      fatRange: fatRange ?? this.fatRange,
    );
  }
}