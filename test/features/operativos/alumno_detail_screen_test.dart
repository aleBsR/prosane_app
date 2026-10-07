import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:prosane_app/core/notificaciones/notificacion_controller.dart';
import 'package:prosane_app/core/providers.dart';
import 'package:prosane_app/core/session/entities.dart';
import 'package:prosane_app/core/session/session_controller.dart';
import 'package:prosane_app/core/theme/app_theme.dart';
import 'package:prosane_app/features/operativos/data/operativos_repository.dart';
import 'package:prosane_app/features/operativos/presentation/controllers/operativo_detail_controller.dart';
import 'package:prosane_app/features/operativos/presentation/screens/alumno_detail_screen.dart';

class _MockRepo extends Mock implements OperativosRepository {}

Map<String, dynamic> _operativo({String estado = 'borrador'}) => {
      'id': 'op1',
      'nombre': 'Operativo Test',
      'escuela': {'nombre': 'Escuela 1'},
      'fecha': '2026-09-01',
      'lugar_realizacion': 'escuela',
      'estado': estado,
      'alumnos_count': 1,
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
    {bool alumnoCompleto = false,
    String estado = 'borrador',
    List<Accion> acciones = const [],
    String rolName = 'medico'}) {
  return ProviderScope(
    overrides: [
      operativoDetailProvider
          .overrideWith((ref, id) async => _operativo(estado: estado)),
      completitudProvider.overrideWith((ref, id) async => {
            'total_alumnos': 1,
            'completos': alumnoCompleto ? 1 : 0,
            'puede_finalizar': true,
          }),
      alumnosProvider.overrideWith(
          (ref, id) async => [_alumno(completo: alumnoCompleto)]),
      operativoDetailControllerProvider.overrideWith((ref, id) =>
          OperativoDetailController(
              repo: repo,
              operativoId: id,
              notificacionController: NotificacionController())),
      operativosRepositoryProvider.overrideWith((ref) => repo),
      if (acciones.isNotEmpty)
        sessionControllerProvider.overrideWith(
          (ref) => SessionController()
            ..state = SesionAutenticada(
              Sesion(
                usuario: Usuario(
                    id: 'u1', nombre: 'Médico', rolName: rolName, rolLabel: 'Médico'),
                acciones: acciones,
              ),
            ),
        ),
    ],
    child: MaterialApp(
      // Sin ripple: el shader ink_sparkle no carga en este entorno de test.
      theme: AppTheme.light().copyWith(splashFactory: NoSplash.splashFactory),
      home: const Scaffold(
          body: AlumnoDetailScreen(operativoId: 'op1', alumnoId: 'a1')),
    ),
  );
}

