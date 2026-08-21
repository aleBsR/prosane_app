import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../data/escuelas_repository.dart';

final escuelasListControllerProvider =
    FutureProvider<List<Escuela>>((ref) async {
  final repo = ref.watch(escuelasRepositoryProvider);
  return repo.listar();
});
