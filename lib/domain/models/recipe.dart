import 'recipe_ingredient.dart';

class Recipe {
  final int? id;
  final String name;
  final List<RecipeIngredient> ingredients;
  final int preparationTime;
  final String? instructions;
  // TODO add those 2 everywhere
  final int timesUsed;
  final DateTime? lastTimeUsed;

  Recipe({
    required this.name,
    required this.ingredients,
    required this.preparationTime,
    this.instructions,
    this.id,
    this.timesUsed = 0,
    this.lastTimeUsed,
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