void main() {
  testWidgets('detalle con tarjeta estilo post: nombre, DNI y curso',
      (tester) async {
    await tester.pumpWidget(_buildScreen(_MockRepo()));
    await tester.pumpAndSettle();

    expect(find.text('Detalle del alumno'), findsOneWidget);
    expect(find.text('Mamani, Lautaro'), findsOneWidget);
    expect(find.text('DNI 47000001 • 1° A'), findsOneWidget);
    expect(find.text('Pendiente'), findsWidgets);
  });

  testWidgets('alumno presente muestra tildes E/A/M/O en el detalle',
      (tester) async {
    await tester.pumpWidget(_buildScreen(_MockRepo()));
    await tester.pumpAndSettle();

    expect(find.text('E ✓'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('M'), findsOneWidget);
    expect(find.text('O'), findsOneWidget);
  });

  testWidgets('alumno completo evaluado muestra todas las tildes con check',
      (tester) async {
    await tester.pumpWidget(_buildScreen(_MockRepo(), alumnoCompleto: true));
    await tester.pumpAndSettle();

    expect(find.text('E ✓'), findsOneWidget);
    expect(find.text('A ✓'), findsOneWidget);
    expect(find.text('M ✓'), findsOneWidget);
    expect(find.text('O ✓'), findsOneWidget);
    // El estado evaluado es automático: la asistencia se muestra, no se edita.
    expect(find.text('Evaluado'), findsOneWidget);
  });

  testWidgets('botones de carga aparecen cuando el alumno está presente',
      (tester) async {
    await tester.pumpWidget(_buildScreen(
      _MockRepo(),
      estado: 'en_curso',
      acciones: [
        Accion.fromJson(const {
          'name': 'cargarEvaluacionMedica',
          'label': 'Cargar Médica',
        }),
        Accion.fromJson(const {
          'name': 'cargarEvaluacionOdontologica',
          'label': 'Cargar Odonto',
        }),
        Accion.fromJson(const {
          'name': 'cargarSeccionEscuela',
          'label': 'Cargar Escuela',
        }),
        Accion.fromJson(const {
          'name': 'cargarAntecedentesNino',
          'label': 'Cargar Datos',
        }),
      ],
    ));
    await tester.pumpAndSettle();

    expect(find.text('Evaluación médica'), findsOneWidget);
    expect(find.text('Eval. odontológica'), findsOneWidget);
    // El fixture ya trae E completa → rótulo de ver/editar.
    expect(find.text('Ver / editar sec. escuela'), findsOneWidget);
    expect(find.text('Datos de Alumno'), findsOneWidget);
  });

  testWidgets('alumno evaluado en curso ofrece ver y modificar sus secciones',
      (tester) async {
    await tester.pumpWidget(_buildScreen(
      _MockRepo(),
      alumnoCompleto: true,
      estado: 'en_curso',
      acciones: [
        Accion.fromJson(const {
          'name': 'cargarEvaluacionMedica',
          'label': 'Cargar Médica',
        }),
        Accion.fromJson(const {
          'name': 'cargarEvaluacionOdontologica',
          'label': 'Cargar Odonto',
        }),
        Accion.fromJson(const {
          'name': 'cargarSeccionEscuela',
          'label': 'Cargar Escuela',
        }),
        Accion.fromJson(const {
          'name': 'cargarAntecedentesNino',
          'label': 'Cargar Datos',
        }),
      ],
    ));
    await tester.pumpAndSettle();

    expect(find.text('Ver / editar eval. médica'), findsOneWidget);
    expect(find.text('Ver / editar eval. odonto.'), findsOneWidget);
    expect(find.text('Ver / editar sec. escuela'), findsOneWidget);
    expect(find.text('Ver / editar datos'), findsOneWidget);
  });

  testWidgets('antes de en_curso no se ofrecen evaluaciones pero sí escuela',
      (tester) async {
    await tester.pumpWidget(_buildScreen(
      _MockRepo(),
      estado: 'borrador',
      acciones: [
        Accion.fromJson(const {
          'name': 'cargarEvaluacionMedica',
          'label': 'Cargar Médica',
        }),
        Accion.fromJson(const {
          'name': 'cargarEvaluacionOdontologica',
          'label': 'Cargar Odonto',
        }),
        Accion.fromJson(const {
          'name': 'cargarSeccionEscuela',
          'label': 'Cargar Escuela',
        }),
        Accion.fromJson(const {
          'name': 'cargarAntecedentesNino',
          'label': 'Cargar Datos',
        }),
      ],
    ));
    await tester.pumpAndSettle();

    expect(find.text('Evaluación médica'), findsNothing);
    expect(find.text('Eval. odontológica'), findsNothing);
    expect(find.text('Ver / editar sec. escuela'), findsOneWidget);
    expect(find.text('Datos de Alumno'), findsOneWidget);
  });

  testWidgets('en finalizado el ⋯ ofrece constancia y datos a quien tiene permisos',
      (tester) async {
    await tester.pumpWidget(_buildScreen(_MockRepo(),
        alumnoCompleto: true,
        estado: 'finalizado',
        rolName: 'escuela',
        acciones: [
          Accion.fromJson(const {
            'name': 'verOperativo',
            'label': 'Ver operativo',
          }),
          Accion.fromJson(const {
            'name': 'cargarAntecedentesNino',
            'label': 'Datos',
          }),
        ]));
    await tester.pumpAndSettle();

    expect(find.text('Planilla PDF'), findsNothing);
    expect(find.text('Ver datos'), findsNothing);

    final moreMenus = find.byIcon(Icons.more_vert);
    expect(moreMenus, findsWidgets);
    await tester.ensureVisible(moreMenus.last);
    await tester.pumpAndSettle();
    await tester.tap(moreMenus.last);
    await tester.pumpAndSettle();

    expect(find.text('Planilla PDF'), findsOneWidget);
    expect(find.text('Ver datos'), findsOneWidget);
  });

  testWidgets('medico ve planilla y ver datos', (tester) async {
    await tester.pumpWidget(_buildScreen(_MockRepo(),
        alumnoCompleto: true,
        estado: 'finalizado',
        acciones: [
          Accion.fromJson(const {
            'name': 'verOperativo',
            'label': 'Ver operativo',
          }),
        ]));
    await tester.pumpAndSettle();

    final moreMenus = find.byIcon(Icons.more_vert);
    await tester.ensureVisible(moreMenus.last);
    await tester.pumpAndSettle();
    await tester.tap(moreMenus.last);
    await tester.pumpAndSettle();

    expect(find.text('Planilla PDF'), findsOneWidget);
    expect(find.text('Ver datos'), findsOneWidget);
  });

  testWidgets('tutor ve ver datos pero no planilla', (tester) async {
    await tester.pumpWidget(_buildScreen(_MockRepo(),
        alumnoCompleto: true,
        estado: 'finalizado',
        rolName: 'tutor',
        acciones: [
          Accion.fromJson(const {
            'name': 'cargarAntecedentesNino',
            'label': 'Datos',
          }),
        ]));
    await tester.pumpAndSettle();

    final moreMenus = find.byIcon(Icons.more_vert);
    await tester.ensureVisible(moreMenus.last);
    await tester.pumpAndSettle();
    await tester.tap(moreMenus.last);
    await tester.pumpAndSettle();

    expect(find.text('Planilla PDF'), findsNothing);
    expect(find.text('Ver datos'), findsOneWidget);
  });
}