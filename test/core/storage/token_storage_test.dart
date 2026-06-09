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
}
