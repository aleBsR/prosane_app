import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/sync/feature_syncer.dart';
import 'package:prosane_app/core/sync/sync_engine.dart';

class _FakeSyncer implements FeatureSyncer {
  _FakeSyncer({
    this.feature = 'fake',
    List<String> pendientes = const [],
    Map<String, PushOutcome> resultados = const {},
    this.pullThrows = false,
    this.pushLoteThrows = false,
    DateTime? watermarkInicial,
  })  : _pendientes = pendientes,
        _resultados = resultados,
        _watermark = watermarkInicial;

  @override
  final String feature;
  final List<String> _pendientes;
  final Map<String, PushOutcome> _resultados;
  final bool pullThrows;
  final bool pushLoteThrows;
  DateTime? _watermark;

  final List<String> marcadosSincronizados = [];
  int pullLlamado = 0;
  int pushLoteLlamado = 0;
  DateTime? pullRecibioSince;

  @override
  Future<List<String>> idsPendientes() async => List.of(_pendientes);
  @override
  Future<List<PushItemResult>> pushLote(List<String> ids) async {
    pushLoteLlamado++;
    if (pushLoteThrows) throw Exception('push falló');
    return ids
        .map((id) => PushItemResult(id, _resultados[id] ?? PushOutcome.ok))
        .toList();
  }

  @override
  Future<void> marcarSincronizado(String id) async =>
      marcadosSincronizados.add(id);
  @override
  Future<DateTime?> getWatermark() async => _watermark;
  @override
  Future<void> setWatermark(DateTime ts) async => _watermark = ts;
  @override
  Future<void> pullDesdeYMergear(DateTime? since) async {
    pullLlamado++;
    pullRecibioSince = since;
    if (pullThrows) throw Exception('pull falló');
  }
}

void main() {
  test('push confirma fila-por-fila: solo ok queda sincronizado', () async {
    final s = _FakeSyncer(pendientes: ['a', 'b', 'c'], resultados: {
      'a': PushOutcome.ok,
      'b': PushOutcome.transitorio,
      'c': PushOutcome.permanente,
    });
    await SyncEngine([s]).cicloPush();
    expect(s.marcadosSincronizados, ['a']); // b y c NO
  });

  test('watermark NO avanza si el pull lanza', () async {
    final s = _FakeSyncer(pullThrows: true, watermarkInicial: DateTime.utc(2026, 1, 1));
    await SyncEngine([s]).cicloPull(ahora: DateTime.utc(2026, 6, 1));
    expect(await s.getWatermark(), DateTime.utc(2026, 1, 1)); // sin cambios
  });

  test('watermark avanza a `ahora` si el pull commitea', () async {
    final s = _FakeSyncer();
    await SyncEngine([s]).cicloPull(ahora: DateTime.utc(2026, 6, 1));
    expect(await s.getWatermark(), DateTime.utc(2026, 6, 1));
  });

  test('el pull recibe el watermark previo como `since`', () async {
    final s = _FakeSyncer(watermarkInicial: DateTime.utc(2026, 3, 1));
    await SyncEngine([s]).cicloPull(ahora: DateTime.utc(2026, 6, 1));
    expect(s.pullRecibioSince, DateTime.utc(2026, 3, 1));
  });

  test('el fallo de una feature no aborta a las demás (watermark por feature)',
      () async {
    final malo = _FakeSyncer(
        feature: 'malo', pullThrows: true, watermarkInicial: DateTime.utc(2026, 1, 1));
    final bueno = _FakeSyncer(feature: 'bueno');
    await SyncEngine([malo, bueno]).cicloPull(ahora: DateTime.utc(2026, 6, 1));
    expect(await malo.getWatermark(), DateTime.utc(2026, 1, 1)); // no avanzó
    expect(await bueno.getWatermark(), DateTime.utc(2026, 6, 1)); // sí avanzó
  });

  test('cicloPush no llama pushLote si no hay pendientes', () async {
    final s = _FakeSyncer(pendientes: const []);
    await SyncEngine([s]).cicloPush();
    expect(s.marcadosSincronizados, isEmpty);
  });

  // --- Tests agregados más allá del mínimo ---

  test('cicloPush no llama pushLote (efecto observable) sin pendientes', () async {
    // Refuerza el invariante de short-circuit: pushLote NO debe invocarse,
    // no sólo que no haya marcados (que también sería cierto con lista vacía).
    final s = _FakeSyncer(pendientes: const []);
    await SyncEngine([s]).cicloPush();
    expect(s.pushLoteLlamado, 0);
  });

  test('si el pull commitea, el watermark NO queda en el valor previo', () async {
    // Asegura que un setWatermark omitido por error se detecte (no sólo ==ahora).
    final s = _FakeSyncer(watermarkInicial: DateTime.utc(2025, 1, 1));
    await SyncEngine([s]).cicloPull(ahora: DateTime.utc(2026, 6, 1));
    expect(await s.getWatermark(), isNot(DateTime.utc(2025, 1, 1)));
    expect(await s.getWatermark(), DateTime.utc(2026, 6, 1));
  });

  test('ciclo() corre push y luego pull sobre cada syncer', () async {
    final s = _FakeSyncer(pendientes: ['x'], resultados: {'x': PushOutcome.ok});
    await SyncEngine([s]).ciclo(ahora: DateTime.utc(2026, 6, 1));
    expect(s.marcadosSincronizados, ['x']); // push ocurrió
    expect(s.pullLlamado, 1); // pull ocurrió
    expect(await s.getWatermark(), DateTime.utc(2026, 6, 1)); // pull commiteó
  });

  test('push: un syncer cuyo pushLote LANZA no aborta a los demás', () async {
    // Throw real (no un outcome): simétrico con cicloPull, un fallo inesperado
    // de una feature no debe abortar el push de las siguientes.
    final malo = _FakeSyncer(
        feature: 'malo', pendientes: ['p'], pushLoteThrows: true);
    final bueno = _FakeSyncer(
        feature: 'bueno', pendientes: ['q'], resultados: {'q': PushOutcome.ok});
    await SyncEngine([malo, bueno]).cicloPush();
    expect(bueno.marcadosSincronizados, ['q']); // la feature buena se procesó igual
  });

  test('ciclo(): un push que LANZA no impide el pull (fases independientes)',
      () async {
    final s = _FakeSyncer(pendientes: ['p'], pushLoteThrows: true);
    await SyncEngine([s]).ciclo(ahora: DateTime.utc(2026, 6, 1));
    expect(s.pullLlamado, 1); // el pull corrió pese al fallo del push
    expect(await s.getWatermark(), DateTime.utc(2026, 6, 1));
  });
}
