import 'package:drift/drift.dart';
import '../sync_columns.dart';

/// Un hijo (Paciente) cargado por el tutor. Offline-first: se crea local
/// (pendiente) y el HijosSyncer lo empuja al endpoint agregado.
class HijosRows extends Table with SyncColumns {
  TextColumn get tutorId => text()();
  TextColumn get nombreNna => text().withDefault(const Constant(''))();
  TextColumn get apellidoNna => text().withDefault(const Constant(''))();
  TextColumn get payloadJson => text()(); // body exacto del POST /tutores/<id>/hijos/
  TextColumn get serverPacienteId => text().nullable()();
}
