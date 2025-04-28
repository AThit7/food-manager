import 'package:food_manager/domain/models/product/local_product.dart';

class LocalRecipe {
  final int? id;
  final String name;
  final List<Map<String, LocalProduct>>? ingredients;
  final String? instructions;

  LocalRecipe({
    required this.name,
    this.ingredients,
    this.instructions,
    this.id,
  });
}
