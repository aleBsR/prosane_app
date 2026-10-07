import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/database/database_provider.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

const _key =
    '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';

void main() {
  test('SQLCipher disponible y PRAGMA key funciona', () {
    final db = sqlite3.sqlite3.openInMemory();
    db.execute('PRAGMA key = "x\'$_key\'";');
    db.execute('CREATE TABLE t (id INTEGER PRIMARY KEY, v TEXT);');
    db.execute("INSERT INTO t (v) VALUES ('hola');");
    expect(db.select('SELECT v FROM t;').first['v'], 'hola');
    final ver =
        db.select('PRAGMA cipher_version;').first.values.first as String;
    // SQLCipher reporta "4.x community"; SQLite plano devuelve NULL/vacío.
    expect(ver, isNotEmpty);
    db.close();
  });

  test('migrarBaseSiPlana cifra una base plana sin perder datos', () async {
    final dir = await Directory.systemTemp.createTemp('prosane-enc');
    try {
      final file = File('${dir.path}/prosane.sqlite');
      final plano = sqlite3.sqlite3.open(file.path);
      plano.execute('CREATE TABLE t (id INTEGER PRIMARY KEY, v TEXT);');
      plano.execute("INSERT INTO t (v) VALUES ('secreto');");
      plano.close();

      await migrarBaseSiPlana(file, _key);

      // Sin clave ya no abre (cifrada).
      final sinClave = sqlite3.sqlite3.open(file.path);
      expect(
        () => sinClave.execute('SELECT count(*) FROM sqlite_master;'),
        throwsA(anything),
      );
      sinClave.close();

      // Con clave abre y conserva los datos.
      final conClave = sqlite3.sqlite3.open(file.path);
      conClave.execute('PRAGMA key = "x\'$_key\'";');
      expect(
        conClave.select('SELECT v FROM t;').first['v'],
        'secreto',
      );
      conClave.close();
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('migrarBaseSiPlana es idempotente (segunda pasada no rompe)', () async {
    final dir = await Directory.systemTemp.createTemp('prosane-enc2');
    try {
      final file = File('${dir.path}/prosane.sqlite');
      final plano = sqlite3.sqlite3.open(file.path);
      plano.execute('CREATE TABLE t (id INTEGER PRIMARY KEY);');
      plano.close();

      await migrarBaseSiPlana(file, _key);
      await migrarBaseSiPlana(file, _key);

      final conClave = sqlite3.sqlite3.open(file.path);
      conClave.execute('PRAGMA key = "x\'$_key\'";');
      expect(
        conClave
            .select("SELECT name FROM sqlite_master WHERE name='t';")
            .length,
        1,
      );
      conClave.close();
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('migrarBaseSiPlana no hace nada si no hay archivo', () async {
    final dir = await Directory.systemTemp.createTemp('prosane-enc3');
    try {
      await migrarBaseSiPlana(File('${dir.path}/noexiste.sqlite'), _key);
    } finally {
      await dir.delete(recursive: true);
    }
  });
}
