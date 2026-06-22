import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:prosane_app/core/design_system/app_button.dart';
import 'package:prosane_app/core/design_system/app_switch.dart';
import 'package:prosane_app/core/theme/app_theme.dart';
import 'package:prosane_app/features/familia/data/familia_remote_datasource.dart';
import 'package:prosane_app/features/familia/presentation/consentimiento_screen.dart';
import 'package:prosane_app/features/familia/presentation/controllers/consentimiento_controller.dart';

class _MockDs extends Mock implements FamiliaRemoteDataSource {}

/// Fabrica un controller con ds fake, sin sesión real.
ConsentimientoController _ctrl() => ConsentimientoController(
      ds: _MockDs(),
      refrescarSesion: () async {},
      tutorId: 'tut-1',
    );

Widget _buildScreen({ConsentimientoController Function()? factory}) {
  return ProviderScope(
    overrides: [
      consentimientoControllerProvider.overrideWith((_) => factory?.call() ?? _ctrl()),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      home: const Scaffold(body: ConsentimientoScreen()),
    ),
  );
}

void main() {
  testWidgets('Confirmar está deshabilitado (onPressed null) cuando aceptado=false', (t) async {
    await t.pumpWidget(_buildScreen());
    await t.pumpAndSettle();

    final boton = t.widget<AppButton>(find.byType(AppButton));
    expect(boton.onPressed, isNull);
  });

  testWidgets('Activar el switch habilita el botón Confirmar', (t) async {
    await t.pumpWidget(_buildScreen());
    await t.pumpAndSettle();

    // El AppSwitch tiene un GestureDetector opaco; lo encontramos por tipo.
    await t.tap(find.byType(AppSwitch));
    await t.pump();

    final boton = t.widget<AppButton>(find.byType(AppButton));
    expect(boton.onPressed, isNotNull);
  });

  testWidgets('Tocar Ver términos muestra el diálogo con el título correcto', (t) async {
    await t.pumpWidget(_buildScreen());
    await t.pumpAndSettle();

    await t.tap(find.text('Ver términos de consentimiento'));
    await t.pumpAndSettle();

    expect(find.text('Términos del consentimiento'), findsOneWidget);

    // Cerrar el diálogo
    await t.tap(find.text('Cerrar'));
    await t.pumpAndSettle();
    expect(find.text('Términos del consentimiento'), findsNothing);
  });
}
