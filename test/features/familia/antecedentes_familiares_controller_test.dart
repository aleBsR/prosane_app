import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:prosane_app/features/familia/data/familia_remote_datasource.dart';
import 'package:prosane_app/features/familia/presentation/controllers/antecedentes_familiares_controller.dart';

class _MockDs extends Mock implements FamiliaRemoteDataSource {}

void main() {
  setUpAll(() => registerFallbackValue(<String, dynamic>{}));

  test('cargar(): precarga desde el backend', () async {
    final ds = _MockDs();
    when(() => ds.getAntecedentes(any())).thenAnswer((_) async => {
          'problema_salud_importante': 'si',
          'problema_salud_cual': 'asma',
          'muerte_subita_familiar': 'no',
        });
    final c = AntecedentesFamiliaresController(
        ds: ds, refrescarSesion: () async {}, tutorId: 'tut-1');
    await Future<void>.delayed(Duration.zero); // deja correr cargar() del constructor
    expect(c.state.problemaSalud, 'si');
    expect(c.state.problemaCual, 'asma');
    expect(c.state.muerteSubita, 'no');
  });

  test('guardar(): postea body correcto, refresca y marca exito', () async {
    final ds = _MockDs();
    when(() => ds.getAntecedentes(any()))
        .thenAnswer((_) async => <String, dynamic>{});
    when(() => ds.guardarAntecedentes(any(), any())).thenAnswer((_) async {});
    var refrescado = false;
    final c = AntecedentesFamiliaresController(
        ds: ds,
        refrescarSesion: () async => refrescado = true,
        tutorId: 'tut-1');
    c.setProblemaSalud('no');
    c.setMuerteSubita('no_sabe');
    await c.guardar();
    expect(c.state.exito, true);
    expect(refrescado, true);
    verify(() => ds.guardarAntecedentes('tut-1', {
          'problema_salud_importante': 'no',
          'problema_salud_cual': '',
          'muerte_subita_familiar': 'no_sabe',
        })).called(1);
  });

  test('guardar(): sin tutorId setea error', () async {
    final ds = _MockDs();
    final c = AntecedentesFamiliaresController(
        ds: ds, refrescarSesion: () async {}, tutorId: null);
    await c.guardar();
    expect(c.state.error, isNotNull);
    expect(c.state.exito, false);
    verifyNever(() => ds.guardarAntecedentes(any(), any()));
  });

  test('guardar(): error del backend setea mensaje', () async {
    final ds = _MockDs();
    when(() => ds.getAntecedentes(any()))
        .thenAnswer((_) async => <String, dynamic>{});
    when(() => ds.guardarAntecedentes(any(), any()))
        .thenThrow(Exception('network'));
    final c = AntecedentesFamiliaresController(
        ds: ds, refrescarSesion: () async {}, tutorId: 'tut-1');
    await c.guardar();
    expect(c.state.error, isNotNull);
    expect(c.state.exito, false);
  });
}
