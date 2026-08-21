import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../data/usuarios_escuela_repository.dart';

final usuariosEscuelaListProvider =
    FutureProvider<List<UsuarioEscuela>>((ref) async {
  final repo = ref.watch(usuariosEscuelaRepositoryProvider);
  return repo.listar();
});
