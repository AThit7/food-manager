import 'recipe_ingredient.dart';

class Recipe {
  final int? id;
  final String name;
  final List<RecipeIngredient> ingredients;
  final int preparationTime;
  final String? instructions;

  Recipe({
    required this.name,
    required this.ingredients,
    required this.preparationTime,
    this.instructions,
    this.id,
  });

  Recipe copyWith({int? id}) {
    return Recipe(
      id: id ?? this.id,
      name: name,
      ingredients: ingredients,
      preparationTime: preparationTime,
      instructions: instructions,
    );
  }
}