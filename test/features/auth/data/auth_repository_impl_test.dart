import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:prosane_app/core/error/failure.dart';
import 'package:prosane_app/core/session/entities.dart';
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
      expect(await tokens.access(), 'A'); // orden: tokens ya guardados
      return MeResponse(
        id: '1', email: 'a@b.com', nombre: 'Ana', rolName: 'medico', rolLabel: 'Médico/a',
        acciones: const [Accion(name: 'firmarApto', label: 'Firmar', icon: 'draw',
            color: '#2E7D32', type: 'form', category: 'salud', isSensitive: true, sortOrder: 40)],
        metaVersion: 'v1', metaSyncedAt: '2026-06-10T12:00:00Z');
    });

    final repo = AuthRepositoryImpl(remote: remote, tokens: tokens);
    final sesion = await repo.login('a@b.com', 'x');

    expect(await tokens.access(), 'A');
    expect(await tokens.refresh(), 'R');
    expect(sesion.usuario.nombre, 'Ana');
    expect(sesion.usuario.rolName, 'medico');
    expect(sesion.usuario.rolLabel, 'Médico/a');
    expect(sesion.permisos, {'firmarApto'});
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

    // Exception genérica (no DioException) → UnknownFailure tras el rollback.
    await expectLater(repo.login('a@b.com', 'x'), throwsA(isA<UnknownFailure>()));
    expect(await tokens.access(), isNull); // rollback: sin tokens huérfanos
  });

  test('remote.login lanza DioException 401 → repo.login lanza InvalidCredentialsFailure', () async {
    final remote = _MockRemote();
    final tokens = TokenStorage(backend: InMemoryKeyValueStore());
    final reqOpts = RequestOptions(path: '/token');
    when(() => remote.login('a@b.com', 'x')).thenThrow(
      DioException(
        requestOptions: reqOpts,
        response: Response(requestOptions: reqOpts, statusCode: 401),
        type: DioExceptionType.badResponse,
      ),
    );
    final repo = AuthRepositoryImpl(remote: remote, tokens: tokens);

    await expectLater(repo.login('a@b.com', 'x'), throwsA(isA<InvalidCredentialsFailure>()));
  });
}
