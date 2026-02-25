import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xtdespachos/shared/infrastructure/preferences_datasource.dart';

final preferencesDataSourceProvider =
    FutureProvider<PreferencesDataSource>((ref) async {
  return PreferencesDataSource.create();
});
