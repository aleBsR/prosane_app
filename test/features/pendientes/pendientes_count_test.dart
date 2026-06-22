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

  group('calcularBadgePendientes', () {
    test('tutor recién registrado (0 hijos, 0 borradores) → 1 (consentimiento)', () {
      expect(
        calcularBadgePendientes(borradores: 0, totalHijos: 0, esTutor: true),
        1,
      );
    });

    test('tutor con 1 borrador sin sincronizar (ya tiene 1 hijo) → 1', () {
      expect(
        calcularBadgePendientes(borradores: 1, totalHijos: 1, esTutor: true),
        1,
      );
    });

    test('tutor con borradores y aún 0 hijos → suma consentimiento', () {
      // caso defensivo: 2 borradores + consentimiento = 3
      expect(
        calcularBadgePendientes(borradores: 2, totalHijos: 0, esTutor: true),
        3,
      );
    });

    test('tutor todo sincronizado (≥1 hijo, 0 borradores) → 0', () {
      expect(
        calcularBadgePendientes(borradores: 0, totalHijos: 1, esTutor: true),
        0,
      );
    });

    test('no-tutor nunca cuenta el consentimiento', () {
      expect(
        calcularBadgePendientes(borradores: 0, totalHijos: 0, esTutor: false),
        0,
      );
      expect(
        calcularBadgePendientes(borradores: 2, totalHijos: 0, esTutor: false),
        2,
      );
    });
  });
}
