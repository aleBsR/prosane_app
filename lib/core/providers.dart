import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'storage/token_storage.dart';
import 'network/dio_client.dart';
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

final authRepositoryProvider = Provider<AuthRepository>((ref) =>
    AuthRepositoryImpl(
        remote: AuthRemoteDataSourceImpl(ref.watch(dioProvider)),
        tokens: ref.watch(tokenStorageProvider)));

final loginUseCaseProvider =
    Provider((ref) => Login(ref.watch(authRepositoryProvider)));
