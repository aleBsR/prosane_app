import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/features/pendientes/pendientes_count_provider.dart';

void main() {
  test('sin tablas de feature reales el conteo es 0 (badge oculto)', () {
    // Hoy no hay entidades sincronizables: la lista de syncers pendientes está vacía.
    expect(contarPendientes(const []), 0);
  });

  test('suma los pendientes/error de cada feature', () {
    expect(contarPendientes(const [2, 0, 3]), 5);
  });
}
