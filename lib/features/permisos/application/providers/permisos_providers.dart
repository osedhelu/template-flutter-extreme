import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wap_xcontrol/features/permisos/domain/entities/permisos.dart';
import 'package:wap_xcontrol/features/permisos/domain/repositories/permisos_repository.dart';

final permisos_repository_provider = Provider<PermisosRepository>((ref) {
  // TODO: inyectar Dio y datasources; devolver PermisosRepositoryImpl(remote: ..., local: ...)
  throw UnimplementedError(
    'Configurar PermisosRepository con datasources reales',
  );
});

class PermisosState {
  const PermisosState({
    this.items = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<Permisos> items;
  final bool isLoading;
  final String? errorMessage;

  PermisosState copyWith({
    List<Permisos>? items,
    bool? isLoading,
    String? errorMessage,
  }) {
    return PermisosState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  static const PermisosState initial = PermisosState();
}

class PermisosNotifier extends StateNotifier<PermisosState> {
  PermisosNotifier(this._repository) : super(PermisosState.initial);

  final PermisosRepository _repository;

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final items = await _repository.getAll();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
}

final permisosNotifierProvider =
    StateNotifierProvider<PermisosNotifier, PermisosState>((ref) {
  final repo = ref.watch(permisos_repository_provider);
  return PermisosNotifier(repo);
});
