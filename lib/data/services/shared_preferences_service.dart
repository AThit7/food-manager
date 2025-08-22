import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  SharedPreferences? _prefs;
  SharedPreferences get _safe => _prefs ?? (throw StateError('Call init() first.'));

  static const _scannerType = "scanner_type";
  static const _defaultScannerType = "ml-kit";

  static const _upperMealCount = "upper_meal_count";
  static const _lowerMealCount = "lower_meal_count";

  static const _lowerCalories = "lower_calories";
  static const _upperCalories = "upper_calories";

  static const _lowerProtein  = "lower_protein";
  static const _upperProtein  = "upper_protein";

  static const _lowerFat      = "lower_fat";
  static const _upperFat      = "upper_fat";

  static const _lowerCarbs    = "lower_carbs";
  static const _upperCarbs    = "upper_carbs";

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String get scannerType => _safe.getString(_scannerType) ?? _defaultScannerType;
  Future<void> setScannerType(String v) => _safe.setString(_scannerType, v);

  int? get upperMealCount => _safe.getInt(_upperMealCount);
  int? get lowerMealCount => _safe.getInt(_lowerMealCount);
  Future<void> setUpperMealCount(int v) => _safe.setInt(_upperMealCount, v);
  Future<void> setLowerMealCount(int v) => _safe.setInt(_lowerMealCount, v);

  int? get lowerCalories => _safe.getInt(_lowerCalories);
  int? get upperCalories => _safe.getInt(_upperCalories);
  Future<void> setLowerCalories(int v) => _safe.setInt(_lowerCalories, v);
  Future<void> setUpperCalories(int v) => _safe.setInt(_upperCalories, v);
  Future<void> setCaloriesRange({required int lower, required int upper}) =>
      _setRange(lowerKey: _lowerCalories, upperKey: _upperCalories, lower: lower, upper: upper);

  int? get lowerProtein => _safe.getInt(_lowerProtein);
  int? get upperProtein => _safe.getInt(_upperProtein);
  Future<void> setLowerProtein(int v) => _safe.setInt(_lowerProtein, v);
  Future<void> setUpperProtein(int v) => _safe.setInt(_upperProtein, v);
  Future<void> setProteinRange({required int lower, required int upper}) =>
      _setRange(lowerKey: _lowerProtein, upperKey: _upperProtein, lower: lower, upper: upper);

  int? get lowerFat => _safe.getInt(_lowerFat);
  int? get upperFat => _safe.getInt(_upperFat);
  Future<void> setLowerFat(int v) => _safe.setInt(_lowerFat, v);
  Future<void> setUpperFat(int v) => _safe.setInt(_upperFat, v);
  Future<void> setFatRange({required int lower, required int upper}) =>
      _setRange(lowerKey: _lowerFat, upperKey: _upperFat, lower: lower, upper: upper);

  int? get lowerCarbs => _safe.getInt(_lowerCarbs);
  int? get upperCarbs => _safe.getInt(_upperCarbs);
  Future<void> setLowerCarbs(int v) => _safe.setInt(_lowerCarbs, v);
  Future<void> setUpperCarbs(int v) => _safe.setInt(_upperCarbs, v);
  Future<void> setCarbsRange({required int lower, required int upper}) =>
      _setRange(lowerKey: _lowerCarbs, upperKey: _upperCarbs, lower: lower, upper: upper);

  Future<void> _setRange({
    required String lowerKey,
    required String upperKey,
    required int lower,
    required int upper,
  }) async {
    if (lower > upper) {
      throw ArgumentError('Lower bound ($lower) cannot exceed upper bound ($upper).');
    }
    await _safe.setInt(lowerKey, lower);
    await _safe.setInt(upperKey, upper);
  }
}