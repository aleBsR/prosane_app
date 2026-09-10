import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:prosane_app/core/providers.dart';
import 'package:prosane_app/core/session/entities.dart';
import 'package:prosane_app/core/session/session_controller.dart';
import 'package:prosane_app/core/theme/app_theme.dart';
import 'package:prosane_app/features/escuelas/data/escuelas_repository.dart';
import 'package:prosane_app/features/escuelas/presentation/controllers/escuelas_list_controller.dart';
import 'package:prosane_app/features/escuelas/presentation/screens/escuela_detail_screen.dart';

class _MockRepo extends Mock implements EscuelasRepository {}

Accion _accion(String name) => Accion(
      name: name,
      label: name,
      icon: '',
      color: '',
      type: 'crud',
      category: 'escuelas',
      isSensitive: false,
      sortOrder: 0,
    );

Widget _buildScreen(_MockRepo repo, Escuela escuela,
    {List<Accion> acciones = const []}) {
  return ProviderScope(
    overrides: [
      escuelasRepositoryProvider.overrideWithValue(repo),
      escuelaDetalleProvider.overrideWith((ref, id) async => escuela),
      if (acciones.isNotEmpty)
        sessionControllerProvider.overrideWith(
          (ref) => SessionController()
            ..state = SesionAutenticada(
              Sesion(
                usuario: const Usuario(
                    id: 'u1', nombre: 'Admin', rolName: 'x', rolLabel: 'X'),
                acciones: acciones,
              ),
            ),
        ),
    ],
    child: MaterialApp(
      // Sin ripple: el shader ink_sparkle no carga en este entorno de test.
      theme: AppTheme.light().copyWith(splashFactory: NoSplash.splashFactory),
      home: const Scaffold(body: EscuelaDetailScreen(escuelaId: 'e1')),
    ),
  );
}

void main() {
  final escuela = Escuela(
    id: 'e1',
    nombre: 'Escuela 1',
    cue: '66000001',
    localidad: 'Salta',
    activa: true,
  );

  testWidgets('muestra datos y solo Ver cursos sin permisos extra',
      (tester) async {
    final repo = _MockRepo();
    await tester.pumpWidget(_buildScreen(repo, escuela));
    await tester.pumpAndSettle();

    expect(find.text('Escuela 1'), findsWidgets);
    expect(find.text('Ver cursos'), findsOneWidget);
    expect(find.text('Ver alumnos'), findsNothing);
    expect(find.text('Editar'), findsNothing);
    expect(find.text('Eliminar'), findsNothing);
  });

  testWidgets('plurigrado muestra aviso en vez de Ver cursos',
      (tester) async {
    final repo = _MockRepo();
    final pluri = Escuela(id: 'e1', nombre: 'Rural', plurigradoRural: true);
    await tester.pumpWidget(_buildScreen(repo, pluri));
    await tester.pumpAndSettle();

    expect(find.text('Ver cursos'), findsNothing);
    expect(
        find.text(
            'Escuela plurigrado rural: no necesita cursos. Los alumnos se registran sin curso.'),
        findsOneWidget);
  });

  testWidgets('con permisos muestra Ver alumnos y menú ⋯', (tester) async {
    final repo = _MockRepo();
    when(() => repo.obtener('e1')).thenAnswer((_) async => escuela);
    await tester.pumpWidget(_buildScreen(repo, escuela, acciones: [
      _accion('editarEscuela'),
      _accion('eliminarEscuela'),
      _accion('verAlumnosEscuela'),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('Ver alumnos'), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Editar'), findsOneWidget);
    expect(find.text('Eliminar'), findsOneWidget);
  });

  testWidgets('Editar abre el diálogo desde el menú', (tester) async {
    final repo = _MockRepo();
    when(() => repo.obtener('e1')).thenAnswer((_) async => escuela);
    await tester.pumpWidget(_buildScreen(repo, escuela, acciones: [
      _accion('editarEscuela'),
    ]));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();

    expect(find.text('Editar escuela'), findsOneWidget);
  });
}
