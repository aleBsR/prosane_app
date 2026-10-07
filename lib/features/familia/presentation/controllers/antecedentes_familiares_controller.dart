import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../../../core/session/entities.dart';
import '../../../../core/session/session_controller.dart';
import '../../data/familia_remote_datasource.dart';

class AntecedentesFamiliaresState {
  const AntecedentesFamiliaresState({
    this.problemaSalud = '',
    this.problemaCual = '',
    this.muerteSubita = '',
    this.cargando = false,
    this.enviando = false,
    this.exito = false,
    this.error,
  });
  final String problemaSalud; // 'si' | 'no' | 'no_sabe' | ''
  final String problemaCual;
  final String muerteSubita; // 'si' | 'no' | 'no_sabe' | ''
  final bool cargando, enviando, exito;
  final String? error;

  AntecedentesFamiliaresState copyWith({
    String? problemaSalud,
    String? problemaCual,
    String? muerteSubita,
    bool? cargando,
    bool? enviando,
    bool? exito,
    Object? error = _sentinel,
  }) =>
      AntecedentesFamiliaresState(
        problemaSalud: problemaSalud ?? this.problemaSalud,
        problemaCual: problemaCual ?? this.problemaCual,
        muerteSubita: muerteSubita ?? this.muerteSubita,
        cargando: cargando ?? this.cargando,
        enviando: enviando ?? this.enviando,
        exito: exito ?? this.exito,
        error: identical(error, _sentinel) ? this.error : error as String?,
      );
}

const _sentinel = Object();

class AntecedentesFamiliaresController
    extends StateNotifier<AntecedentesFamiliaresState> {
  AntecedentesFamiliaresController({
    required this.ds,
    required this.refrescarSesion,
    required this.tutorId,
  }) : super(const AntecedentesFamiliaresState()) {
    cargar();
  }

  final FamiliaRemoteDataSource ds;
  final Future<void> Function() refrescarSesion;
  final String? tutorId;

  // Al cambiar a No/No sabe se borra el detalle para no guardarlo huérfano.
  void setProblemaSalud(String v) => state = state.copyWith(
        problemaSalud: v,
        problemaCual: v == 'si' ? state.problemaCual : '',
      );
  void setProblemaCual(String v) => state = state.copyWith(problemaCual: v);
  void setMuerteSubita(String v) => state = state.copyWith(muerteSubita: v);

  Future<void> cargar() async {
    if (tutorId == null || tutorId!.isEmpty) return;
    state = state.copyWith(cargando: true);
    try {
      final d = await ds.getAntecedentes(tutorId!);
      if (!mounted) return;
      final salud = (d['problema_salud_importante'] as String?) ?? '';
      state = state.copyWith(
        problemaSalud: salud,
        // Sanea detalle huérfano legacy.
        problemaCual: salud == 'si' ? (d['problema_salud_cual'] as String?) ?? '' : '',
        muerteSubita: (d['muerte_subita_familiar'] as String?) ?? '',
        cargando: false,
      );
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(
          cargando: false); // precarga best-effort; se puede guardar igual
    }
  }

  Future<void> guardar() async {
    if (tutorId == null || tutorId!.isEmpty) {
      state = state.copyWith(error: 'No hay tutor autenticado');
      return;
    }
    state = state.copyWith(enviando: true, error: null);
    try {
      await ds.guardarAntecedentes(tutorId!, {
        'problema_salud_importante': state.problemaSalud,
        'problema_salud_cual': state.problemaCual,
        'muerte_subita_familiar': state.muerteSubita,
      });
      await refrescarSesion();
      if (!mounted) return;
      state = state.copyWith(enviando: false, exito: true);
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(
          enviando: false,
          error:
              'No se pudieron guardar los antecedentes. Probá de nuevo.');
    }
  }
}

final antecedentesFamiliaresControllerProvider = StateNotifierProvider.autoDispose<
    AntecedentesFamiliaresController,
    AntecedentesFamiliaresState>((ref) {
  // select sobre tutorId: ver nota en consentimiento_controller.dart — evita
  // que el refresh de sesión recree/disponga el controller en pleno guardar().
  final tutorId = ref.watch(sessionControllerProvider.select(
    (s) => s is SesionAutenticada ? s.sesion.usuario.tutorId : null,
  ));
  return AntecedentesFamiliaresController(
    ds: ref.watch(familiaRemoteDataSourceProvider),
    refrescarSesion: () async {
      final sesion = await ref.read(authRepositoryProvider).refrescarSesion();
      ref.read(sessionControllerProvider.notifier).refrescar(sesion);
    },
    tutorId: tutorId,
  );
});
