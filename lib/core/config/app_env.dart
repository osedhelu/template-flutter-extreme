import 'package:wap_xcontrol/features/config_http/domain/entities/http_config.dart';

/// Valores por defecto del servidor API (origen: old_proyect_android ConfiguracionHttpBL).
///
/// Principal: track-jamar.extreme.com.co
/// Respaldo:  track-jamar.xtechno.co
class AppEnv {
  AppEnv._();

  // ─── URL principal (getDefaultConfiguracion) ──────────────────────────────

  static const String defaultProtocol = 'http';
  static const String defaultHost = 'track-jamar.extreme.com.co';
  static const int defaultPort = 80;
  static const String defaultContext = 'webservice/ws';

  /// Config HTTP principal por defecto (track-jamar.extreme.com.co).
  static const HttpConfig defaultHttpConfig = HttpConfig(
    protocol: defaultProtocol,
    host: defaultHost,
    port: defaultPort,
    context: defaultContext,
  );

  /// URL base por defecto para el cliente HTTP.
  /// Ej: http://track-jamar.extreme.com.co:80/webservice/ws/
  static String get defaultBaseUrl => defaultHttpConfig.toBaseUrl();

  // ─── URL de respaldo (getDefaultConfiguracionReserve) ─────────────────────

  static const String reserveHost = 'track-jamar.xtechno.co';
  static const int reservePort = 80;
  static const String reserveContext = 'webservice/ws';

  /// Config HTTP de respaldo por defecto (track-jamar.xtechno.co).
  static const HttpConfig defaultReserveHttpConfig = HttpConfig(
    protocol: defaultProtocol,
    host: reserveHost,
    port: reservePort,
    context: reserveContext,
  );

  /// URL base de respaldo por defecto.
  static String get defaultReserveBaseUrl => defaultReserveHttpConfig.toBaseUrl();

  // ─── API: endpoints y parámetros (origen: old_proyect_android) ─────────────

  /// Endpoint de login (MyServlets.LOGIN).
  static const String loginEndpoint = 'webmovilxtespecial/loginv4';

  /// Versión de la app para el parámetro version (Android usa BuildConfig.VERSION_NAME).
  static const String appVersion = '1.0.0';
}
