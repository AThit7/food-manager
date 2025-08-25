import 'dart:async';
import 'dart:developer';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:food_manager/core/exceptions/exceptions.dart';
import 'package:food_manager/core/result/result.dart';
import 'package:food_manager/data/repositories/tag_repository.dart';
import 'package:food_manager/domain/models/recipe_ingredient.dart';
import 'package:food_manager/domain/models/tag.dart';
import 'package:fuzzy/fuzzy.dart';

import '../../../data/repositories/recipe_repository.dart';
import '../../../domain/models/recipe.dart';
import '../models/recipe_form_model.dart';
import '../models/ingredient_data.dart';
import '../../../domain/validators/recipe_validator.dart';

sealed class InsertResult {}

class InsertSuccess extends InsertResult {
  final Recipe recipe;

  InsertSuccess(this.recipe);
}

class InsertRepoFailure extends InsertResult {}

class InsertValidationFailure extends InsertResult {
  final String message;

  InsertValidationFailure(this.message);
}

class RecipeFormViewmodel extends ChangeNotifier {
  RecipeFormViewmodel({
    required RecipeRepository recipeRepository,
    required TagRepository tagRepository,
  })  : _recipeRepository = recipeRepository,
        _tagRepository = tagRepository;

  final RecipeRepository _recipeRepository;
  final TagRepository _tagRepository;
  bool _isLoadingTags = false;
  String? _errorMessage;

  Map<String, ({int id, List<String> units})> _tagUnitsMap = {};
  Fuzzy<String> _tagsFuse = Fuzzy<String>([]);
  Map<String, Fuzzy<String>> _unitFuseMap = {};

  get tags => List<String>.unmodifiable(_tagUnitsMap.keys);
  get isLoadingTags => _isLoadingTags;
  get errorMessage => _errorMessage;

  List<String> getUnits(String tag) =>
      List<String>.unmodifiable(_tagUnitsMap[tag]?.units ?? []); // TODO: maybe null instead of empty

  Iterable<String> tagSearch(String tag) {
    return _tagsFuse.search(tag).map((e) => e.item);
  }

  Iterable<String> unitSearch(String unit, String tag) {
    return _unitFuseMap[tag]?.search(unit).map((e) => e.item) ?? Iterable<String>.empty();
  }

  String? getTagUnitStatus(String tag, String unit) {
    if (!_unitFuseMap.containsKey(tag)) return 'Tag not found in the database.';
    final unitMatch = _unitFuseMap[tag]!.search(unit, 1).firstOrNull;
    if (unitMatch?.item != unit) return 'No such unit exists for this tag.';
    return null;
  }

  Future<InsertResult> saveRecipe(RecipeFormModel form) async {
    Recipe recipe;
    try {
      if (form.name == null || form.ingredients == null || form.preparationTime == null) {
        throw ArgumentError('Required form fields were null');
      }
      if (form.ingredients!.length != form.ingredients!.map((e) => e.tag).toSet().length) {
        throw ArgumentError('Ingredient names cannot repeat');
      }

      final recipeIngredients = <RecipeIngredient>[];
      for (final ingredientData in form.ingredients!) {
        if (ingredientData.tag == null || ingredientData.unit == null || ingredientData.amount == null) {
          throw ArgumentError('Required form ingredient fields were null');
        }
        recipeIngredients.add(RecipeIngredient(
          tag: Tag(name: ingredientData.tag!, id: _tagUnitsMap[ingredientData.tag]?.id),
          unit: ingredientData.unit!,
          amount: double.parse(ingredientData.amount!),
        ));
      }

      recipe = Recipe(
        id: form.id,
        name: form.name!,
        ingredients: recipeIngredients,
        preparationTime: int.parse(form.preparationTime!),
        instructions: form.instructions,
        timesUsed: form.timesUsed ?? 0,
        lastTimeUsed: form.lastTimeUsed,
      );

      RecipeValidator.validate(recipe);
    } catch (e) {
      log(
        "Failed to validate recipe.",
        name: "RecipeFormViewmodel",
        error: e,
      );
      String? msg = e is ArgumentError ? e.message : null;
      msg ??= e is ValidationError ? e.message : null;

      return InsertValidationFailure(msg ?? 'Could not validate recipe');
    }

    if (recipe.id == null) {
      final result = await _recipeRepository.insertRecipe(recipe);
      switch (result) {
        case ResultSuccess():
          return InsertSuccess(recipe.copyWith(id: result.data));
        case ResultFailure():
          return InsertRepoFailure();
        case ResultError():
          return InsertRepoFailure();
      }
    } else {
      final result = await _recipeRepository.updateRecipe(recipe);
      switch (result) {
        case ResultSuccess():
          return InsertSuccess(recipe);
        case ResultFailure():
          return InsertRepoFailure();
        case ResultError():
          return InsertRepoFailure();
      }
    }
  }

