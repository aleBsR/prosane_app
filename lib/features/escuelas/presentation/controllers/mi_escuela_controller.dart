import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../../../core/session/session_controller.dart';

final miEscuelaProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  // Observar sesión para que al cambiar de usuario se refetchee y no quede cache de la escuela anterior (bug agus@gmail.com veía san agustin)
  ref.watch(sessionControllerProvider);
  return ref.watch(escuelasRepositoryProvider).miEscuela();
});
