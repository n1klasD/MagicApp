import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesHandler {
  static late SharedPreferences _preferences;

  static Future<void> init() async {
    WidgetsFlutterBinding.ensureInitialized();
    _preferences = await SharedPreferences.getInstance();
  }

  static T getValue<T>(String key, T defaultValue) {
    if (_preferences.get(key) != null) {
      return _preferences.get(key) as T;
    } else {
      saveValue(key, defaultValue);
      return defaultValue;
    }
  }

  static void saveValue<T>(String key, T value) {
    if (value is String) {
      _preferences.setString(key, value);
    } else if (value is int) {
      _preferences.setInt(key, value);
    } else if (value is bool) {
      _preferences.setBool(key, value);
    } else if (value is double) {
      _preferences.setDouble(key, value);
    } else if (value is List<String>) {
      _preferences.setStringList(key, value);
    } else {
      throw TypeError();
    }
  }
}
