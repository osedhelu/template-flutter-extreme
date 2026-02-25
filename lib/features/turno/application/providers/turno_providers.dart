import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wap_xcontrol/features/turno/domain/entities/turno.dart';
import 'package:wap_xcontrol/features/turno/domain/repositories/turno_repository.dart';

final turno_repository_provider = Provider<TurnoRepository>((ref) {
  // TODO: inyectar Dio y datasources; devolver TurnoRepositoryImpl(remote: ..., local: ...)
  throw UnimplementedError(
    'Configurar TurnoRepository con datasources reales',
  );
});

class TurnoState {
  const TurnoState({
    this.items = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<Turno> items;
  final bool isLoading;
  final String? errorMessage;

  TurnoState copyWith({
    List<Turno>? items,
    bool? isLoading,
    String? errorMessage,
  }) {
    return TurnoState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  static const TurnoState initial = TurnoState();
}

class TurnoNotifier extends StateNotifier<TurnoState> {
  TurnoNotifier(this._repository) : super(TurnoState.initial);

  final TurnoRepository _repository;

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

final turnoNotifierProvider =
    StateNotifierProvider<TurnoNotifier, TurnoState>((ref) {
  final repo = ref.watch(turno_repository_provider);
  return TurnoNotifier(repo);
});
