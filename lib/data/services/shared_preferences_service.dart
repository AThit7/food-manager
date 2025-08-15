import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  SharedPreferences? _prefs;
  SharedPreferences get _safe => _prefs ?? (throw StateError('Call init() first.'));

  static const _scannerType = "scanner_type";
  static const _upperMealCount = "upper_meal_count";
  static const _lowerMealCount = "lower_meal_count";

  static const _defaultScannerType = "ml-kit";
  static const _defaultUpperMealCount = 5;
  static const _defaultLowerMealCount = 3;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String get scannerType => _safe.getString(_scannerType) ?? _defaultScannerType;
  Future<void> setScannerType(String v) => _safe.setString(_scannerType, v);

  int get upperMealCount => _safe.getInt(_upperMealCount) ?? _defaultUpperMealCount;
  Future<void> setUpperMealCount(int v) => _safe.setInt(_upperMealCount, v);

  int get lowerMealCount => _safe.getInt(_lowerMealCount) ?? _defaultLowerMealCount;
  Future<void> setLowerMealCount(int v) => _safe.setInt(_lowerMealCount, v);
}