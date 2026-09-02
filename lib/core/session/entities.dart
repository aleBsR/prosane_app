class Accion {
  const Accion({
    required this.name, required this.label, required this.icon,
    required this.color, required this.type, required this.category,
    required this.isSensitive, required this.sortOrder,
    this.showInMenu = true,
  });
  final String name, label, icon, color, type, category;
  final bool isSensitive;
  final int sortOrder;
  final bool showInMenu;

  factory Accion.fromJson(Map<String, dynamic> j) => Accion(
        name: j['name'] as String? ?? '',
        label: j['label'] as String? ?? '',
        icon: j['icon'] as String? ?? '',
        color: j['color'] as String? ?? '',
        type: j['type'] as String? ?? '',
        category: j['category'] as String? ?? '',
        isSensitive: j['is_sensitive'] as bool? ?? false,
        sortOrder: j['sort_order'] as int? ?? 0,
        showInMenu: j['show_in_menu'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'name': name, 'label': label, 'icon': icon, 'color': color,
        'type': type, 'category': category,
        'is_sensitive': isSensitive, 'sort_order': sortOrder,
        'show_in_menu': showInMenu,
      };
}

class Usuario {
  const Usuario({
    required this.id,
    required this.nombre,
    required this.rolName,
    required this.rolLabel,
    this.tutorId,
    this.nombrePila,
    this.apellido,
    this.tipoDni,
    this.dni,
    this.consentimientoAceptado = false,
    this.antecedentesFamiliaresCompletos = false,
  });
  final String id, nombre, rolName, rolLabel;
  final String? tutorId;
  // Identidad desagregada del tutor (para prefill del adulto responsable).
  final String? nombrePila;
  final String? apellido;
  final String? tipoDni;
  final String? dni;
  final bool consentimientoAceptado;
  final bool antecedentesFamiliaresCompletos;

  Usuario copyWith({
    bool? consentimientoAceptado,
    bool? antecedentesFamiliaresCompletos,
  }) =>
      Usuario(
        id: id, nombre: nombre, rolName: rolName, rolLabel: rolLabel,
        tutorId: tutorId, nombrePila: nombrePila, apellido: apellido,
        tipoDni: tipoDni, dni: dni,
        consentimientoAceptado: consentimientoAceptado ?? this.consentimientoAceptado,
        antecedentesFamiliaresCompletos:
            antecedentesFamiliaresCompletos ?? this.antecedentesFamiliaresCompletos,
      );
}

class Sesion {
  const Sesion({required this.usuario, required this.acciones});
  final Usuario usuario;
  final List<Accion> acciones;                       // orden del server, intacto
  Set<String> get permisos => acciones.map((a) => a.name).toSet();
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
