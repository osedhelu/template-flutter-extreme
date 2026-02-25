/// Configuración HTTP para URL base del API (equivalente a XConfHttp / ConfigHttpReserve).
class HttpConfig {
  const HttpConfig({
    this.protocol = 'http',
    required this.host,
    this.port = 80,
    this.context = '',
  });

  final String protocol;
  final String host;
  final int port;
  final String context;

  /// Protocolo coherente con el puerto: 443 → https, resto → http.
  static String protocolForPort(int port) =>
      port == 443 ? 'https' : 'http';

  /// Puertos por defecto por protocolo (no se muestran en la URL).
  static bool isDefaultPort(String protocol, int port) =>
      (protocol == 'https' && port == 443) || (protocol == 'http' && port == 80);

  /// Construye la URL base con trailing slash.
  /// Omite el puerto si es el estándar (80 para http, 443 para https).
  String toBaseUrl() {
    final ctx = context.trim();
    final path = ctx.isEmpty ? '' : '/$ctx';
    final showPort = !isDefaultPort(protocol, port);
    final portPart = showPort ? ':$port' : '';
    return '$protocol://$host$portPart$path/';
  }

  HttpConfig copyWith({
    String? protocol,
    String? host,
    int? port,
    String? context,
  }) {
    return HttpConfig(
      protocol: protocol ?? this.protocol,
      host: host ?? this.host,
      port: port ?? this.port,
      context: context ?? this.context,
    );
  }

  factory HttpConfig.fromJson(Map<String, dynamic> json) {
    final port = (json['port'] as num?)?.toInt() ?? 80;
    return HttpConfig(
      protocol: protocolForPort(port),
      host: json['host'] as String? ?? '',
      port: port,
      context: json['context'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'protocol': protocol,
        'host': host,
        'port': port,
        'context': context,
      };
}
