import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../../../core/session/session_controller.dart';

final operativosListControllerProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  // Observar sesión para que al cambiar de usuario se refetchee y no quede
  // la lista del usuario anterior (bug: escuela veía los 5 del superadmin).
  ref.watch(sessionControllerProvider);
  final repo = ref.watch(operativosRepositoryProvider);
  return repo.listar();
});
