/// DTO de `GET /api/v1/auth/me/` — contrato congelado del backend (spec permisos):
///   { "user": {id, email, nombre, apellido, is_staff},
///     "roles": [{name, label}], "actions": [{name, ...}], "meta": {...} }
/// `permisos` = el conjunto de `name` de `actions`.
class MeResponse {
  MeResponse({required this.id, required this.nombre, required this.rol, required this.permisos});
  final String id;
  final String nombre;
  final String rol;
  final Set<String> permisos;

  factory MeResponse.fromJson(Map<String, dynamic> j) {
    final user = (j['user'] as Map<String, dynamic>?) ?? const {};
    final roles = (j['roles'] as List?) ?? const [];
    final actions = (j['actions'] as List?) ?? const [];

    // nombre + apellido; si vienen vacíos (ej. superusuario), cae al email.
    final nombre = [user['nombre'], user['apellido']]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .join(' ');
    final rol = roles.isNotEmpty ? ((roles.first as Map)['name'] as String? ?? '') : '';

    return MeResponse(
      id: (user['id'] as String?) ?? '',
      nombre: nombre.isNotEmpty ? nombre : (user['email'] as String? ?? ''),
      rol: rol,
      permisos: actions
          .whereType<Map>()
          .map((a) => a['name'] as String?)
          .whereType<String>()
          .toSet(),
    );
  }
}
