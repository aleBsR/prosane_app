import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/features/auth/data/dtos/me_response.dart';

void main() {
  Map<String, dynamic> base() => {
        'user': {'id': '1', 'email': 'ana@b.com', 'nombre': 'Ana', 'apellido': 'Gómez'},
        'roles': [{'name': 'medico', 'label': 'Médico/a'}],
        'actions': [
          {'name': 'listarPacientes', 'label': 'Listar pacientes', 'icon': 'people',
           'color': '#1565C0', 'type': 'list', 'category': 'salud',
           'is_sensitive': false, 'sort_order': 10},
          {'name': 'firmarApto', 'label': 'Firmar apto físico', 'icon': 'draw',
           'color': '#2E7D32', 'type': 'form', 'category': 'salud',
           'is_sensitive': true, 'sort_order': 40},
        ],
        'meta': {'version': 'abcd1234', 'permissions_synced_at': '2026-06-10T12:00:00Z'},
      };

  test('parsea las 8 claves de cada acción y respeta el orden del server', () {
    final me = MeResponse.fromJson(base());
    expect(me.acciones.map((a) => a.name).toList(), ['listarPacientes', 'firmarApto']);
    final a = me.acciones.first;
    expect(a.label, 'Listar pacientes');
    expect(a.icon, 'people');
    expect(a.color, '#1565C0');
    expect(a.type, 'list');
    expect(a.category, 'salud');
    expect(a.isSensitive, false);
    expect(a.sortOrder, 10);
    expect(me.acciones[1].isSensitive, true);
  });

  test('expone rolName y rolLabel del primer rol', () {
    final me = MeResponse.fromJson(base());
    expect(me.rolName, 'medico');
    expect(me.rolLabel, 'Médico/a');
  });

  test('nombre = nombre+apellido; cae al email si vienen vacíos (superusuario)', () {
    expect(MeResponse.fromJson(base()).nombre, 'Ana Gómez');
    final sinPersona = base()..['user'] = {'id': '1', 'email': 'admin@b.com', 'nombre': '', 'apellido': ''};
    final me = MeResponse.fromJson(sinPersona);
    expect(me.nombre, 'admin@b.com');
  });

  test('nombre/apellido null (usuario sin persona vinculada) → cae al email', () {
    final nul = base()..['user'] = {'id': '1', 'email': 'medico@prosane.test', 'nombre': null, 'apellido': null};
    expect(MeResponse.fromJson(nul).nombre, 'medico@prosane.test');
  });

  test('meta.version y metaSyncedAt se exponen para invalidar el caché', () {
    final me = MeResponse.fromJson(base());
    expect(me.metaVersion, 'abcd1234');
    expect(me.metaSyncedAt, '2026-06-10T12:00:00Z');
  });

  test('sin roles ni actions no rompe', () {
    final me = MeResponse.fromJson({'user': {'id': '1', 'email': 'x@y.com'}, 'roles': [], 'actions': []});
    expect(me.acciones, isEmpty);
    expect(me.rolName, '');
    expect(me.rolLabel, '');
  });

  test('sin meta no rompe (backend viejo sin campo meta)', () {
    final me = MeResponse.fromJson({'user': {'id': '1', 'email': 'x@y.com'}, 'roles': [], 'actions': []});
    expect(me.metaVersion, '');
    expect(me.metaSyncedAt, '');
  });

  test('tutor_id se expone como tutorId (nullable)', () {
    final conTutor = base()..['user'] = {
      'id': '1', 'email': 'ana@b.com', 'nombre': 'Ana', 'apellido': 'Gómez',
      'tutor_id': 'tut-123',
    };
    expect(MeResponse.fromJson(conTutor).tutorId, 'tut-123');
    // Sin tutor_id → null (no rompe)
    expect(MeResponse.fromJson(base()).tutorId, isNull);
  });

  test('MeResponse parsea nombrePila, apellido, tipoDni y dni por separado', () {
    final me = MeResponse.fromJson({
      'user': {
        'id': 'u1', 'email': 'j@t.com', 'nombre': 'Juan', 'apellido': 'Arquipa',
        'tipo_dni': 'DNI', 'dni': '43949474', 'tutor_id': 'tut-1',
      },
      'roles': [{'name': 'tutor', 'label': 'Tutor'}],
      'actions': [],
      'meta': {'version': '1', 'permissions_synced_at': '2026-06-22T00:00:00Z'},
    });
    expect(me.nombre, 'Juan Arquipa');
    expect(me.nombrePila, 'Juan');
    expect(me.apellido, 'Arquipa');
    expect(me.tipoDni, 'DNI');
    expect(me.dni, '43949474');
  });
}
