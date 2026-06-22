import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Tipo de notificación → define color e ícono de la tarjeta.
enum TipoNotificacion { exito, error, info }

/// Una notificación efímera para mostrar sobre el nav bar.
/// [id] permite re-disparar la misma copia (timer/animación) si se llama
/// mostrar() dos veces con el mismo mensaje.
@immutable
class Notificacion {
  const Notificacion({
    required this.mensaje,
    required this.tipo,
    required this.id,
  });

  final String mensaje;
  final TipoNotificacion tipo;
  final int id;

  Color get color => switch (tipo) {
    TipoNotificacion.exito => const Color(0xFF2E9E5B),
    TipoNotificacion.error => AppColors.error,
    TipoNotificacion.info => AppColors.primario,
  };

  IconData get icono => switch (tipo) {
    TipoNotificacion.exito => Icons.check_circle_rounded,
    TipoNotificacion.error => Icons.error_rounded,
    TipoNotificacion.info => Icons.info_rounded,
  };
}
