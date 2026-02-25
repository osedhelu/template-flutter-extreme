import 'package:wap_xcontrol/features/auth/domain/entities/user.dart';

abstract class AuthRepository {
  Future<User> login({
    required String username,
    required String password,
    required String typeUser,
  });

  Future<void> logout();

  Future<User?> getCurrentUser();
}
