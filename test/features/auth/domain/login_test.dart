import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:prosane_app/core/session/entities.dart';
import 'package:prosane_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:prosane_app/features/auth/domain/usecases/login.dart';
import 'package:prosane_app/features/auth/domain/usecases/register.dart';

class _MockRepo extends Mock implements AuthRepository {}

void main() {
  test('Login delega en el repo y devuelve la sesión', () async {
    final repo = _MockRepo();
    final sesion = Sesion(
      usuario: const Usuario(id: '1', nombre: 'Ana', rolName: 'profesional', rolLabel: 'Profesional'),
      acciones: const [],
    );
    when(() => repo.login('a@b.com', 'x', recordarme: any(named: 'recordarme'))).thenAnswer((_) async => sesion);
    final r = await Login(repo)('a@b.com', 'x');
    expect(r.usuario.nombre, sesion.usuario.nombre);
    expect(r.usuario.rolName, sesion.usuario.rolName);
    expect(r.permisos, sesion.permisos);
    verify(() => repo.login('a@b.com', 'x', recordarme: any(named: 'recordarme'))).called(1);
  });

  test('Login reenvía recordarme=false al repo', () async {
    final repo = _MockRepo();
    final sesion = Sesion(
      usuario: const Usuario(id: '1', nombre: 'Ana', rolName: 'profesional', rolLabel: 'Profesional'),
      acciones: const [],
    );
    when(() => repo.login('a@b.com', 'x', recordarme: false)).thenAnswer((_) async => sesion);
    await Login(repo)('a@b.com', 'x', recordarme: false);
    verify(() => repo.login('a@b.com', 'x', recordarme: false)).called(1);
  });

  test('Register delega en el repo con el payload', () async {
    final repo = _MockRepo();
    final sesion = Sesion(
      usuario: const Usuario(id: '1', nombre: 'Ana', rolName: 'tutor', rolLabel: 'Tutor'),
      acciones: const [],
    );
    when(() => repo.register(any())).thenAnswer((_) async => sesion);
    await Register(repo)({'email': 'a@b.com'});
    verify(() => repo.register({'email': 'a@b.com'})).called(1);
  });
}
