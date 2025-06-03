import 'dart:async';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:food_manager/core/result/repo_result.dart';
import 'package:food_manager/data/repositories/tag_repository.dart';
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

class InsertValidationFailure extends InsertResult {}

class RecipeFormViewmodel extends ChangeNotifier {
  RecipeFormViewmodel({
    required RecipeRepository recipeRepository,
    required TagRepository tagRepository,
  })  : _recipeRepository = recipeRepository,
        _tagRepository = tagRepository;

  final RecipeRepository _recipeRepository;
  final TagRepository _tagRepository;
  bool _isLoadingTags = false;
  Map<String, List<String>> _tagUnitsMap = {};
  String? _errorMessage;
  Fuzzy<String> _tagsFuse = Fuzzy<String>([]);
  Map<String, Fuzzy<String>> _unitFuseMap = {};

  get tags => List.unmodifiable(_tagUnitsMap.keys);
  get isLoadingTags => _isLoadingTags;
  get errorMessage => _errorMessage;

  List<String> getUnits(String tag) => List.unmodifiable(_tagUnitsMap[tag] ?? []); // TODO: maybe null instead of empty

  bool tagExists(String name) {
    return _tagUnitsMap.containsKey(name);
  }

  Future<InsertResult> saveRecipe(RecipeFormModel form) async {
    return InsertRepoFailure();
    /*
    Recipe recipe;
    try {
      recipe = Recipe(...);
      RecipeValidator.validate(recipe);
    } catch (e) {
      log(
        "Failed to validate recipe.",
        name: "RecipeFormViewmodel",
        error: e,
      );
      return InsertValidationFailure();
    }

    if (recipe.id == null) {
      final result = await _recipeRepository.insertRecipe(recipe);
      switch (result) {
        case RepoSuccess():
          return InsertSuccess(recipe.copyWith(id: result.data));
        case RepoFailure():
          return InsertRepoFailure();
        case RepoError():
          return InsertRepoFailure();
      }
    } else {
      final result = await _recipeRepository.updateRecipe(recipe);
      switch (result) {
        case RepoSuccess():
          return InsertSuccess(recipe);
        case RepoFailure():
          return InsertRepoFailure();
        case RepoError():
          return InsertRepoFailure();
      }
    }
     */
  }

  Future<void> loadTagsAndUnits() async {
    _isLoadingTags = true;
    final result = await _tagRepository.getTagUnitsMap();
    _errorMessage = null;
    _tagUnitsMap = {};

    switch (result) {
      case RepoSuccess():
        _tagUnitsMap =
            Map<String, List<String>>.fromEntries(result.data.entries.map((e) => MapEntry(e.key.name, e.value)));
      case RepoError():
        _errorMessage = result.message;
      case RepoFailure():
        throw StateError('Unexpected RepoFailure in loadTagsAndUnits');
    }

    _tagsFuse = Fuzzy(_tagUnitsMap.keys.toList());
    _unitFuseMap =
        Map<String, Fuzzy<String>>.fromEntries(_tagUnitsMap.entries.map((e) => MapEntry(e.key, Fuzzy(e.value))));

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
    return line.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
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
    final regex = RegExp(r'^(\d+\/\d+|\d+(?:[\.,]\d+)?(?:\s+\d+\/\s*\d+)?)\s*(.*)$');
    final match = regex.firstMatch(line);

    if (match == null) return IngredientData();

    final amountString  = match.group(1)!;
    final rest = match.group(2)!;

    final amount = _parseAmount(amountString);
    final parsedAmountString = amount?.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');

    // TODO: adjust weight(s)?
    final unitWeight = 0.5;
    final tagWeight = 1.0;
    final noUnitPenalty = 0.7;

    final words = rest.split(' ');
    final matchedTag = _tagsFuse.search(rest, 1).firstOrNull;
    String? bestUnit;
    String? bestTag = matchedTag?.item;
    double bestScore = (matchedTag?.score ?? 10000.0) * tagWeight + noUnitPenalty * unitWeight;

    for (int i = 1; i <= words.length; i++) {
      final tagCandidate = words.sublist(i).join(' ');
      final unitCandidate = words.sublist(0, i).join(' ');
      final matchedTags = _tagsFuse.search(tagCandidate, 5);

      for (final matchedTag in matchedTags) {
        final unitsFuse = _unitFuseMap[matchedTag.item];
        final matchedUnit = unitsFuse?.search(unitCandidate, 1).firstOrNull;
        final score = (matchedUnit?.score ?? noUnitPenalty) * unitWeight + matchedTag.score * tagWeight;

        if (score < bestScore) {
          bestTag = matchedTag.item;
          bestUnit = matchedUnit?.item;
          bestScore = score;
        }
      }
    }

    return IngredientData(amount: parsedAmountString, tag: bestTag, unit: bestUnit);
  }

  List<IngredientData> parseIngredients(String text) {
    final results = <IngredientData>[];
    for (final line in text.split('\n')) {
      final normalizedLine = normalizeLine(line);
      if (line.isNotEmpty) {
        final parsedLine = _parseLine(normalizedLine);
        parsedLine.originalValue = line;
        results.add(parsedLine);
      }
    }

    return results;
  }
}
