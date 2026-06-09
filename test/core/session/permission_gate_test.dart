import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/session/entities.dart';
import 'package:prosane_app/core/session/permission_gate.dart';
import 'package:prosane_app/core/session/session_controller.dart';

void main() {
  testWidgets('PermissionGate muestra el child solo con el permiso, y REACCIONA al login', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: PermissionGate(permiso: 'firmar_apto', child: Text('VISIBLE')),
      ),
    ));
    expect(find.text('VISIBLE'), findsNothing); // sin sesión: oculto

    container.read(sessionControllerProvider.notifier).setSesion(Sesion(
      usuario: const Usuario(id: '1', nombre: 'Ana', rol: 'profesional'),
      permisos: const {'firmar_apto'},
    ));
    await tester.pump();
    expect(find.text('VISIBLE'), findsOneWidget); // tras login con permiso: visible
  });

  testWidgets('sin permiso muestra el fallback provisto', (tester) async {
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(
        home: PermissionGate(
          permiso: 'firmar_apto',
          fallback: Text('SIN PERMISO'),
          child: Text('VISIBLE'),
        ),
      ),
    ));
    expect(find.text('VISIBLE'), findsNothing);
    expect(find.text('SIN PERMISO'), findsOneWidget);
  });
}
