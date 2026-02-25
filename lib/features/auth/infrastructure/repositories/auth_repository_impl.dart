import 'package:dio/dio.dart';
import 'package:wap_xcontrol/features/auth/domain/entities/user.dart';
import 'package:wap_xcontrol/features/auth/domain/repositories/auth_repository.dart';
import 'package:wap_xcontrol/features/auth/infrastructure/datasources/auth_local_datasource.dart';
import 'package:wap_xcontrol/features/auth/infrastructure/datasources/auth_remote_datasource.dart';

/// Código de estado OK según backend (CommonsUtils.EST_OK).
const _estOk = 200;

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required Dio dio,
    required AuthLocalDataSource local,
  })  : _remote = AuthRemoteDataSource(dio),
        _local = local;

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;

  @override
  Future<User> login({
    required String username,
    required String password,
    required String typeUser,
  }) async {
    final data = await _remote.login(
      username: username,
      password: password,
      typeUser: typeUser,
    );

    // Formato MyHttpResponseGeneric<Conductor>: est, eDB, msj, datos.
    final est = data['est'] as int? ?? 0;
    final eDB = data['eDB'] as int? ?? 0;
    final msj = data['msj'] as String? ?? '';
    final datos = data['datos'] as Map<String, dynamic>?;

    if (eDB != _estOk) {
      throw FormatException(msj.isNotEmpty ? msj : 'Error de base de datos');
    }
    if (est != _estOk) {
      throw FormatException(
        msj.isNotEmpty ? msj : 'Usuario y/o contraseña incorrectos',
      );
    }
    if (datos == null) {
      throw const FormatException(
        'Usuario y/o contraseña incorrectos. Verifique y vuelva a intentarlo',
      );
    }

    // Mapeo Conductor -> User (campos del backend).
    final user = User(
      id: datos['idconductor'] as int? ?? 0,
      username: datos['cedula'] as String? ?? username,
      fullName: datos['nombre'] as String? ?? '',
      typeUser: typeUser,
      isInspector: datos['inspector'] as bool? ?? false,
      isLogistics: datos['logistics'] as bool? ?? false,
      token: null,
    );

    await _local.saveUser(user);
    return user;
  }

  @override
  Future<void> logout() async {
    await _local.clear();
  }

  @override
  Future<User?> getCurrentUser() => _local.getUser();
}
