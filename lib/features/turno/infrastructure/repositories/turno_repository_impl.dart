import 'package:wap_xcontrol/features/turno/domain/entities/turno.dart';
import 'package:wap_xcontrol/features/turno/domain/repositories/turno_repository.dart';
import 'package:wap_xcontrol/features/turno/infrastructure/datasources/turno_local_datasource.dart';
import 'package:wap_xcontrol/features/turno/infrastructure/datasources/turno_remote_datasource.dart';

class TurnoRepositoryImpl implements TurnoRepository {
  TurnoRepositoryImpl({
    required TurnoRemoteDataSource remote,
    required TurnoLocalDataSource local,
  })  : _remote = remote,
        _local = local;

  final TurnoRemoteDataSource _remote;
  final TurnoLocalDataSource _local;

  @override
  Future<Turno> getById(int id) async {
    final data = await _remote.getById(id);
    return Turno.fromJson(data);
  }

  @override
  Future<List<Turno>> getAll() async {
    try {
      final list = await _remote.getAll();
      final items = list.map((e) => Turno.fromJson(e)).toList();
      await _local.saveList(items);
      return items;
    } catch (_) {
      return _local.getList();
    }
  }
}
