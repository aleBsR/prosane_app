import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/database/app_database.dart';
import 'package:prosane_app/features/hijos/presentation/controllers/planilla_controller.dart';

void main() {
  test('guardar: payload con persona, domicilio(11), cobertura, telefonos a raiz y SIN antecedentes', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final ctrl = PlanillaController(db: db, tutorId: 'tut-1', generarId: () => 'h1');
    ctrl.setNombre('Juana');
    ctrl.setApellido('Pérez');
    ctrl.setDni('70000000');
    ctrl.setSexo('F');
    ctrl.setFechaNacimiento(DateTime(2015, 6, 1));
    ctrl.setTieneCud('SI');
    ctrl.setTelefonoFijo('0387-4000000');
    ctrl.setCelular('+5493870000000');
    ctrl.setCalle('San Martín');
    ctrl.setNroCalle('123');
    ctrl.setPiso('2');
    ctrl.setDpto('B');
    ctrl.setManzana('4');
    ctrl.setCasa('10');
    ctrl.setNroCasa('11');
    ctrl.setPieza('1');
    ctrl.setProvincia('Salta');
    ctrl.setDepartamento('Capital');
    ctrl.setLocalidad('Salta');
    ctrl.setTipoCobertura('obra_social');
    ctrl.setNombreCobertura('OSDE');

    await ctrl.guardar();

    final row = (await db.hijosPendientes()).single;
    expect(row.tutorId, 'tut-1');
    final body = jsonDecode(row.payloadJson) as Map<String, dynamic>;

    final persona = body['persona'] as Map;
    expect(persona['dni'], '70000000');
    expect(persona['fecha_nacimiento'], '2015-06-01');
    expect(persona.containsKey('telefono_fijo'), isFalse); // telefonos NO van en persona

    final dom = body['domicilio'] as Map;
    expect(dom.keys, containsAll(<String>[
      'calle','nro_calle','piso','dpto','manzana','casa','nro_casa','pieza','provincia','departamento','localidad',
    ]));
    expect(dom['piso'], '2');
    expect(dom['localidad'], 'Salta');

    expect(body['edad'], greaterThanOrEqualTo(9));
    expect(body['tiene_cud'], 'SI');
    expect(body['tipo_cobertura'], 'obra_social');
    expect(body['nombre_cobertura'], 'OSDE');
    expect(body['telefono_fijo'], '0387-4000000'); // a nivel raiz (Paciente)
    expect(body['celular'], '+5493870000000');

    expect(body.containsKey('antecedentes_personales'), isFalse);
    expect(body.containsKey('consentimiento'), isFalse);
    expect(body.containsKey('antecedentes_familiares'), isFalse);

    await db.close();
  });

  test('pideNombreCobertura es true solo para obra_social y prepaga', () {
    const base = PlanillaState();
    expect(base.copyWith(tipoCobertura: 'obra_social').pideNombreCobertura, isTrue);
    expect(base.copyWith(tipoCobertura: 'prepaga').pideNombreCobertura, isTrue);
    expect(base.copyWith(tipoCobertura: 'estatal').pideNombreCobertura, isFalse);
    expect(base.copyWith(tipoCobertura: 'sin_cobertura').pideNombreCobertura, isFalse);
  });

  test('setTipoCobertura limpia nombre_cobertura al cambiar a una sin nombre', () {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final ctrl = PlanillaController(db: db, tutorId: 'tut-1');
    ctrl.setTipoCobertura('obra_social');
    ctrl.setNombreCobertura('OSDE');
    expect(ctrl.state.nombreCobertura, 'OSDE'); // se mantiene

    ctrl.setTipoCobertura('sin_cobertura');
    expect(ctrl.state.pideNombreCobertura, isFalse);
    expect(ctrl.state.nombreCobertura, isEmpty); // se limpió
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
