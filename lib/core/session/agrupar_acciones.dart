import 'entities.dart';

class GrupoAcciones {
  const GrupoAcciones(this.categoria, this.acciones);
  final String categoria;
  final List<Accion> acciones;
}

/// Agrupa por `category` preservando (a) el orden de las acciones tal como vienen
/// del server y (b) el orden de aparición de cada categoría. Una categoría que
/// reaparece se acumula en su grupo existente (no crea uno nuevo).
List<GrupoAcciones> agruparPorCategoria(List<Accion> acciones) {
  final orden = <String>[];
  final mapa = <String, List<Accion>>{};
  for (final a in acciones) {
    if (!mapa.containsKey(a.category)) {
      orden.add(a.category);
      mapa[a.category] = [];
    }
    mapa[a.category]!.add(a);
  }
  return orden.map((c) => GrupoAcciones(c, List.unmodifiable(mapa[c]!))).toList();
}
