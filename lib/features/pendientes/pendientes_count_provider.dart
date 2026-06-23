import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/database_provider.dart';
import '../../core/providers.dart';
import '../../core/session/entities.dart';
import '../../core/session/session_controller.dart';

/// Un ítem pendiente que se muestra como card en el mazo de Pendientes.
class ItemPendiente {
  const ItemPendiente({
    required this.titulo,
    required this.subtitulo,
    required this.ruta,
    required this.icono,
  });
  final String titulo, subtitulo, ruta;
  final IconData icono;
}

/// Arma la lista de pendientes (función pura, testeable).
/// Orden: consentimiento, antecedentes familiares, luego una card por hijo sin antecedentes.
List<ItemPendiente> armarPendientes({
  required bool esTutor,
  required bool consentimientoAceptado,
  required bool antecedentesCompletos,
  required List<({String id, String nombre, bool tieneAntecedentes})> hijos,
}) {
  if (!esTutor) return const [];
  return [
    if (!consentimientoAceptado)
      const ItemPendiente(
        titulo: 'Consentimiento',
        subtitulo: 'Aceptá los términos para poder registrar a tus hijos',
        ruta: '/consentimiento',
        icono: Icons.assignment_turned_in_outlined,
      ),
    if (!antecedentesCompletos)
      const ItemPendiente(
        titulo: 'Antecedentes familiares',
        subtitulo: 'Completá los antecedentes de salud de la familia',
        ruta: '/antecedentes-familiares',
        icono: Icons.family_restroom_outlined,
      ),
    for (final h in hijos)
      if (!h.tieneAntecedentes)
        ItemPendiente(
          titulo: 'Antecedentes de ${h.nombre.isEmpty ? 'tu hijo/a' : h.nombre}',
          subtitulo: 'Completá los antecedentes de salud del niño/a',
          ruta: '/hijos/${h.id}/antecedentes',
          icono: Icons.medical_information_outlined,
        ),
  ];
}

/// Lista reactiva de pendientes (sesión + tabla de hijos).
final pendientesItemsProvider = StreamProvider<List<ItemPendiente>>((ref) {
  final db = ref.watch(databaseProvider);
  // ref.watch (no read): al cambiar la sesión (p.ej. tras aceptar consentimiento)
  // el provider se reconstruye y re-evalúa los flags + re-suscribe el stream.
  final s = ref.watch(sessionControllerProvider);
  final esTutor = s is SesionAutenticada && s.sesion.usuario.rolName == 'tutor';
  final consent = s is SesionAutenticada && s.sesion.usuario.consentimientoAceptado;
  final antec = s is SesionAutenticada && s.sesion.usuario.antecedentesFamiliaresCompletos;
  return db.watchHijosConAntecedentes().map((hijos) => armarPendientes(
        esTutor: esTutor,
        consentimientoAceptado: consent,
        antecedentesCompletos: antec,
        hijos: hijos,
      ));
});

/// Devuelve el título legible de un operativo (nombre o escuela).
String _tituloOperativo(Map<String, dynamic> o) =>
    (o['nombre'] as String?)?.isNotEmpty == true
        ? o['nombre'] as String
        : (o['escuela_nombre'] as String? ?? 'Operativo');

/// Operativos pendientes según el rol del usuario.
/// - Ayudante/superadmin (verOperativo): operativos en borrador sin confirmar.
/// - Médico/odontólogo (cargarEvaluacionMedica/Odontologica): operativos
///   asignados en estado 'confirmado' o 'en_curso' con alumnos por evaluar.
/// Solo se consulta si el usuario puede ver operativos (evita 403 en tutores).
final operativosPendientesProvider =
    FutureProvider.autoDispose<List<ItemPendiente>>((ref) async {
  final s = ref.watch(sessionControllerProvider);
  if (s is! SesionAutenticada) return const [];

  final permisos = s.sesion.permisos;
  final puedeVer = permisos.contains('verOperativo');
  final esProfesional = permisos.contains('cargarEvaluacionMedica') ||
      permisos.contains('cargarEvaluacionOdontologica');

  // Sin permisos para ver operativos ni evaluar → nada que mostrar (tutor).
  if (!puedeVer && !esProfesional) return const [];

  final repo = ref.watch(operativosRepositoryProvider);
  final operativos = await repo.listar();

  final items = <ItemPendiente>[];

  // Borradores del ayudante/superadmin (comportamiento existente).
  if (puedeVer) {
    items.addAll(operativos
        .where((o) => o['estado'] == 'borrador')
        .map((o) => ItemPendiente(
              titulo: _tituloOperativo(o),
              subtitulo: 'Operativo sin confirmar — completá y confirmalo',
              ruta: '/operativos/${o['id']}',
              icono: Icons.assignment_late_outlined,
            )));
  }

  // Operativos asignados al profesional con alumnos por evaluar.
  // El backend ya filtra la lista por asignación.
  if (esProfesional) {
    items.addAll(operativos
        .where((o) =>
            o['estado'] == 'confirmado' || o['estado'] == 'en_curso')
        .map((o) => ItemPendiente(
              titulo: _tituloOperativo(o),
              subtitulo: 'Tenés alumnos por evaluar',
              ruta: '/operativos/${o['id']}',
              icono: Icons.medical_services_outlined,
            )));
  }

  return items;
});

/// Lista combinada: pendientes del tutor (Drift) + operativos borrador.
final pendientesTotalProvider = Provider.autoDispose<List<ItemPendiente>>((ref) {
  final tutor = ref.watch(pendientesItemsProvider).maybeWhen(
        data: (v) => v,
        orElse: () => const <ItemPendiente>[],
      );
  final ops = ref.watch(operativosPendientesProvider).maybeWhen(
        data: (v) => v,
        orElse: () => const <ItemPendiente>[],
      );
  return [...tutor, ...ops];
});

/// Conteo para el badge del nav bar (tutor + operativos borrador).
final pendientesCountProvider = Provider<AsyncValue<int>>(
  (ref) => AsyncValue.data(ref.watch(pendientesTotalProvider).length),
);
