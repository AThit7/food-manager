import '../../../domain/models/recipe.dart';
import 'ingredient_data.dart';

class RecipeFormModel {
  int? id;
  String? name;
  List<IngredientData>? ingredients;
  String? instructions;
  String? preparationTime;

  RecipeFormModel({this.id, this.name, this.ingredients, this.instructions, this.preparationTime});

  RecipeFormModel.fromRecipe(Recipe recipe) {
    id = recipe.id;
    name = recipe.name;
    ingredients = recipe.ingredients.map((e) => IngredientData(
      amount: e.amount.toString(),
      unit: e.unit,
      tag: e.tag.name,
    )).toList();
    instructions = recipe.instructions;
    preparationTime = recipe.preparationTime.toString();
  }

  RecipeFormModel copyWith({
    int? id,
    String? name,
    List<IngredientData>? ingredients,
    String? instructions,
    String? preparationTime,
  }) {
    return RecipeFormModel(
      id: id ?? this.id,
      name: name ?? this.name,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      preparationTime: preparationTime ?? this.preparationTime,
    );
  }
}