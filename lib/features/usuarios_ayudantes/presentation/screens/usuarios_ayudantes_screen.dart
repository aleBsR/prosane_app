import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/app_gradient_scaffold.dart';
import '../../../../core/design_system/app_switch.dart';
import '../../../../core/design_system/app_text_field.dart';
import '../../../../core/notificaciones/notificacion_controller.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/usuarios_ayudantes_repository.dart';
import '../controllers/usuarios_ayudantes_controller.dart';

class UsuariosAyudantesScreen extends ConsumerWidget {
  const UsuariosAyudantesScreen({super.key});

  Future<void> _abrirFormulario(
    BuildContext context,
    WidgetRef ref, {
    UsuarioAyudante? usuario,
  }) async {
    final guardado = await showDialog<bool>(
      context: context,
      builder: (_) => UsuarioAyudanteFormDialog(usuario: usuario),
    );
    if (guardado == true) {
      ref.invalidate(usuariosAyudantesListProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuariosAsync = ref.watch(usuariosAyudantesListProvider);

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
                  child: Text('Usuarios ayudantes',
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
                        Text('No hay usuarios ayudantes',
                            style: AppTypography.subtitulo
                                .copyWith(color: AppColors.blanco)),
                        const SizedBox(height: AppSpacing.sm),
                        Text('Creá uno para asignarle tareas de gestión',
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
                                    'Ayudante',
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

class UsuarioAyudanteFormDialog extends ConsumerStatefulWidget {
  const UsuarioAyudanteFormDialog({super.key, this.usuario});

  /// Si viene, el diálogo edita; si es null, crea una cuenta nueva.
  final UsuarioAyudante? usuario;

  @override
  ConsumerState<UsuarioAyudanteFormDialog> createState() =>
      _UsuarioAyudanteFormDialogState();
}

class _UsuarioAyudanteFormDialogState
    extends ConsumerState<UsuarioAyudanteFormDialog> {
  late final TextEditingController _emailCtrl;
  late bool _isActive;
  String? _error;
  bool _guardando = false;
  bool _reenvizando = false;

  bool get _esEdicion => widget.usuario != null;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.usuario?.email ?? '');
    _isActive = widget.usuario?.isActive ?? true;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  bool get _puedeGuardar {
    final emailOk = _emailCtrl.text.trim().contains('@');
    return emailOk && !_guardando;
  }

  Future<void> _guardar() async {
    setState(() {
      _error = null;
      _guardando = true;
    });
    final repo = ref.read(usuariosAyudantesRepositoryProvider);
    try {
      if (_esEdicion) {
        final cambios = <String, dynamic>{
          'email': _emailCtrl.text.trim(),
          'is_active': _isActive,
        };
        await repo.editar(widget.usuario!.id, cambios);
      } else {
        await repo.crear(
          email: _emailCtrl.text.trim(),
        );
      }
      if (!mounted) return;
      ref.read(notificacionProvider.notifier).exito(
          _esEdicion ? '¡Usuario actualizado!' : '¡Usuario creado! Se envió temporal por mail (72h).');
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
      await ref.read(usuariosAyudantesRepositoryProvider).reenviarTemporal(widget.usuario!.id);
      if (!mounted) return;
      ref.read(notificacionProvider.notifier).exito('Temporal reenviada (72h).');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _reenvizando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: SingleChildScrollView(
        child: AppCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_esEdicion ? 'Editar usuario' : 'Nuevo usuario ayudante',
                  style: AppTypography.titulo.copyWith(fontSize: 20)),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Email *',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => setState(() {}),
              ),
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
                        child: Text('Se enviará contraseña temporal por mail (72h).',
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
                      child: Text('La contraseña solo la cambia el usuario. No es visible.',
                          style: AppTypography.texto.copyWith(fontSize: 11, color: Color(0xFF2E7D32))),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    OutlinedButton.icon(
                      onPressed: _reenvizando ? null : _reenviar,
                      icon: _reenvizando
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.refresh, size: 16),
                      label: Text(_reenvizando ? 'Reenviando...' : 'Reenviar temporal (72h)'),
                    ),
                  ],
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