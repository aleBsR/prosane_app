import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:prosane_app/core/providers.dart';
import 'package:prosane_app/core/session/entities.dart';
import 'package:prosane_app/core/session/session_controller.dart';
import 'package:prosane_app/core/theme/app_theme.dart';
import 'package:prosane_app/features/operativos/data/operativos_repository.dart';
import 'package:prosane_app/features/operativos/presentation/controllers/operativo_detail_controller.dart';
import 'package:prosane_app/features/operativos/presentation/screens/escuela_datos_screen.dart';

class _MockRepo extends Mock implements OperativosRepository {}

Map<String, dynamic> _operativo({String estado = 'en_curso'}) => {
      'id': 'op1',
      'nombre': 'Operativo Test',
      'estado': estado,
      'alumnos_count': 1,
      'profesionales_asignados': [],
    };

Map<String, dynamic> _datosAlumno() => {
      'operativo_alumno': {
        'nombre': 'Lautaro',
        'apellido': 'Mamani',
        'dni': '47000001',
        'fecha_nacimiento': '',
        'sexo': 'masculino',
      },
      'paciente': <String, dynamic>{},
      'persona': <String, dynamic>{},
      'domicilio': <String, dynamic>{},
      'antecedentes': <String, dynamic>{},
    };

Widget _buildScreen(_MockRepo repo,
    {String estado = 'en_curso',
    List<Accion> acciones = const [],
    String rolName = 'medico'}) {
  return ProviderScope(
    overrides: [
      operativoDetailProvider
          .overrideWith((ref, id) async => _operativo(estado: estado)),
      operativosRepositoryProvider.overrideWith((ref) => repo),
      if (acciones.isNotEmpty)
        sessionControllerProvider.overrideWith(
          (ref) => SessionController()
            ..state = SesionAutenticada(
              Sesion(
                usuario: Usuario(
                    id: 'u1', nombre: 'Real', rolName: rolName, rolLabel: 'Real'),
                acciones: acciones,
              ),
            ),
        ),
    ],
    child: MaterialApp(
      theme: AppTheme.light().copyWith(splashFactory: NoSplash.splashFactory),
      home: const Scaffold(
          body: EscuelaDatosScreen(operativoId: 'op1', alumnoId: 'a1')),
    ),
  );
}

