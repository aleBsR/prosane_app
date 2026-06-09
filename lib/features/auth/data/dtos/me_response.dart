class MeResponse {
  MeResponse({required this.id, required this.nombre, required this.rol, required this.permisos});
  final String id;
  final String nombre;
  final String rol;
  final Set<String> permisos;

  factory MeResponse.fromJson(Map<String, dynamic> j) => MeResponse(
        id: j['id'] as String,
        nombre: j['nombre'] as String,
        rol: j['rol'] as String,
        permisos: ((j['permisos'] as List?) ?? const []).cast<String>().toSet(),
      );
}
