import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/features/pendientes/pendientes_count_provider.dart';

void main() {
  test('no tutor → sin pendientes', () {
    expect(
      armarPendientes(esTutor: false, consentimientoAceptado: true, antecedentesCompletos: true, hijos: const []),
      isEmpty,
    );
  });

  test('hijo sin antecedentes → card de antecedentes del niño con ruta per-hijo', () {
    final items = armarPendientes(
      esTutor: true, consentimientoAceptado: true, antecedentesCompletos: true,
      hijos: const [(id: 'h1', nombre: 'Ana', tieneAntecedentes: false)],
    );
    expect(items.length, 1);
    expect(items.single.ruta, '/hijos/h1/antecedentes');
    expect(items.single.titulo, contains('Ana'));
  });

  test('hijo con antecedentes cargados → no aparece', () {
    final items = armarPendientes(
      esTutor: true, consentimientoAceptado: true, antecedentesCompletos: true,
      hijos: const [(id: 'h1', nombre: 'Ana', tieneAntecedentes: true)],
    );
    expect(items, isEmpty);
  });

  test('consentimiento pendiente sigue apareciendo primero', () {
    final items = armarPendientes(
      esTutor: true, consentimientoAceptado: false, antecedentesCompletos: true,
      hijos: const [],
    );
    expect(items.single.ruta, '/consentimiento');
  });
}
