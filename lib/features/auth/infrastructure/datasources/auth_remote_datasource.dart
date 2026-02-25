import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:wap_xcontrol/core/config/app_env.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);

  final Dio _dio;

  /// Realiza la petición de login. Compatible con el backend de Android:
  /// - Endpoint: webmovilxtespecial/loginv4
  /// - Content-Type: application/x-www-form-urlencoded
  /// - Parámetros: login (JSON string), version, servidor (host)
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
    required String typeUser,
  }) async {
    final uri = Uri.parse(_dio.options.baseUrl);
    final servidor = uri.host;

    final loginJson = jsonEncode({
      'usuario': username,
      'clave': password,
      'tipoUsuario': typeUser,
    });

    // Formato application/x-www-form-urlencoded como en Android (RequestParams).
    final body = 'login=${Uri.encodeComponent(loginJson)}'
        '&version=${Uri.encodeComponent(AppEnv.appVersion)}'
        '&servidor=${Uri.encodeComponent(servidor)}';

    final response = await _dio.post<Map<String, dynamic>>(
      AppEnv.loginEndpoint,
      data: body,
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    final data = response.data;
    if (data == null) {
      throw const FormatException('Respuesta vacía en login');
    }

    if (response.statusCode == 404) {
      throw FormatException('Endpoint no encontrado (404)');
    }

    return data;
  }
}
