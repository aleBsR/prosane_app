import 'feature_syncer.dart';

/// Orquesta la sincronización local↔remoto. Las features no orquestan red:
/// escriben local; este engine empuja (push) y trae (pull) por separado.
class SyncEngine {
  SyncEngine(this._syncers);
  final List<FeatureSyncer> _syncers;

  Future<void> ciclo({required DateTime ahora}) async {
    // Push y pull son fases independientes: un fallo del push no debe impedir
    // bajar cambios del servidor.
    try {
      await cicloPush();
    } catch (_) {
      // se ignora; el pull corre igual
    }
    await cicloPull(ahora: ahora);
  }

  /// INVARIANTE: confirmación fila-por-fila. Solo `ok` se marca sincronizado;
  /// `transitorio` queda pendiente (reintenta), `permanente` lo marca la feature.
  Future<void> cicloPush() async {
    for (final s in _syncers) {
      try {
        final pendientes = await s.idsPendientes();
        if (pendientes.isEmpty) continue;
        final resultados = await s.pushLote(pendientes);
        for (final r in resultados) {
          if (r.outcome == PushOutcome.ok) {
            await s.marcarSincronizado(r.id);
          }
        }
      } catch (_) {
        // Simétrico con cicloPull: un fallo inesperado (DB/red) en una feature
        // no aborta a las demás. Las filas sin confirmar quedan pendientes y se
        // reintentan el próximo ciclo (el push es idempotente por UUID).
        continue;
      }
    }
  }

  /// INVARIANTE: el watermark avanza SOLO si el merge commitea entero. Si una
  /// feature falla, no se mueve su watermark ni se aborta a las demás.
  Future<void> cicloPull({required DateTime ahora}) async {
    for (final s in _syncers) {
      try {
        final since = await s.getWatermark();
        await s.pullDesdeYMergear(since); // si lanza, NO se llega a setWatermark
        await s.setWatermark(ahora);
      } catch (_) {
        continue; // reintenta el próximo ciclo; no toca el watermark
      }
    }
  }
}
