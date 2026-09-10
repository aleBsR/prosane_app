import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:prosane_app/core/providers.dart';
import 'package:prosane_app/core/theme/app_theme.dart';
import 'package:prosane_app/features/escuelas/data/alumnos_escuela_repository.dart';
import 'package:prosane_app/features/escuelas/presentation/controllers/alumnos_escuela_controller.dart';
import 'package:prosane_app/features/escuelas/presentation/controllers/mi_escuela_controller.dart';
import 'package:prosane_app/features/escuelas/presentation/screens/alumnos_escuela_screen.dart';
import 'package:prosane_app/features/operativos/presentation/controllers/operativos_list_controller.dart';

class _MockRepo extends Mock implements AlumnosEscuelaRepository {}

Widget _buildScreen(_MockRepo repo) {
  return ProviderScope(
    overrides: [
      alumnosEscuelaRepositoryProvider.overrideWithValue(repo),
      alumnosEscuelaProvider.overrideWith((ref) async => []),
      miEscuelaProvider.overrideWith((ref) async => {
            'id': 'e1',
            'nombre': 'Escuela 1',
            'plurigrado_rural': false,
            'cursos': [],
          }),
      operativosListControllerProvider.overrideWith((ref) async => []),
    ],
    child: MaterialApp(
      // Sin ripple: el shader ink_sparkle no carga en este entorno de test.
      theme: AppTheme.light().copyWith(splashFactory: NoSplash.splashFactory),
      home: const Scaffold(body: AlumnosEscuelaScreen()),
    ),
  );
}

Widget _buildScreenAuto(_MockRepo repo) {
  return ProviderScope(
    overrides: [
      alumnosEscuelaRepositoryProvider.overrideWithValue(repo),
      alumnosEscuelaProvider.overrideWith((ref) async => []),
      miEscuelaProvider.overrideWith((ref) async => {
            'id': 'e1',
            'nombre': 'Escuela 1',
            'plurigrado_rural': false,
            'cursos': [],
          }),
      operativosListControllerProvider.overrideWith((ref) async => []),
    ],
    child: MaterialApp(
      // Sin ripple: el shader ink_sparkle no carga en este entorno de test.
      theme: AppTheme.light().copyWith(splashFactory: NoSplash.splashFactory),
      home: const Scaffold(body: AlumnosEscuelaScreen(abrirRegistro: true)),
    ),
  );
}

void main() {
  testWidgets('Registrar alumno abre el formulario directo con aviso inline',
      (tester) async {
    await tester.pumpWidget(_buildScreen(_MockRepo()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Registrar alumno'));
    await tester.pumpAndSettle();

    // El formulario abre sin diálogos intermedios…
    expect(find.text('Nombre *'), findsOneWidget);
    // …y el faltante de cursos se avisa adentro, con atajo para crearlo.
    expect(
        find.text('Todavía no hay cursos. Creá uno para poder guardar.'),
        findsOneWidget);
    expect(find.text('Crear curso'), findsOneWidget);
  });

  testWidgets('abrirRegistro abre el formulario automáticamente al entrar',
      (tester) async {
    await tester.pumpWidget(_buildScreenAuto(_MockRepo()));
    await tester.pumpAndSettle();

    // Sin tocar ningún botón, el formulario ya está abierto.
    expect(find.text('Nombre *'), findsOneWidget);
  });
}
