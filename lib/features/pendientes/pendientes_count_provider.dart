import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Suma los conteos de pendientes/error por feature. Función pura, testeable.
int contarPendientes(List<int> porFeature) => porFeature.fold(0, (a, b) => a + b);

/// Conteo global de ítems pendientes de sincronizar. Hoy NO hay tablas de feature
/// reales (apto_físico diferido) → 0 → el badge no se muestra (invariante #3).
/// Cuando exista la primera feature, se suman acá sus conteos desde Drift.
final pendientesCountProvider = Provider<int>((ref) => contarPendientes(const []));
