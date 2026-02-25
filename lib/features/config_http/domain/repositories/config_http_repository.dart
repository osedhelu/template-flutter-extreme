import 'package:wap_xcontrol/features/config_http/domain/entities/http_config.dart';

abstract class ConfigHttpRepository {
  Future<HttpConfig?> getConfig();
  Future<HttpConfig?> getReserveConfig();

  Future<void> saveConfig(HttpConfig config);
  Future<void> saveReserveConfig(HttpConfig config);

  /// URL base para el cliente HTTP (con trailing slash). Null si no hay config.
  Future<String?> getBaseUrl();

  /// URL de respaldo. Null si no hay config reserva.
  Future<String?> getReserveBaseUrl();
}
