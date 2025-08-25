import 'dart:developer';

import 'package:food_manager/domain/models/pantry_item.dart';
import 'package:food_manager/domain/models/recipe.dart';
import 'package:uuid/uuid.dart';

class MealPlan {
  DateTime dayZero;
  ({int lower, int upper}) mealsPerDayRange;
  List<List<MealPlanSlot>> plan;
  List<double> waste;
  List<bool> valid;

  int get length => plan.length;

  MealPlan({
    required this.dayZero,
    required this.mealsPerDayRange,
    required this.plan,
    required this.waste,
    required this.valid,
  }) {
    if (plan.length > waste.length || valid.length != plan.length) {
      throw ArgumentError("Bad list lengths");
    }

    log("Created new plan starting at ${dayZero.toString()}");
    plan.map((e) => e.map((e2) => 'item uuid: ${e2.ingredients.values.firstOrNull?.firstOrNull?.item.uuid.substring(0,4)}').toString()).forEach(log);
  }

  void clearPastDays(DateTime newDayZero, int newPlanLength) {
    if (newPlanLength < 0) {
      throw ArgumentError('newPlanLength must be >= 0');
    }

    final int drop = newDayZero.difference(dayZero).inDays.clamp(0, plan.length);

    // keep [drop, drop + newPlanLength)
    final int newPlanEnd = (drop + newPlanLength).clamp(0, plan.length);
    final int newWasteEnd = (drop + newPlanLength).clamp(0, waste.length);
    final int newValidEnd = (drop + newPlanLength).clamp(0, valid.length);

    plan  = plan.sublist(drop,  newPlanEnd);
    waste = waste.sublist(drop, newWasteEnd);
    valid = valid.sublist(drop, newValidEnd);

    if (plan.length < newPlanLength) {
      plan.addAll(List.generate(newPlanLength - plan.length, (_) => []));
    }
    if (waste.length < newPlanLength) {
      waste.addAll(List.generate(newPlanLength - waste.length, (_) => 0.0));
    }
    if (valid.length < newPlanLength) {
      valid.addAll(List.generate(newPlanLength - valid.length, (_) => true));
    }

    dayZero = newDayZero;
    assert(plan.length == waste.length && plan.length == valid.length);
  }

  double _sumDay(int day, double Function(MealPlanSlot s) pick) {
    if (day < 0 || day >= plan.length) return -1.0;
    return plan[day].fold(0.0, (p, s) => (p + pick(s)));
  }

  List<MealPlanSlot>? getDate(DateTime date) {
    final index = date.difference(dayZero).inDays;
    //log("Getting date ${date.toString()} => day: $index");
    if (index < 0 || index >= plan.length) return null;
    return List.unmodifiable(plan[index]);
  }

  double getWasteDate(DateTime date) => getWasteDay(date.difference(dayZero).inDays);
  double getWasteDay(int day) {
    if (day < 0 || day >= waste.length) return -1.0;
    return waste[day];
  }

  bool getValidDate(DateTime date) => getValidDay(date.difference(dayZero).inDays);
  bool getValidDay(int day) {
    if (day < 0 || day >= waste.length) return true;
    return valid[day];
  }

  double getCaloriesDate(DateTime date) => getCaloriesDay(date.difference(dayZero).inDays);
  double getCaloriesDay(int day) => _sumDay(day, (e) => e.calories);

  double getProteinDate(DateTime date) => getProteinDay(date.difference(dayZero).inDays);
  double getProteinDay(int day) => _sumDay(day, (e) => e.protein);

  double getCarbsDate(DateTime date) => getCarbsDay(date.difference(dayZero).inDays);
  double getCarbsDay(int day) => _sumDay(day, (e) => e.carbs);

  double getFatDate(DateTime date) => getFatDay(date.difference(dayZero).inDays);
  double getFatDay(int day) => _sumDay(day, (e) => e.fat);
}

class MealPlanSlot {
  final Recipe recipe;
  final Map<String, List<({PantryItem item, double quantity})>> ingredients;
  final double calories;
  final double protein;
  final double fat;
  final double carbs;
  final bool isValid;
  final String uuid;

  bool _isEaten = false;
  bool get isEaten => _isEaten;
  void eat() {
    _isEaten = true;
    ingredients.clear();
  }

  MealPlanSlot({
    required this.recipe,
    required this.ingredients,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.isValid,
    required bool isEaten,
  }) : _isEaten = isEaten, uuid = const Uuid().v4();
}