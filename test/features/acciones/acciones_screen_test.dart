import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/session/entities.dart';
import 'package:prosane_app/core/session/session_controller.dart';
import 'package:prosane_app/features/acciones/presentation/acciones_screen.dart';

Accion _a(String name, String label, String cat) => Accion(name: name, label: label, icon: 'draw',
    color: '#2E7D32', type: 'form', category: cat, isSensitive: false, sortOrder: 1);

void main() {
  Future<void> pump(WidgetTester t, List<Accion> acciones) async {
    final c = SessionController()..setSesion(Sesion(
        usuario: const Usuario(id: '1', nombre: 'Ana', rolName: 'medico', rolLabel: 'Médico/a'),
        acciones: acciones));
    // c es propiedad del ProviderScope: lo destruye al hacer dispose del scope.
    // No llamar c.dispose() en tearDown para evitar el doble-dispose.
    await t.pumpWidget(ProviderScope(
      overrides: [sessionControllerProvider.overrideWith((ref) => c)],
      child: const MaterialApp(home: AccionesScreen()),
    ));
  }

  testWidgets('agrupa por categoría y lista las acciones del rol', (t) async {
    await pump(t, [_a('listarPacientes', 'Listar pacientes', 'salud'), _a('verConstancias', 'Ver constancias', 'consentimiento')]);
    // Los headers de grupo son visibles aunque los grupos arranquen colapsados
    expect(find.text('SALUD'), findsOneWidget);
    expect(find.text('CONSENTIMIENTO'), findsOneWidget);
    // Las acciones están ocultas hasta que se expande el grupo
    expect(find.text('Listar pacientes'), findsNothing);
    // Al tocar el header SALUD se expande y aparece la acción
    await t.tap(find.text('SALUD'));
    await t.pumpAndSettle();
    expect(find.text('Listar pacientes'), findsOneWidget);
  });

  testWidgets('sin acciones muestra el estado vacío', (t) async {
    await pump(t, const []);
    expect(find.text('No tenés acciones disponibles todavía'), findsOneWidget);
  });

  testWidgets('tocar una acción abre el placeholder "próximamente"', (t) async {
    await pump(t, [_a('firmarApto', 'Firmar apto físico', 'salud')]);
    // El grupo arranca colapsado: expandir primero
    await t.tap(find.text('SALUD'));
    await t.pumpAndSettle();
    await t.tap(find.text('Firmar apto físico'));
    await t.pumpAndSettle();
    expect(find.textContaining('próximamente'), findsOneWidget);
  });
}
