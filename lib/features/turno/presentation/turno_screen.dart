import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wap_xcontrol/features/turno/application/providers/turno_providers.dart';

class TurnoScreen extends ConsumerStatefulWidget {
  const TurnoScreen({super.key});

  @override
  ConsumerState<TurnoScreen> createState() => _TurnoScreenState();
}

class _TurnoScreenState extends ConsumerState<TurnoScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(turnoNotifierProvider.notifier).loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(turnoNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Turno'),
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
