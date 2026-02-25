import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wap_xcontrol/shared/infrastructure/preferences_datasource.dart';

final preferencesDataSourceProvider =
    FutureProvider<PreferencesDataSource>((ref) async {
  return PreferencesDataSource.create();
});
