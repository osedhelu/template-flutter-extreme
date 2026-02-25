import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wap_xcontrol/core/utils/api_error_message.dart';
import 'package:wap_xcontrol/features/auth/domain/entities/user.dart';
import 'package:wap_xcontrol/features/auth/domain/repositories/auth_repository.dart';
import 'package:wap_xcontrol/features/auth/infrastructure/datasources/auth_local_datasource.dart';
import 'package:wap_xcontrol/features/auth/infrastructure/repositories/auth_repository_impl.dart';
import 'package:wap_xcontrol/features/config_http/application/providers/config_http_providers.dart';
import 'package:wap_xcontrol/shared/application/preferences_provider.dart';

/// Cliente HTTP con baseUrl desde config_http (o valor por defecto).
final dioProvider = FutureProvider<Dio>((ref) async {
  final baseUrl = await ref.watch(currentBaseUrlProvider.future);
  return Dio(BaseOptions(baseUrl: baseUrl));
});

final authRepositoryProvider = FutureProvider<AuthRepository>((ref) async {
  final dio = await ref.watch(dioProvider.future);
  final prefs = await ref.watch(preferencesDataSourceProvider.future);
  final local = AuthLocalDataSource(prefs);
  return AuthRepositoryImpl(dio: dio, local: local);
});

class AuthState {
  const AuthState({
    required this.user,
    required this.isLoading,
    this.errorMessage,
  });

  final User? user;
  final bool isLoading;
  final String? errorMessage;

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  static const AuthState initial = AuthState(user: null, isLoading: false);
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repository) : super(AuthState.initial);

  final AuthRepository _repository;

  Future<void> checkSession() async {
    final user = await _repository.getCurrentUser();
    state = state.copyWith(user: user, isLoading: false, errorMessage: null);
  }

  Future<void> login({
    required String username,
    required String password,
    required String typeUser,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await _repository.login(
        username: username,
        password: password,
        typeUser: typeUser,
      );
      state = state.copyWith(user: user, isLoading: false, errorMessage: null);
    } catch (e) {
      final message = ApiErrorMessage.fromException(
        e,
        defaultMessage: 'Error de autenticación',
      );
      state = state.copyWith(
        isLoading: false,
        errorMessage: message,
      );
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = AuthState.initial;
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  throw UnimplementedError(
    'authNotifierProvider debe ser overrideado con un AuthNotifier real',
  );
});
