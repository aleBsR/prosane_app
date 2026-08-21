import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:prosane_app/core/network/auth_interceptor.dart';
import 'package:prosane_app/core/network/logging_interceptor.dart';
import 'package:prosane_app/core/network/refresh_interceptor.dart';
import 'package:prosane_app/core/storage/token_storage.dart';

/// Crea un [TokenStorage] con backend en memoria y tokens pre-cargados.
/// Es `async` para que `guardar` complete antes de que el test lo use.
Future<TokenStorage> _store({String? a, String? r}) async {
  final s = TokenStorage(backend: InMemoryKeyValueStore());
  if (a != null && r != null) await s.guardar(access: a, refresh: r);
  return s;
}

/// Handler de request que completa un Completer con las opciones modificadas.
class _OnReq extends RequestInterceptorHandler {
  _OnReq(this.c);
  final Completer<RequestOptions> c;
  @override
  void next(RequestOptions options) => c.complete(options);
}

/// Handler de error que completa el Completer cuando el interceptor resuelve.
/// Si el interceptor propaga el error con [next], el Completer no se completa.
class _OnError extends ErrorInterceptorHandler {
  _OnError(this._c);
  final Completer<Response> _c;

  @override
  void resolve(Response response) {
    if (!_c.isCompleted) _c.complete(response);
  }

  @override
  void next(DioException err) {
    // Error propagado — el Completer queda incompleto (tests lo verifican con isCompleted == false).
  }
}

