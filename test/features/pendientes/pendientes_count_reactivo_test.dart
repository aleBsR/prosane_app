import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/database/app_database.dart';
import 'package:prosane_app/core/database/database_provider.dart';
import 'package:prosane_app/core/session/entities.dart';
import 'package:prosane_app/core/session/session_controller.dart';
import 'package:prosane_app/features/pendientes/pendientes_count_provider.dart';

SessionController _tutorController() => SessionController()
  ..setSesion(const Sesion(
    usuario: Usuario(id: 'u1', nombre: 'Marta', rolName: 'tutor', rolLabel: 'Tutor/a'),
    acciones: [],
  ));

SessionController _medicoController() => SessionController()
  ..setSesion(const Sesion(
    usuario: Usuario(id: 'u2', nombre: 'Carlos', rolName: 'medico', rolLabel: 'Médico/a'),
    acciones: [],
  ));

/// Espera (con timeout) a que el badge llegue al valor esperado tras una
/// mutación de la DB (las emisiones de Drift watch son asíncronas).
Future<void> _esperarBadge(ProviderContainer c, int esperado) async {
  for (var i = 0; i < 100; i++) {
    if (c.read(pendientesCountProvider).value == esperado) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('badge no llegó a $esperado; último=${c.read(pendientesCountProvider).value}');
}

void main() {
  test('tutor recién registrado (0 hijos) → badge 1', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final c = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      sessionControllerProvider.overrideWith((ref) => _tutorController()),
    ]);
    addTearDown(c.dispose);
    c.listen(pendientesCountProvider, (_, _) {}); // mantiene vivo el stream

    await _esperarBadge(c, 1);
  });

  test('badge reactivo: alta de hijo mantiene 1, sincronizar baja a 0', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final c = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      sessionControllerProvider.overrideWith((ref) => _tutorController()),
    ]);
    addTearDown(c.dispose);
    c.listen(pendientesCountProvider, (_, _) {});

    await _esperarBadge(c, 1); // consentimiento pendiente

    // Alta de un hijo (borrador): ya hay 1 hijo (consent=0) + 1 borrador = 1
    await db.insertHijoDraft(
      id: 'h1', tutorId: 't1', nombreNna: 'Nico', apellidoNna: 'P', payloadJson: '{}',
    );
    await _esperarBadge(c, 1);

    // Sincronizado: 1 hijo (consent=0) + 0 borradores = 0
    await db.marcarHijoSincronizado('h1');
    await _esperarBadge(c, 0);
  });

  test('no-tutor sin hijos → badge 0 (no cuenta consentimiento)', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final c = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      sessionControllerProvider.overrideWith((ref) => _medicoController()),
    ]);
    addTearDown(c.dispose);
    c.listen(pendientesCountProvider, (_, _) {});

    await _esperarBadge(c, 0);
  });
}
