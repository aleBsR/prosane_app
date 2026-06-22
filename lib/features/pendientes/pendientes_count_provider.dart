import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/database_provider.dart';
import '../../core/database/sync_columns.dart';
import '../../core/session/entities.dart';
import '../../core/session/session_controller.dart';

/// Suma los conteos de pendientes/error por feature. Función pura, testeable.
int contarPendientes(List<int> porFeature) =>
    porFeature.fold(0, (a, b) => a + b);

/// Badge de 'Pendientes' = borradores sin sincronizar + (1 si el tutor todavía
/// no registró ningún hijo → consentimiento pendiente). Función pura, testeable.
int calcularBadgePendientes({
  required int borradores,
  required int totalHijos,
  required bool esTutor,
}) {
  final consentimientoPendiente = (esTutor && totalHijos == 0) ? 1 : 0;
  return contarPendientes([borradores, consentimientoPendiente]);
}

/// Conteo global de ítems pendientes, **reactivo**: emite un valor nuevo ante
/// cualquier cambio en la tabla de hijos (alta/baja/sync) o en la sesión.
/// Los consumidores resuelven el [AsyncValue] con `.value ?? 0`.
final pendientesCountProvider = StreamProvider<int>((ref) {
  final db = ref.watch(databaseProvider);
  final session = ref.watch(sessionControllerProvider);
  final esTutor =
      session is SesionAutenticada && session.sesion.usuario.rolName == 'tutor';

  return db.watchHijosVivos().map((hijos) {
    final borradores = hijos
        .where((h) => h.syncStatus == SyncStatus.pendiente)
        .length;
    return calcularBadgePendientes(
      borradores: borradores,
      totalHijos: hijos.length,
      esTutor: esTutor,
    );
  });
});
