import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:prosane_app/core/providers.dart';
import 'package:prosane_app/core/notificaciones/notificacion_controller.dart';
import 'package:prosane_app/core/theme/app_theme.dart';
import 'package:prosane_app/features/operativos/data/operativos_repository.dart';
import 'package:prosane_app/features/operativos/presentation/controllers/evaluacion_medica_controller.dart';
import 'package:prosane_app/features/operativos/presentation/controllers/operativo_detail_controller.dart';
import 'package:prosane_app/features/operativos/presentation/screens/evaluacion_medica_screen.dart';

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
      evaluacionMedicaControllerProvider.overrideWith((ref, a) =>
          EvaluacionMedicaController(
              repo: repo,
              args: args,
              notificacionController: NotificacionController())),
    ],
    child: MaterialApp(
      theme: AppTheme.light().copyWith(splashFactory: NoSplash.splashFactory),
      home: const Scaffold(
          body: EvaluacionMedicaScreen(operativoId: 'op1', alumnoId: 'a1')),
    ),
  );
}

void main() {
  testWidgets('muestra paso 1 y bloquea Siguiente con faltantes',
      (tester) async {
    final repo = _MockRepo();
    when(() => repo.getEvaluacionMedica(any(), any()))
        .thenThrow(_dio404());
    await tester.pumpWidget(_buildScreen(repo));
    await tester.pumpAndSettle();

    expect(find.textContaining('Paso 1 de 8'), findsOneWidget);
    expect(find.text('Examen clínico'), findsWidgets);

    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();

    // No avanzó: sigue en paso 1 y muestra el faltante.
    expect(find.textContaining('Paso 1 de 8'), findsOneWidget);
    expect(find.textContaining('lugar del examen'), findsWidgets);
  });

  testWidgets('salto directo a revisión y volver', (tester) async {
    final repo = _MockRepo();
    when(() => repo.getEvaluacionMedica(any(), any()))
        .thenThrow(_dio404());
    await tester.pumpWidget(_buildScreen(repo));
    await tester.pumpAndSettle();

    // Toca el punto 8 del stepper.
    await tester.tap(find.text('8'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Paso 8 de 8'), findsOneWidget);
    expect(find.text('Revisión'), findsWidgets);
    expect(find.text('Guardar'), findsOneWidget);

    await tester.tap(find.text('Atrás'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Paso 7 de 8'), findsOneWidget);
  });

  testWidgets('Siguiente inválido no persiste nada', (tester) async {
    final repo = _MockRepo();
    when(() => repo.getEvaluacionMedica(any(), any()))
        .thenThrow(_dio404());
    await tester.pumpWidget(_buildScreen(repo));
    await tester.pumpAndSettle();

    expect(find.text('Guardar avance'), findsNothing);
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();

    verifyNever(() => repo.putEvaluacionMedica(any(), any(), any()));
    expect(find.textContaining('Paso 1 de 8'), findsOneWidget);
  });
}
