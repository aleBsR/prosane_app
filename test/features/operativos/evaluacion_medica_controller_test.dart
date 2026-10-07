import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:prosane_app/core/providers.dart';
import 'package:prosane_app/features/operativos/data/operativos_repository.dart';
import 'package:prosane_app/features/operativos/presentation/controllers/evaluacion_medica_controller.dart';

class _MockRepo extends Mock implements OperativosRepository {}

DioException _dio404() => DioException(
      requestOptions: RequestOptions(path: ''),
      response:
          Response(requestOptions: RequestOptions(path: ''), statusCode: 404),
    );

ProviderContainer _container(_MockRepo repo) => ProviderContainer(
      overrides: [operativosRepositoryProvider.overrideWithValue(repo)],
    );

const _args = (opId: 'op1', alumnoId: 'a1');

Future<EvaluacionMedicaController> _ctrl(ProviderContainer c) async {
  // El provider es autoDispose: sin listener se destruye en cada read.
  final sub = c.listen(
    evaluacionMedicaControllerProvider(_args),
    (_, _) {},
  );
  addTearDown(sub.close);
  final ctrl =
      c.read(evaluacionMedicaControllerProvider(_args).notifier);
  for (var i = 0;
      i < 20 &&
          c.read(evaluacionMedicaControllerProvider(_args)).cargando;
      i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  return ctrl;
}

void main() {
  test('paso inicial 0 y validación por paso', () async {
    final repo = _MockRepo();
    when(() => repo.getEvaluacionMedica(any(), any()))
        .thenThrow(_dio404());
    final c = _container(repo);
    addTearDown(c.dispose);

    await _ctrl(c);
    var s = c.read(evaluacionMedicaControllerProvider(_args));
    expect(s.paso, 0);
    // Por defecto examen realizado sin lugar → falta lugar del examen.
    expect(
        c
            .read(evaluacionMedicaControllerProvider(_args).notifier)
            .validarPaso(0),
        contains('lugar del examen'));
  });

  test('intentarAvanzar bloquea con faltantes y autogarda al completar',
      () async {
    final repo = _MockRepo();
    when(() => repo.getEvaluacionMedica(any(), any()))
        .thenThrow(_dio404());
    registerFallbackValue(<String, dynamic>{});
    Map<String, dynamic>? enviado;
    when(() => repo.putEvaluacionMedica(any(), any(), any()))
        .thenAnswer((inv) async {
      enviado = inv.positionalArguments[2] as Map<String, dynamic>;
      return <String, dynamic>{};
    });
    final c = _container(repo);
    addTearDown(c.dispose);

    final ctrl = await _ctrl(c);
    expect(await ctrl.intentarAvanzar(), false);
    var s = c.read(evaluacionMedicaControllerProvider(_args));
    expect(s.paso, 0);
    expect(s.error, contains('lugar del examen'));
    verifyNever(() => repo.putEvaluacionMedica(any(), any(), any()));

    ctrl.setLugarExamen('escuela');
    expect(await ctrl.intentarAvanzar(), true);
    s = c.read(evaluacionMedicaControllerProvider(_args));
    expect(s.paso, 1);
    verify(() => repo.putEvaluacionMedica(any(), any(), any())).called(1);
    expect(enviado?['completar'], false);
  });

  test('guardarAvance envía completar:false y limpia dirty', () async {
    final repo = _MockRepo();
    when(() => repo.getEvaluacionMedica(any(), any()))
        .thenThrow(_dio404());
    registerFallbackValue(<String, dynamic>{});
    Map<String, dynamic>? enviado;
    when(() => repo.putEvaluacionMedica(any(), any(), any()))
        .thenAnswer((inv) async {
      enviado = inv.positionalArguments[2] as Map<String, dynamic>;
      return <String, dynamic>{};
    });
    final c = _container(repo);
    addTearDown(c.dispose);

    final ctrl = await _ctrl(c);
    ctrl.setLugarExamen('escuela');
    var s = c.read(evaluacionMedicaControllerProvider(_args));
    expect(ctrl.tieneCambiosSinGuardar, true);

    final ok = await ctrl.guardarAvance();
    expect(ok, true);
    expect(enviado?['completar'], false);
    expect(enviado?['lugar_examen'], 'escuela');
    s = c.read(evaluacionMedicaControllerProvider(_args));
    expect(ctrl.tieneCambiosSinGuardar, false);
    expect(s.error, isNull);
  });

  test('guardar final envía completar:true', () async {
    final repo = _MockRepo();
    when(() => repo.getEvaluacionMedica(any(), any()))
        .thenThrow(_dio404());
    registerFallbackValue(<String, dynamic>{});
    Map<String, dynamic>? enviado;
    when(() => repo.putEvaluacionMedica(any(), any(), any()))
        .thenAnswer((inv) async {
      enviado = inv.positionalArguments[2] as Map<String, dynamic>;
      return <String, dynamic>{};
    });
    final c = _container(repo);
    addTearDown(c.dispose);

    final ctrl = await _ctrl(c);
    ctrl.setLugarExamen('escuela');
    ctrl.setAntropometriaEvaluada(false);
    ctrl.setPresionEvaluada(false);
    final ok = await ctrl.guardar();
    expect(ok, true);
    expect(enviado?['completar'], true);
  });

  test('validar agrega secciones: antropometría incompleta', () async {
    final repo = _MockRepo();
    when(() => repo.getEvaluacionMedica(any(), any()))
        .thenThrow(_dio404());
    final c = _container(repo);
    addTearDown(c.dispose);

    final ctrl = await _ctrl(c);
    // Antropometría evaluada por defecto sin peso → falta.
    expect(ctrl.validarPaso(1), contains('peso'));
    ctrl.setAntropometriaEvaluada(false);
    expect(ctrl.validarPaso(1), isNull);
    // El validar() total agrega todas las secciones.
    ctrl.setLugarExamen('escuela');
    ctrl.setPresionEvaluada(false);
    expect(ctrl.validar(), isNull);
  });
}
