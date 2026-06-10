import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'app_database.dart';

/// Abre la DB Drift nativa en el directorio de la app. Una sola instancia viva.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(LazyDatabase(() async {
    final dir = await getApplicationSupportDirectory();
    return NativeDatabase.createInBackground(File(p.join(dir.path, 'prosane.sqlite')));
  }));
  ref.onDispose(db.close);
  return db;
});
