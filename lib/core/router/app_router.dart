import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wap_xcontrol/features/auth/application/providers/auth_providers.dart';
import 'package:wap_xcontrol/features/auth/presentation/login_screen.dart';

class HomePlaceholderScreen extends StatelessWidget {
  const HomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Home XtDespachos (placeholder)'),
      ),
    );
  }
}

/// Espera a que [authRepositoryProvider] esté listo antes de construir [RootRouter].
/// Evita el error "AuthRepository no disponible" en el override de [authNotifierProvider].
class AuthRepositoryGate extends ConsumerWidget {
  const AuthRepositoryGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRepo = ref.watch(authRepositoryProvider);

    return asyncRepo.when(
      data: (_) => const RootRouter(),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Error al inicializar: $err',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget raíz que decide si mostrar login o home según el estado de auth.
class RootRouter extends ConsumerStatefulWidget {
  const RootRouter({super.key});

  @override
  ConsumerState<RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends ConsumerState<RootRouter> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _initAuth();
    }
  }

  Future<void> _initAuth() async {
    await ref.read(authNotifierProvider.notifier).checkSession();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final screen = authState.user == null
        ? const LoginScreen()
        : const HomePlaceholderScreen();

    if (!authState.isLoading) return screen;

    return Stack(
      children: [
        screen,
        Positioned.fill(
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(
                color: Colors.black.withValues(alpha: 0.2),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
