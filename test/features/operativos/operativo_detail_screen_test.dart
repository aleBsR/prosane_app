import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:prosane_app/core/notificaciones/notificacion_controller.dart';
import 'package:prosane_app/core/providers.dart';
import 'package:prosane_app/core/session/entities.dart';
import 'package:prosane_app/core/session/session_controller.dart';
import 'package:prosane_app/core/theme/app_theme.dart';
import 'package:prosane_app/features/operativos/data/operativos_repository.dart';
import 'package:prosane_app/features/operativos/presentation/controllers/operativo_detail_controller.dart';
import 'package:prosane_app/features/operativos/presentation/screens/operativo_detail_screen.dart';

class _MockRepo extends Mock implements OperativosRepository {}

Map<String, dynamic> _operativo() => {
      'id': 'op1',
      'nombre': 'Operativo Test',
      'escuela': {'nombre': 'Escuela 1'},
      'fecha': '2026-09-01',
      'lugar_realizacion': 'escuela',
      'estado': 'borrador',
      'alumnos_count': 0,
      'profesionales_asignados': [],
    };

Map<String, dynamic> _alumno({bool completo = false}) => {
      'id': 'a1',
      'nombre': 'Lautaro',
      'apellido': 'Mamani',
      'dni': '47000001',
      'completo': completo,
      'estado': completo ? 'evaluado' : 'presente',
      'escuela_completado': true,
      'antecedentes_completado': completo,
      'medica_completada': completo,
      'odontologica_completada': completo,
      'curso_display': '1° A',
    };

Widget _buildScreen(_MockRepo repo,
    {bool conAlumno = false,
    bool alumnoCompleto = false,
    String estado = 'borrador',
    List<Accion> acciones = const []}) {
  final op = _operativo();
  op['estado'] = estado;
  return ProviderScope(
    overrides: [
      operativosRepositoryProvider.overrideWithValue(repo),
      operativoDetailProvider.overrideWith((ref, id) async => op),
      completitudProvider.overrideWith((ref, id) async => {
            'total_alumnos': conAlumno ? 1 : 0,
            'completos': 0,
            'puede_finalizar': false,
          }),
      alumnosProvider.overrideWith((ref, id) async => [
            if (conAlumno) _alumno(completo: alumnoCompleto),
          ]),
      operativoDetailControllerProvider.overrideWith((ref, id) =>
          OperativoDetailController(
              repo: repo,
              operativoId: id,
              notificacionController: NotificacionController())),
      if (acciones.isNotEmpty)
        sessionControllerProvider.overrideWith(
          (ref) => SessionController()
            ..state = SesionAutenticada(
              Sesion(
                usuario: const Usuario(
                    id: 'u1', nombre: 'Médico', rolName: 'medico', rolLabel: 'Médico'),
                acciones: acciones,
              ),
            ),
        ),
    ],
    child: MaterialApp(
      // Sin ripple: el shader ink_sparkle no carga en este entorno de test.
      theme: AppTheme.light().copyWith(splashFactory: NoSplash.splashFactory),
      home: const Scaffold(
          body: OperativoDetailScreen(operativoId: 'op1')),
    ),
  );
}

