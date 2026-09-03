import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';

import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/app_gradient_scaffold.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/providers.dart';

class ConstanciaScreen extends ConsumerStatefulWidget {
  const ConstanciaScreen({super.key, required this.operativoId, required this.alumnoId});
  final String operativoId;
  final String alumnoId;

  @override
  ConsumerState<ConstanciaScreen> createState() => _ConstanciaScreenState();
}

class _ConstanciaScreenState extends ConsumerState<ConstanciaScreen> {
  Uint8List? _pdfBytes;
  String? _error;
  bool _cargando = true;
  String? _alumnoNombre;
  String? _alumnoDni;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      // Precargar nombre/dni del alumno para filename amigable
      try {
        final repo = ref.read(operativosRepositoryProvider);
        final alumnos = await repo.listarAlumnos(widget.operativoId);
        final match = alumnos.firstWhere((a) => a['id'].toString() == widget.alumnoId, orElse: () => {});
        if (match.isNotEmpty) {
          _alumnoNombre = '${match['apellido'] ?? ''}_${match['nombre'] ?? ''}'.trim();
          _alumnoDni = match['dni']?.toString();
        }
      } catch (_) {}
      final repo = ref.read(operativosRepositoryProvider);
      final bytes = await repo.getConstanciaPdf(widget.operativoId, widget.alumnoId);
      if (!mounted) return;
      setState(() {
        _pdfBytes = Uint8List.fromList(bytes);
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _humanError(e);
        _cargando = false;
      });
    }
  }

  String _humanError(Object e) {
    final s = e.toString();
    if (s.contains('409')) return 'La constancia solo está disponible cuando el operativo está finalizado.';
    if (s.contains('404')) return 'Alumno u operativo no encontrado.';
    if (s.contains('403')) return 'No tenés permiso para ver esta constancia.';
    return 'No se pudo cargar la constancia. Verificá tu conexión e intentá nuevamente.';
  }

  Future<String> _guardarTemp(Uint8List bytes, String nombre) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$nombre');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<void> _compartir() async {
    if (_pdfBytes == null) return;
    final dni = _alumnoDni ?? widget.alumnoId;
    final path = await _guardarTemp(_pdfBytes!, 'constancia-$dni.pdf');
    await Share.shareXFiles([XFile(path)], text: 'Constancia PROSANE — DNI $dni');
  }

  Future<void> _abrir() async {
    if (_pdfBytes == null) return;
    final dni = _alumnoDni ?? widget.alumnoId;
    final path = await _guardarTemp(_pdfBytes!, 'constancia-$dni.pdf');
    await OpenFilex.open(path);
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
                onPressed: () {
                  if (context.canPop()) context.pop();
                  else context.go('/operativos/${widget.operativoId}');
                },
              ),
              Expanded(
                child: Text('Constancia',
                    style: AppTypography.titulo.copyWith(color: AppColors.blanco, fontSize: 22)),
              ),
            ]),
          ),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator(color: AppColors.blanco))
                : _error != null
                    ? Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: AppCard(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                              const SizedBox(height: AppSpacing.md),
                              Text(_error!, style: AppTypography.texto, textAlign: TextAlign.center),
                              const SizedBox(height: AppSpacing.md),
                              AppButton(label: 'Reintentar', onPressed: _cargar),
                            ],
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppCard(
                              child: Column(
                                children: [
                                  const Icon(Icons.picture_as_pdf, size: 48, color: AppColors.primario),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text('Constancia lista',
                                      style: AppTypography.subtitulo.copyWith(color: AppColors.primario)),
                                  const SizedBox(height: 4),
                                  Text(
                                    _alumnoNombre != null && _alumnoNombre!.isNotEmpty
                                        ? 'Alumno: $_alumnoNombre — DNI ${_alumnoDni ?? ''}'
                                        : 'DNI ${_alumnoDni ?? widget.alumnoId}',
                                    style: AppTypography.texto.copyWith(fontSize: 12, color: AppColors.texto.withValues(alpha: 0.6)),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 2),
                                  Text('${(_pdfBytes!.length / 1024).toStringAsFixed(0)} KB',
                                      style: AppTypography.texto.copyWith(fontSize: 11, color: AppColors.texto.withValues(alpha: 0.5))),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AppCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  AppButton(label: 'Abrir PDF', onPressed: _abrir),
                                  const SizedBox(height: AppSpacing.sm),
                                  AppButton(label: 'Compartir', onPressed: _compartir),
                                  const SizedBox(height: AppSpacing.sm),
                                  TextButton(
                                    onPressed: _cargar,
                                    child: Text('Volver a cargar', style: AppTypography.texto.copyWith(color: AppColors.link)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Center(
                              child: Container(
                                constraints: const BoxConstraints(maxWidth: 320),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFF66BB6A)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.verified_outlined, size: 14, color: Color(0xFF2E7D32)),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text('Documento generado desde operativo finalizado — PROSANE Salta',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32))),
                                    ),
                                  ],
                                ),
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
