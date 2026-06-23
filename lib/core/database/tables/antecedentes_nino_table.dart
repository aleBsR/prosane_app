import 'package:drift/drift.dart';
import '../sync_columns.dart';

class AntecedentesNinoRows extends Table with SyncColumns {
  TextColumn get hijoLocalId => text()();
  TextColumn get payloadJson => text()();
}