void main() {
  // -----------------------------------------------------------------------
  // (a) AuthInterceptor adjunta Bearer
  // -----------------------------------------------------------------------
  test('AuthInterceptor adjunta Bearer', () async {
    final tokens = await _store(a: 'TOK', r: 'r');
    final opts = RequestOptions(path: '/x');
    final completer = Completer<RequestOptions>();
    AuthInterceptor(tokens).onRequest(opts, _OnReq(completer));
    final out = await completer.future;
    expect(out.headers['Authorization'], 'Bearer TOK');
  });

  test('AuthInterceptor no adjunta header si no hay token', () async {
    final tokens = await _store(); // sin tokens
    final opts = RequestOptions(path: '/x');
    final completer = Completer<RequestOptions>();
    AuthInterceptor(tokens).onRequest(opts, _OnReq(completer));
    final out = await completer.future;
    expect(out.headers.containsKey('Authorization'), isFalse);
  });

  // -----------------------------------------------------------------------
  // (b) redactarSensibles — redacción obligatoria (Ley 25.326, datos de menores)
  // -----------------------------------------------------------------------
  test('redactarSensibles oculta password/token y enmascara email', () {
    final out = redactarSensibles({
      'email': 'ana@b.com',
      'password': 'secreto',
      'access': 'xyz',
      'refresh': 'abc',
      'token': 'tkn',
      'confirmPassword': 'secreto2',
      'nombre': 'Ana',
    });
    expect(out['password'], '***');
    expect(out['access'], '***');
    expect(out['refresh'], '***');
    expect(out['token'], '***');
    expect(out['confirmPassword'], '***');
    expect(out['email'], isNot('ana@b.com'));
    expect(out['email'], startsWith('a***@'));
    expect(out['nombre'], 'Ana'); // campo no sensible: sin tocar
  });

  test('redactarSensibles redacta secretos anidados en maps y listas', () {
    final out = redactarSensibles({
      'usuario': {'password': 'secreto', 'nombre': 'Ana'},
      'credenciales': [
        {'token': 'abc'},
        {'nombre': 'Bea'},
      ],
    });
    final usuario = out['usuario'] as Map<String, dynamic>;
    expect(usuario['password'], '***'); // secreto anidado redactado
    expect(usuario['nombre'], 'Ana');
    final cred = out['credenciales'] as List;
    expect((cred[0] as Map)['token'], '***'); // secreto en lista de maps
    expect((cred[1] as Map)['nombre'], 'Bea');
  });

  // -----------------------------------------------------------------------
  // (c) RefreshInterceptor: 401 → refresca → reintenta y resuelve
  // -----------------------------------------------------------------------
  test('RefreshInterceptor reintenta request tras 401 y resuelve con token nuevo', () async {
    final tokens = await _store(a: 'OLD_ACCESS', r: 'OLD_REFRESH');

    // refreshDio bare: solo para POST /token/refresh
    final refreshDio = Dio(BaseOptions(baseUrl: 'http://test'));
    final refreshAdapter = DioAdapter(dio: refreshDio);
    refreshAdapter.onPost(
      '/token/refresh/',
      (server) => server.reply(200, {'access': 'NEW_ACCESS'}),
      data: {'refresh': 'OLD_REFRESH'},
    );

    // retryDio: reintenta el request original (GET /recurso)
    final retryDio = Dio(BaseOptions(baseUrl: 'http://test'));
    final retryAdapter = DioAdapter(dio: retryDio);
    retryAdapter.onGet(
      '/recurso',
      (server) => server.reply(200, {'ok': true}),
    );

    bool logoutLlamado = false;
    final interceptor = RefreshInterceptor(
      tokens: tokens,
      retryDio: retryDio,
      refreshDio: refreshDio,
      onLogout: () async => logoutLlamado = true,
    );

    final requestOptions = RequestOptions(
      path: '/recurso',
      baseUrl: 'http://test',
    );
    final err401 = DioException(
      requestOptions: requestOptions,
      response: Response(requestOptions: requestOptions, statusCode: 401),
      type: DioExceptionType.badResponse,
    );

    final completer = Completer<Response>();
    await interceptor.onError(err401, _OnError(completer));

    expect(completer.isCompleted, isTrue);
    final response = await completer.future;
    expect(response.statusCode, 200);
    expect(response.data, {'ok': true});
    expect(logoutLlamado, isFalse);
    // Token actualizado en storage
    expect(await tokens.access(), 'NEW_ACCESS');
  });

  // -----------------------------------------------------------------------
  // (c2) RefreshInterceptor: rota el refresh nuevo si el backend lo devuelve
  // -----------------------------------------------------------------------
  test('RefreshInterceptor persiste el refresh rotado devuelto por el backend', () async {
    final tokens = await _store(a: 'OLD_ACCESS', r: 'OLD_REFRESH');

    final refreshDio = Dio(BaseOptions(baseUrl: 'http://test'));
    final refreshAdapter = DioAdapter(dio: refreshDio);
    refreshAdapter.onPost(
      '/token/refresh/',
      (server) => server.reply(200, {'access': 'NEW_ACCESS', 'refresh': 'NEW_REFRESH'}),
      data: {'refresh': 'OLD_REFRESH'},
    );

    final retryDio = Dio(BaseOptions(baseUrl: 'http://test'));
    final retryAdapter = DioAdapter(dio: retryDio);
    retryAdapter.onGet('/recurso', (server) => server.reply(200, {'ok': true}));

    final interceptor = RefreshInterceptor(
      tokens: tokens,
      retryDio: retryDio,
      refreshDio: refreshDio,
    );

    final requestOptions = RequestOptions(path: '/recurso', baseUrl: 'http://test');
    final err401 = DioException(
      requestOptions: requestOptions,
      response: Response(requestOptions: requestOptions, statusCode: 401),
      type: DioExceptionType.badResponse,
    );

    final completer = Completer<Response>();
    await interceptor.onError(err401, _OnError(completer));

    expect(await tokens.access(), 'NEW_ACCESS');
    expect(await tokens.refresh(), 'NEW_REFRESH', reason: 'el refresh rotado se persiste');
  });

  test('RefreshInterceptor conserva el refresh actual si el backend no rota', () async {
    final tokens = await _store(a: 'OLD_ACCESS', r: 'OLD_REFRESH');

    final refreshDio = Dio(BaseOptions(baseUrl: 'http://test'));
    final refreshAdapter = DioAdapter(dio: refreshDio);
    refreshAdapter.onPost(
      '/token/refresh/',
      (server) => server.reply(200, {'access': 'NEW_ACCESS'}), // sin campo refresh
      data: {'refresh': 'OLD_REFRESH'},
    );

    final retryDio = Dio(BaseOptions(baseUrl: 'http://test'));
    final retryAdapter = DioAdapter(dio: retryDio);
    retryAdapter.onGet('/recurso', (server) => server.reply(200, {'ok': true}));

    final interceptor = RefreshInterceptor(
      tokens: tokens,
      retryDio: retryDio,
      refreshDio: refreshDio,
    );

    final requestOptions = RequestOptions(path: '/recurso', baseUrl: 'http://test');
    final err401 = DioException(
      requestOptions: requestOptions,
      response: Response(requestOptions: requestOptions, statusCode: 401),
      type: DioExceptionType.badResponse,
    );

    final completer = Completer<Response>();
    await interceptor.onError(err401, _OnError(completer));

    expect(await tokens.access(), 'NEW_ACCESS');
    expect(await tokens.refresh(), 'OLD_REFRESH');
  });

  // -----------------------------------------------------------------------
  // (d) RefreshInterceptor: refresh falla → onLogout + error propaga
  // -----------------------------------------------------------------------
  test('RefreshInterceptor llama onLogout y propaga error cuando refresh falla', () async {
    final tokens = await _store(a: 'OLD_ACCESS', r: 'OLD_REFRESH');

    // refreshDio devuelve 401 (token de refresh expirado)
    final refreshDio = Dio(BaseOptions(baseUrl: 'http://test'));
    final refreshAdapter = DioAdapter(dio: refreshDio);
    refreshAdapter.onPost(
      '/token/refresh/',
      (server) => server.reply(401, {'detail': 'token expired'}),
      data: {'refresh': 'OLD_REFRESH'},
    );

    final retryDio = Dio(BaseOptions(baseUrl: 'http://test'));

    bool logoutLlamado = false;
    final interceptor = RefreshInterceptor(
      tokens: tokens,
      retryDio: retryDio,
      refreshDio: refreshDio,
      onLogout: () async => logoutLlamado = true,
    );

    final requestOptions = RequestOptions(
      path: '/recurso',
      baseUrl: 'http://test',
    );
    final err401 = DioException(
      requestOptions: requestOptions,
      response: Response(requestOptions: requestOptions, statusCode: 401),
      type: DioExceptionType.badResponse,
    );

    final completer = Completer<Response>();
    await interceptor.onError(err401, _OnError(completer));

    // onLogout debe haber sido llamado
    expect(logoutLlamado, isTrue);
    // El error se propaga: el Completer NO fue completado (no hubo resolve)
    expect(completer.isCompleted, isFalse);
  });

  // -----------------------------------------------------------------------
  // (e) Single-flight: dos 401 concurrentes → UN solo POST /token/refresh
  //
  // Implementación: [RefreshInterceptor] usa `_refreshEnVuelo ??= _refrescar()`
  // para que múltiples errores 401 concurrentes compartan la misma Future
  // de refresh. Se usa `replyCallback` para contar hits en tiempo de request
  // (a diferencia de `reply`, cuyo callback corre en tiempo de registro).
  // -----------------------------------------------------------------------
  test('Single-flight: dos 401 concurrentes generan UN solo refresh', () async {
    final tokens = await _store(a: 'OLD_ACCESS', r: 'OLD_REFRESH');

    int refreshCount = 0;

    // refreshDio que cuenta hits en tiempo de request (replyCallback)
    final refreshDio = Dio(BaseOptions(baseUrl: 'http://test'));
    final refreshAdapter = DioAdapter(dio: refreshDio);
    // Primera respuesta registrada
    refreshAdapter.onPost(
      '/token/refresh/',
      (server) => server.replyCallback(200, (_) {
        refreshCount++;
        return {'access': 'NEW_ACCESS'};
      }),
      data: {'refresh': 'OLD_REFRESH'},
    );
    // Segunda respuesta (si single-flight falla y hay un segundo POST)
    refreshAdapter.onPost(
      '/token/refresh/',
      (server) => server.replyCallback(200, (_) {
        refreshCount++;
        return {'access': 'NEW_ACCESS_2'};
      }),
      data: {'refresh': 'OLD_REFRESH'},
    );

    // retryDio sirve los dos reintentos originales
    final retryDio = Dio(BaseOptions(baseUrl: 'http://test'));
    final retryAdapter = DioAdapter(dio: retryDio);
    retryAdapter.onGet('/a', (server) => server.reply(200, {'a': 1}));
    retryAdapter.onGet('/b', (server) => server.reply(200, {'b': 2}));

    final interceptor = RefreshInterceptor(
      tokens: tokens,
      retryDio: retryDio,
      refreshDio: refreshDio,
    );

    final optsA = RequestOptions(path: '/a', baseUrl: 'http://test');
    final optsB = RequestOptions(path: '/b', baseUrl: 'http://test');
    final err401A = DioException(
      requestOptions: optsA,
      response: Response(requestOptions: optsA, statusCode: 401),
      type: DioExceptionType.badResponse,
    );
    final err401B = DioException(
      requestOptions: optsB,
      response: Response(requestOptions: optsB, statusCode: 401),
      type: DioExceptionType.badResponse,
    );

    final completerA = Completer<Response>();
    final completerB = Completer<Response>();

    // Lanzar los dos en paralelo SIN await individual para que el single-flight actúe
    final futureA = interceptor.onError(err401A, _OnError(completerA));
    final futureB = interceptor.onError(err401B, _OnError(completerB));

    await Future.wait<void>([futureA, futureB]);

    expect(completerA.isCompleted, isTrue);
    expect(completerB.isCompleted, isTrue);

    final responseA = await completerA.future;
    final responseB = await completerB.future;

    expect(responseA.statusCode, 200);
    expect(responseB.statusCode, 200);
    expect(
      refreshCount,
      1,
      reason: 'Solo debe haber UN POST a /token/refresh (single-flight)',
    );
  });
}
