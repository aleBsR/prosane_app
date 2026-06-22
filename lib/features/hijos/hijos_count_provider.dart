import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/database_provider.dart';

/// Total de hijos cargados localmente (no borrados).
/// Usado por PendientesScreen para mostrar el nudge de consentimiento
/// cuando un tutor aún no registró ningún hijo.
final hijosCountProvider = FutureProvider<int>(
  (ref) => ref.watch(databaseProvider).contarHijos(),
);
