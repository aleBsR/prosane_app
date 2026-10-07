import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:prosane_app/core/providers.dart';
import 'package:prosane_app/features/operativos/data/operativos_repository.dart';
import 'package:prosane_app/features/operativos/presentation/controllers/evaluacion_odontologica_controller.dart';

class _MockRepo extends Mock implements OperativosRepository {}

DioException _dio404() => DioException(
      requestOptions: RequestOptions(path: ''),
      response: Response(requestOptions: RequestOptions(path: ''), statusCode: 404),
    );

ProviderContainer _container(_MockRepo repo) => ProviderContainer(
      overrides: [operativosRepositoryProvider.overrideWithValue(repo)],
    );

const _args = (opId: 'op1', alumnoId: 'a1');

Future<EvaluacionOdontologicaController> _ctrl(
    ProviderContainer c) async {
  // El provider es autoDispose: sin listener se destruye en cada read y
  // _cargar() nunca termina. La suscripción lo mantiene vivo.
  final sub = c.listen(
    evaluacionOdontologicaControllerProvider(_args),
    (_, _) {},
  );
  addTearDown(sub.close);
  final ctrl = c.read(evaluacionOdontologicaControllerProvider(_args).notifier);
  // Espera a que termine _cargar() del constructor.
  for (var i = 0; i < 20 && c.read(evaluacionOdontologicaControllerProvider(_args)).cargando; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  return ctrl;
}

void main() {
  test('evaluación nueva: salud bucal por defecto No evaluado', () async {
    final repo = _MockRepo();
    when(() => repo.getEvaluacionOdontologica(any(), any())).thenThrow(_dio404());
    final c = _container(repo);
    addTearDown(c.dispose);

    final ctrl = await _ctrl(c);
    final s = c.read(evaluacionOdontologicaControllerProvider(_args));
    expect(s.cargando, false);
    expect(s.saludBucal, 'no_eval');
    expect(s.otrosMarcado, false);
    expect(ctrl, isNotNull);
  });

  test('salir de Con hallazgos limpia checks y Otros', () async {
    final repo = _MockRepo();
    when(() => repo.getEvaluacionOdontologica(any(), any())).thenThrow(_dio404());
    final c = _container(repo);
    addTearDown(c.dispose);

    final ctrl = await _ctrl(c);
    ctrl.setSaludBucal('con_hallazgos');
    ctrl.setCaries(true);
    ctrl.setMaloclusion(true);
    ctrl.setOtrosMarcado(true);
    ctrl.setOtros('algo');
    ctrl.setSaludBucal('sin_hallazgos');

    final s = c.read(evaluacionOdontologicaControllerProvider(_args));
    expect(s.saludBucal, 'sin_hallazgos');
    expect(s.caries, false);
    expect(s.maloclusion, false);
    expect(s.otrosMarcado, false);
    expect(s.otros, '');
  });

  test('desmarcar Otros borra el texto', () async {
    final repo = _MockRepo();
    when(() => repo.getEvaluacionOdontologica(any(), any())).thenThrow(_dio404());
    final c = _container(repo);
    addTearDown(c.dispose);

    final ctrl = await _ctrl(c);
    ctrl.setSaludBucal('con_hallazgos');
    ctrl.setOtrosMarcado(true);
    ctrl.setOtros('detalle');
    ctrl.setOtrosMarcado(false);

    final s = c.read(evaluacionOdontologicaControllerProvider(_args));
    expect(s.otrosMarcado, false);
    expect(s.otros, '');
  });

  test('carga existente con Otros lo deja marcado', () async {
    final repo = _MockRepo();
    when(() => repo.getEvaluacionOdontologica(any(), any())).thenAnswer(
      (_) async => <String, dynamic>{
        'salud_bucal': 'con_hallazgos',
        'lesiones_tejidos_blandos': true,
        'maloclusion': false,
        'fluorosis': false,
        'caries': false,
        'otros': 'otra cosa',
      },
    );
    final c = _container(repo);
    addTearDown(c.dispose);

    await _ctrl(c);
    final s = c.read(evaluacionOdontologicaControllerProvider(_args));
    expect(s.saludBucal, 'con_hallazgos');
    expect(s.lesionesTejidosBlandos, true);
    expect(s.otrosMarcado, true);
    expect(s.otros, 'otra cosa');
  });

  test('guardar envía no_eval y sin Otros si no está marcado', () async {    final repo = _MockRepo();
    when(() => repo.getEvaluacionOdontologica(any(), any())).thenThrow(_dio404());
    registerFallbackValue(<String, dynamic>{});
    Map<String, dynamic>? enviado;
    when(() => repo.putEvaluacionOdontologica(any(), any(), any()))
        .thenAnswer((inv) async {
      enviado = inv.positionalArguments[2] as Map<String, dynamic>;
      return <String, dynamic>{};
    });
    final c = _container(repo);
    addTearDown(c.dispose);

    final ctrl = await _ctrl(c);
    final ok = await ctrl.guardar();
    expect(ok, true);
    expect(enviado?['salud_bucal'], 'no_eval');
    expect(enviado?['lesiones_tejidos_blandos'], false);
    expect(enviado?['otros'], '');
  });

  test('CPO/ceo son checks: se guardan booleanos', () async {
    final repo = _MockRepo();
    when(() => repo.getEvaluacionOdontologica(any(), any())).thenThrow(_dio404());
    registerFallbackValue(<String, dynamic>{});
    Map<String, dynamic>? enviado;
    when(() => repo.putEvaluacionOdontologica(any(), any(), any()))
        .thenAnswer((inv) async {
      enviado = inv.positionalArguments[2] as Map<String, dynamic>;
      return <String, dynamic>{};
    });
    final c = _container(repo);
    addTearDown(c.dispose);

    final ctrl = await _ctrl(c);
    var s = c.read(evaluacionOdontologicaControllerProvider(_args));
    expect(s.cpoC, false);
    ctrl.setCpoC(true);
    ctrl.setCeoE(true);
    final ok = await ctrl.guardar();
    expect(ok, true);
    expect(enviado?['cpo_c'], true);
    expect(enviado?['cpo_p'], false);
    expect(enviado?['ceo_e'], true);
    expect(enviado?['ceo_o'], false);
  });

  test('CPO/ceo aceptan cantidades legacy (1/0) al cargar', () async {
    final repo = _MockRepo();
    when(() => repo.getEvaluacionOdontologica(any(), any())).thenAnswer(
      (_) async => <String, dynamic>{
        'salud_bucal': 'con_hallazgos',
        'cpo_c': 2,
        'cpo_p': 0,
        'ceo_e': 1,
      },
    );
    final c = _container(repo);
    addTearDown(c.dispose);

    await _ctrl(c);
    final s = c.read(evaluacionOdontologicaControllerProvider(_args));
    expect(s.cpoC, true);
    expect(s.cpoP, false);
    expect(s.ceoE, true);
  });
}
