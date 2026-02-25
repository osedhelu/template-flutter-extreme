import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wap_xcontrol/core/router/app_router.dart';
import 'package:wap_xcontrol/core/theme/app_theme.dart';
import 'package:wap_xcontrol/features/auth/application/providers/auth_providers.dart';

void main() {
  runApp(
    ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith((ref) {
          final asyncRepo = ref.watch(authRepositoryProvider);
          return AuthNotifier(
            asyncRepo.when(
              data: (repo) => repo,
              loading: () => throw StateError('AuthRepository no disponible'),
              error: (_, __) => throw StateError('AuthRepository no disponible'),
            ),
          );
        }),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'XtDespachos',
      theme: buildAppTheme(),
      home: const AuthRepositoryGate(),
    );
  }
}
