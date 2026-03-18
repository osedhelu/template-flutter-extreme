import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestor_pqr/shared/infrastructure/preferences_datasource.dart';

final preferencesDataSourceProvider =
    FutureProvider<PreferencesDataSource>((ref) async {
  return PreferencesDataSource.create();
});
