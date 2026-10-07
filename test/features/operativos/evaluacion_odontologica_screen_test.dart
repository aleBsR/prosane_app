import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:prosane_app/core/notificaciones/notificacion_controller.dart';
import 'package:prosane_app/core/providers.dart';
import 'package:prosane_app/core/theme/app_theme.dart';
import 'package:prosane_app/features/operativos/data/operativos_repository.dart';
import 'package:prosane_app/features/operativos/presentation/controllers/evaluacion_odontologica_controller.dart';
import 'package:prosane_app/features/operativos/presentation/controllers/operativo_detail_controller.dart';
import 'package:prosane_app/features/operativos/presentation/screens/evaluacion_odontologica_screen.dart';

class _MockRepo extends Mock implements OperativosRepository {}

DioException _dio404() => DioException(
      requestOptions: RequestOptions(path: ''),
      response:
          Response(requestOptions: RequestOptions(path: ''), statusCode: 404),
    );

Widget _buildScreen(_MockRepo repo) {
  const args = (opId: 'op1', alumnoId: 'a1');
  return ProviderScope(
    overrides: [
      operativosRepositoryProvider.overrideWithValue(repo),
      operativoDetailProvider.overrideWith((ref, id) async => {
            'id': 'op1',
            'estado': 'en_curso',
          }),
      evaluacionOdontologicaControllerProvider.overrideWith((ref, a) =>
          EvaluacionOdontologicaController(
              repo: repo,
              args: args,
              notificacionController: NotificacionController())),
    ],
    child: MaterialApp(
      theme: AppTheme.light().copyWith(splashFactory: NoSplash.splashFactory),
      home: const Scaffold(
          body:
              EvaluacionOdontologicaScreen(operativoId: 'op1', alumnoId: 'a1')),
    ),
  );
}

void main() {
  testWidgets('muestra paso 1 y avanza a prácticas', (tester) async {
    final repo = _MockRepo();
    when(() => repo.getEvaluacionOdontologica(any(), any()))
        .thenThrow(_dio404());
    when(() => repo.putEvaluacionOdontologica(any(), any(), any()))
        .thenAnswer((_) async => <String, dynamic>{});
    await tester.pumpWidget(_buildScreen(repo));
    await tester.pumpAndSettle();

    expect(find.textContaining('Paso 1 de 4'), findsOneWidget);
    expect(find.text('Salud bucal'), findsWidgets);

    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Paso 2 de 4'), findsOneWidget);
    expect(find.text('Prácticas'), findsWidgets);
  });

  testWidgets('salto directo a revisión y volver', (tester) async {
    final repo = _MockRepo();
    when(() => repo.getEvaluacionOdontologica(any(), any()))
        .thenThrow(_dio404());
    await tester.pumpWidget(_buildScreen(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('4'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Paso 4 de 4'), findsOneWidget);
    expect(find.text('Revisión'), findsWidgets);
    expect(find.text('Guardar'), findsOneWidget);

    await tester.tap(find.text('Atrás'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Paso 3 de 4'), findsOneWidget);
  });

  testWidgets('Siguiente autogarda el avance y avanza', (tester) async {
    final repo = _MockRepo();
    when(() => repo.getEvaluacionOdontologica(any(), any()))
        .thenThrow(_dio404());
    registerFallbackValue(<String, dynamic>{});
    Map<String, dynamic>? enviado;
    when(() => repo.putEvaluacionOdontologica(any(), any(), any()))
        .thenAnswer((inv) async {
      enviado = inv.positionalArguments[2] as Map<String, dynamic>;
      return <String, dynamic>{};
    });
    await tester.pumpWidget(_buildScreen(repo));
    await tester.pumpAndSettle();

    expect(find.text('Guardar avance'), findsNothing);
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();

    verify(() => repo.putEvaluacionOdontologica(any(), any(), any()))
        .called(1);
    expect(enviado?['completar'], false);
    expect(find.textContaining('Paso 2 de 4'), findsOneWidget);
  });
}