  Future<void> loadTagsAndUnits() async {
    _isLoadingTags = true;
    final result = await _tagRepository.getTagUnitsMap();
    _errorMessage = null;
    _tagUnitsMap = {};
    notifyListeners();

    switch (result) {
      case ResultSuccess():
        _tagUnitsMap = Map<String, ({int id, List<String> units})>.fromEntries(
            result.data.map((e) => MapEntry(e.tag.name, (id: e.tag.id!, units: List.of(e.units)))));
      case ResultError():
        _errorMessage = result.message;
      case ResultFailure():
        throw StateError('Unexpected RepoFailure in loadTagsAndUnits');
    }

    final tagOpts = FuzzyOptions<String>(
        distance: 10000,
        minMatchCharLength: 3
    );
    final unitOpts = FuzzyOptions<String>(
      distance: 10000,
    );

    _tagsFuse = Fuzzy(_tagUnitsMap.keys.toList(), options: tagOpts);
    _unitFuseMap = Map<String, Fuzzy<String>>
        .fromEntries(_tagUnitsMap.entries
        .map((e) => MapEntry(e.key, Fuzzy(e.value.units, options: unitOpts))));

    _isLoadingTags = false;
    notifyListeners();
  }

  String normalizeLine(String line) {
    final normalizedFractions = {
      '⅛': '1/8',
      '⅙': '1/6',
      '⅕': '1/5',
      '¼': '1/4',
      '⅓': '1/3',
      '½': '1/2',
      '⅔': '2/3',
      '⅖': '2/5',
      '¾': '3/4',
      '⅗': '3/5',
      '⅜': '3/8',
      '⅘': '4/5',
      '⅚': '5/6',
      '⅝': '5/8',
      '⅞': '7/8',
    };
    normalizedFractions.forEach((k, v) => line = line.replaceAll(k, v));
    return line.toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  double? _parseAmount(String amountString) {
    amountString = amountString.replaceAll(RegExp(r'\s*/\s*'), '/');
    amountString = amountString.trim();
    final parts = amountString.split(' ');
    double result = 0;

    for (var part in parts) {
      if (part.contains('/')) {
        final fractionParts = part.split('/');
        if (fractionParts.length == 2) {
          final num = double.tryParse(fractionParts[0]);
          final den = double.tryParse(fractionParts[1]);
          if (num != null && den != null && den != 0) {
            result += num / den;
            continue;
          }
        }
      }

      final number = double.tryParse(part.replaceAll(',', '.'));
      if (number != null) {
        result += number;
      }
    }

    return result > 0 ? result : null;
  }

  IngredientData _parseLine(String line) {
    final regex = RegExp(r'^(.*?)\s*(\d+/\d+|\d+(?:[.,]\d+)?(?:\s+\d+/\s*\d+)?)\s*(.*)$');
    final match = regex.firstMatch(line);

    if (match == null) return IngredientData();

    final amountString = match.group(2)!;
    final rest = '${match.group(1)} ${match.group(3)}'.replaceAll(RegExp(r'[^a-zA-Z\s]'), ' ').trim();

    final amount = _parseAmount(amountString);
    final parsedAmountString = amount?.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');

    final words = rest.split(' ')..removeWhere((e) => e.trim() == '');

    final bestTags = <String, double>{};
    for (final candidate in words.where((e) => e.length > 2)) {
      final hits = _tagsFuse.search(candidate);
      for (final hit in hits) {
        if (hit.score < 0.3) {
          bestTags[hit.item] = (bestTags[hit.item] ?? 0) + 1;
        }
      }
    }

    final bestTag = bestTags.isEmpty
        ? null
        : bestTags.entries.reduce((v, e) => v.value < e.value ? e : v).key;
    if (bestTag == null) return IngredientData(amount: parsedAmountString, tag: bestTag);

    final unitsFuse = _unitFuseMap[bestTag]!;
    final units = getUnits(bestTag).toSet();
    final bestUnits = <String, double>{};
    String? bestUnit;
    for (final candidate in words) {
      if (units.contains(candidate)) {
        bestUnit = candidate;
        break;
      }
      final hits = unitsFuse.search(candidate);
      for (final hit in hits) {
        if (hit.score < 0.3) {
          bestUnits[hit.item] = (bestUnits[hit.item] ?? 0) + 1;
        }
      }
    }

    bestUnit ??= bestUnits.isEmpty
        ? null
        : bestUnits.entries.reduce((v, e) => v.value < e.value ? e : v).key;
    return IngredientData(amount: parsedAmountString, tag: bestTag, unit: bestUnit);
  }

  List<IngredientData> parseIngredients(String text) {
    final results = <IngredientData>[];
    for (final line in text.split('\n')) {
      final normalizedLine = normalizeLine(line);
      if (line.trim().isNotEmpty) {
        final parsedLine = _parseLine(normalizedLine);
        parsedLine.originalValue = line;
        results.add(parsedLine);
      }
    }

    return results;
  }
}