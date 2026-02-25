import 'dart:convert';

import 'package:wap_xcontrol/features/turno/domain/entities/turno.dart';
import 'package:wap_xcontrol/shared/infrastructure/preferences_datasource.dart';

class TurnoLocalDataSource {
  TurnoLocalDataSource(this._prefs);

  final PreferencesDataSource _prefs;

  static const _keyList = 'turno_list';

  Future<void> saveList(List<Turno> list) async {
    final jsonList = list.map((e) => e.toJson()).toList();
    await _prefs.setString(_keyList, jsonEncode(jsonList));
  }

  Future<List<Turno>> getList() async {
    final raw = _prefs.getString(_keyList);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => Turno.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> clear() async {
    await _prefs.remove(_keyList);
  }
}
