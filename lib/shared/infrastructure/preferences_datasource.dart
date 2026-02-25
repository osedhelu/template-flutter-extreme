import 'package:shared_preferences/shared_preferences.dart';

/// DataSource simple para persistencia clave-valor (sesión, token, etc.).
class PreferencesDataSource {
  PreferencesDataSource(this._prefs);

  final SharedPreferences _prefs;

  static const String keyUser = 'auth_user_json';
  static const String keyToken = 'auth_token';

  static Future<PreferencesDataSource> create() async {
    final prefs = await SharedPreferences.getInstance();
    return PreferencesDataSource(prefs);
  }

  Future<bool> setString(String key, String value) async {
    return _prefs.setString(key, value);
  }

  String? getString(String key) => _prefs.getString(key);

  Future<bool> remove(String key) async => _prefs.remove(key);

  Future<void> clearAuth() async {
    await Future.wait([
      remove(keyUser),
      remove(keyToken),
    ]);
  }
}