void main() {
  testWidgets('escuela con permiso edita en operativo en curso',
      (tester) async {
    final repo = _MockRepo();
    when(() => repo.getDatosAlumno('op1', 'a1'))
        .thenAnswer((_) async => _datosAlumno());
    when(() => repo.listarAlumnos(any())).thenAnswer((_) async => []);
    await tester.pumpWidget(_buildScreen(repo,
        acciones: [
          Accion.fromJson(const {
            'name': 'cargarAntecedentesNino',
            'label': 'Datos',
          }),
        ],
        rolName: 'escuela'));
    await tester.pumpAndSettle();

    // Wizard: en el paso 1 no hay Guardar; está en Revisión (paso 5).
    expect(find.textContaining('Paso 1 de 5'), findsOneWidget);
    expect(find.text('Guardar'), findsNothing);
    expect(find.textContaining('solo lectura'), findsNothing);
    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Paso 5 de 5'), findsOneWidget);
    expect(find.text('Guardar'), findsOneWidget);
  });

  testWidgets('medico sin cargarAntecedentesNino ve solo lectura',
      (tester) async {
    final repo = _MockRepo();
    when(() => repo.getDatosAlumno('op1', 'a1'))
        .thenAnswer((_) async => _datosAlumno());
    await tester.pumpWidget(_buildScreen(repo,
        acciones: [
          Accion.fromJson(const {
            'name': 'verOperativo',
            'label': 'Ver',
          }),
        ]));
    await tester.pumpAndSettle();

    expect(find.text('Solo lectura — no tenés permisos de edición'),
        findsOneWidget);
    expect(find.text('Guardar'), findsNothing);
  });

  testWidgets('escuela en operativo finalizado ve solo lectura',
      (tester) async {
    final repo = _MockRepo();
    when(() => repo.getDatosAlumno('op1', 'a1'))
        .thenAnswer((_) async => _datosAlumno());
    await tester.pumpWidget(_buildScreen(repo,
        estado: 'finalizado',
        acciones: [
          Accion.fromJson(const {
            'name': 'cargarAntecedentesNino',
            'label': 'Datos',
          }),
        ],
        rolName: 'escuela'));
    await tester.pumpAndSettle();

    expect(find.text('Operativo finalizado — solo lectura'), findsOneWidget);
    expect(find.text('Guardar'), findsNothing);
  });

  testWidgets('medico ve ficha de datos en solo lectura con todas las secciones',
      (tester) async {
    final repo = _MockRepo();
    final data = Map<String, dynamic>.from(_datosAlumno())
      ..['operativo_alumno'] = <String, dynamic>{
        'nombre': 'Lautaro',
        'apellido': 'Mamani',
        'dni': '47000001',
      }
      ..['persona'] = <String, dynamic>{
        'nombre': 'Lautaro',
        'apellido': 'Mamani',
        'dni': '47000001',
        'sexo': 'femenino',
      }
      ..['paciente'] = <String, dynamic>{
        'edad': 8,
        'tipo_cobertura': 'obra_social',
        'nombre_cobertura': 'IAPOS',
      }
      ..['domicilio'] = <String, dynamic>{'localidad': 'Boulevard'};
    when(() => repo.getDatosAlumno('op1', 'a1')).thenAnswer((_) async => data);
    await tester.pumpWidget(_buildScreen(repo,
        acciones: [
          Accion.fromJson(const {
            'name': 'verOperativo',
            'label': 'Ver',
          }),
        ],
        rolName: 'medico'));
    await tester.pumpAndSettle();

    expect(find.text('Solo lectura — no tenés permisos de edición'),
        findsOneWidget);
    expect(find.text('Datos personales'), findsOneWidget);
    expect(find.text('Cobertura y contacto'), findsOneWidget);
    expect(find.text('Antecedentes personales'), findsOneWidget);
    expect(find.text('47000001'), findsOneWidget);
    expect(find.text('Femenino'), findsOneWidget);
    expect(find.text('Obra Social (incluye PAMI)'), findsOneWidget);
    expect(find.text('IAPOS'), findsOneWidget);
    expect(find.text('Boulevard'), findsOneWidget);
    expect(find.text('Nació prematuro'), findsOneWidget);
    expect(find.text('Guardar'), findsNothing);
  });

  testWidgets('ficha muestra evaluaciones médica y odontológica',
      (tester) async {
    final repo = _MockRepo();
    final data = Map<String, dynamic>.from(_datosAlumno())
      ..['evaluacion_medica'] = <String, dynamic>{
        'completada': true,
        'profesional': 'Dra. Peña',
        'examen_realizado': true,
        'peso': 26.5,
        'talla': 128.0,
        'percentil_imc': 'entre_10_84',
        'audiometria_resultado': 'pasa',
        'hallazgos': <String, dynamic>{
          'piel': <String, dynamic>{'estado': 'sin', 'detalle': ''}
        },
        'derivaciones': <String, dynamic>{
          'oftalmologia': <String, dynamic>{'deriva': true, 'motivo': 'Miopía'}
        },
      }
      ..['evaluacion_odontologica'] = <String, dynamic>{
        'completada': true,
        'profesional': 'Od. Díaz',
        'salud_bucal': 'sin_hallazgos',
        'caries': false,
        'cpo_c': 0,
        'ceo_c': 1,
        'odontograma': <String, dynamic>{
          '51': <String, dynamic>{
            'estado_general': '',
            'caras': <String, dynamic>{
              'oclusal': 'restauracion',
              'vestibular': 'sellador',
            },
          },
          '55': <String, dynamic>{
            'estado_general': 'a_extraer',
            'notas': 'Revisar',
          },
        },
      };
    when(() => repo.getDatosAlumno('op1', 'a1')).thenAnswer((_) async => data);
    when(() => repo.listarAlumnos(any())).thenAnswer((_) async => []);
    await tester.pumpWidget(_buildScreen(repo,
        acciones: [
          Accion.fromJson(const {
            'name': 'cargarAntecedentesNino',
            'label': 'Datos',
          }),
        ],
        rolName: 'escuela'));
    await tester.pumpAndSettle();

    // Los resúmenes de evaluaciones viven en el paso Revisión.
    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();

    expect(find.text('Evaluación médica'), findsOneWidget);
    expect(find.text('Evaluación odontológica'), findsOneWidget);
    expect(find.text('Dra. Peña'), findsOneWidget);
    expect(find.text('Od. Díaz'), findsOneWidget);
    expect(find.text('Entre 10 y 84 (normal)'), findsOneWidget);
    expect(find.text('Pasa'), findsOneWidget);
    expect(find.text('Deriva a Oftalmología'), findsOneWidget);
    expect(find.text('Pieza 51'), findsOneWidget);
    expect(find.text('Pieza 55'), findsOneWidget);
    expect(find.text('Estado general'), findsNWidgets(2));
    expect(find.text('Normal'), findsOneWidget);
    expect(find.text('Para extraer'), findsOneWidget);
    expect(find.text('Oclusal'), findsOneWidget);
    expect(find.text('Restauración'), findsOneWidget);
    expect(find.text('Vestibular'), findsOneWidget);
    expect(find.text('Sellador'), findsOneWidget);
    expect(find.text('Revisar'), findsOneWidget);
  });

  Widget buildEditable(_MockRepo repo) {
    when(() => repo.listarAlumnos(any())).thenAnswer((_) async => []);
    return _buildScreen(repo,
        acciones: [
          Accion.fromJson(const {
            'name': 'cargarAntecedentesNino',
            'label': 'Datos',
          }),
        ],
        rolName: 'escuela');
  }

  testWidgets('wizard: Siguiente bloquea sin datos del niño', (tester) async {
    final repo = _MockRepo();
    when(() => repo.getDatosAlumno('op1', 'a1'))
        .thenAnswer((_) async => _datosAlumno());
    await tester.pumpWidget(buildEditable(repo));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Siguiente'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Paso 1 de 5'), findsOneWidget);
    expect(find.text('Seleccioná la fecha de nacimiento'), findsOneWidget);
  });

  Map<String, dynamic> datosCompletos() {
    final data = Map<String, dynamic>.from(_datosAlumno());
    data['operativo_alumno'] = <String, dynamic>{
      'nombre': 'Lautaro',
      'apellido': 'Mamani',
      'dni': '47000001',
      'fecha_nacimiento': '2018-05-01',
      'sexo': 'masculino',
    };
    return data;
  }

  testWidgets('wizard: Siguiente autogarda sin tocar sección si no se visitó',
      (tester) async {
    final repo = _MockRepo();
    when(() => repo.getDatosAlumno('op1', 'a1'))
        .thenAnswer((_) async => datosCompletos());
    registerFallbackValue(<String, dynamic>{});
    Map<String, dynamic>? enviadoDatos;
    when(() => repo.patchDatosAlumno(any(), any(), any()))
        .thenAnswer((inv) async {
      enviadoDatos =
          Map<String, dynamic>.from(inv.positionalArguments[2] as Map);
      return <String, dynamic>{};
    });
    await tester.pumpWidget(buildEditable(repo));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Siguiente'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();

    verify(() => repo.patchDatosAlumno('op1', 'a1', any())).called(1);
    expect(enviadoDatos?['completar'], false);
    verifyNever(() => repo.patchSeccionEscuela(any(), any(), any()));
    expect(find.textContaining('Paso 2 de 5'), findsOneWidget);
  });

  testWidgets('wizard: desde E, Siguiente guarda todo con completar:false',
      (tester) async {
    final repo = _MockRepo();
    when(() => repo.getDatosAlumno('op1', 'a1'))
        .thenAnswer((_) async => datosCompletos());
    when(() => repo.listarAlumnos(any())).thenAnswer((_) async => []);
    registerFallbackValue(<String, dynamic>{});
    Map<String, dynamic>? enviadoSeccion;
    when(() => repo.patchDatosAlumno(any(), any(), any()))
        .thenAnswer((_) async => <String, dynamic>{});
    when(() => repo.patchSeccionEscuela(any(), any(), any()))
        .thenAnswer((inv) async {
      enviadoSeccion =
          Map<String, dynamic>.from(inv.positionalArguments[2] as Map);
      return <String, dynamic>{};
    });
    await tester.pumpWidget(buildEditable(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('4'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Paso 4 de 5'), findsOneWidget);

    await tester.ensureVisible(find.text('Siguiente'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();

    verify(() => repo.patchSeccionEscuela('op1', 'a1', any())).called(1);
    expect(enviadoSeccion?['completar'], false);
    expect(find.textContaining('Paso 5 de 5'), findsOneWidget);
  });
}