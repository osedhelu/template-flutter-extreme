import 'package:wap_xcontrol/features/turno/domain/entities/turno.dart';

abstract class TurnoRepository {
  Future<Turno> getById(int id);
  Future<List<Turno>> getAll();
}
