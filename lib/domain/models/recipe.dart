import 'recipe_ingredient.dart';

class Recipe {
  final int? id;
  final String name;
  final List<RecipeIngredient> ingredients;
  final int preparationTime;
  final String? instructions;
  final int timesUsed;
  final DateTime? lastTimeUsed;

  Recipe({
    required this.name,
    required this.ingredients,
    required this.preparationTime,
    required this.instructions,
    required this.id,
    required this.timesUsed,
    required this.lastTimeUsed,
  });

  Recipe copyWith({
    int? id,
    String? name,
    List<RecipeIngredient>? ingredients,
    int? preparationTime,
    String? instructions,
    int? timesUsed,
    DateTime? lastTimeUsed,
  }) {
    return Recipe(
      id: id ?? this.id,
      name: name ?? this.name,
      ingredients: ingredients ?? this.ingredients,
      preparationTime: preparationTime ?? this.preparationTime,
      instructions: instructions ?? this.instructions,
      timesUsed: timesUsed ?? this.timesUsed,
      lastTimeUsed: lastTimeUsed,
    );
  }
}