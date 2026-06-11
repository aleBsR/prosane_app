import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/session/entities.dart';
import 'package:prosane_app/core/session/session_controller.dart';

void main() {
  test('hidratar con una sesión cacheada deja la sesión autenticada', () async {
    final c = SessionController();
    addTearDown(c.dispose);
    await c.hidratar(() async => const Sesion(
        usuario: Usuario(id: '1', nombre: 'Ana', rolName: 'medico', rolLabel: 'Médico/a'), acciones: []));
    expect(c.state, isA<SesionAutenticada>());
  });

  test('hidratar sin cache (null) deja noAutenticada', () async {
    final c = SessionController();
    addTearDown(c.dispose);
    await c.hidratar(() async => null);
    expect(c.state, isA<SesionNoAutenticada>());
  });
}
