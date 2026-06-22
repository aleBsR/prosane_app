import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/database_provider.dart';

/// Suma los conteos de pendientes/error por feature. Función pura, testeable.
int contarPendientes(List<int> porFeature) => porFeature.fold(0, (a, b) => a + b);

/// Conteo global de ítems pendientes de sincronizar.
/// Lee el conteo de hijos pendientes desde Drift y lo suma con futuras features.
/// Los consumidores deben resolver el [AsyncValue] con `.value ?? 0` o similar.
final pendientesCountProvider = FutureProvider<int>((ref) async {
  final db = ref.watch(databaseProvider);
  final hijosCount = await db.contarHijosPendientes();
  return contarPendientes([hijosCount]);
});
