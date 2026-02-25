import 'package:dio/dio.dart';

class PermisosRemoteDataSource {
  PermisosRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<Map<String, dynamic>>> getAll() async {
    final path = '/permisos';
    final response = await _dio.get<dynamic>(path);
    final data = response.data;
    if (data is List) {
      return List<Map<String, dynamic>>.from(
        data.map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{}),
      );
    }
    return [];
  }

  Future<Map<String, dynamic>> getById(int id) async {
    final path = '/permisos/$id';
    final response = await _dio.get<Map<String, dynamic>>(path);
    final data = response.data;
    if (data == null) throw FormatException('Respuesta vacía');
    return data;
  }
}
