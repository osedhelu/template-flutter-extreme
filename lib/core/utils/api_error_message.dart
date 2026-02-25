import 'package:dio/dio.dart';

/// Utilidad para extraer mensajes de error mostrables al usuario desde excepciones
/// de API (Dio, FormatException, etc.).
///
/// Compatible con el backend XtDespachos (MyHttpResponseGeneric): usa el campo `msj`
/// de la respuesta cuando está disponible.
///
/// Usar en providers, notifiers y pantallas donde se manejen errores de API.
class ApiErrorMessage {
  ApiErrorMessage._();

  /// Clave del mensaje en respuestas JSON del backend (MyHttpResponseGeneric.msj).
  static const String responseMessageKey = 'msj';

  /// Extrae un mensaje amigable para mostrar al usuario.
  ///
  /// [error] – Excepción capturada (FormatException, DioException, etc.).
  /// [defaultMessage] – Mensaje por defecto si no se puede extraer uno específico.
  ///
  /// Ejemplo:
  /// ```dart
  /// try {
  ///   await repository.login(...);
  /// } catch (e) {
  ///   state = state.copyWith(
  ///     errorMessage: ApiErrorMessage.fromException(e, defaultMessage: 'Error de autenticación'),
  ///   );
  /// }
  /// ```
  static String fromException(Object error, {String defaultMessage = 'Ha ocurrido un error'}) {
    if (error is FormatException) return error.message;
    if (error is DioException) return _fromDioException(error, defaultMessage);
    return defaultMessage;
  }

  static String _fromDioException(DioException e, String defaultMessage) {
    final data = e.response?.data;
    if (data is Map && data[responseMessageKey] != null) {
      return data[responseMessageKey] as String;
    }
    switch (e.type) {
      case DioExceptionType.connectionError:
        return 'Sin conexión. Verifica tu conexión a internet.';
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Tiempo de espera agotado. Intenta de nuevo.';
      default:
        return defaultMessage;
    }
  }
}
