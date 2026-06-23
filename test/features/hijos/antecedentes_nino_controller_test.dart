import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/database/app_database.dart';
import 'package:prosane_app/features/hijos/presentation/controllers/antecedentes_nino_controller.dart';

void main() {
  Future<AppDatabase> dbConHijo({String sexo = 'F'}) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.insertHijoDraft(
      id: 'h1', tutorId: 'tut-1', nombreNna: 'Ana', apellidoNna: 'Pérez',
      payloadJson: jsonEncode({'persona': {'sexo': sexo}}),
    );
    return db;
  }

  test('guardar arma el payload de los 20 campos y hace upsert', () async {
    final db = await dbConHijo();
    final ctrl = AntecedentesNinoController(db: db, hijoLocalId: 'h1', generarId: () => 'a1');
    await ctrl.listo; // espera la precarga inicial
    ctrl.setCampo('diabetes', 'si');
    ctrl.setPesoNacimiento('3.4');
    ctrl.setEdadMenstruacion('12');
    await ctrl.guardar();

    final row = await db.antecedenteNinoPorHijo('h1');
    final body = jsonDecode(row!.payloadJson) as Map<String, dynamic>;
    expect(body['diabetes'], 'si');
    expect(body['peso_nacimiento'], '3.4');
    expect(body['edad_primera_menstruacion'], 12);
    expect(body.containsKey('nacio_prematuro'), isTrue);
    expect(ctrl.state.exito, isTrue);
    await db.close();
  });

  test('precarga: lee el borrador existente', () async {
    final db = await dbConHijo();
    await db.upsertAntecedenteNinoDraft(
      id: 'a0', hijoLocalId: 'h1', payloadJson: jsonEncode({'diabetes': 'si', 'peso_nacimiento': '2.9'}),
    );
    final ctrl = AntecedentesNinoController(db: db, hijoLocalId: 'h1', generarId: () => 'a1');
    await ctrl.listo;
    expect(ctrl.state.respuestas['diabetes'], 'si');
    expect(ctrl.state.pesoNacimiento, '2.9');
    await db.close();
  });

  test('esFemenino refleja el sexo del hijo', () async {
    final db = await dbConHijo(sexo: 'M');
    final ctrl = AntecedentesNinoController(db: db, hijoLocalId: 'h1', generarId: () => 'a1');
    await ctrl.listo;
    expect(ctrl.state.esFemenino, isFalse);
    await db.close();
  });
}
