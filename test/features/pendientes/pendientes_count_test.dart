import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/database/app_database.dart';
import 'package:prosane_app/core/database/database_provider.dart';
import 'package:prosane_app/core/session/entities.dart';
import 'package:prosane_app/core/session/session_controller.dart';
import 'package:prosane_app/features/pendientes/pendientes_count_provider.dart';

void main() {
  test('no-tutor no tiene pendientes', () {
    expect(
      armarPendientes(esTutor: false, consentimientoAceptado: false, antecedentesCompletos: false, hijos: const []),
      isEmpty,
    );
  });

  test('tutor recién registrado: consentimiento + antecedentes', () {
    final p = armarPendientes(esTutor: true, consentimientoAceptado: false, antecedentesCompletos: false, hijos: const []);
    expect(p.map((e) => e.ruta), ['/consentimiento', '/antecedentes-familiares']);
  });

  test('tutor con todo general hecho + 2 hijos sin antecedentes: 2 cards de antecedentes', () {
    final p = armarPendientes(
      esTutor: true,
      consentimientoAceptado: true,
      antecedentesCompletos: true,
      hijos: const [
        (id: 'h1', nombre: 'Juana', tieneAntecedentes: false),
        (id: 'h2', nombre: 'Pedro', tieneAntecedentes: false),
      ],
    );
    expect(p.length, 2);
    expect(p.first.titulo, contains('Juana'));
    expect(p.every((e) => e.ruta.startsWith('/hijos/') && e.ruta.endsWith('/antecedentes')), isTrue);
  });

  test('orden: consentimiento primero, luego antecedentes, luego hijos', () {
    final p = armarPendientes(
      esTutor: true,
      consentimientoAceptado: false,
      antecedentesCompletos: false,
      hijos: const [(id: 'h1', nombre: 'Ana', tieneAntecedentes: false)],
    );
    expect(p.map((e) => e.ruta).toList(), ['/consentimiento', '/antecedentes-familiares', '/hijos/h1/antecedentes']);
  });

  test('pendientesCountProvider cuenta los items (tutor sin consentimiento → >=1)', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final c = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      sessionControllerProvider.overrideWith((ref) => SessionController()
        ..setSesion(const Sesion(
          usuario: Usuario(id: 'u1', nombre: 'Ana', rolName: 'tutor', rolLabel: 'Tutor'),
          acciones: [],
        ))),
    ]);
    addTearDown(c.dispose);
    c.listen(pendientesCountProvider, (_, _) {}); // mantiene vivo el stream
    // primera emisión del stream
    await c.read(pendientesItemsProvider.future);
    expect(c.read(pendientesCountProvider).value, greaterThanOrEqualTo(1));
  });
}
