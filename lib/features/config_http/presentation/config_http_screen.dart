import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xtdespachos/core/config/app_env.dart';
import 'package:xtdespachos/core/theme/app_palette.dart';
import 'package:xtdespachos/features/config_http/domain/entities/http_config.dart';
import 'package:xtdespachos/features/config_http/application/providers/config_http_providers.dart';

class ConfigHttpScreen extends ConsumerStatefulWidget {
  const ConfigHttpScreen({super.key});

  @override
  ConsumerState<ConfigHttpScreen> createState() => _ConfigHttpScreenState();
}

class _ConfigHttpScreenState extends ConsumerState<ConfigHttpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hostController = TextEditingController();
  final _portController = TextEditingController();
  final _contextController = TextEditingController();
  final _hostReserveController = TextEditingController();
  final _portReserveController = TextEditingController();
  final _contextReserveController = TextEditingController();
  bool _expandedReserve = false;
  bool _saving = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final repo = await ref.read(configHttpRepositoryProvider.future);
    final config = await repo.getConfig();
    final reserve = await repo.getReserveConfig();
    if (!mounted) return;
    final main = config ?? AppEnv.defaultHttpConfig;
    final res = reserve ?? AppEnv.defaultReserveHttpConfig;
    setState(() {
      _hostController.text = main.host;
      _portController.text = main.port.toString();
      _contextController.text = main.context;
      _hostReserveController.text = res.host;
      _portReserveController.text = res.port.toString();
      _contextReserveController.text = res.context;
    });
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _contextController.dispose();
    _hostReserveController.dispose();
    _portReserveController.dispose();
    _contextReserveController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _message = null;
    });

    try {
      final repo = await ref.read(configHttpRepositoryProvider.future);
      final port = int.tryParse(_portController.text.trim()) ?? 80;
      final protocol = HttpConfig.protocolForPort(port);
      final config = HttpConfig(
        protocol: protocol,
        host: _hostController.text.trim(),
        port: port,
        context: _contextController.text.trim(),
      );
      await repo.saveConfig(config);

      final hostReserve = _hostReserveController.text.trim();
      if (hostReserve.isNotEmpty) {
        final portReserve = int.tryParse(_portReserveController.text.trim()) ?? 80;
        final protocolReserve = HttpConfig.protocolForPort(portReserve);
        final reserve = HttpConfig(
          protocol: protocolReserve,
          host: hostReserve,
          port: portReserve,
          context: _contextReserveController.text.trim(),
        );
        await repo.saveReserveConfig(reserve);
      }

      // No invalidar aquí: provocaría recarga de dio/authRepository y error
      // "AuthRepository no disponible" al volver. La nueva URL se usa al reiniciar la app.

      if (!mounted) return;
      setState(() {
        _saving = false;
        _message = 'Configuración guardada. Reinicia la app para usar la nueva URL.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _message = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración HTTP'),
        foregroundColor: colorScheme.onSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'URL principal del API',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppPalette.textGrayDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _hostController,
                decoration: _decoration('Servidor', 'ej. api.ejemplo.com'),
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Ingresa el servidor' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _portController,
                decoration: _decoration('Puerto', '80'),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Ingresa el puerto';
                  if (int.tryParse(v.trim()) == null) return 'Puerto no válido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contextController,
                decoration: _decoration('Contexto', 'ej. webservice'),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 24),
              InkWell(
                onTap: () => setState(() => _expandedReserve = !_expandedReserve),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        _expandedReserve
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'URL de respaldo (opcional)',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_expandedReserve) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _hostReserveController,
                  decoration: _decoration('Servidor respaldo', 'ej. backup.ejemplo.com'),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _portReserveController,
                  decoration: _decoration('Puerto respaldo', '80'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contextReserveController,
                  decoration: _decoration('Contexto respaldo', 'webservice'),
                ),
              ],
              if (_message != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _message!.startsWith('Error')
                        ? colorScheme.errorContainer.withValues(alpha: 0.5)
                        : colorScheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _message!,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _saving
                    ? SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.onPrimary,
                        ),
                      )
                    : const Text('Guardar configuración'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      labelStyle: const TextStyle(
        color: AppPalette.textGrayDark,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
