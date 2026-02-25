import 'dart:convert';

import 'package:xtdespachos/features/config_http/domain/entities/http_config.dart';
import 'package:xtdespachos/shared/infrastructure/preferences_datasource.dart';

class ConfigHttpLocalDataSource {
  ConfigHttpLocalDataSource(this._prefs);

  final PreferencesDataSource _prefs;

  static const String keyConfig = 'config_http';
  static const String keyConfigReserve = 'config_http_reserve';

  Future<HttpConfig?> getConfig() async {
    final jsonStr = _prefs.getString(keyConfig);
    if (jsonStr == null) return null;
    try {
      return HttpConfig.fromJson(
        jsonDecode(jsonStr) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<HttpConfig?> getReserveConfig() async {
    final jsonStr = _prefs.getString(keyConfigReserve);
    if (jsonStr == null) return null;
    try {
      return HttpConfig.fromJson(
        jsonDecode(jsonStr) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> saveConfig(HttpConfig config) async {
    await _prefs.setString(keyConfig, jsonEncode(config.toJson()));
  }

  Future<void> saveReserveConfig(HttpConfig config) async {
    await _prefs.setString(keyConfigReserve, jsonEncode(config.toJson()));
  }
}
