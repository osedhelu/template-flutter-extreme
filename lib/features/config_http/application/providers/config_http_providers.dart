import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wap_xcontrol/core/config/app_env.dart';
import 'package:wap_xcontrol/features/config_http/domain/repositories/config_http_repository.dart';
import 'package:wap_xcontrol/features/config_http/infrastructure/datasources/config_http_local_datasource.dart';
import 'package:wap_xcontrol/features/config_http/infrastructure/repositories/config_http_repository_impl.dart';
import 'package:wap_xcontrol/shared/application/preferences_provider.dart';

final configHttpRepositoryProvider = FutureProvider<ConfigHttpRepository>((ref) async {
  final prefs = await ref.watch(preferencesDataSourceProvider.future);
  final local = ConfigHttpLocalDataSource(prefs);
  return ConfigHttpRepositoryImpl(local);
});

/// URL base actual para el cliente HTTP. Usa config guardada o [AppEnv.defaultBaseUrl].
final currentBaseUrlProvider = FutureProvider<String>((ref) async {
  final repo = await ref.watch(configHttpRepositoryProvider.future);
  final baseUrl = await repo.getBaseUrl();
  return baseUrl ?? AppEnv.defaultBaseUrl;
});
