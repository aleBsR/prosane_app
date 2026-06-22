import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:prosane_app/core/design_system/app_button.dart';
import 'package:prosane_app/core/design_system/app_dropdown_field.dart';
import 'package:prosane_app/core/theme/app_theme.dart';
import 'package:prosane_app/features/familia/data/familia_remote_datasource.dart';
import 'package:prosane_app/features/familia/presentation/antecedentes_familiares_screen.dart';
import 'package:prosane_app/features/familia/presentation/controllers/antecedentes_familiares_controller.dart';

class _MockDs extends Mock implements FamiliaRemoteDataSource {}

void main() {
  setUpAll(() => registerFallbackValue(<String, dynamic>{}));

  _MockDs _buildDs() {
    final ds = _MockDs();
    when(() => ds.getAntecedentes(any()))
        .thenAnswer((_) async => <String, dynamic>{});
    when(() => ds.guardarAntecedentes(any(), any())).thenAnswer((_) async {});
    return ds;
  }

  Widget _buildApp(_MockDs ds) {
    final router = GoRouter(
      initialLocation: '/antecedentes-familiares',
      routes: [
        GoRoute(
          path: '/antecedentes-familiares',
          builder: (c, s) => ProviderScope(
            overrides: [
              antecedentesFamiliaresControllerProvider.overrideWith((ref) =>
                  AntecedentesFamiliaresController(
                    ds: ds,
                    refrescarSesion: () async {},
                    tutorId: 'tut-1',
                  )),
            ],
            child: MaterialApp(
              theme: AppTheme.light(),
              home: const Scaffold(body: AntecedentesFamiliaresScreen()),
            ),
          ),
        ),
        GoRoute(
          path: '/inicio',
          builder: (c, s) => const Scaffold(body: Text('inicio')),
        ),
      ],
    );

    return MaterialApp.router(routerConfig: router);
  }

  testWidgets('renderiza los dos AppDropdownField con sus labels', (t) async {
    final ds = _buildDs();
    await t.pumpWidget(_buildApp(ds));
    await t.pumpAndSettle();

    expect(find.byType(AppDropdownField), findsNWidgets(2));
    expect(
      find.text('¿Tienen o han tenido algún problema de salud importante?'),
      findsOneWidget,
    );
    expect(
      find.text(
          '¿Algún familiar directo menor de 50 años sufrió muerte súbita o repentina?'),
      findsOneWidget,
    );
  });

  testWidgets('seleccionar un dropdown y tocar Guardar llama guardarAntecedentes',
      (t) async {
    final ds = _buildDs();
    await t.pumpWidget(_buildApp(ds));
    await t.pumpAndSettle();

    // Seleccionar "No" en el primer dropdown
    await t.tap(find.byType(AppDropdownField).first);
    await t.pumpAndSettle();
    // The dropdown items appear in an overlay; tap the last 'No' text to avoid
    // hitting the label if it matched (the label says "algún problema..." not "No")
    await t.tap(find.text('No').last);
    await t.pumpAndSettle();

    // Tocar el botón Guardar
    await t.tap(find.byType(AppButton));
    await t.pumpAndSettle();

    verify(() => ds.guardarAntecedentes('tut-1', any())).called(1);
  });

  testWidgets('el botón Guardar está presente y habilitado', (t) async {
    final ds = _buildDs();
    await t.pumpWidget(_buildApp(ds));
    await t.pumpAndSettle();

    final boton = t.widget<AppButton>(find.byType(AppButton));
    expect(boton.label, 'Guardar');
    // isLoading=false y enviando=false, el botón tiene onPressed no nulo
    expect(boton.onPressed, isNotNull);
  });
}
