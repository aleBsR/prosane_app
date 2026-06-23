import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';

final operativosListControllerProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(operativosRepositoryProvider);
  return repo.listar();
});
