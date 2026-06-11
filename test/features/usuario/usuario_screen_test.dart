import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/providers.dart';
import 'package:prosane_app/core/session/entities.dart';
import 'package:prosane_app/core/session/session_controller.dart';
import 'package:prosane_app/features/usuario/presentation/usuario_screen.dart';

void main() {
  Future<SessionController> pump(WidgetTester t, {required String nombre}) async {
    final c = SessionController()..setSesion(Sesion(
        usuario: Usuario(id: '1', nombre: nombre, rolName: 'medico', rolLabel: 'Médico/a'), acciones: const []));
    await t.pumpWidget(ProviderScope(
      overrides: [
        sessionControllerProvider.overrideWith((ref) => c),
        // logout aislado del repo/DB real: solo cierra el estado en memoria
        logoutProvider.overrideWithValue(() async => c.cerrar()),
      ],
      child: const MaterialApp(home: UsuarioScreen()),
    ));
    return c;
  }

  testWidgets('caso normal: muestra el nombre real de la persona + label del rol', (t) async {
    // El backend ya vincula personas (people.json): /me devuelve nombre+apellido reales.
    await pump(t, nombre: 'Mariana Médica');
    expect(find.text('Mariana Médica'), findsOneWidget);
    expect(find.text('Médico/a'), findsOneWidget);
  });

  testWidgets('fallback: usuario sin persona → se muestra el email (ya resuelto en MeResponse)', (t) async {
    await pump(t, nombre: 'medico@prosane.test');
    expect(find.text('medico@prosane.test'), findsOneWidget);
  });

  testWidgets('Configuración es un placeholder "próximamente"', (t) async {
    await pump(t, nombre: 'Ana');
    await t.tap(find.text('Configuración'));
    await t.pumpAndSettle();
    expect(find.textContaining('próximamente'), findsOneWidget);
  });

  testWidgets('logout pide confirmación; al Confirmar cierra la sesión', (t) async {
    final c = await pump(t, nombre: 'Ana');
    await t.tap(find.text('Cerrar sesión'));
    await t.pumpAndSettle();
    expect(find.text('¿Estás seguro que querés cerrar sesión?'), findsOneWidget); // diálogo visible
    expect(c.state, isA<SesionAutenticada>()); // todavía no se cerró
    await t.tap(find.text('Confirmar'));
    await t.pumpAndSettle();
    expect(c.state, isA<SesionNoAutenticada>()); // recién acá se cierra
  });

  testWidgets('logout: al Cancelar NO cierra la sesión', (t) async {
    final c = await pump(t, nombre: 'Ana');
    await t.tap(find.text('Cerrar sesión'));
    await t.pumpAndSettle();
    await t.tap(find.text('Cancelar'));
    await t.pumpAndSettle();
    expect(find.text('¿Estás seguro que querés cerrar sesión?'), findsNothing); // diálogo cerrado
    expect(c.state, isA<SesionAutenticada>()); // sigue logueada
  });
}
