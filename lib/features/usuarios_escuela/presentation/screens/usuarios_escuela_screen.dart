import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/app_dropdown_field.dart';
import '../../../../core/design_system/app_gradient_scaffold.dart';
import '../../../../core/design_system/app_switch.dart';
import '../../../../core/design_system/app_text_field.dart';
import '../../../../core/notificaciones/notificacion_controller.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../escuelas/presentation/controllers/escuelas_list_controller.dart';
import '../../data/usuarios_escuela_repository.dart';
import '../controllers/usuarios_escuela_controller.dart';

class UsuariosEscuelaScreen extends ConsumerWidget {
  const UsuariosEscuelaScreen({super.key});

  Future<void> _abrirFormulario(
    BuildContext context,
    WidgetRef ref, {
    UsuarioEscuela? usuario,
  }) async {
    final guardado = await showDialog<bool>(
      context: context,
      builder: (_) => UsuarioEscuelaFormDialog(usuario: usuario),
    );
    if (guardado == true) {
      ref.invalidate(usuariosEscuelaListProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuariosAsync = ref.watch(usuariosEscuelaListProvider);

    return AppGradientScaffold(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.blanco),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/inicio');
                    }
                  },
                ),
                Expanded(
                  child: Text('Usuarios de escuelas',
                      style: AppTypography.titulo
                          .copyWith(color: AppColors.blanco, fontSize: 24)),
                ),
              ],
            ),
          ),
          Expanded(
            child: usuariosAsync.when(
              data: (usuarios) {
                if (usuarios.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.manage_accounts_outlined,
                            size: 64,
                            color: AppColors.blanco.withValues(alpha: 0.3)),
                        const SizedBox(height: AppSpacing.md),
                        Text('No hay usuarios de escuelas',
                            style: AppTypography.subtitulo
                                .copyWith(color: AppColors.blanco)),
                        const SizedBox(height: AppSpacing.sm),
                        Text('Creá uno para asignarle una escuela',
                            style: AppTypography.texto.copyWith(
                                color:
                                    AppColors.blanco.withValues(alpha: 0.7))),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: usuarios.length,
                  itemBuilder: (context, i) {
                    final u = usuarios[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: AppCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(u.email,
                                      style: AppTypography.subtitulo,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Text(
                                    u.escuelaNombre?.isNotEmpty == true
                                        ? u.escuelaNombre!
                                        : 'Sin escuela asignada',
                                    style: AppTypography.texto.copyWith(
                                        fontSize: 12,
                                        color: AppColors.texto
                                            .withValues(alpha: 0.6)),
                                  ),
                                  if (!u.isActive) ...[
                                    const SizedBox(height: 4),
                                    Text('Cuenta desactivada',
                                        style: AppTypography.texto.copyWith(
                                            fontSize: 12,
                                            color: AppColors.error)),
                                  ],
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  color: AppColors.primario),
                              tooltip: 'Editar',
                              onPressed: () =>
                                  _abrirFormulario(context, ref, usuario: u),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(
                child: Text('Error: $e',
                    style:
                        AppTypography.texto.copyWith(color: AppColors.blanco)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
            child: AppButton(
              label: 'Nuevo usuario',
              onPressed: () => _abrirFormulario(context, ref),
            ),
          ),
        ],
      ),
    );
  }
}

class UsuarioEscuelaFormDialog extends ConsumerStatefulWidget {
  const UsuarioEscuelaFormDialog({super.key, this.usuario});

  /// Si viene, el diálogo edita; si es null, crea una cuenta nueva.
  final UsuarioEscuela? usuario;

  @override
  ConsumerState<UsuarioEscuelaFormDialog> createState() =>
      _UsuarioEscuelaFormDialogState();
}

class _UsuarioEscuelaFormDialogState
    extends ConsumerState<UsuarioEscuelaFormDialog> {
  late final TextEditingController _emailCtrl;
  late final TextEditingController _passwordCtrl;
  String? _escuelaId;
  late bool _isActive;
  String? _error;
  bool _guardando = false;

  bool get _esEdicion => widget.usuario != null;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.usuario?.email ?? '');
    _passwordCtrl = TextEditingController();
    _escuelaId = widget.usuario?.escuelaId;
    _isActive = widget.usuario?.isActive ?? true;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  bool get _puedeGuardar {
    final emailOk = _emailCtrl.text.trim().contains('@');
    final passwordOk =
        _esEdicion ? true : _passwordCtrl.text.trim().length >= 6;
    return emailOk && passwordOk && _escuelaId != null && !_guardando;
  }

  Future<void> _guardar() async {
    setState(() {
      _error = null;
      _guardando = true;
    });
    final repo = ref.read(usuariosEscuelaRepositoryProvider);
    try {
      if (_esEdicion) {
        final cambios = <String, dynamic>{
          'email': _emailCtrl.text.trim(),
          'escuela': _escuelaId,
          'is_active': _isActive,
        };
        final password = _passwordCtrl.text.trim();
        if (password.isNotEmpty) {
          if (password.length < 6) {
            throw Exception('La contraseña debe tener al menos 6 caracteres.');
          }
          cambios['password'] = password;
        }
        await repo.editar(widget.usuario!.id, cambios);
      } else {
        await repo.crear(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text.trim(),
          escuelaId: _escuelaId!,
        );
      }
      if (!mounted) return;
      ref.read(notificacionProvider.notifier).exito(
          _esEdicion ? '¡Usuario actualizado!' : '¡Usuario creado!');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final escuelasAsync = ref.watch(escuelasListControllerProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: SingleChildScrollView(
        child: AppCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_esEdicion ? 'Editar usuario' : 'Nuevo usuario de escuela',
                  style: AppTypography.titulo.copyWith(fontSize: 20)),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Email *',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: _esEdicion ? 'Nueva contraseña' : 'Contraseña *',
                hint: _esEdicion ? 'Dejar vacío para no cambiar' : null,
                controller: _passwordCtrl,
                isPassword: true,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.md),
              escuelasAsync.when(
                data: (escuelas) => AppDropdownField(
                  label: 'Escuela *',
                  value: _escuelaId,
                  items: [
                    for (final e in escuelas)
                      (value: e.id, label: e.nombre),
                  ],
                  onChanged: (v) => setState(() => _escuelaId = v),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Text('No se pudieron cargar las escuelas',
                    style: AppTypography.texto.copyWith(color: AppColors.error)),
              ),
              if (_esEdicion) ...[
                const SizedBox(height: AppSpacing.sm),
                AppSwitch(
                  label: 'Cuenta activa',
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(_error!,
                    style: AppTypography.texto.copyWith(color: AppColors.error),
                    textAlign: TextAlign.center),
              ],
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: 'Guardar',
                isLoading: _guardando,
                onPressed: _puedeGuardar ? _guardar : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed:
                    _guardando ? null : () => Navigator.of(context).pop(false),
                child: Text('Cancelar',
                    style: AppTypography.texto.copyWith(color: AppColors.link)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
