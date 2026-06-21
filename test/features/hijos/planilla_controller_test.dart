import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/database/app_database.dart';
import 'package:prosane_app/features/hijos/presentation/controllers/planilla_controller.dart';

void main() {
  test('guardar arma payload y persiste draft pendiente', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final ctrl = PlanillaController(db: db, tutorId: 'tut-1', generarId: () => 'hijo-1');
    ctrl.setNombre('Juana');
    ctrl.setApellido('Pérez');
    ctrl.setDni('70000000');
    ctrl.setTipoDni('DNI');
    ctrl.setSexo('F');
    ctrl.setFechaNacimiento(DateTime(2015, 6, 1));
    ctrl.setEdad(10);
    ctrl.setAdultoNombre('Pedro');
    ctrl.setAdultoApellido('Pérez');
    ctrl.setAdultoTipoDocumento('DNI');
    ctrl.setAdultoDni('40000000');
    ctrl.setConsentimientoAceptado(true);

    await ctrl.guardar();

    expect(await db.contarHijosPendientes(), 1);
    final row = (await db.hijosPendientes()).single;
    expect(row.tutorId, 'tut-1');
    final body = jsonDecode(row.payloadJson) as Map<String, dynamic>;
    expect((body['persona'] as Map)['dni'], '70000000');
    expect((body['persona'] as Map)['tipo_dni'], 'DNI');
    expect((body['consentimiento'] as Map)['adulto_dni'], '40000000');
    await db.close();
  });
}
