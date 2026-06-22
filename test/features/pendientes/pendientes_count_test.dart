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
      armarPendientes(esTutor: false, consentimientoAceptado: false, antecedentesCompletos: false, nombresHijos: []),
      isEmpty,
    );
  });

  test('tutor recién registrado: consentimiento + antecedentes', () {
    final p = armarPendientes(esTutor: true, consentimientoAceptado: false, antecedentesCompletos: false, nombresHijos: []);
    expect(p.map((e) => e.ruta), ['/consentimiento', '/antecedentes-familiares']);
  });

  test('tutor con todo general hecho + 2 hijos: 2 cards de evaluación', () {
    final p = armarPendientes(esTutor: true, consentimientoAceptado: true, antecedentesCompletos: true, nombresHijos: ['Juana', 'Pedro']);
    expect(p.length, 2);
    expect(p.first.titulo, contains('Juana'));
    expect(p.every((e) => e.ruta == '/hijos'), isTrue);
  });

  test('orden: consentimiento primero, luego antecedentes, luego hijos', () {
    final p = armarPendientes(esTutor: true, consentimientoAceptado: false, antecedentesCompletos: false, nombresHijos: ['Ana']);
    expect(p.map((e) => e.ruta).toList(), ['/consentimiento', '/antecedentes-familiares', '/hijos']);
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
