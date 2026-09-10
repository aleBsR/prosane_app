import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:prosane_app/core/notificaciones/notificacion_controller.dart';
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

  testWidgets('fila de alumno minimalista sin avatar y con tildes',
      (tester) async {
    await tester.pumpWidget(_buildScreen(_MockRepo(), conAlumno: true));
    await tester.pumpAndSettle();

    expect(find.text('Lautaro Mamani'), findsOneWidget);
    expect(find.text('DNI 47000001'), findsOneWidget);
    expect(find.text('E ✓'), findsOneWidget);
    // Solo la cabecera del operativo lleva avatar con inicial.
    expect(find.byType(CircleAvatar), findsOneWidget);
  });

  testWidgets('en finalizado el ⋯ del alumno ofrece constancia y datos',
      (tester) async {
    await tester.pumpWidget(_buildScreen(_MockRepo(),
        conAlumno: true, alumnoCompleto: true, estado: 'finalizado'));
    await tester.pumpAndSettle();

    // Sin botones sueltos: todo va por el menú.
    expect(find.text('Constancia PDF'), findsNothing);
    expect(find.text('Ver datos'), findsNothing);

    await tester.ensureVisible(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Constancia PDF'), findsOneWidget);
    expect(find.text('Ver datos'), findsOneWidget);
  });

  testWidgets('botones de carga de seccion se muestran para alumno presente',
      (tester) async {
    await tester.pumpWidget(_buildScreen(
      _MockRepo(),
      conAlumno: true,
      acciones: [
        Accion.fromJson(const {'name': 'cargarEvaluacionMedica', 'label': 'Cargar Médica'}),
        Accion.fromJson(const {'name': 'cargarEvaluacionOdontologica', 'label': 'Cargar Odonto'}),
        Accion.fromJson(const {'name': 'cargarSeccionEscuela', 'label': 'Cargar Escuela'}),
        Accion.fromJson(const {'name': 'cargarAntecedentesNino', 'label': 'Cargar Datos'}),
      ],
    ));
    await tester.pumpAndSettle();

    expect(find.text('Evaluación médica'), findsOneWidget);
    expect(find.text('Eval. odontológica'), findsOneWidget);
    expect(find.text('Sección escuela'), findsOneWidget);
    expect(find.text('Datos personales y familia'), findsOneWidget);
  });
}

