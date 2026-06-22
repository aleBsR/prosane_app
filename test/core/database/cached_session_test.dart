import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/database/app_database.dart';
import 'package:prosane_app/core/session/entities.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Sesion sesion() => const Sesion(
        usuario: Usuario(id: 'u1', nombre: 'Ana', rolName: 'medico', rolLabel: 'Médico/a'),
        acciones: [Accion(name: 'firmarApto', label: 'Firmar', icon: 'draw', color: '#2E7D32',
            type: 'form', category: 'salud', isSensitive: true, sortOrder: 40)],
      );

  test('guardar + leer reconstruye la sesión completa (usuario, rol label, acciones)', () async {
    await db.guardarSesion(sesion(), email: 'ana@b.com', version: 'v1', syncedAtIso: '2026-06-10T12:00:00Z');
    final out = await db.leerSesion();
    expect(out!.usuario.nombre, 'Ana');
    expect(out.usuario.rolName, 'medico');
    expect(out.usuario.rolLabel, 'Médico/a');
    expect(out.acciones.single.name, 'firmarApto');
    expect(out.acciones.single.color, '#2E7D32');
    expect(out.acciones.single.isSensitive, isTrue);
    expect(out.acciones.single.sortOrder, 40);
  });

  test('leerSesion sin nada guardado devuelve null', () async {
    expect(await db.leerSesion(), isNull);
  });

  test('guardar de nuevo reemplaza la fila (singleton)', () async {
    await db.guardarSesion(sesion(), email: 'ana@b.com', version: 'v1', syncedAtIso: '');
    await db.guardarSesion(sesion(), email: 'ana@b.com', version: 'v2', syncedAtIso: '');
    expect(await db.versionCacheada(), 'v2');
  });

  test('limpiarSesion borra la fila', () async {
    await db.guardarSesion(sesion(), email: 'ana@b.com', version: 'v1', syncedAtIso: '');
    await db.limpiarSesion();
    expect(await db.leerSesion(), isNull);
  });

  test('cachea y restaura la identidad del tutor (tutorId + adulto)', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    const u = Usuario(
      id: 'u1', nombre: 'Juan Arquipa', rolName: 'tutor', rolLabel: 'Tutor',
      tutorId: 'tut-1', nombrePila: 'Juan', apellido: 'Arquipa', tipoDni: 'DNI', dni: '43949474',
    );
    await db.guardarSesion(const Sesion(usuario: u, acciones: []),
        email: 'j@t.com', version: '1', syncedAtIso: '2026-06-22T00:00:00Z');

    final leida = await db.leerSesion();
    expect(leida!.usuario.tutorId, 'tut-1');
    expect(leida.usuario.nombrePila, 'Juan');
    expect(leida.usuario.apellido, 'Arquipa');
    expect(leida.usuario.tipoDni, 'DNI');
    expect(leida.usuario.dni, '43949474');
    await db.close();
  });
}
