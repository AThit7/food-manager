import 'dart:async';
import 'dart:developer';

import 'package:food_manager/data/database/schema/recipe_ingredient_schema.dart';
import 'package:food_manager/data/database/schema/tag_schema.dart';
import 'package:food_manager/data/repositories/tag_repository.dart';
import 'package:food_manager/domain/models/recipe_ingredient.dart';
import 'package:food_manager/domain/models/tag.dart';
import 'package:food_manager/domain/validators/recipe_validator.dart';

import '../../core/result/repo_result.dart';
import '../../domain/models/recipe.dart';
import '../../data/database/schema/recipe_schema.dart';
import '../../data/services/database/database_service.dart';

sealed class RecipeEvent {}

class RecipeAdded extends RecipeEvent {
  final Recipe recipe;
  RecipeAdded(this.recipe);
}

class RecipeModified extends RecipeEvent {
  final Recipe recipe;
  RecipeModified(this.recipe);
}

class RecipeDeleted extends RecipeEvent {
  final int recipeId;
  RecipeDeleted(this.recipeId);
}

class RecipeRepository{
  final DatabaseService _db;
  final TagRepository _tagRepository;
  final _recipeUpdates = StreamController<RecipeEvent>.broadcast();

  Stream<RecipeEvent> get recipeUpdates => _recipeUpdates.stream;

  RecipeRepository(DatabaseService databaseService, TagRepository tagRepository)
      : _db = databaseService,
        _tagRepository = tagRepository;

  void dispose() {
    _recipeUpdates.close();
  }

  Map<String, dynamic> _recipeToMap(Recipe recipe) {
    return {
      RecipeSchema.id: recipe.id,
      RecipeSchema.name: recipe.name,
      RecipeSchema.preparationTime: recipe.preparationTime,
      RecipeSchema.instructions: recipe.instructions,
      RecipeSchema.timesUsed: recipe.timesUsed,
      RecipeSchema.lastTimeUsed: recipe.lastTimeUsed?.millisecondsSinceEpoch,
    };
  }

  List<({Map<String, dynamic> ingredient, Map<String, dynamic> tag})> _recipeToIngredientsTagsMaps(Recipe recipe) {
    final List<({Map<String, dynamic> ingredient,
    Map<String, dynamic> tag})> results = [];

    for (final ingredient in recipe.ingredients) {
      results.add((
        ingredient: {
          RecipeIngredientSchema.recipeId: recipe.id,
          RecipeIngredientSchema.tagId: ingredient.tag.id,
          RecipeIngredientSchema.amount: ingredient.amount,
          RecipeIngredientSchema.unit: ingredient.unit,
        },
        tag: {
          TagSchema.id: ingredient.tag.id,
          TagSchema.name: ingredient.tag.name,
        },
      ));
    }

    return results;
  }

  Recipe _recipeFromMap(Map<String, dynamic> recipeMap) {
    final lastTime = recipeMap[RecipeSchema.lastTimeUsed] as int?;

    return Recipe(
      id: recipeMap[RecipeSchema.id] as int,
      name: recipeMap[RecipeSchema.name] as String,
      ingredients: [],
      preparationTime: recipeMap[RecipeSchema.preparationTime] as int,
      instructions: recipeMap[RecipeSchema.instructions] as String?,
      timesUsed: recipeMap[RecipeSchema.timesUsed] as int,
      lastTimeUsed: lastTime == null ? null : DateTime.fromMillisecondsSinceEpoch(lastTime),
    );
  }

  Future<RepoResult<int>> insertRecipe(Recipe recipe) async {
    if (!RecipeValidator.isValid(recipe)) {
      throw ArgumentError('Recipe has invalid fields.');
    }

    try {
      final recipeMap = _recipeToMap(recipe);
      final ingredientsTagsMaps = _recipeToIngredientsTagsMaps(recipe);

      int recipeId = await _db.transaction((txn) async {
        final id = await txn.insert(RecipeSchema.table, recipeMap);
        final batch = txn.batch();

        for (final ingredientTagMap in ingredientsTagsMaps) {
          final tagId = await _tagRepository.getOrCreateTagByNameTxn(ingredientTagMap.tag[TagSchema.name], txn);
          ingredientTagMap.ingredient[RecipeIngredientSchema.recipeId] = id;
          ingredientTagMap.ingredient[RecipeIngredientSchema.tagId] = tagId;
          batch.insert(RecipeIngredientSchema.table, ingredientTagMap.ingredient);
        }

        await batch.commit(noResult: true);
        return id;
      });

      _recipeUpdates.add(RecipeAdded(recipe.copyWith(id: recipeId)));
      return RepoSuccess(recipeId);
    } catch (e, s) {
      log(
        'Unexpected error when inserting recipe.',
        name: 'RecipeRepository',
        error: e,
        stackTrace: s,
        level: 1200,
      );
      return RepoError('Unexpected error when inserting recipe.', e);
    }
  }