void main() {
  testWidgets('cabecera estilo post con chips y sin CSV sin permiso',
      (tester) async {
    await tester.pumpWidget(_buildScreen(_MockRepo()));
    await tester.pumpAndSettle();

    expect(find.text('Operativo Test'), findsWidgets);
    expect(find.text('Borrador'), findsOneWidget);
    expect(find.text('0 alumnos'), findsOneWidget);
    expect(find.text('0 profesionales'), findsOneWidget);
    // Sin sesión con permiso, el botón CSV no se muestra.
    expect(find.text('Seleccionar archivo CSV'), findsNothing);
  });

  testWidgets('fila de alumno compacta: solo apellido, nombre y DNI',
      (tester) async {
    await tester.pumpWidget(_buildScreen(_MockRepo(), conAlumno: true));
    await tester.pumpAndSettle();

    expect(find.text('Mamani, Lautaro'), findsOneWidget);
    expect(find.text('DNI 47000001'), findsOneWidget);
    // Las tildes y botones ya no viven en la lista: van al detalle del alumno.
    expect(find.text('E ✓'), findsNothing);
    expect(find.text('Evaluación médica'), findsNothing);
    // Solo la cabecera del operativo lleva avatar con inicial.
    expect(find.byType(CircleAvatar), findsOneWidget);
  });

  Accion accion(String name) => Accion(
      name: name,
      label: name,
      icon: '',
      color: '',
      type: '',
      category: '',
      isSensitive: false,
      sortOrder: 0);

  testWidgets('sin permisos no hay menu editar/eliminar', (tester) async {
    await tester.pumpWidget(_buildScreen(_MockRepo()));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.more_vert), findsNothing);
  });

  testWidgets('menu editar/eliminar visible con permisos en borrador',
      (tester) async {
    await tester.pumpWidget(_buildScreen(_MockRepo(),
        acciones: [accion('editarOperativo'), accion('cancelarOperativo')]));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Editar'), findsOneWidget);
    expect(find.text('Eliminar'), findsOneWidget);
  });

  testWidgets('en finalizado no hay menu aunque haya permisos',
      (tester) async {
    await tester.pumpWidget(_buildScreen(_MockRepo(),
        estado: 'finalizado',
        acciones: [accion('editarOperativo'), accion('cancelarOperativo')]));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.more_vert), findsNothing);
  });

  testWidgets('editar guarda via repo.actualizar', (tester) async {
    final repo = _MockRepo();
    registerFallbackValue(<String, dynamic>{});
    when(() => repo.actualizar(any(), any()))
        .thenAnswer((_) async => <String, dynamic>{});
    await tester.pumpWidget(_buildScreen(repo,
        acciones: [accion('editarOperativo'), accion('cancelarOperativo')]));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();

    expect(find.text('Editar operativo'), findsOneWidget);
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    verify(() => repo.actualizar('op1', any())).called(1);
  });

  testWidgets('eliminar pide confirmacion y cancela', (tester) async {
    final repo = _MockRepo();
    when(() => repo.cancelar(any())).thenAnswer((_) async {});
    final router = GoRouter(
      initialLocation: '/operativos/op1',
      routes: [
        GoRoute(
            path: '/operativos',
            builder: (c, s) => const Scaffold(body: Text('lista'))),
        GoRoute(
            path: '/operativos/:id',
            builder: (c, s) =>
                const Scaffold(body: OperativoDetailScreen(operativoId: 'op1'))),
      ],
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        operativosRepositoryProvider.overrideWithValue(repo),
        operativoDetailProvider.overrideWith((ref, id) async {
          final op = _operativo();
          return op;
        }),
        completitudProvider.overrideWith((ref, id) async => {
              'total_alumnos': 0,
              'completos': 0,
              'puede_finalizar': false,
            }),
        alumnosProvider.overrideWith((ref, id) async => []),
        operativoDetailControllerProvider.overrideWith((ref, id) =>
            OperativoDetailController(
                repo: repo,
                operativoId: id,
                notificacionController: NotificacionController())),
        sessionControllerProvider.overrideWith(
          (ref) => SessionController()
            ..state = SesionAutenticada(
              Sesion(
                usuario: const Usuario(
                    id: 'u1',
                    nombre: 'Admin',
                    rolName: 'superadmin',
                    rolLabel: 'Superadmin'),
                acciones: [
                  accion('editarOperativo'),
                  accion('cancelarOperativo')
                ],
              ),
            ),
        ),
      ],
      child: MaterialApp.router(
        theme:
            AppTheme.light().copyWith(splashFactory: NoSplash.splashFactory),
        routerConfig: router,
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    expect(find.textContaining('¿Eliminar'), findsOneWidget);
    await tester.tap(find.text('Sí'));
    await tester.pumpAndSettle();

    verify(() => repo.cancelar('op1')).called(1);
    expect(find.text('lista'), findsOneWidget);
  });
}