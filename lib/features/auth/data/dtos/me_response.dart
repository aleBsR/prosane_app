import '../../../../core/session/entities.dart';

/// DTO de `GET /api/v1/auth/me/` — contrato congelado del backend.
///   { user:{id,email,nombre,apellido,is_staff}, roles:[{name,label}],
///     actions:[{8 claves}], meta:{version, permissions_synced_at} }
class MeResponse {
  MeResponse({
    required this.id, required this.email, required this.nombre,
    required this.rolName, required this.rolLabel, required this.acciones,
    required this.metaVersion, required this.metaSyncedAt,
    this.tutorId,
  });
  final String id, email, nombre, rolName, rolLabel, metaVersion, metaSyncedAt;
  final String? tutorId;
  final List<Accion> acciones;

  factory MeResponse.fromJson(Map<String, dynamic> j) {
    final user = (j['user'] as Map<String, dynamic>?) ?? const {};
    final roles = (j['roles'] as List?) ?? const [];
    final actions = (j['actions'] as List?) ?? const [];
    final meta = (j['meta'] as Map<String, dynamic>?) ?? const {};

    final nombre = [user['nombre'], user['apellido']]
        .whereType<String>().where((s) => s.isNotEmpty).join(' ');
    final rol = roles.isNotEmpty ? (roles.first as Map) : const {};

    return MeResponse(
      id: (user['id'] as String?) ?? '',
      email: (user['email'] as String?) ?? '',
      nombre: nombre.isNotEmpty ? nombre : ((user['email'] as String?) ?? ''),
      rolName: (rol['name'] as String?) ?? '',
      rolLabel: (rol['label'] as String?) ?? '',
      acciones: actions
          .whereType<Map>()
          .map((a) => Accion.fromJson(a.cast<String, dynamic>()))
          .toList(),
      metaVersion: (meta['version'] as String?) ?? '',
      metaSyncedAt: (meta['permissions_synced_at'] as String?) ?? '',
      tutorId: user['tutor_id'] as String?,
    );
  }
}
