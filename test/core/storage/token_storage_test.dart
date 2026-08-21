import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/storage/token_storage.dart';

void main() {
  test('guarda y lee access/refresh y limpia', () async {
    final store = TokenStorage(backend: InMemoryKeyValueStore());
    await store.guardar(access: 'a', refresh: 'r');
    expect(await store.access(), 'a');
    expect(await store.refresh(), 'r');
    await store.limpiar();
    expect(await store.access(), isNull);
    expect(await store.refresh(), isNull);
  });

  test('sin guardar nada, access y refresh son null', () async {
    final store = TokenStorage(backend: InMemoryKeyValueStore());
    expect(await store.access(), isNull);
    expect(await store.refresh(), isNull);
  });

  test('persistente=false: escribe solo en memoria (backend limpio)', () async {
    final backend = InMemoryKeyValueStore();
    final store = TokenStorage(backend: backend);
    await store.guardar(access: 'a', refresh: 'r', persistente: false);
    expect(await store.access(), 'a'); // lee desde memoria
    expect(await store.refresh(), 'r');
    // El backend persistente quedó limpio: la sesión no sobrevive un cierre.
    expect(await backend.read('jwt_access'), isNull);
    expect(await backend.read('jwt_refresh'), isNull);
  });

  test('guardar efímero no filtra una sesión persistente previa', () async {
    final backend = InMemoryKeyValueStore();
    final store = TokenStorage(backend: backend);
    await store.guardar(access: 'Viejo', refresh: 'R_viejo'); // sesión persistente
    await store.guardar(access: 'Nuevo', refresh: 'R_nuevo', persistente: false);
    expect(await store.access(), 'Nuevo'); // gana la efímera
    expect(await backend.read('jwt_access'), isNull); // disco limpio
  });

  test('guardar sin persistente conserva el modo actual (efímera se mantiene efímera)', () async {
    final backend = InMemoryKeyValueStore();
    final store = TokenStorage(backend: backend);
    await store.guardar(access: 'a', refresh: 'r', persistente: false);
    await store.guardar(access: 'b', refresh: 'r2'); // refresh: no cambia el modo
    expect(await store.access(), 'b');
    expect(await backend.read('jwt_access'), isNull, reason: 'sigue siendo efímera');
    await store.limpiar();
    expect(await store.access(), isNull);
  });

  test('limpiar borra memoria y backend y restaura el modo persistente', () async {
    final backend = InMemoryKeyValueStore();
    final store = TokenStorage(backend: backend);
    await store.guardar(access: 'a', refresh: 'r', persistente: false);
    await store.limpiar();
    expect(await store.access(), isNull);
    await store.guardar(access: 'c', refresh: 'r3');
    expect(await backend.read('jwt_access'), 'c'); // vuelve a escribir en disco
  });
}
