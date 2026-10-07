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

/// Edición de datos personales (nombre y apellido). Extraído de la antigua
/// pantalla única de Configuración: ahora se entra desde el hub con el botón
/// "Datos personales".
class DatosPersonalesScreen extends ConsumerStatefulWidget {
  const DatosPersonalesScreen({super.key});
  @override
  ConsumerState<DatosPersonalesScreen> createState() => _DatosPersonalesScreenState();
}

class _DatosPersonalesScreenState extends ConsumerState<DatosPersonalesScreen> {
  bool _cargando = true;
  bool _guardando = false;
  String? _error;
  String? _ok;

  late TextEditingController _nombreCtrl;
  late TextEditingController _apellidoCtrl;
  String _email = '';
  String _escuela = '';
  String _rolLabel = '';

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
    super.dispose();
  }

  Future<void> _cargarPerfil() async {
    setState(() {
      _cargando = true;
      _error = null;
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
        _escuela = (user['escuela_nombre'] ?? '').toString();
        final roles = data['roles'] as List?;
        if (roles != null && roles.isNotEmpty) {
          _rolLabel = (roles.first['label'] ?? '').toString();
        }
        _cargando = false;
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
        _cargando = false;
        _error = _humanError(e);
      });
    }
  }

  String _humanError(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
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

  Future<void> _guardar() async {
    final nombre = _nombreCtrl.text.trim();
    final apellido = _apellidoCtrl.text.trim();
    if (nombre.isEmpty && apellido.isEmpty) {
      setState(() => _error = 'Ingresá al menos nombre o apellido.');
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
      _ok = null;
    });
    try {
      final repo = ref.read(usuarioRepositoryProvider);
      final data = await repo.patchMe(nombre: nombre, apellido: apellido);
      if (!mounted) return;
      setState(() {
        _ok = 'Perfil actualizado.';
        _guardando = false;
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
    if (mounted && _guardando) setState(() => _guardando = false);
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
                child: Text('Datos personales',
                    style: AppTypography.titulo.copyWith(color: AppColors.blanco, fontSize: 22)),
              ),
            ]),
          ),
          Expanded(
            child: _cargando
                ?  Center(child: CircularProgressIndicator(color: AppColors.blanco))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
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
                          if (_error != null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Text(_error!, style: AppTypography.texto.copyWith(color: AppColors.error), textAlign: TextAlign.center),
                          ],
                          if (_ok != null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Text(_ok!, style: AppTypography.texto.copyWith(color: Colors.green), textAlign: TextAlign.center),
                          ],
                          const SizedBox(height: AppSpacing.md),
                          AppButton(label: 'Guardar', isLoading: _guardando, onPressed: _guardando ? null : _guardar),
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
