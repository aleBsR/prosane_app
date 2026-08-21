import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class KeyValueStore {
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
}

class SecureKeyValueStore implements KeyValueStore {
  final _s = const FlutterSecureStorage();
  @override Future<void> write(String k, String v) => _s.write(key: k, value: v);
  @override Future<String?> read(String k) => _s.read(key: k);
  @override Future<void> delete(String k) => _s.delete(key: k);
}

class InMemoryKeyValueStore implements KeyValueStore {
  final _m = <String, String>{};
  @override Future<void> write(String k, String v) async => _m[k] = v;
  @override Future<String?> read(String k) async => _m[k];
  @override Future<void> delete(String k) async => _m.remove(k);
}

/// Guarda los JWT según el modo de la sesión.
///
/// - `persistente: true` (default): escribe en el backend seguro. Es la sesión
///   con "Recordarme" activado: sobrevive al cierre de la app.
/// - `persistente: false`: escribe SOLO en memoria. Es la sesión efímera
///   ("Recordarme" apagado): al cerrar la app no queda nada en disco.
/// - `persistente: null` (omiso): conserva el modo actual (los refrescos de
///   token no deben "subir de nivel" una sesión efímera a persistente).
class TokenStorage {
  TokenStorage({KeyValueStore? backend}) : _b = backend ?? SecureKeyValueStore();
  final KeyValueStore _b;
  final KeyValueStore _m = InMemoryKeyValueStore();
  bool _persistente = true;
  static const _kAccess = 'jwt_access', _kRefresh = 'jwt_refresh';

  Future<void> guardar({
    required String access,
    required String refresh,
    bool? persistente,
  }) async {
    _persistente = persistente ?? _persistente;
    if (_persistente) {
      // Sesión persistente: limpia la efímera previa y escribe en disco.
      await _m.delete(_kAccess);
      await _m.delete(_kRefresh);
      await _b.write(_kAccess, access);
      await _b.write(_kRefresh, refresh);
    } else {
      // Sesión efímera: limpia el disco (no filtra una sesión vieja) y
      // escribe solo en memoria.
      await _b.delete(_kAccess);
      await _b.delete(_kRefresh);
      await _m.write(_kAccess, access);
      await _m.write(_kRefresh, refresh);
    }
  }
  Future<String?> access() async => await _m.read(_kAccess) ?? await _b.read(_kAccess);
  Future<String?> refresh() async => await _m.read(_kRefresh) ?? await _b.read(_kRefresh);
  Future<void> limpiar() async {
    _persistente = true;
    await _b.delete(_kAccess);
    await _b.delete(_kRefresh);
    await _m.delete(_kAccess);
    await _m.delete(_kRefresh);
  }
}
