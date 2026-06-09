class Usuario {
  const Usuario({required this.id, required this.nombre, required this.rol});
  final String id;
  final String nombre;
  final String rol;
}

class Sesion {
  const Sesion({required this.usuario, required this.permisos});
  final Usuario usuario;
  final Set<String> permisos;
}

sealed class SesionState {}

class SesionNoAutenticada extends SesionState {}

class SesionAutenticada extends SesionState {
  SesionAutenticada(this.sesion);
  final Sesion sesion;
}

/// `can` definido una sola vez sobre el estado: lo usan el controller y el gate.
extension SesionPermisos on SesionState {
  bool can(String permiso) {
    if (permiso.trim().isEmpty) return false; // guard defensivo: nunca conceder por un permiso vacío
    final s = this;
    return s is SesionAutenticada && s.sesion.permisos.contains(permiso);
  }
}
