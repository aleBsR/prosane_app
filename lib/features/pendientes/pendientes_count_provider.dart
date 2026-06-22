import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/database_provider.dart';
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
/// Orden: consentimiento, antecedentes familiares, luego una card por hijo.
List<ItemPendiente> armarPendientes({
  required bool esTutor,
  required bool consentimientoAceptado,
  required bool antecedentesCompletos,
  required List<String> nombresHijos,
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
    // Placeholder: por ahora todas las cards de hijo van al listado /hijos.
    // La "segunda parte" por-hijo (ruta específica) se definirá más adelante.
    for (final nombre in nombresHijos)
      ItemPendiente(
        titulo: 'Evaluación de ${nombre.isEmpty ? 'tu hijo/a' : nombre}',
        subtitulo: 'Completá la evaluación integral',
        ruta: '/hijos',
        icono: Icons.assignment_outlined,
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
  return db.watchHijosVivos().map((hijos) => armarPendientes(
        esTutor: esTutor,
        consentimientoAceptado: consent,
        antecedentesCompletos: antec,
        nombresHijos: [for (final h in hijos) h.nombreNna],
      ));
});

/// Conteo para el badge del nav bar (deriva de los items). Los consumidores
/// resuelven el AsyncValue con `.value ?? 0`.
final pendientesCountProvider = Provider<AsyncValue<int>>(
  (ref) => ref.watch(pendientesItemsProvider).whenData((items) => items.length),
);
