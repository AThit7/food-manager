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

  Recipe copyWith({int? id}) {
    return Recipe(
      id: id ?? this.id,
      name: name,
      ingredients: ingredients,
      preparationTime: preparationTime,
      instructions: instructions,
      timesUsed: timesUsed,
      lastTimeUsed: lastTimeUsed,
    );
  }
}