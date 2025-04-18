import 'package:flutter/material.dart';

import '../../../data/services/database/database_service.dart';
import '../../../domain/models/recipe.dart';

class AddRecipeViewmodel extends ChangeNotifier {
  AddRecipeViewmodel({
    required this.productBarcode,
    required DatabaseService databaseService,
  }) : _databaseService = databaseService;

  final String? productBarcode;
  final DatabaseService _databaseService;

  Future<void> addRecipe(String args) async {
    // TODO
    //final recipe = LocalRecipe(args);
    //await _databaseService.insertRecipe(recipe);
  }
}
