import 'entities.dart';

/// Puerto de persistencia de la sesión (lo implementa AppDatabase con Drift).
/// Vive en core/session (junto a Sesion/entities) para que core/database lo
/// implemente sin que core dependa de un feature.
abstract class SessionCache {
  Future<void> guardarSesion(Sesion s, {required String email, required String version, required String syncedAtIso});
  Future<Sesion?> leerSesion();
  Future<void> limpiarSesion();
}
