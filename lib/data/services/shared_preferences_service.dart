import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  late final SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    if(!_prefs.containsKey('scannerType')) {
      _prefs.setString('scannerType', 'ml-kit');
    }

    if(!_prefs.containsKey('preferredUnits')) {
      _prefs.setString('preferredUnits', 'metric');
    }
  }

  void saveString(String key, String value) {
    _prefs.setString(key, value);
  }

  String? getString(String key) {
    return _prefs.getString(key);
  }

  void remove(String key) {
    _prefs.remove(key);
  }
}