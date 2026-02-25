import 'dart:convert';

import 'package:xtdespachos/features/auth/domain/entities/user.dart';
import 'package:xtdespachos/shared/infrastructure/preferences_datasource.dart';

class AuthLocalDataSource {
  AuthLocalDataSource(this._prefs);

  final PreferencesDataSource _prefs;

  Future<void> saveUser(User user) async {
    final jsonStr = jsonEncode(user.toJson());
    await _prefs.setString(PreferencesDataSource.keyUser, jsonStr);
    if (user.token != null) {
      await _prefs.setString(PreferencesDataSource.keyToken, user.token!);
    }
  }

  Future<User?> getUser() async {
    final jsonStr = _prefs.getString(PreferencesDataSource.keyUser);
    if (jsonStr == null) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return User.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() => _prefs.clearAuth();
}
