import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notificacion.dart';

/// Estado global de la notificación actual (o null si no hay ninguna visible).
/// Una sola a la vez: mostrar() reemplaza la anterior.
class NotificacionController extends StateNotifier<Notificacion?> {
  NotificacionController() : super(null);

  int _seq = 0;

  /// Muestra una notificación. Cada llamada genera un [id] nuevo para que el
  /// host reinicie su timer/animación aunque el mensaje sea idéntico.
  void mostrar(String mensaje, TipoNotificacion tipo) {
    _seq++;
    state = Notificacion(mensaje: mensaje, tipo: tipo, id: _seq);
  }

  void exito(String mensaje) => mostrar(mensaje, TipoNotificacion.exito);
  void error(String mensaje) => mostrar(mensaje, TipoNotificacion.error);
  void info(String mensaje) => mostrar(mensaje, TipoNotificacion.info);

  void ocultar() => state = null;
}

final notificacionProvider =
    StateNotifierProvider<NotificacionController, Notificacion?>(
      (ref) => NotificacionController(),
    );
