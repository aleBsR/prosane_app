import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/session/entities.dart';
import 'package:prosane_app/core/session/session_controller.dart';

void main() {
  test('estado inicial es noAutenticado y can() es false', () {
    final c = SessionController();
    expect(c.state, isA<SesionNoAutenticada>());
    expect(c.can('firmarApto'), false);
  });

  test('tras setSesion, can() refleja los permisos del backend', () {
    final c = SessionController();
    c.setSesion(Sesion(
      usuario: const Usuario(id: '1', nombre: 'Ana', rol: 'profesional'),
      permisos: const {'firmarApto'},
    ));
    expect(c.can('firmarApto'), true);
    expect(c.can('borrarTodo'), false);
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
