import 'package:drift/drift.dart';

/// Watermark de pull incremental POR FEATURE (nunca global).
class SyncStateRows extends Table {
  TextColumn get feature => text()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  @override
  Set<Column> get primaryKey => {feature};
}
