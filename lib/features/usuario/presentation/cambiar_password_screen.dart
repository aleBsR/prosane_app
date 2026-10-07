import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../core/design_system/app_button.dart';
import '../../../core/design_system/app_card.dart';
import '../../../core/design_system/app_gradient_scaffold.dart';
import '../../../core/design_system/app_text_field.dart';
import '../../../core/notificaciones/notificacion_controller.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Cambio de contraseña con la actual como confirmación. Extraído de la
/// antigua pantalla única de Configuración: ahora se entra desde el hub con
/// el botón "Cambiar contraseña".
class CambiarPasswordScreen extends ConsumerStatefulWidget {
  const CambiarPasswordScreen({super.key});
  @override
  ConsumerState<CambiarPasswordScreen> createState() => _CambiarPasswordScreenState();
}

class _CambiarPasswordScreenState extends ConsumerState<CambiarPasswordScreen> {
  bool _guardando = false;
  String? _error;
  String? _ok;

  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _repeatCtrl = TextEditingController();

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _repeatCtrl.dispose();
    super.dispose();
  }

  String _humanError(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        if (data['old_password'] is List) return (data['old_password'] as List).first.toString();
        if (data['new_password'] is List) return (data['new_password'] as List).first.toString();
        if (data['detail'] != null) return data['detail'].toString();
        if (data['error'] != null) return data['error'].toString();
        for (final v in data.values) {
          if (v is List && v.isNotEmpty) return v.first.toString();
        }
      }
      final code = e.response?.statusCode;
      if (code == 401) return 'Sesión expirada, volvé a iniciar sesión.';
      if (code == 400) return 'Datos inválidos.';
      return e.message ?? 'Error de conexión.';
    }
    return e.toString();
  }

  Future<void> _cambiar() async {
    final oldP = _oldCtrl.text;
    final newP = _newCtrl.text;
    final rep = _repeatCtrl.text;
    if (oldP.isEmpty || newP.isEmpty) {
      setState(() => _error = 'Completá ambos campos.');
      return;
    }
    if (newP.length < 6) {
      setState(() => _error = 'La nueva contraseña debe tener al menos 6 caracteres.');
      return;
    }
    if (newP != rep) {
      setState(() => _error = 'Las contraseñas no coinciden.');
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
      _ok = null;
    });
    try {
      final repo = ref.read(usuarioRepositoryProvider);
      await repo.changePassword(oldPassword: oldP, newPassword: newP);
      if (!mounted) return;
      setState(() {
        _ok = 'Contraseña actualizada. Volvé a iniciar sesión si se cierra.';
        _guardando = false;
      });
      ref.read(notificacionProvider.notifier).exito('Contraseña actualizada');
      _oldCtrl.clear();
      _newCtrl.clear();
      _repeatCtrl.clear();
      // Volver al hub de Configuración tras guardar.
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _humanError(e);
        _guardando = false;
      });
      ref.read(notificacionProvider.notifier).error(_error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppGradientScaffold(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(children: [
              IconButton(
                icon:  Icon(Icons.arrow_back, color: AppColors.blanco),
                onPressed: () => context.pop(),
              ),
              Expanded(
                child: Text('Cambiar contraseña',
                    style: AppTypography.titulo.copyWith(color: AppColors.blanco, fontSize: 22)),
              ),
            ]),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Usá tu contraseña actual para confirmar el cambio.',
                        style: AppTypography.texto.copyWith(fontSize: 12, color: AppColors.texto.withValues(alpha: 0.6))),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(label: 'Contraseña actual', controller: _oldCtrl, isPassword: true),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(label: 'Nueva contraseña', controller: _newCtrl, isPassword: true, helperText: 'Mínimo 6 caracteres'),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(label: 'Repetir nueva', controller: _repeatCtrl, isPassword: true),
                    if (_error != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(_error!, style: AppTypography.texto.copyWith(color: AppColors.error), textAlign: TextAlign.center),
                    ],
                    if (_ok != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(_ok!, style: AppTypography.texto.copyWith(color: Colors.green), textAlign: TextAlign.center),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    AppButton(label: 'Actualizar contraseña', isLoading: _guardando, onPressed: _guardando ? null : _cambiar),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
