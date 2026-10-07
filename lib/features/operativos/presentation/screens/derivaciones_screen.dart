import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/app_gradient_scaffold.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Derivaciones generadas en un operativo (Anexo I 4.6).
/// Agrega las derivaciones de las evaluaciones médicas, con filtro por
/// especialidad. Visible para admin y profesionales de sus operativos.
class DerivacionesScreen extends ConsumerStatefulWidget {
  const DerivacionesScreen({super.key, required this.operativoId});
  final String operativoId;

  @override
  ConsumerState<DerivacionesScreen> createState() => _DerivacionesScreenState();
}

const _especialidades = <String, String>{
  '': 'Todas',
  'odontologia': 'Odontología',
  'oftalmologia': 'Oftalmología',
  'nutricion': 'Nutrición',
  'vacunatorio': 'Vacunatorio',
  'pediatria': 'Pediatría',
  'fonoaudiologia': 'Fonoaudiología',
};

class _DerivacionesScreenState extends ConsumerState<DerivacionesScreen> {
  String _filtro = '';
  Map<String, dynamic>? _datos;
  bool _cargando = true;
  String? _error;

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
      final repo = ref.read(operativosRepositoryProvider);
      final datos = await repo.getDerivaciones(widget.operativoId,
          especialidad: _filtro.isEmpty ? null : _filtro);
      if (!mounted) return;
      setState(() {
        _datos = datos;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudieron cargar las derivaciones';
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ((_datos?['derivaciones'] as List?) ?? []).cast<Map>();
    return AppGradientScaffold(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 120),
        children: [
          Row(children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            Expanded(
              child: Text('Derivaciones',
                  style: AppTypography.titulo
                      .copyWith(fontSize: 24, color: Colors.white)),
            ),
          ]),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Especialidad', style: AppTypography.subtitulo),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final entry in _especialidades.entries)
                      _FiltroChip(
                        label: entry.value,
                        selected: _filtro == entry.key,
                        onTap: () {
                          setState(() => _filtro = entry.key);
                          _cargar();
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _cargando
                      ? 'Cargando…'
                      : '${_datos?['total'] ?? 0} derivaciones',
                  style: AppTypography.texto.copyWith(
                      color: AppColors.texto.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_cargando)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            AppCard(child: Text(_error!, style: AppTypography.texto))
          else if (items.isEmpty)
            AppCard(
              child: Text('Sin derivaciones registradas',
                  style: AppTypography.texto.copyWith(
                      color: AppColors.texto.withValues(alpha: 0.6))),
            )
          else ...[
            for (final d in items)
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${d['apellido']}, ${d['nombre']}',
                        style: AppTypography.subtitulo),
                    const SizedBox(height: 4),
                    Text(
                      'DNI ${d['dni']}${(d['curso'] as String? ?? '').isNotEmpty ? " · ${d['curso']}" : ''}',
                      style: AppTypography.texto.copyWith(
                          color:
                              AppColors.texto.withValues(alpha: 0.6)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${d['especialidad_label'] ?? d['especialidad']}',
                      style: AppTypography.texto.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.aviso),
                    ),
                    if ((d['motivo'] as String? ?? '').isNotEmpty)
                      Text('${d['motivo']}',
                          style: AppTypography.texto),
                    if ((d['profesional'] as String? ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('Deriva: ${d['profesional']}',
                            style: AppTypography.texto.copyWith(
                                fontSize: 11,
                                color: AppColors.texto
                                    .withValues(alpha: 0.6))),
                      ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Píldora de filtro al estilo de la app: fondo primario sólido con texto
/// blanco si está elegida, campo con texto normal si no. Legible en ambos modos.
class _FiltroChip extends StatelessWidget {
  const _FiltroChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primario : AppColors.campo,
          borderRadius: BorderRadius.circular(20),
          border: selected
              ? null
              : Border.all(
                  color: AppColors.texto.withValues(alpha: 0.2)),
        ),
        child: Text(
          label,
          style: AppTypography.texto.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.texto,
          ),
        ),
      ),
    );
  }
}
