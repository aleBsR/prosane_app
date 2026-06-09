import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/session/entities.dart';
import 'package:prosane_app/core/session/session_controller.dart';

void main() {
  test('estado inicial es noAutenticado y can() es false', () {
    final c = SessionController();
    expect(c.state, isA<SesionNoAutenticada>());
    expect(c.can('firmar_apto'), false);
  });

  test('tras setSesion, can() refleja los permisos del backend', () {
    final c = SessionController();
    c.setSesion(Sesion(
      usuario: const Usuario(id: '1', nombre: 'Ana', rol: 'profesional'),
      permisos: const {'firmar_apto'},
    ));
    expect(c.can('firmar_apto'), true);
    expect(c.can('borrar_todo'), false);
  });

  test('cerrar vuelve a noAutenticado', () {
    final c = SessionController();
    c.setSesion(Sesion(
      usuario: const Usuario(id: '1', nombre: 'Ana', rol: 'profesional'),
      permisos: const {'x'},
    ));
    c.cerrar();
    expect(c.state, isA<SesionNoAutenticada>());
    expect(c.can('x'), false);
  });
}
