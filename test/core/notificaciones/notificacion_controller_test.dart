import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/notificaciones/notificacion.dart';
import 'package:prosane_app/core/notificaciones/notificacion_controller.dart';

void main() {
  test('arranca sin notificación', () {
    expect(NotificacionController().state, isNull);
  });

  test('mostrar() setea mensaje y tipo', () {
    final c = NotificacionController();
    c.exito('listo');
    expect(c.state!.mensaje, 'listo');
    expect(c.state!.tipo, TipoNotificacion.exito);
  });

  test('cada mostrar() genera un id nuevo (re-dispara aunque repita mensaje)', () {
    final c = NotificacionController();
    c.error('uh');
    final id1 = c.state!.id;
    c.error('uh');
    expect(c.state!.id, isNot(id1));
  });

  test('ocultar() limpia el estado', () {
    final c = NotificacionController()..info('hola');
    c.ocultar();
    expect(c.state, isNull);
  });

  test('color e ícono dependen del tipo', () {
    const exito = Notificacion(mensaje: 'a', tipo: TipoNotificacion.exito, id: 1);
    const error = Notificacion(mensaje: 'b', tipo: TipoNotificacion.error, id: 2);
    expect(exito.color, isNot(error.color));
    expect(exito.icono, isNot(error.icono));
  });
}
