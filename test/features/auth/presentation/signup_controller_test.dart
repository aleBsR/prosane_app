import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:prosane_app/core/error/failure.dart';
import 'package:prosane_app/features/auth/domain/usecases/register.dart';
import 'package:prosane_app/features/auth/presentation/controllers/signup_controller.dart';

class _MockRegister extends Mock implements Register {}

SignupController _ctrl([Register? reg]) =>
    SignupController(register: reg ?? _MockRegister());

void main() {
  test('etapa 0: inválida sin aceptar política; válida con doc + política', () {
    final c = _ctrl();
    c.setTipoDocumento('DNI');
    c.setNumeroDocumento('12345678');
    expect(c.etapaValida(0), false); // falta aceptar política
    c.setAceptaPolitica(true);
    expect(c.etapaValida(0), true);
  });

  test('etapa 2: email != confirmEmail es inválida', () {
    final c = _ctrl();
    c.setPaisResidencia('Argentina');
    c.setEmail('a@b.com');
    c.setConfirmEmail('x@b.com');
    expect(c.etapaValida(2), false);
    c.setConfirmEmail('a@b.com');
    expect(c.etapaValida(2), true);
  });

  test('etapa 3: password != confirmPassword es inválida; corta también', () {
    final c = _ctrl();
    c.setPassword('Secreto123');
    c.setConfirmPassword('otra');
    expect(c.etapaValida(3), false);
    c.setConfirmPassword('Secreto123');
    expect(c.etapaValida(3), true);
    c.setPassword('123'); c.setConfirmPassword('123');
    expect(c.etapaValida(3), false); // muy corta
  });

  test('siguiente() avanza solo si la etapa actual es válida; anterior() conserva datos', () {
    final c = _ctrl();
    c.siguiente(); // etapa 0 inválida → no avanza
    expect(c.state.currentStep, 0);
    c.setTipoDocumento('DNI');
    c.setNumeroDocumento('12345678');
    c.setAceptaPolitica(true);
    c.siguiente();
    expect(c.state.currentStep, 1);
    c.anterior();
    expect(c.state.currentStep, 0);
    expect(c.state.formData.numeroDocumento, '12345678'); // datos conservados
  });

  test('enviar(): con datos válidos llama Register y marca registrado', () async {
    final reg = _MockRegister();
    when(() => reg.call(any())).thenAnswer((_) async {});
    final c = _llenarTodo(_ctrl(reg));
    await c.enviar();
    verify(() => reg.call(any())).called(1);
    expect(c.state.registrado, true);
    expect(c.state.error, isNull);
  });

  test('enviar(): un Failure setea el mensaje de error y NO marca registrado', () async {
    final reg = _MockRegister();
    when(() => reg.call(any())).thenThrow(const ServerFailure());
    final c = _llenarTodo(_ctrl(reg));
    await c.enviar();
    expect(c.state.error, 'Hubo un problema, probá de nuevo');
    expect(c.state.registrado, false);
  });

  test('enviar(): NO llama Register si faltan etapas anteriores (valida todo el form)', () async {
    final reg = _MockRegister();
    when(() => reg.call(any())).thenAnswer((_) async {});
    final c = _ctrl(reg);
    // Solo se completa la etapa 3; las 0–2 quedan incompletas.
    c.setPassword('Secreto123');
    c.setConfirmPassword('Secreto123');
    await c.enviar();
    verifyNever(() => reg.call(any()));
    expect(c.state.registrado, false);
  });

  test('enviar(): un error no-Failure cae al mensaje genérico', () async {
    final reg = _MockRegister();
    when(() => reg.call(any())).thenThrow(Exception('raro')); // NO es Failure
    final c = _llenarTodo(_ctrl(reg));
    await c.enviar();
    expect(c.state.error, 'Hubo un problema, probá de nuevo');
    expect(c.state.registrado, false);
  });

  test('enviar(): no registra dos veces (guard de doble-submit)', () async {
    final reg = _MockRegister();
    when(() => reg.call(any())).thenAnswer((_) async {});
    final c = _llenarTodo(_ctrl(reg));
    await c.enviar();
    await c.enviar(); // segunda llamada: ya registrado → no hace nada
    verify(() => reg.call(any())).called(1);
  });
}

SignupController _llenarTodo(SignupController c) {
  c.setTipoDocumento('DNI');
  c.setNumeroDocumento('12345678');
  c.setAceptaPolitica(true);
  c.setNombre('Ana'); c.setApellido('Gómez'); c.setSexo('F');
  c.setFechaNacimiento(DateTime.utc(2010, 5, 1)); c.setLugarNacimiento('Salta');
  c.setPaisResidencia('Argentina');
  c.setEmail('a@b.com'); c.setConfirmEmail('a@b.com');
  c.setPassword('Secreto123'); c.setConfirmPassword('Secreto123');
  return c;
}
