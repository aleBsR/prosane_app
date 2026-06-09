/// Resultado del push de UNA fila.
enum PushOutcome { ok, transitorio, permanente }

class PushItemResult {
  PushItemResult(this.id, this.outcome);
  final String id;
  final PushOutcome outcome;
}

/// Contrato que cada feature real implementa para enchufarse al [SyncEngine].
abstract class FeatureSyncer {
  String get feature;
  Future<List<String>> idsPendientes();
  Future<List<PushItemResult>> pushLote(List<String> ids);
  Future<void> marcarSincronizado(String id);
  Future<DateTime?> getWatermark();
  Future<void> setWatermark(DateTime ts);

  /// Baja lo cambiado desde [since] y mergea (LWW) DENTRO de una transacción.
  /// Si lanza, el engine NO avanza el watermark.
  Future<void> pullDesdeYMergear(DateTime? since);
}
