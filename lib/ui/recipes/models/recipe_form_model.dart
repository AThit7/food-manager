import '../../../domain/models/recipe.dart';

// TODO finish
class RecipeFormModel {
  int? id;
  String? name;
  Map<String, double>? products;

  RecipeFormModel({this.id});

  RecipeFormModel.fromRecipe(Recipe recipe) {
    id = recipe.id;
  }

  RecipeFormModel copyWith({int? id}) {
    return RecipeFormModel(id: id);
  }
}
