import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../../../core/session/entities.dart';
import '../../../../core/session/session_controller.dart';
import '../../data/familia_remote_datasource.dart';

class ConsentimientoState {
  const ConsentimientoState({
    this.aceptado = false,
    this.enviando = false,
    this.exito = false,
    this.error,
  });
  final bool aceptado, enviando, exito;
  final String? error;

  ConsentimientoState copyWith({
    bool? aceptado,
    bool? enviando,
    bool? exito,
    Object? error = _sentinel,
  }) =>
      ConsentimientoState(
        aceptado: aceptado ?? this.aceptado,
        enviando: enviando ?? this.enviando,
        exito: exito ?? this.exito,
        error: identical(error, _sentinel) ? this.error : error as String?,
      );
}

const _sentinel = Object();

class ConsentimientoController extends StateNotifier<ConsentimientoState> {
  ConsentimientoController({
    required this.ds,
    required this.refrescarSesion,
    required this.tutorId,
  }) : super(const ConsentimientoState());

  final FamiliaRemoteDataSource ds;
  final Future<void> Function() refrescarSesion;
  final String? tutorId;

  void setAceptado(bool v) => state = state.copyWith(aceptado: v);

  Future<void> confirmar() async {
    if (tutorId == null || tutorId!.isEmpty) {
      state = state.copyWith(error: 'No hay tutor autenticado');
      return;
    }
    if (!state.aceptado) return;
    state = state.copyWith(enviando: true, error: null);
    try {
      await ds.aceptarConsentimiento(tutorId!);
      await refrescarSesion();
      if (!mounted) return;
      state = state.copyWith(enviando: false, exito: true);
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(
        enviando: false,
        error: 'No se pudo registrar el consentimiento. Probá de nuevo.',
      );
    }
  }
}

final consentimientoControllerProvider =
    StateNotifierProvider.autoDispose<ConsentimientoController, ConsentimientoState>((ref) {
  // select sobre tutorId: el refresh de sesión cambia los flags pero NO el
  // tutorId, así el provider no se recrea (ni dispone el controller) en pleno
  // confirmar(). Solo se recrea si inicia sesión otro tutor.
  final tutorId = ref.watch(sessionControllerProvider.select(
    (s) => s is SesionAutenticada ? s.sesion.usuario.tutorId : null,
  ));
  return ConsentimientoController(
    ds: ref.watch(familiaRemoteDataSourceProvider),
    refrescarSesion: () async {
      final sesion = await ref.read(authRepositoryProvider).refrescarSesion();
      ref.read(sessionControllerProvider.notifier).refrescar(sesion);
    },
    tutorId: tutorId,
  );
});
