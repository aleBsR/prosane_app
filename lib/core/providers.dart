import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'storage/token_storage.dart';
import 'network/dio_client.dart';
import 'config/app_config.dart';
import 'database/database_provider.dart';
import '../features/auth/data/datasources/auth_remote_datasource.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/usecases/login.dart';
import 'session/session_controller.dart';
import '../features/hijos/data/hijos_syncer.dart';
import '../features/hijos/data/antecedentes_nino_syncer.dart';
import '../features/familia/data/familia_remote_datasource.dart';
import 'sync/sync_engine.dart';
import 'sync/connectivity_service.dart';
import 'sync/sync_scheduler.dart';
import '../features/operativos/data/operativos_repository.dart';
import '../features/escuelas/data/escuelas_repository.dart';
import '../features/escuelas/data/alumnos_escuela_repository.dart';
import '../features/usuarios_escuela/data/usuarios_escuela_repository.dart';
import '../features/usuarios_ayudantes/data/usuarios_ayudantes_repository.dart';
import '../features/profesionales/data/profesionales_repository.dart';
import '../features/usuario/data/usuario_repository.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final dioProvider = Provider<Dio>((ref) {
  final tokens = ref.watch(tokenStorageProvider);
  final cache = ref.watch(databaseProvider);
  // onLogout (refresh token rechazado) = logout COMPLETO, igual que el botón manual:
  // limpia tokens + cache de Drift + estado. Si solo hiciera cerrar(), hidratar() al
  // reabrir re-autenticaría desde el cache viejo.
  // Importante: no podemos leer authRepositoryProvider aquí (closure dentro de un
  // Provider<Dio> que authRepositoryProvider observa → ciclo de inferencia de tipos
  // en Dart). En cambio realizamos las mismas operaciones directamente sobre las
  // dependencias ya resueltas (tokens + cache + sessionController).
  return buildDio(tokens, onLogout: () async {
    await tokens.limpiar();
    await cache.limpiarSesion();
    ref.read(sessionControllerProvider.notifier).cerrar();
  });
});

/// Dio con base `.../api/v1` (sin sufijo `/auth`), para syncers y rutas
/// que viven fuera del espacio de autenticación (ej: /tutores/, /hijos/).
/// Comparte los mismos interceptors de auth que [dioProvider].
final dioV1Provider = Provider<Dio>((ref) {
  final tokens = ref.watch(tokenStorageProvider);
  final cache = ref.watch(databaseProvider);
  return buildDio(
    tokens,
    baseUrl: AppConfig.apiV1Base,
    onLogout: () async {
      await tokens.limpiar();
      await cache.limpiarSesion();
      ref.read(sessionControllerProvider.notifier).cerrar();
    },
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepositoryImpl(
      remote: AuthRemoteDataSourceImpl(ref.watch(dioProvider)),
      tokens: ref.watch(tokenStorageProvider),
      cache: ref.watch(databaseProvider),
    ));

final loginUseCaseProvider =
    Provider((ref) => Login(ref.watch(authRepositoryProvider)));

final hijosSyncerProvider = Provider<HijosSyncer>(
  (ref) => HijosSyncer(ref.watch(databaseProvider), ref.watch(dioV1Provider)),
);

final antecedentesNinoSyncerProvider = Provider<AntecedentesNinoSyncer>(
  (ref) => AntecedentesNinoSyncer(ref.watch(databaseProvider), ref.watch(dioV1Provider)),
);

final syncEngineProvider = Provider<SyncEngine>(
  (ref) => SyncEngine([
    ref.watch(hijosSyncerProvider),
    ref.watch(antecedentesNinoSyncerProvider),
  ]),
);

final connectivityServiceProvider =
    Provider<ConnectivityService>((ref) => ConnectivityService());

final syncSchedulerProvider = Provider<SyncScheduler>((ref) {
  final engine = ref.watch(syncEngineProvider);
  final conn = ref.watch(connectivityServiceProvider);
  final scheduler = SyncScheduler(
    onlineStream: conn.onlineStream,
    ejecutarCiclo: () => engine.ciclo(ahora: DateTime.now()),
  );
  ref.onDispose(scheduler.dispose);
  return scheduler;
});

final familiaRemoteDataSourceProvider =
    Provider<FamiliaRemoteDataSource>((ref) => FamiliaRemoteDataSource(ref.watch(dioV1Provider)));

/// Logout completo: limpia tokens + cache de Drift (authRepository.logout)
/// y el estado en memoria (sessionController.cerrar). El borrado del cache es
/// imprescindible: si no, hidratar() al arrancar re-autenticaría al usuario.
final logoutProvider = Provider<Future<void> Function()>((ref) {
  final repo = ref.read(authRepositoryProvider);
  final session = ref.read(sessionControllerProvider.notifier);
  return () async {
    await repo.logout();
    session.cerrar();
  };
});

final operativosRepositoryProvider = Provider<OperativosRepository>(
  (ref) => OperativosRepository(ref.watch(dioV1Provider)),
);

final escuelasRepositoryProvider = Provider<EscuelasRepository>(
  (ref) => EscuelasRepository(ref.watch(dioV1Provider)),
);

final alumnosEscuelaRepositoryProvider = Provider<AlumnosEscuelaRepository>(
  (ref) => AlumnosEscuelaRepository(ref.watch(dioV1Provider)),
);

final usuariosEscuelaRepositoryProvider = Provider<UsuariosEscuelaRepository>(
  (ref) => UsuariosEscuelaRepository(ref.watch(dioV1Provider)),
);

final usuariosAyudantesRepositoryProvider = Provider<UsuariosAyudantesRepository>(
  (ref) => UsuariosAyudantesRepository(ref.watch(dioV1Provider)),
);

final profesionalesRepositoryProvider = Provider<ProfesionalesRepository>(
  (ref) => ProfesionalesRepository(ref.watch(dioV1Provider)),
);

final usuarioRepositoryProvider = Provider<UsuarioRepository>(
  (ref) => UsuarioRepository(ref.watch(dioV1Provider)),
);
