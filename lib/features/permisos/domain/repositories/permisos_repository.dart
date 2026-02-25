import 'package:wap_xcontrol/features/permisos/domain/entities/permisos.dart';

abstract class PermisosRepository {
  Future<Permisos> getById(int id);
  Future<List<Permisos>> getAll();
}
