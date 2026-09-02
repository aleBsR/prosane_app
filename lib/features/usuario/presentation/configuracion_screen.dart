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
import '../../../core/session/session_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class ConfiguracionScreen extends ConsumerStatefulWidget {
  const ConfiguracionScreen({super.key});
  @override
  ConsumerState<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends ConsumerState<ConfiguracionScreen> {
  bool _cargandoPerfil = true;
  bool _guardandoPerfil = false;
  bool _guardandoPass = false;
  String? _errorPerfil;
  String? _errorPass;
  String? _okPerfil;
  String? _okPass;

  // perfil controllers
  late TextEditingController _nombreCtrl;
  late TextEditingController _apellidoCtrl;
  String _email = '';
  String _escuela = '';
  String _rolLabel = '';

  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _repeatCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController();
    _apellidoCtrl = TextEditingController();
    _cargarPerfil();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _repeatCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarPerfil() async {
    setState(() {
      _cargandoPerfil = true;
      _errorPerfil = null;
    });
    try {
      final repo = ref.read(usuarioRepositoryProvider);
      final data = await repo.fetchMe();
      final user = data['user'] as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _nombreCtrl.text = (user['nombre'] ?? '').toString();
        _apellidoCtrl.text = (user['apellido'] ?? '').toString();
        _email = (user['email'] ?? '').toString();
        // dni no viene en /me para no exponer, mostramos vacío o desde persona si existiera
        _escuela = (user['escuela_nombre'] ?? '').toString();
        final roles = data['roles'] as List?;
        if (roles != null && roles.isNotEmpty) {
          _rolLabel = (roles.first['label'] ?? '').toString();
        }
        _cargandoPerfil = false;
      });
      // también refrescar sesión local para que UsuarioScreen muestre nuevo nombre
      try {
        final authRepo = ref.read(authRepositoryProvider);
        final sesion = await authRepo.refrescarSesion();
        ref.read(sessionControllerProvider.notifier).refrescar(sesion);
      } catch (_) {}
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargandoPerfil = false;
        _errorPerfil = _humanError(e);
      });
    }
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

  Future<void> _guardarPerfil() async {
    final nombre = _nombreCtrl.text.trim();
    final apellido = _apellidoCtrl.text.trim();
    if (nombre.isEmpty && apellido.isEmpty) {
      setState(() => _errorPerfil = 'Ingresá al menos nombre o apellido.');
      return;
    }
    setState(() {
      _guardandoPerfil = true;
      _errorPerfil = null;
      _okPerfil = null;
    });
    try {
      final repo = ref.read(usuarioRepositoryProvider);
      final data = await repo.patchMe(nombre: nombre, apellido: apellido);
      if (!mounted) return;
      setState(() {
        _okPerfil = 'Perfil actualizado.';
        _guardandoPerfil = false;
      });
      ref.read(notificacionProvider.notifier).exito('Perfil actualizado');
      // refrescar sesión para que UsuarioScreen muestre nuevo nombre
      try {
        final authRepo = ref.read(authRepositoryProvider);
        final sesion = await authRepo.refrescarSesion();
        ref.read(sessionControllerProvider.notifier).refrescar(sesion);
      } catch (_) {}
      // también actualizar local controllers con respuesta
      final user = data['user'] as Map<String, dynamic>?;
      if (user != null) {
        _nombreCtrl.text = (user['nombre'] ?? '').toString();
        _apellidoCtrl.text = (user['apellido'] ?? '').toString();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorPerfil = _humanError(e);
        _guardandoPerfil = false;
      });
      ref.read(notificacionProvider.notifier).error(_errorPerfil!);
    }
    if (mounted && _guardandoPerfil) setState(() => _guardandoPerfil = false);
  }

  Future<void> _cambiarPass() async {
    final oldP = _oldCtrl.text;
    final newP = _newCtrl.text;
    final rep = _repeatCtrl.text;
    if (oldP.isEmpty || newP.isEmpty) {
      setState(() => _errorPass = 'Completá ambos campos.');
      return;
    }
    if (newP.length < 6) {
      setState(() => _errorPass = 'La nueva contraseña debe tener al menos 6 caracteres.');
      return;
    }
    if (newP != rep) {
      setState(() => _errorPass = 'Las contraseñas no coinciden.');
      return;
    }
    setState(() {
      _guardandoPass = true;
      _errorPass = null;
      _okPass = null;
    });
    try {
      final repo = ref.read(usuarioRepositoryProvider);
      await repo.changePassword(oldPassword: oldP, newPassword: newP);
      if (!mounted) return;
      setState(() {
        _okPass = 'Contraseña actualizada. Volvé a iniciar sesión si se cierra.';
        _guardandoPass = false;
      });
      ref.read(notificacionProvider.notifier).exito('Contraseña actualizada');
      _oldCtrl.clear();
      _newCtrl.clear();
      _repeatCtrl.clear();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorPass = _humanError(e);
        _guardandoPass = false;
      });
      ref.read(notificacionProvider.notifier).error(_errorPass!);
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
                icon: const Icon(Icons.arrow_back, color: AppColors.blanco),
                onPressed: () => context.pop(),
              ),
              Expanded(
                child: Text('Configuración',
                    style: AppTypography.titulo.copyWith(color: AppColors.blanco, fontSize: 22)),
              ),
            ]),
          ),
          Expanded(
            child: _cargandoPerfil
                ? const Center(child: CircularProgressIndicator(color: AppColors.blanco))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Mi perfil
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text('Mi perfil', style: AppTypography.subtitulo),
                              const SizedBox(height: 4),
                              Text('Actualizá tu nombre y apellido.',
                                  style: AppTypography.texto.copyWith(fontSize: 12, color: AppColors.texto.withValues(alpha: 0.6))),
                              const SizedBox(height: AppSpacing.md),
                              AppTextField(label: 'Nombre', controller: _nombreCtrl),
                              const SizedBox(height: AppSpacing.md),
                              AppTextField(label: 'Apellido', controller: _apellidoCtrl),
                              const SizedBox(height: AppSpacing.md),
                              AppTextField(label: 'Email', controller: TextEditingController(text: _email), readOnly: true, helperText: 'No se puede cambiar'),
                              if (_escuela.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.md),
                                AppTextField(label: 'Escuela', controller: TextEditingController(text: _escuela), readOnly: true),
                              ],
                              if (_rolLabel.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.sm),
                                Text('Rol: $_rolLabel', style: AppTypography.texto.copyWith(fontSize: 12, color: AppColors.primario)),
                              ],
                              if (_errorPerfil != null) ...[
                                const SizedBox(height: AppSpacing.sm),
                                Text(_errorPerfil!, style: AppTypography.texto.copyWith(color: AppColors.error), textAlign: TextAlign.center),
                              ],
                              if (_okPerfil != null) ...[
                                const SizedBox(height: AppSpacing.sm),
                                Text(_okPerfil!, style: AppTypography.texto.copyWith(color: Colors.green), textAlign: TextAlign.center),
                              ],
                              const SizedBox(height: AppSpacing.md),
                              AppButton(label: 'Guardar perfil', isLoading: _guardandoPerfil, onPressed: _guardandoPerfil ? null : _guardarPerfil),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        // Cambiar contraseña
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text('Cambiar contraseña', style: AppTypography.subtitulo),
                              const SizedBox(height: 4),
                              Text('Usá tu contraseña actual para confirmar el cambio.',
                                  style: AppTypography.texto.copyWith(fontSize: 12, color: AppColors.texto.withValues(alpha: 0.6))),
                              const SizedBox(height: AppSpacing.md),
                              AppTextField(label: 'Contraseña actual', controller: _oldCtrl, isPassword: true),
                              const SizedBox(height: AppSpacing.md),
                              AppTextField(label: 'Nueva contraseña', controller: _newCtrl, isPassword: true, helperText: 'Mínimo 6 caracteres'),
                              const SizedBox(height: AppSpacing.md),
                              AppTextField(label: 'Repetir nueva', controller: _repeatCtrl, isPassword: true),
                              if (_errorPass != null) ...[
                                const SizedBox(height: AppSpacing.sm),
                                Text(_errorPass!, style: AppTypography.texto.copyWith(color: AppColors.error), textAlign: TextAlign.center),
                              ],
                              if (_okPass != null) ...[
                                const SizedBox(height: AppSpacing.sm),
                                Text(_okPass!, style: AppTypography.texto.copyWith(color: Colors.green), textAlign: TextAlign.center),
                              ],
                              const SizedBox(height: AppSpacing.md),
                              AppButton(label: 'Actualizar contraseña', isLoading: _guardandoPass, onPressed: _guardandoPass ? null : _cambiarPass),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text('Acerca de', style: AppTypography.subtitulo),
                              const SizedBox(height: 4),
                              Text('PROSANE Salta — v1.0.0', style: AppTypography.texto.copyWith(fontSize: 12, color: AppColors.texto.withValues(alpha: 0.6))),
                              const SizedBox(height: 2),
                              Text('Si necesitás ayuda contactá a soporte.', style: AppTypography.texto.copyWith(fontSize: 12)),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
