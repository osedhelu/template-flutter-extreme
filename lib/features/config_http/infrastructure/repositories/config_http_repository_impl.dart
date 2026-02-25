import 'package:xtdespachos/features/config_http/domain/entities/http_config.dart';
import 'package:xtdespachos/features/config_http/domain/repositories/config_http_repository.dart';
import 'package:xtdespachos/features/config_http/infrastructure/datasources/config_http_local_datasource.dart';

class ConfigHttpRepositoryImpl implements ConfigHttpRepository {
  ConfigHttpRepositoryImpl(this._local);

  final ConfigHttpLocalDataSource _local;

  @override
  Future<HttpConfig?> getConfig() => _local.getConfig();

  @override
  Future<HttpConfig?> getReserveConfig() => _local.getReserveConfig();

  @override
  Future<void> saveConfig(HttpConfig config) => _local.saveConfig(config);

  @override
  Future<void> saveReserveConfig(HttpConfig config) =>
      _local.saveReserveConfig(config);

  @override
  Future<String?> getBaseUrl() async {
    final config = await _local.getConfig();
    if (config == null || config.host.trim().isEmpty) return null;
    return config.toBaseUrl();
  }

  @override
  Future<String?> getReserveBaseUrl() async {
    final config = await _local.getReserveConfig();
    if (config == null || config.host.trim().isEmpty) return null;
    return config.toBaseUrl();
  }
}
