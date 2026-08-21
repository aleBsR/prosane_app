import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';

final miEscuelaProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.watch(escuelasRepositoryProvider).miEscuela();
});
