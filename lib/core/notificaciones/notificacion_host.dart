import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_typography.dart';
import 'notificacion.dart';
import 'notificacion_controller.dart';

/// Capa global que renderiza la notificación actual como una tarjeta flotante
/// sobre el nav bar. Se monta una sola vez, en el root (encima del router).
///
/// No bloquea la interacción del resto de la pantalla: solo la tarjeta captura
/// toques; el área vacía deja pasar los gestos a lo que está debajo.
class NotificacionHost extends ConsumerStatefulWidget {
  const NotificacionHost({
    super.key,
    this.duracion = const Duration(milliseconds: 3500),
    this.bottomOffset = 100,
  });

  /// Tiempo visible antes de auto-cerrarse.
  final Duration duracion;

  /// Separación desde abajo (debe librar el nav bar flotante).
  final double bottomOffset;

  @override
  ConsumerState<NotificacionHost> createState() => _NotificacionHostState();
}

class _NotificacionHostState extends ConsumerState<NotificacionHost> {
  Timer? _timer;

  void _programarAutoCierre(Notificacion notif) {
    _timer?.cancel();
    _timer = Timer(widget.duracion, () {
      // Solo cerrar si sigue siendo ESTA notificación (no pisar una más nueva).
      if (mounted && ref.read(notificacionProvider)?.id == notif.id) {
        ref.read(notificacionProvider.notifier).ocultar();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<Notificacion?>(notificacionProvider, (prev, next) {
      if (next == null) {
        _timer?.cancel();
      } else {
        _programarAutoCierre(next);
      }
    });

    final notif = ref.watch(notificacionProvider);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: widget.bottomOffset + bottomInset,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.35),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
          child: notif == null
              ? const SizedBox.shrink(key: ValueKey('sin-notif'))
              : _TarjetaNotificacion(
                  key: ValueKey(notif.id),
                  notif: notif,
                  onCerrar: () =>
                      ref.read(notificacionProvider.notifier).ocultar(),
                ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class _TarjetaNotificacion extends StatelessWidget {
  const _TarjetaNotificacion({
    super.key,
    required this.notif,
    required this.onCerrar,
  });

  final Notificacion notif;
  final VoidCallback onCerrar;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('dismiss-${notif.id}'),
      direction: DismissDirection.down,
      onDismissed: (_) => onCerrar(),
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.blanco.withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(color: AppColors.blanco.withValues(alpha: 0.85)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3C288C).withValues(alpha: 0.30),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: notif.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(notif.icono, color: notif.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  notif.mensaje,
                  style: AppTypography.subtitulo.copyWith(fontSize: 14),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onCerrar,
                child: const Icon(
                  Icons.close_rounded,
                  size: 19,
                  color: Color(0xFF9A93B0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
