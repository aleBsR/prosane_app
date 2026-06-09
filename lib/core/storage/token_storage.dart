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

class TokenStorage {
  TokenStorage({KeyValueStore? backend}) : _b = backend ?? SecureKeyValueStore();
  final KeyValueStore _b;
  static const _kAccess = 'jwt_access', _kRefresh = 'jwt_refresh';

  Future<void> guardar({required String access, required String refresh}) async {
    await _b.write(_kAccess, access);
    await _b.write(_kRefresh, refresh);
  }
  Future<String?> access() => _b.read(_kAccess);
  Future<String?> refresh() => _b.read(_kRefresh);
  Future<void> limpiar() async { await _b.delete(_kAccess); await _b.delete(_kRefresh); }
}
