import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:prosane_app/core/storage/token_storage.dart';
import 'package:prosane_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:prosane_app/features/auth/data/dtos/me_response.dart';
import 'package:prosane_app/features/auth/data/repositories/auth_repository_impl.dart';

class _MockRemote extends Mock implements AuthRemoteDataSource {}

void main() {
  test('login guarda tokens (antes del /me) y arma la sesión con permisos de /me', () async {
    final remote = _MockRemote();
    final tokens = TokenStorage(backend: InMemoryKeyValueStore());
    when(() => remote.login('a@b.com', 'x'))
        .thenAnswer((_) async => (access: 'A', refresh: 'R'));
    when(() => remote.me()).thenAnswer((_) async {
      // Prueba el ORDEN real: cuando se llama /me, los tokens YA están guardados
      // (si se invirtiera el orden, este expect fallaría).
      expect(await tokens.access(), 'A');
      return MeResponse(id: '1', nombre: 'Ana', rol: 'profesional', permisos: {'firmar_apto'});
    });

    final repo = AuthRepositoryImpl(remote: remote, tokens: tokens);
    final sesion = await repo.login('a@b.com', 'x');

    expect(await tokens.access(), 'A');
    expect(await tokens.refresh(), 'R');
    expect(sesion.usuario.nombre, 'Ana');
    expect(sesion.usuario.rol, 'profesional');
    expect(sesion.permisos, {'firmar_apto'});
  });

  test('register delega en remote.register', () async {
    final remote = _MockRemote();
    final tokens = TokenStorage(backend: InMemoryKeyValueStore());
    when(() => remote.register(any())).thenAnswer((_) async {});
    await AuthRepositoryImpl(remote: remote, tokens: tokens).register({'email': 'a@b.com'});
    verify(() => remote.register({'email': 'a@b.com'})).called(1);
  });

  test('logout limpia los tokens', () async {
    final remote = _MockRemote();
    final tokens = TokenStorage(backend: InMemoryKeyValueStore());
    await tokens.guardar(access: 'A', refresh: 'R');
    await AuthRepositoryImpl(remote: remote, tokens: tokens).logout();
    expect(await tokens.access(), isNull);
  });

  test('si /me falla, limpia los tokens (login atómico) y propaga', () async {
    final remote = _MockRemote();
    final tokens = TokenStorage(backend: InMemoryKeyValueStore());
    when(() => remote.login('a@b.com', 'x'))
        .thenAnswer((_) async => (access: 'A', refresh: 'R'));
    when(() => remote.me()).thenThrow(Exception('me falló'));
    final repo = AuthRepositoryImpl(remote: remote, tokens: tokens);

    await expectLater(repo.login('a@b.com', 'x'), throwsException);
    expect(await tokens.access(), isNull); // rollback: sin tokens huérfanos
  });

  test('MeResponse.fromJson parsea permisos', () {
    final me = MeResponse.fromJson({
      'id': '1', 'nombre': 'Ana', 'rol': 'profesional',
      'permisos': ['firmar_apto', 'ver_ficha'],
    });
    expect(me.permisos, {'firmar_apto', 'ver_ficha'});
  });

  test('MeResponse.fromJson sin permisos -> set vacío', () {
    final me = MeResponse.fromJson({'id': '1', 'nombre': 'Ana', 'rol': 'profesional'});
    expect(me.permisos, isEmpty);
  });
}
