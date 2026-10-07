import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../data/usuarios_administrativos_repository.dart';

final usuariosAdministrativosListProvider =
    FutureProvider<List<UsuarioAdministrativo>>((ref) async {
  final repo = ref.watch(usuariosAdministrativosRepositoryProvider);
  return repo.listar();
});