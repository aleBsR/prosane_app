import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'storage/token_storage.dart';
import 'network/dio_client.dart';
import 'database/database_provider.dart';
import '../features/auth/data/datasources/auth_remote_datasource.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/usecases/login.dart';
import 'session/session_controller.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final dioProvider = Provider((ref) {
  final tokens = ref.watch(tokenStorageProvider);
  return buildDio(tokens,
      onLogout: () async =>
          ref.read(sessionControllerProvider.notifier).cerrar());
});

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepositoryImpl(
      remote: AuthRemoteDataSourceImpl(ref.watch(dioProvider)),
      tokens: ref.watch(tokenStorageProvider),
      cache: ref.watch(databaseProvider),
    ));

final loginUseCaseProvider =
    Provider((ref) => Login(ref.watch(authRepositoryProvider)));

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
