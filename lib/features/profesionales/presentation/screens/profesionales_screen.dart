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
import '../../data/profesionales_repository.dart';
import '../controllers/profesionales_controller.dart';

const _rolOptions = [
  (value: 'medico', label: 'Médico'),
  (value: 'odontologo', label: 'Odontólogo'),
];

String _rolLabel(String rol) {
  for (final o in _rolOptions) {
    if (o.value == rol) return o.label;
  }
  return rol;
}

class ProfesionalesScreen extends ConsumerWidget {
  const ProfesionalesScreen({super.key});

  Future<void> _abrirFormulario(
    BuildContext context,
    WidgetRef ref, {
    Profesional? profesional,
  }) async {
    final guardado = await showDialog<bool>(
      context: context,
      builder: (_) => ProfesionalFormDialog(profesional: profesional),
    );
    if (guardado == true) {
      ref.invalidate(profesionalesListProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profesionalesAsync = ref.watch(profesionalesListProvider);

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
                  child: Text('Profesionales',
                      style: AppTypography.titulo
                          .copyWith(color: AppColors.blanco, fontSize: 24)),
                ),
              ],
            ),
          ),
          Expanded(
            child: profesionalesAsync.when(
              data: (profesionales) {
                if (profesionales.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.medical_services_outlined,
                            size: 64,
                            color: AppColors.blanco.withValues(alpha: 0.3)),
                        const SizedBox(height: AppSpacing.md),
                        Text('No hay profesionales',
                            style: AppTypography.subtitulo
                                .copyWith(color: AppColors.blanco)),
                        const SizedBox(height: AppSpacing.sm),
                        Text('Creá una cuenta para médico u odontólogo',
                            style: AppTypography.texto.copyWith(
                                color:
                                    AppColors.blanco.withValues(alpha: 0.7))),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: profesionales.length,
                  itemBuilder: (context, i) {
                    final p = profesionales[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: AppCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.nombreCompleto,
                                      style: AppTypography.subtitulo,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Text(
                                    p.email,
                                    style: AppTypography.texto.copyWith(
                                        fontSize: 12,
                                        color: AppColors.texto
                                            .withValues(alpha: 0.6)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_rolLabel(p.rol)} · Mat. ${p.matricula}',
                                    style: AppTypography.texto.copyWith(
                                        fontSize: 12,
                                        color: AppColors.texto
                                            .withValues(alpha: 0.6)),
                                  ),
                                  if (!p.isActive) ...[
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
                              onPressed: () => _abrirFormulario(context, ref,
                                  profesional: p),
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
                    style: AppTypography.texto
                        .copyWith(color: AppColors.blanco)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
            child: AppButton(
              label: 'Nuevo profesional',
              onPressed: () => _abrirFormulario(context, ref),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfesionalFormDialog extends ConsumerStatefulWidget {
  const ProfesionalFormDialog({super.key, this.profesional});

  /// Si viene, el diálogo edita; si es null, crea una cuenta nueva.
  final Profesional? profesional;

  @override
  ConsumerState<ProfesionalFormDialog> createState() =>
      _ProfesionalFormDialogState();
}

class _ProfesionalFormDialogState
    extends ConsumerState<ProfesionalFormDialog> {
  late final TextEditingController _emailCtrl;
  late final TextEditingController _passwordCtrl;
  late final TextEditingController _matriculaCtrl;
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _apellidoCtrl;
  String? _rol;
  late bool _isActive;
  String? _error;
  bool _guardando = false;
  bool _validando = false;

  bool get _esEdicion => widget.profesional != null;

  @override
  void initState() {
    super.initState();
    final p = widget.profesional;
    _emailCtrl = TextEditingController(text: p?.email ?? '');
    _passwordCtrl = TextEditingController();
    _matriculaCtrl = TextEditingController(text: p?.matricula ?? '');
    _nombreCtrl = TextEditingController(text: p?.nombre ?? '');
    _apellidoCtrl = TextEditingController(text: p?.apellido ?? '');
    _rol = p?.rol;
    _isActive = p?.isActive ?? true;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _matriculaCtrl.dispose();
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    super.dispose();
  }

  bool get _puedeGuardar {
    final emailOk = _emailCtrl.text.trim().contains('@');
    final matriculaOk = _matriculaCtrl.text.trim().isNotEmpty;
    final rolOk = _rol != null && _rol!.isNotEmpty;
    final passwordOk = _esEdicion
        ? true
        : _passwordCtrl.text.trim().length >= 6;
    return emailOk && matriculaOk && rolOk && passwordOk &&
        !_guardando && !_validando;
  }

  /// Valida la matrícula contra REFEPS y autocompleta nombre/apellido (y el rol
  /// si aún no se eligió). Si REFEPS está caído o no encuentra la matrícula,
  /// muestra el mensaje y deja cargar los datos de forma manual.
  Future<void> _validarMatricula() async {
    final matricula = _matriculaCtrl.text.trim();
    if (matricula.isEmpty) return;
    setState(() {
      _validando = true;
      _error = null;
    });
    final repo = ref.read(profesionalesRepositoryProvider);
    try {
      final datos = await repo.validarMatricula(matricula);
      if (!mounted) return;
      setState(() {
        if (_nombreCtrl.text.trim().isEmpty) {
          _nombreCtrl.text = datos.nombre;
        }
        if (_apellidoCtrl.text.trim().isEmpty) {
          _apellidoCtrl.text = datos.apellido;
        }
        _rol ??= _rolSugerido(datos.profesion);
        _validando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _validando = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String? _rolSugerido(String profesion) {
    final p = profesion.toLowerCase();
    if (p.contains('médico') || p.contains('medico')) return 'medico';
    if (p.contains('odont')) return 'odontologo';
    return null;
  }

  Future<void> _guardar() async {
    setState(() {
      _error = null;
      _guardando = true;
    });
    final repo = ref.read(profesionalesRepositoryProvider);
    try {
      if (_esEdicion) {
        final cambios = <String, dynamic>{
          'email': _emailCtrl.text.trim(),
          'rol': _rol,
          'matricula': _matriculaCtrl.text.trim(),
          'nombre': _nombreCtrl.text.trim(),
          'apellido': _apellidoCtrl.text.trim(),
          'is_active': _isActive,
        };
        final password = _passwordCtrl.text.trim();
        if (password.isNotEmpty) {
          if (password.length < 6) {
            throw Exception('La contraseña debe tener al menos 6 caracteres.');
          }
          cambios['password'] = password;
        }
        await repo.editar(widget.profesional!.id, cambios);
      } else {
        await repo.crear(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text.trim(),
          rol: _rol!,
          matricula: _matriculaCtrl.text.trim(),
          nombre: _nombreCtrl.text.trim(),
          apellido: _apellidoCtrl.text.trim(),
        );
      }
      if (!mounted) return;
      ref.read(notificacionProvider.notifier).exito(
          _esEdicion ? '¡Profesional actualizado!' : '¡Profesional creado!');
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
    return Dialog(
      backgroundColor: Colors.transparent,
      child: SingleChildScrollView(
        child: AppCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                  _esEdicion ? 'Editar profesional' : 'Nuevo profesional',
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

              AppDropdownField(
                label: 'Rol *',
                value: _rol,
                items: _rolOptions,
                onChanged: (v) => setState(() => _rol = v),
              ),
              const SizedBox(height: AppSpacing.md),

              // Matrícula + botón Validar (autocompleta desde REFEPS)
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Matrícula *',
                      hint: 'Ingresá el número de matrícula',
                      controller: _matriculaCtrl,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  SizedBox(
                    height: 52,
                    child: TextButton(
                      onPressed: _validando ||
                              _matriculaCtrl.text.trim().isEmpty
                          ? null
                          : _validarMatricula,
                      style: TextButton.styleFrom(
                        foregroundColor: _validando
                            ? null
                            : AppColors.primario,
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md),
                      ),
                      child: _validando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Validar'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              AppTextField(
                label: 'Nombre',
                hint: 'Se autocompleta por matrícula',
                controller: _nombreCtrl,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.md),

              AppTextField(
                label: 'Apellido',
                hint: 'Se autocompleta por matrícula',
                controller: _apellidoCtrl,
                onChanged: (_) => setState(() {}),
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
                onPressed: (_guardando || _validando)
                    ? null
                    : () => Navigator.of(context).pop(false),
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
