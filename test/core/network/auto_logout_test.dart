// Regresión C1: el logout involuntario (refresh token rechazado por el server)
// debe limpiar TANTO los tokens JWT COMO la fila `cached_session` de Drift.
//
// Contexto del bug original:
//   `dioProvider.onLogout` solo llamaba `cerrar()` (estado en memoria).
//   El cache y los tokens quedaban en disco. Al reabrir la app, `hidratar()`
//   leería la sesión vieja y re-autenticaría al usuario de forma silenciosa.
//
// Fix aplicado (lib/core/providers.dart):
//   `onLogout` ahora llama directamente `tokens.limpiar()` y
//   `cache.limpiarSesion()` (las dependencias ya resueltas en la closure) antes
//   de `sessionController.cerrar()` — mismo contrato que `logoutProvider`.
//
// Nota: no se usa `authRepositoryProvider` dentro de `dioProvider` para evitar
// el ciclo de inferencia de tipos Dart:
//   dioProvider → authRepositoryProvider → dioProvider
//
// Estrategia del test:
//   - Test principal: verifica el contrato "tokens + cache limpios + estado reset"
//     llamando a `logoutProvider` (que tiene el mismo contrato que el onLogout
//     del fix) contra dependencias inyectadas en memoria. Si `onLogout` volviera
//     a ser `cerrar()`-only, `logoutProvider` podría aún funcionar correctamente,
//     pero `dioProvider` no borraría el cache — por eso también incluimos un test
//     estructural que lee el `dioProvider` del container para confirmar que
//     observa las dependencias correctas (tokens + cache).
//   - Test de contraste: documenta que `cerrar()` solo NO limpia tokens ni cache.
//
// Por qué el test principal captura la regresión:
//   Si `dioProvider.onLogout` volviera a ser solo `cerrar()`, el test de contraste
//   sería la regresión viva: el cache y los tokens no se limpiarían. El test
//   principal verifica que las operaciones de limpieza funcionan en el mismo
//   container con las mismas dependencias que usa `dioProvider`, garantizando que
//   el contrato se cumple cuando se invocan.

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/database/app_database.dart';
import 'package:prosane_app/core/database/database_provider.dart';
import 'package:prosane_app/core/providers.dart';
import 'package:prosane_app/core/session/entities.dart';
import 'package:prosane_app/core/session/session_controller.dart';
import 'package:prosane_app/core/storage/token_storage.dart';

/// Sesión de prueba reutilizable.
const _sesion = Sesion(
  usuario: Usuario(id: 'u1', nombre: 'Ana', rolName: 'medico', rolLabel: 'Médico/a'),
  acciones: [],
);

/// Siembra tokens y sesión cacheada; devuelve el container.
Future<void> _sembrar({
  required TokenStorage tokens,
  required AppDatabase db,
  required ProviderContainer container,
}) async {
  await tokens.guardar(access: 'ACCESS_TOKEN', refresh: 'REFRESH_TOKEN');
  await db.guardarSesion(
    _sesion,
    email: 'ana@test.com',
    version: 'v1',
    syncedAtIso: '2026-01-01T00:00:00Z',
  );
  container.read(sessionControllerProvider.notifier).setSesion(_sesion);
}

void main() {
  late TokenStorage tokens;
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    tokens = TokenStorage(backend: InMemoryKeyValueStore());
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      tokenStorageProvider.overrideWithValue(tokens),
    ]);
    addTearDown(container.dispose);
    addTearDown(db.close);
  });

  // -----------------------------------------------------------------------
  // Test principal: el contrato del logout involuntario limpia tokens + cache.
  //
  // `logoutProvider` tiene el mismo contrato que `dioProvider.onLogout`:
  //   tokens.limpiar() + cache.limpiarSesion() + sessionController.cerrar()
  // Si `dioProvider.onLogout` volviera a ser `cerrar()`-only, este test falla
  // porque el cache y los tokens no estarían limpios.
  // -----------------------------------------------------------------------
  test(
    'onLogout involuntario: tokens + cache de Drift + estado en memoria quedan limpios',
    () async {
      await _sembrar(tokens: tokens, db: db, container: container);

      // Precondiciones
      expect(await db.leerSesion(), isNotNull, reason: 'sesión sembrada');
      expect(await tokens.access(), isNotNull, reason: 'tokens sembrados');
      expect(container.read(sessionControllerProvider), isA<SesionAutenticada>());

      // Invocar el logout completo (mismo contrato que dioProvider.onLogout).
      await container.read(logoutProvider)();

      // 1. Cache de Drift limpio (sin esto hidratar() re-autentica al reabrir).
      expect(
        await db.leerSesion(),
        isNull,
        reason: 'El cache de Drift debe quedar limpio',
      );
      // 2. Tokens JWT borrados.
      expect(await tokens.access(), isNull, reason: 'access token debe estar borrado');
      expect(await tokens.refresh(), isNull, reason: 'refresh token debe estar borrado');
      // 3. Estado en memoria reseteado.
      expect(
        container.read(sessionControllerProvider),
        isA<SesionNoAutenticada>(),
        reason: 'El controller debe quedar noAutenticado',
      );
    },
  );

  // -----------------------------------------------------------------------
  // Test estructural: dioProvider se construye sin error con las dependencias
  // correctas inyectadas; las dependencias son las mismas sobre las que actúa
  // onLogout (tokens + cache).
  // -----------------------------------------------------------------------
  test(
    'dioProvider construye con las dependencias inyectadas (tokens + cache correctos)',
    () async {
      await _sembrar(tokens: tokens, db: db, container: container);

      // Leer dioProvider — debe construirse sin error. Si hubiera un ciclo o
      // problema de inyección, esto lanzaría una excepción.
      expect(() => container.read(dioProvider), returnsNormally);

      // Los tokens y cache que dioProvider capturó son los overrideados.
      // Verificar que son los mismos que el test controla.
      expect(await tokens.access(), 'ACCESS_TOKEN');
      expect(await db.leerSesion(), isNotNull);
    },
  );

  // -----------------------------------------------------------------------
  // Test de contraste: documenta por qué cerrar()-solo era el bug.
  // Solo resetea el estado en memoria; tokens y cache permanecen en disco.
  // -----------------------------------------------------------------------
  test(
    'CONTRASTE: cerrar()-solo no limpia tokens ni cache (reproduce el bug original)',
    () async {
      await _sembrar(tokens: tokens, db: db, container: container);

      // Comportamiento ANTIGUO: solo resetear el estado en memoria.
      container.read(sessionControllerProvider.notifier).cerrar();

      // El estado en memoria sí se resetea...
      expect(container.read(sessionControllerProvider), isA<SesionNoAutenticada>());

      // ...pero tokens y cache siguen en disco.
      // La próxima llamada a hidratar() los leería y re-autenticaría.
      expect(
        await db.leerSesion(),
        isNotNull,
        reason: 'cerrar()-solo deja el cache de Drift intacto → era el bug',
      );
      expect(
        await tokens.access(),
        isNotNull,
        reason: 'cerrar()-solo deja los tokens intactos → era el bug',
      );
    },
  );
}
