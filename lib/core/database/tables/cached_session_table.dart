import 'package:drift/drift.dart';

/// Caché del /me para arrancar offline (una sola fila, id fijo 'me').
/// Guarda TODO lo necesario para reconstruir la sesión sin red: usuario,
/// nombre, label del rol y la lista completa de acciones (accionesJson).
class CachedSessionRows extends Table {
  TextColumn get id => text()(); // singleton: siempre 'me'
  TextColumn get userId => text()();
  TextColumn get email => text()();
  TextColumn get nombre => text().nullable()(); // backend puede mandar null
  TextColumn get rolName => text()();
  TextColumn get rolLabel => text()();
  TextColumn get accionesJson => text()(); // JSON array de las 8 claves c/u
  TextColumn get metaVersion => text()();
  DateTimeColumn get permissionsSyncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
