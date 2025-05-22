import 'tag.dart';

class RecipeIngredient {
  final int? id;
  final Tag tag;
  final double amount;
  final String unit;

  RecipeIngredient({
    required this.tag,
    required this.amount,
    required this.unit,
    this.id,
  });

  RecipeIngredient copyWith({int? id}) {
    return RecipeIngredient(
      id: id ?? this.id,
      tag: tag,
      amount: amount,
      unit: unit,
    );
  }
}