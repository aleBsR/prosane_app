import 'package:drift/drift.dart';

enum SyncStatus { pendiente, sincronizado, error } // Drift lo serializa por índice vía intEnum

/// Mixin con la metadata de sync que toda tabla de dominio hereda.
/// (Espejo del BaseModel del API: id UUID generado en cliente, updatedAt,
/// estado de sync y tombstone para borrados.)
///
/// Define `primaryKey = {id}`. Si una tabla necesita PK compuesta, debe
/// sobreescribir `primaryKey` en la clase concreta.
mixin SyncColumns on Table {
  TextColumn get id => text()();                                   // UUID generado en cliente
  // clientDefault: se setea a "ahora" (UTC) en cada insert sin que el caller
  // tenga que recordarlo. Es client-side (no toca el esquema SQL).
  DateTimeColumn get updatedAt => dateTime().clientDefault(() => DateTime.now().toUtc())();
  // Default = pendiente por su índice (evita hardcodear 0): si el enum se
  // reordena, el cambio queda visible acá. Genera el mismo DEFAULT en SQL.
  IntColumn get syncStatus =>
      intEnum<SyncStatus>().withDefault(Constant(SyncStatus.pendiente.index))();
  DateTimeColumn get deletedAt => dateTime().nullable()();         // tombstone

  @override
  Set<Column> get primaryKey => {id};
}
