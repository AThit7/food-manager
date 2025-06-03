import '../../../domain/models/recipe.dart';
import 'ingredient_data.dart';

// TODO finish
class RecipeFormModel {
  int? id;
  String? name;
  List<IngredientData>? ingredients;
  String? instructions;
  String? preparationTime;
  Map<String, double>? products;

  RecipeFormModel({this.id});

  RecipeFormModel.fromRecipe(Recipe recipe) {
    id = recipe.id;
  }

  RecipeFormModel copyWith({int? id}) {
    return RecipeFormModel(id: id);
  }
}
