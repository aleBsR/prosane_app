import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../data/usuarios_ayudantes_repository.dart';

final usuariosAyudantesListProvider =
    FutureProvider<List<UsuarioAyudante>>((ref) async {
  final repo = ref.watch(usuariosAyudantesRepositoryProvider);
  return repo.listar();
});