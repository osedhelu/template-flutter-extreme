import 'package:wap_xcontrol/features/permisos/domain/entities/permisos.dart';
import 'package:wap_xcontrol/features/permisos/domain/repositories/permisos_repository.dart';
import 'package:wap_xcontrol/features/permisos/infrastructure/datasources/permisos_remote_datasource.dart';

class PermisosRepositoryImpl implements PermisosRepository {
  PermisosRepositoryImpl({required PermisosRemoteDataSource remote})
      : _remote = remote;

  final PermisosRemoteDataSource _remote;

  @override
  Future<Permisos> getById(int id) async {
    final data = await _remote.getById(id);
    return Permisos.fromJson(data);
  }

  @override
  Future<List<Permisos>> getAll() async {
    final list = await _remote.getAll();
    return list.map((e) => Permisos.fromJson(e)).toList();
  }
}
