import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../data/profesionales_repository.dart';

final profesionalesListProvider = FutureProvider<List<Profesional>>((ref) async {
  final repo = ref.watch(profesionalesRepositoryProvider);
  return repo.listar();
});
