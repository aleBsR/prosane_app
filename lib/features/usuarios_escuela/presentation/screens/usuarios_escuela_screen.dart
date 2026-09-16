import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/app_dialog.dart';
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
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert,
                                  color: AppColors.texto),
                              onSelected: (valor) {
                                if (valor == 'editar') {
                                  _abrirFormulario(context, ref, usuario: u);
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'editar',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_outlined,
                                          size: 18,
                                          color: AppColors.primario),
                                      SizedBox(width: 8),
                                      Text('Editar'),
                                    ],
                                  ),
                                ),
                              ],
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
  late final TextEditingController _emailConfirmCtrl;
  String? _escuelaId;
  bool _escuelaOriginalInvalida = false;
  late bool _isActive;
  String? _error;
  bool _guardando = false;
  bool _reenvizando = false;

  bool get _esEdicion => widget.usuario != null;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.usuario?.email ?? '');
    _emailConfirmCtrl = TextEditingController();
    _escuelaId = widget.usuario?.escuelaId;
    _isActive = widget.usuario?.isActive ?? true;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _emailConfirmCtrl.dispose();
    super.dispose();
  }

  /// Los correos deben coincidir (solo en alta; en edición no se pide repetir).
  bool get _emailsCoinciden {
    if (_esEdicion) return true;
    return _emailCtrl.text.trim().toLowerCase() ==
        _emailConfirmCtrl.text.trim().toLowerCase();
  }

  bool get _puedeGuardar {
    final emailOk = _emailCtrl.text.trim().contains('@');
    return emailOk && _emailsCoinciden && _escuelaId != null && !_guardando;
  }

  Future<void> _guardar() async {
    if (!_emailsCoinciden) {
      setState(() => _error = 'Los correos no coinciden. Revisalos antes de guardar.');
      return;
    }
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
        await repo.editar(widget.usuario!.id, cambios);
      } else {
        await repo.crear(
          email: _emailCtrl.text.trim(),
          escuelaId: _escuelaId!,
        );
      }
      if (!mounted) return;
      ref.read(notificacionProvider.notifier).exito(
          _esEdicion ? '¡Usuario actualizado!' : '¡Usuario creado! Se envió contraseña temporal por mail (72h).');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _reenviar() async {
    if (!_esEdicion) return;
    setState(() => _reenvizando = true);
    try {
      await ref.read(usuariosEscuelaRepositoryProvider).reenviarTemporal(widget.usuario!.id);
      if (!mounted) return;
      ref.read(notificacionProvider.notifier).exito('Contraseña temporal reenviada por mail (72h).');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _reenvizando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final escuelasAsync = ref.watch(escuelasListControllerProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: kWideDialogInset,
      child: SingleChildScrollView(
        child: SizedBox(
          width: wideDialogWidth(context),
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
              if (!_esEdicion) ...[
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Repetir email *',
                  controller: _emailConfirmCtrl,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) => setState(() {}),
                  errorText: !_emailsCoinciden &&
                          _emailConfirmCtrl.text.isNotEmpty
                      ? 'Los correos no coinciden'
                      : null,
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              if (!_esEdicion)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF66BB6A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.mail_outline, size: 16, color: Color(0xFF2E7D32)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Se enviará contraseña temporal por mail (vence en 72h). El usuario deberá cambiarla al primer ingreso.',
                            style: AppTypography.texto.copyWith(fontSize: 11, color: Color(0xFF2E7D32))),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF66BB6A)),
                      ),
                      child: Text('La contraseña solo la gestiona el propio usuario. No es visible para el admin.',
                          style: AppTypography.texto.copyWith(fontSize: 11, color: Color(0xFF2E7D32))),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    OutlinedButton.icon(
                      onPressed: _reenvizando ? null : _reenviar,
                      icon: _reenvizando
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.refresh, size: 16),
                      label: Text(_reenvizando ? 'Reenviando...' : 'Reenviar contraseña temporal (72h)'),
                    ),
                  ],
                ),
              const SizedBox(height: AppSpacing.md),
              escuelasAsync.when(
                data: (escuelas) {
                  // Si la escuela asignada ya no está disponible (ej. fue
                  // eliminada/desactivada), el valor no existe en la lista y
                  // rompería el desplegable: se limpia y se pide elegir otra.
                  final escuelaValida = _escuelaId == null ||
                      escuelas.any((e) => e.id == _escuelaId);
                  if (!escuelaValida) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _escuelaId = null;
                          _escuelaOriginalInvalida = true;
                        });
                      }
                    });
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_esEdicion &&
                          _escuelaOriginalInvalida &&
                          _escuelaId == null) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.warning_amber_outlined,
                                color: AppColors.error, size: 18),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'La escuela asignada ya no está disponible: elegí una nueva.',
                                style: AppTypography.texto.copyWith(
                                    fontSize: 12, color: AppColors.error),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                      AppDropdownField(
                        label: 'Escuela *',
                        value: escuelaValida ? _escuelaId : null,
                        items: [
                          for (final e in escuelas)
                            (value: e.id, label: e.nombre),
                        ],
                        onChanged: (v) => setState(() => _escuelaId = v),
                      ),
                    ],
                  );
                },
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
      ),
    );
  }
}
