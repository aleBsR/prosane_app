import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prosane_app/core/notificaciones/notificacion.dart';
import 'package:prosane_app/core/notificaciones/notificacion_controller.dart';
import 'package:prosane_app/core/notificaciones/notificacion_host.dart';

Widget _wrap({Duration? duracion}) => ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: Stack(children: [
            NotificacionHost(
              duracion: duracion ?? const Duration(milliseconds: 200),
            ),
          ]),
        ),
      ),
    );

void main() {
  testWidgets('sin notificación no muestra texto', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('al mostrar() aparece el mensaje', (tester) async {
    late WidgetRef ref;
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: Consumer(builder: (c, r, _) {
            ref = r;
            return const NotificacionHost(duracion: Duration(seconds: 5));
          }),
        ),
      ),
    ));
    ref.read(notificacionProvider.notifier).exito('¡Cuenta creada!');
    await tester.pump(); // dispara rebuild
    await tester.pump(const Duration(milliseconds: 300)); // anim de entrada
    expect(find.text('¡Cuenta creada!'), findsOneWidget);
  });

  testWidgets('se auto-cierra tras la duración', (tester) async {
    late WidgetRef ref;
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: Consumer(builder: (c, r, _) {
            ref = r;
            return const NotificacionHost(duracion: Duration(milliseconds: 200));
          }),
        ),
      ),
    ));
    ref.read(notificacionProvider.notifier).error('falló algo');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('falló algo'), findsOneWidget);
    // Pasada la duración, el timer dispara ocultar() → desaparece.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 400)); // anim de salida
    expect(ref.read(notificacionProvider), isNull);
  });

  testWidgets('tocar la X la cierra', (tester) async {
    late WidgetRef ref;
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: Consumer(builder: (c, r, _) {
            ref = r;
            return const NotificacionHost(duracion: Duration(seconds: 5));
          }),
        ),
      ),
    ));
    ref.read(notificacionProvider.notifier).info('hola');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    expect(ref.read(notificacionProvider), isNull);
  });
}
