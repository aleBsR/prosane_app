import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/app_gradient_scaffold.dart';
import '../../../../core/design_system/app_text_field.dart';
import '../../../../core/notificaciones/notificacion_controller.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/session/session_controller.dart';

class ForceChangePasswordScreen extends ConsumerStatefulWidget {
  const ForceChangePasswordScreen({super.key});
  @override
  ConsumerState<ForceChangePasswordScreen> createState() => _ForceChangePasswordScreenState();
}

class _ForceChangePasswordScreenState extends ConsumerState<ForceChangePasswordScreen> {
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _cambiar() async {
    if (_oldCtrl.text.isEmpty || _newCtrl.text.isEmpty || _confirmCtrl.text.isEmpty) {
      setState(() => _error = 'Completá todos los campos');
      return;
    }
    if (_newCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'La nueva contraseña y la confirmación no coinciden');
      return;
    }
    if (_newCtrl.text.length < 6) {
      setState(() => _error = 'La nueva contraseña debe tener al menos 6 caracteres');
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final dio = ref.read(dioV1Provider);
      await dio.post('/auth/change-password/', data: {
        'old_password': _oldCtrl.text,
        'new_password': _newCtrl.text,
      });
      // Refrescar sesión para limpiar must_change_password
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.refrescarSesion();
      if (!mounted) return;
      ref.read(notificacionProvider.notifier).exito('Contraseña actualizada. ¡Bienvenido!');
      // Limpiar y ir a inicio
      context.go('/inicio');
    } catch (e) {
      String friendly = 'No se pudo cambiar la contraseña';
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map) {
          for (final value in data.values) {
            if (value is List && value.isNotEmpty) {
              friendly = value.first.toString();
              break;
            }
            if (value is String) {
              friendly = value;
              break;
            }
          }
        }
      } else {
        final msg = e.toString();
        if (msg.contains('old_password') || msg.contains('incorrecta')) {
          friendly = 'La contraseña actual (temporal) es incorrecta';
        } else if (msg.contains('MUST_CHANGE_PASSWORD')) {
          friendly = 'Debes cambiar la contraseña temporal primero';
        } else if (msg.contains('TEMP_EXPIRED')) {
          friendly = 'La temporal expiró (72h). Pedí al admin que te reenvíe una nueva.';
        }
      }
      if (mounted) setState(() => _error = friendly);
      if (mounted) ref.read(notificacionProvider.notifier).error(friendly);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppGradientScaffold(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Text('Cambio de contraseña obligatorio',
                style: AppTypography.titulo.copyWith(color: AppColors.blanco, fontSize: 20), textAlign: TextAlign.center),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tu contraseña es temporal (vence en 72h) y debes cambiarla para continuar.',
                            style: AppTypography.texto.copyWith(fontSize: 12, color: AppColors.texto.withValues(alpha: 0.7))),
                        const SizedBox(height: AppSpacing.sm),
                        Text('Por seguridad legal, cada usuario gestiona su propia contraseña. El admin no puede verla.',
                            style: AppTypography.texto.copyWith(fontSize: 11, color: AppColors.texto.withValues(alpha: 0.6), fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppTextField(label: 'Contraseña temporal actual *', controller: _oldCtrl, isPassword: true),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(label: 'Nueva contraseña *', controller: _newCtrl, isPassword: true),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(label: 'Confirmar nueva contraseña *', controller: _confirmCtrl, isPassword: true),
                        if (_error != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          Text(_error!, style: AppTypography.texto.copyWith(color: AppColors.error), textAlign: TextAlign.center),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        AppButton(label: 'Cambiar contraseña', isLoading: _guardando, onPressed: _guardando ? null : _cambiar),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppCard(
                    child: Column(
                      children: [
                        TextButton(
                          onPressed: () async {
                            // Logout por si quiere salir
                            await ref.read(authRepositoryProvider).logout();
                            ref.read(sessionControllerProvider.notifier).cerrar();
                            if (context.mounted) context.go('/login');
                          },
                          child: const Text('Cerrar sesión'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
