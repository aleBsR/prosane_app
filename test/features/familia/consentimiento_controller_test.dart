import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:prosane_app/features/familia/data/familia_remote_datasource.dart';
import 'package:prosane_app/features/familia/presentation/controllers/consentimiento_controller.dart';

class _MockDs extends Mock implements FamiliaRemoteDataSource {}

void main() {
  test('confirmar(): postea, refresca y marca exito', () async {
    final ds = _MockDs();
    when(() => ds.aceptarConsentimiento(any())).thenAnswer((_) async {});
    var refrescado = false;
    final c = ConsentimientoController(
      ds: ds,
      refrescarSesion: () async => refrescado = true,
      tutorId: 'tut-1',
    );
    c.setAceptado(true);
    await c.confirmar();
    expect(c.state.exito, true);
    expect(refrescado, true);
    verify(() => ds.aceptarConsentimiento('tut-1')).called(1);
  });

  test('confirmar(): sin aceptar no hace nada', () async {
    final ds = _MockDs();
    final c = ConsentimientoController(
      ds: ds,
      refrescarSesion: () async {},
      tutorId: 'tut-1',
    );
    await c.confirmar();
    expect(c.state.exito, false);
    verifyNever(() => ds.aceptarConsentimiento(any()));
  });

  test('confirmar(): error del backend setea mensaje', () async {
    final ds = _MockDs();
    when(() => ds.aceptarConsentimiento(any())).thenThrow(Exception('x'));
    final c = ConsentimientoController(
      ds: ds,
      refrescarSesion: () async {},
      tutorId: 'tut-1',
    );
    c.setAceptado(true);
    await c.confirmar();
    expect(c.state.error, isNotNull);
    expect(c.state.exito, false);
  });
}
