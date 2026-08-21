import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:prosane_app/core/error/failure.dart';
import 'package:prosane_app/core/session/entities.dart';
import 'package:prosane_app/core/storage/token_storage.dart';
import 'package:prosane_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:prosane_app/features/auth/data/dtos/me_response.dart';
import 'package:prosane_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:prosane_app/core/session/session_cache.dart';

class _MockRemote extends Mock implements AuthRemoteDataSource {}

class _FakeCache implements SessionCache {
  Sesion? guardada; String? version; bool limpiado = false;
  @override Future<void> guardarSesion(Sesion s, {required String email, required String version, required String syncedAtIso}) async { guardada = s; this.version = version; }
  @override Future<Sesion?> leerSesion() async => guardada;
  @override Future<void> limpiarSesion() async { guardada = null; limpiado = true; }
}

class _ThrowingCache implements SessionCache {
  @override
  Future<void> guardarSesion(Sesion s, {required String email, required String version, required String syncedAtIso}) async =>
      throw Exception('disco lleno');
  @override
  Future<Sesion?> leerSesion() async => null;
  @override
  Future<void> limpiarSesion() async {}
}

void main() {
  test('login guarda tokens (antes del /me) y arma la sesión con permisos de /me', () async {
    final remote = _MockRemote();
    final tokens = TokenStorage(backend: InMemoryKeyValueStore());
    final cache = _FakeCache();
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

    final repo = AuthRepositoryImpl(remote: remote, tokens: tokens, cache: cache);
    final sesion = await repo.login('a@b.com', 'x');

    expect(await tokens.access(), 'A');
    expect(await tokens.refresh(), 'R');
    expect(sesion.usuario.nombre, 'Ana');
    expect(sesion.usuario.rolName, 'medico');
    expect(sesion.usuario.rolLabel, 'Médico/a');
    expect(sesion.permisos, {'firmarApto'});
    expect(cache.guardada!.permisos, {'firmarApto'});
  });

  test('login efímero (recordarme=false): tokens en memoria y sin caché de Drift', () async {
    final remote = _MockRemote();
    final tokens = TokenStorage(backend: InMemoryKeyValueStore());
    final cache = _FakeCache()..guardada = const Sesion(
        usuario: Usuario(id: '9', nombre: 'Vieja', rolName: 'r', rolLabel: 'R'), acciones: []);
    when(() => remote.login('a@b.com', 'x'))
        .thenAnswer((_) async => (access: 'A', refresh: 'R'));
    when(() => remote.me()).thenAnswer((_) async => MeResponse(
        id: '1', email: 'a@b.com', nombre: 'Ana', rolName: 'medico', rolLabel: 'Médico/a',
        acciones: const [], metaVersion: 'v1', metaSyncedAt: '2026-06-10T12:00:00Z'));

    final repo = AuthRepositoryImpl(remote: remote, tokens: tokens, cache: cache);
    final sesion = await repo.login('a@b.com', 'x', recordarme: false);

    expect(sesion.usuario.nombre, 'Ana');
    expect(await tokens.access(), 'A'); // sigue funcionando en memoria
    expect(cache.guardada, isNull, reason: 'no se persiste la sesión efímera');
    expect(cache.limpiado, true, reason: 'limpia la sesión previa de la caché');
  });

  test('register: guarda tokens, trae /me y devuelve Sesion', () async {
    final remote = _MockRemote();
    final tokens = TokenStorage(backend: InMemoryKeyValueStore());
    final cache = _FakeCache();
    final meResponseFake = MeResponse(
      id: '2', email: 'a@b.com', nombre: 'Carlos', rolName: 'tutor', rolLabel: 'Tutor/a',
      acciones: const [], metaVersion: 'v1', metaSyncedAt: '2026-06-21T10:00:00Z');
    when(() => remote.registerTutor(any())).thenAnswer((_) async => (access: 'A', refresh: 'R'));
    when(() => remote.me()).thenAnswer((_) async => meResponseFake);

    final repo = AuthRepositoryImpl(remote: remote, tokens: tokens, cache: cache);
    final sesion = await repo.register({'email': 'a@b.com'});

    expect(sesion.usuario.rolName, meResponseFake.rolName);
    expect(await tokens.access(), 'A');
    expect(await tokens.refresh(), 'R');
    verify(() => remote.registerTutor({'email': 'a@b.com'})).called(1);
    verify(() => remote.me()).called(1);
  });

  test('logout llama al backend (blacklist) con el refresh y luego limpia tokens + cache', () async {
    final remote = _MockRemote();
    final tokens = TokenStorage(backend: InMemoryKeyValueStore());
    await tokens.guardar(access: 'A', refresh: 'R');
    final cache = _FakeCache()..guardada = const Sesion(
        usuario: Usuario(id: '1', nombre: 'A', rolName: 'r', rolLabel: 'R'), acciones: []);
    when(() => remote.logout('R')).thenAnswer((_) async {});

    await AuthRepositoryImpl(remote: remote, tokens: tokens, cache: cache).logout();

    verify(() => remote.logout('R')).called(1);   // best-effort blacklist con el refresh
    expect(await tokens.access(), isNull);          // local limpiado
    expect(cache.limpiado, true);
  });

  test('logout es best-effort: si el backend falla (offline), igual limpia local', () async {
    final remote = _MockRemote();
    final tokens = TokenStorage(backend: InMemoryKeyValueStore());
    await tokens.guardar(access: 'A', refresh: 'R');
    final cache = _FakeCache();
    when(() => remote.logout(any())).thenThrow(Exception('offline'));

    // NO debe propagar la excepción
    await AuthRepositoryImpl(remote: remote, tokens: tokens, cache: cache).logout();

    expect(await tokens.access(), isNull);   // limpió igual
    expect(cache.limpiado, true);
  });

  test('logout sin refresh token no llama al backend pero limpia local', () async {
    final remote = _MockRemote();
    final tokens = TokenStorage(backend: InMemoryKeyValueStore()); // sin tokens guardados
    final cache = _FakeCache();

    await AuthRepositoryImpl(remote: remote, tokens: tokens, cache: cache).logout();

    verifyNever(() => remote.logout(any()));
    expect(cache.limpiado, true);
    expect(await tokens.access(), isNull);
  });

  test('si /me falla, limpia los tokens (login atómico) y propaga', () async {
    final remote = _MockRemote();
    final tokens = TokenStorage(backend: InMemoryKeyValueStore());
    when(() => remote.login('a@b.com', 'x'))
        .thenAnswer((_) async => (access: 'A', refresh: 'R'));
    when(() => remote.me()).thenThrow(Exception('me falló'));
    final repo = AuthRepositoryImpl(remote: remote, tokens: tokens, cache: _FakeCache());

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
    final repo = AuthRepositoryImpl(remote: remote, tokens: tokens, cache: _FakeCache());

    await expectLater(repo.login('a@b.com', 'x'), throwsA(isA<InvalidCredentialsFailure>()));
  });

  test('sesionCacheada() hidrata desde la cache (offline)', () async {
    final cache = _FakeCache()..guardada = const Sesion(
      usuario: Usuario(id: '1', nombre: 'Ana', rolName: 'medico', rolLabel: 'Médico/a'),
      acciones: []);
    final repo = AuthRepositoryImpl(remote: _MockRemote(), tokens: TokenStorage(backend: InMemoryKeyValueStore()), cache: cache);
    expect((await repo.sesionCacheada())!.usuario.nombre, 'Ana');
  });

  test('sesionCacheada() devuelve null si la cache está vacía', () async {
    final repo = AuthRepositoryImpl(remote: _MockRemote(), tokens: TokenStorage(backend: InMemoryKeyValueStore()), cache: _FakeCache());
    expect(await repo.sesionCacheada(), isNull);
  });

  test('si el guardado en cache falla, login es atómico: limpia tokens y propaga UnknownFailure', () async {
    final remote = _MockRemote();
    final tokens = TokenStorage(backend: InMemoryKeyValueStore());
    when(() => remote.login('a@b.com', 'x')).thenAnswer((_) async => (access: 'A', refresh: 'R'));
    when(() => remote.me()).thenAnswer((_) async => MeResponse(
        id: '1', email: 'a@b.com', nombre: 'Ana', rolName: 'medico', rolLabel: 'Médico/a',
        acciones: const [], metaVersion: 'v1', metaSyncedAt: ''));
    final repo = AuthRepositoryImpl(remote: remote, tokens: tokens, cache: _ThrowingCache());

    await expectLater(repo.login('a@b.com', 'x'), throwsA(isA<UnknownFailure>()));
    expect(await tokens.access(), isNull); // rollback: sin tokens huérfanos
  });

  test('solicitarResetPassword delega en el remote', () async {
    final remote = _MockRemote();
    when(() => remote.solicitarResetPassword('a@b.com')).thenAnswer((_) async {});
    final repo = AuthRepositoryImpl(remote: remote, tokens: TokenStorage(backend: InMemoryKeyValueStore()), cache: _FakeCache());
    await repo.solicitarResetPassword('a@b.com');
    verify(() => remote.solicitarResetPassword('a@b.com')).called(1);
  });

  test('confirmarResetPassword delega en el remote', () async {
    final remote = _MockRemote();
    when(() => remote.confirmarResetPassword('a@b.com', '123456', 'nueva1'))
        .thenAnswer((_) async {});
    final repo = AuthRepositoryImpl(remote: remote, tokens: TokenStorage(backend: InMemoryKeyValueStore()), cache: _FakeCache());
    await repo.confirmarResetPassword('a@b.com', '123456', 'nueva1');
    verify(() => remote.confirmarResetPassword('a@b.com', '123456', 'nueva1'))
        .called(1);
  });
}
