import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wap_xcontrol/features/permisos/application/providers/permisos_providers.dart';

class PermisosScreen extends ConsumerStatefulWidget {
  const PermisosScreen({super.key});

  @override
  ConsumerState<PermisosScreen> createState() => _PermisosScreenState();
}

class _PermisosScreenState extends ConsumerState<PermisosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(permisosNotifierProvider.notifier).loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(permisosNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Permisos'),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      state.errorMessage!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: state.items.length,
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    return ListTile(
                      title: Text(item.name),
                      subtitle: item.id != null ? Text('ID: ${item.id}') : null,
                    );
                  },
                ),
    );
  }
}
