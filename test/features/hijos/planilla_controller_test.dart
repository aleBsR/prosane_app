import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/database/app_database.dart';
import 'package:prosane_app/features/hijos/presentation/controllers/planilla_controller.dart';

void main() {
  test('guardar: edad derivada y payload SIN consentimiento ni antecedentes_familiares', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final ctrl = PlanillaController(db: db, tutorId: 'tut-1', generarId: () => 'h1');
    ctrl.setNombre('Juana');
    ctrl.setApellido('Pérez');
    ctrl.setDni('70000000');
    ctrl.setSexo('F');
    ctrl.setFechaNacimiento(DateTime(2015, 6, 1));
    await ctrl.guardar();
    final body =
        jsonDecode((await db.hijosPendientes()).single.payloadJson) as Map<String, dynamic>;
    expect((body['persona'] as Map)['dni'], '70000000');
    expect(body['edad'], greaterThanOrEqualTo(9));
    expect(body.containsKey('consentimiento'), isFalse);
    expect(body.containsKey('antecedentes_familiares'), isFalse);
    expect((body['antecedentes_personales'] as Map)['asma_espasmos'], isA<bool>());
    await db.close();
  });

  test('puedeGuardar exige nombre/apellido/dni/fecha/sexo', () {
    const base = PlanillaState();
    expect(base.puedeGuardar, isFalse);
    final ok = base.copyWith(
      nombre: 'J', apellido: 'P', dni: '1', sexo: 'F', fechaNacimiento: DateTime(2015, 6, 1),
    );
    expect(ok.puedeGuardar, isTrue);
  });
}
