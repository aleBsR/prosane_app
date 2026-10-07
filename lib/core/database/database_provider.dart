import 'dart:io';
import 'dart:math';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'app_database.dart';

/// Clave hex de 256 bits en almacenamiento seguro (nunca en prefs ni logs).
const _kDbKey = 'prosane_db_key';

Future<String> _claveDb() async {
  const store = FlutterSecureStorage();
  final guardada = await store.read(key: _kDbKey);
  if (guardada != null && guardada.isNotEmpty) return guardada;
  final rnd = Random.secure();
  final hex = [
    for (var i = 0; i < 32; i++) rnd.nextInt(256),
  ].map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  await store.write(key: _kDbKey, value: hex);
  return hex;
}

String _pragmaKey(String hexKey) => 'PRAGMA key = "x\'$hexKey\'";';

/// Migra una base plana legacy a cifrada (Anexo I: resguardo local).
/// Idempotente: archivo inexistente, vacío o ya cifrado → no hace nada.
/// Si la clave se perdió (irrecuperable por diseño), resguarda el archivo
/// como `.ilegible` y deja que drift cree una base nueva.
/// Pública para poder testearla.
Future<void> migrarBaseSiPlana(File file, String hexKey) async {
  if (!file.existsSync()) return;
  sqlite3.Database? db;
  var abierta = false;
  try {
    db = sqlite3.sqlite3.open(file.path);
    abierta = true;
    List<sqlite3.Row> tablas;
    try {
      tablas = db.select(
        "SELECT name FROM sqlite_master WHERE type='table' "
        "AND name NOT LIKE 'sqlite_%';",
      );
    } catch (_) {
      // No abre sin clave: puede estar cifrada. Probar con la clave.
      try {
        db.execute(_pragmaKey(hexKey));
        db.execute('SELECT count(*) FROM sqlite_master;');
        return; // cifrada OK
      } catch (_) {
        // Ni plana ni abre con nuestra clave: resguardar y empezar de cero.
        final rota = File('${file.path}.ilegible');
        if (rota.existsSync()) rota.deleteSync();
        file.renameSync(rota.path);
        return;
      } finally {
        db.close();
        abierta = false;
      }
    }
    if (tablas.isEmpty) return; // vacía: drift la crea cifrada
    final tmp = File('${file.path}.cifrada');
    if (tmp.existsSync()) tmp.deleteSync();
    final ruta = tmp.path.replaceAll("'", "''");
    db.execute('ATTACH DATABASE \'$ruta\' AS cifrada KEY "x\'$hexKey\'";');
    db.execute("SELECT sqlcipher_export('cifrada');");
    db.execute('DETACH DATABASE cifrada;');
    db.close();
    abierta = false;
    file.deleteSync();
    tmp.renameSync(file.path);
  } finally {
    if (abierta) db!.close();
  }
}

/// Abre la DB Drift nativa, cifrada con SQLCipher. Una sola instancia viva.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(LazyDatabase(() async {
    final dir = await getApplicationSupportDirectory();
    final file = File(p.join(dir.path, 'prosane.sqlite'));
    final hexKey = await _claveDb();
    await migrarBaseSiPlana(file, hexKey);
    return NativeDatabase.createInBackground(file, setup: (raw) {
      raw.execute(_pragmaKey(hexKey));
    });
  }));
  ref.onDispose(db.close);
  return db;
});