  Future<RepoResult<void>> updateRecipe(Recipe recipe) async {
    if (recipe.id == null) {
      throw ArgumentError('Recipe must have an ID when updating.');
    }
    if (!RecipeValidator.isValid(recipe)) {
      throw ArgumentError('Recipe has invalid fields.');
    }

    int count;
    try {
      final recipeMap = _recipeToMap(recipe);
      final ingredientsTagsMaps = _recipeToIngredientsTagsMaps(recipe);

      count = await _db.transaction((txn) async {
        final updatedCount = txn.update(
          RecipeSchema.table,
          recipeMap,
          where: '${RecipeSchema.id} = ?',
          whereArgs: [recipe.id],
        );
        txn.delete(
            RecipeIngredientSchema.table,
            where: '${RecipeIngredientSchema.recipeId} = ?',
            whereArgs: [recipe.id]
        );

        final batch = txn.batch();
        for (final ingredientTagMap in ingredientsTagsMaps) {
          final tagId = await _tagRepository.getOrCreateTagByNameTxn(ingredientTagMap.tag[TagSchema.name], txn);
          ingredientTagMap.ingredient[RecipeIngredientSchema.recipeId] = recipe.id!;
          ingredientTagMap.ingredient[RecipeIngredientSchema.tagId] = tagId;
          batch.insert(RecipeIngredientSchema.table, ingredientTagMap.ingredient);
        }

        await batch.commit(noResult: true);
        return updatedCount;
      });
    } catch (e, s) {
      log(
        'Unexpected error when updating recipe.',
        name: 'RecipeRepository',
        error: e,
        stackTrace: s,
        level: 1200,
      );
      return RepoError('Unexpected error when updating recipe.', e);
    }

    if (count == 0) {
      return RepoFailure("No recipe found with id ${recipe.id}.");
    }
    if (count == 1) {
      _recipeUpdates.add(RecipeModified(recipe));
      return RepoSuccess(null);
    }

    throw StateError(
      'Unexpected update count: $count for id ${recipe.id}. Expected 0 or 1. Data may be corrupted.',
    );
  }

  Future<RepoResult<void>> deleteRecipe(int recipeId) async {
    int count;
    try {
      count = await _db.delete(
        RecipeSchema.table,
        where: '${RecipeSchema.id} = ?',
        whereArgs: [recipeId],
      );
    } catch (e, s) {
      log(
        'Unexpected error when deleting recipe.',
        name: 'RecipeRepository',
        error: e,
        stackTrace: s,
        level: 1200,
      );
      return RepoError('Unexpected error when deleting recipe.', e);
    }

    if (count == 0) return RepoFailure('No recipe found with id $recipeId.');
    if (count == 1) {
      _recipeUpdates.add(RecipeDeleted(recipeId));
      return RepoSuccess(null);
    }

    throw StateError(
      'Unexpected delete count: $count for id $recipeId. '
          'Expected 0 or 1. Data may be corrupted.',
    );
  }

  Future<RepoResult<List<Recipe>>> listRecipes() async {
    const String unitColumn = 'unit_column';
    const String amountColumn = 'amount_column';
    const String tagIdColumn = 'tag_id_column';
    const String tagNameColumn = 'tag_name_column';
    const String recipeTable = 'recipe_table';
    const String ingredientTable = 'ingredient_table';
    const String tagTable = 'tag_table';

    try {
      final rows = await _db.rawQuery('''
        SELECT 
          $recipeTable.*,
          $ingredientTable.${RecipeIngredientSchema.unit} AS $unitColumn,
          $ingredientTable.${RecipeIngredientSchema.amount} AS $amountColumn,
          $ingredientTable.${RecipeIngredientSchema.tagId} AS $tagIdColumn,
          $tagTable.${TagSchema.name} AS $tagNameColumn
        FROM ${RecipeSchema.table} $recipeTable
        INNER JOIN ${RecipeIngredientSchema.table} $ingredientTable
          ON $recipeTable.${RecipeSchema.id} = $ingredientTable.${RecipeIngredientSchema.recipeId}
        INNER JOIN ${TagSchema.table} $tagTable
          ON $ingredientTable.${RecipeIngredientSchema.tagId} = $tagTable.${TagSchema.id}
      ''');

      final recipesMap = <int, Recipe>{};

      for (final row in rows) {
        final recipeId = row[RecipeSchema.id] as int;

        recipesMap.putIfAbsent(recipeId, () => _recipeFromMap(row));

        final recipeIngredient = RecipeIngredient(
          tag: Tag(
            id: row[tagIdColumn] as int,
            name: row[tagNameColumn] as String,
          ),
          amount: (row[amountColumn] as num).toDouble(),
          unit: row[unitColumn] as String,
        );

        recipesMap[recipeId]!.ingredients.add(recipeIngredient);
      }

      return RepoSuccess(recipesMap.values.toList());
    } catch (e, s) {
      log(
        'Unexpected error when fetching all recipes.',
        name: 'RecipeRepository',
        error: e,
        stackTrace: s,
        level: 1200,
      );
      return RepoError('Unexpected error when fetching all recipes: $e');
    }
  }

  // TODO ingredients and tags
  Future<RepoResult<Recipe?>> getRecipe(int id) async {
    try {
      final List<Map<String, Object?>> recipesMap = await _db.query(
        RecipeSchema.table,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (recipesMap.isEmpty) {
        return RepoFailure('No recipe with id $id');
      }
      return RepoSuccess(_recipeFromMap(recipesMap.first));
    } catch (e, s) {
      log(
        'Unexpected error when fetching recipe with id $id.',
        name: 'RecipeRepository',
        error: e,
        stackTrace: s,
        level: 1200,
      );
      return RepoError('Unexpected error when fetching recipe with id $id: $e');
    }
  }
}