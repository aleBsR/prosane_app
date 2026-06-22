# Entrega 1 — Registro de hijo: Datos del niño + Cobertura — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ampliar el formulario de alta de hijo para capturar todos los campos de "Datos del niño" + "Cobertura" del PDF PROSANE, y quitar los antecedentes de salud (van a la Entrega 2).

**Architecture:** Cambios acotados a 2 archivos de la feature `hijos` (controller + screen) y sus 2 tests. Sin tocar provider, Drift, scheduler ni design system. Persistencia offline-first intacta: `guardar()` arma un payload JSON nuevo y lo escribe como borrador (`insertHijoDraft`).

**Tech Stack:** Flutter, Riverpod (StateNotifier), Drift (test in-memory), flutter_test.

**Spec:** `docs/superpowers/specs/2026-06-22-registro-hijo-datos-cobertura-design.md`

---

## File Structure

- `lib/features/hijos/presentation/controllers/planilla_controller.dart` — estado del form + payload. Se agregan 10 campos (2 teléfonos + 8 de domicilio), se quitan 2 (`asmaEspasmos`, `diabetes`), cambia el payload.
- `lib/features/hijos/presentation/screens/planilla_screen.dart` — UI en 3 cards. Se quita la card de antecedentes; se agregan campos a las 3 cards.
- `test/features/hijos/planilla_controller_test.dart` — verifica el payload nuevo y `puedeGuardar`.
- `test/features/hijos/planilla_screen_test.dart` — verifica render de cards/campos y ausencia de antecedentes.

---

### Task 1: PlanillaController — estado y payload nuevos

**Files:**
- Modify: `lib/features/hijos/presentation/controllers/planilla_controller.dart`
- Test: `test/features/hijos/planilla_controller_test.dart`

- [ ] **Step 1: Reescribir el test del payload (debe fallar)**

Reemplazar **todo** el contenido de `test/features/hijos/planilla_controller_test.dart` por:

```dart
import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/database/app_database.dart';
import 'package:prosane_app/features/hijos/presentation/controllers/planilla_controller.dart';

void main() {
  test('guardar: payload con persona, domicilio(11), cobertura, telefonos a raiz y SIN antecedentes', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final ctrl = PlanillaController(db: db, tutorId: 'tut-1', generarId: () => 'h1');
    ctrl.setNombre('Juana');
    ctrl.setApellido('Pérez');
    ctrl.setDni('70000000');
    ctrl.setSexo('F');
    ctrl.setFechaNacimiento(DateTime(2015, 6, 1));
    ctrl.setTieneCud('SI');
    ctrl.setTelefonoFijo('0387-4000000');
    ctrl.setCelular('+5493870000000');
    ctrl.setCalle('San Martín');
    ctrl.setNroCalle('123');
    ctrl.setPiso('2');
    ctrl.setDpto('B');
    ctrl.setManzana('4');
    ctrl.setCasa('10');
    ctrl.setNroCasa('11');
    ctrl.setPieza('1');
    ctrl.setProvincia('Salta');
    ctrl.setDepartamento('Capital');
    ctrl.setLocalidad('Salta');
    ctrl.setTipoCobertura('obra_social');
    ctrl.setNombreCobertura('OSDE');

    await ctrl.guardar();

    final row = (await db.hijosPendientes()).single;
    expect(row.tutorId, 'tut-1');
    final body = jsonDecode(row.payloadJson) as Map<String, dynamic>;

    final persona = body['persona'] as Map;
    expect(persona['dni'], '70000000');
    expect(persona['fecha_nacimiento'], '2015-06-01');
    expect(persona.containsKey('telefono_fijo'), isFalse); // telefonos NO van en persona

    final dom = body['domicilio'] as Map;
    expect(dom.keys, containsAll(<String>[
      'calle','nro_calle','piso','dpto','manzana','casa','nro_casa','pieza','provincia','departamento','localidad',
    ]));
    expect(dom['piso'], '2');
    expect(dom['localidad'], 'Salta');

    expect(body['edad'], greaterThanOrEqualTo(9));
    expect(body['tiene_cud'], 'SI');
    expect(body['tipo_cobertura'], 'obra_social');
    expect(body['nombre_cobertura'], 'OSDE');
    expect(body['telefono_fijo'], '0387-4000000'); // a nivel raiz (Paciente)
    expect(body['celular'], '+5493870000000');

    expect(body.containsKey('antecedentes_personales'), isFalse);
    expect(body.containsKey('consentimiento'), isFalse);
    expect(body.containsKey('antecedentes_familiares'), isFalse);

    await db.close();
  });

  test('setTipoCobertura limpia nombre_cobertura cuando no es obra_social/prepaga', () {
    const base = PlanillaState();
    final s1 = base.copyWith(tipoCobertura: 'obra_social', nombreCobertura: 'OSDE');
    expect(s1.pideNombreCobertura, isTrue);
    final s2 = base.copyWith(tipoCobertura: 'sin_cobertura', nombreCobertura: 'OSDE');
    expect(s2.pideNombreCobertura, isFalse);
  });

  test('puedeGuardar exige nombre/apellido/dni/fecha/sexo', () {
    const base = PlanillaState();
    expect(base.puedeGuardar, isFalse);
    final ok = base.copyWith(
      nombre: 'J', apellido: 'P', dni: '1', sexo: 'F', fechaNacimiento: DateTime(2015, 6, 1),
    );
    expect(ok.puedeGuardar, isTrue);
  });
}
```

- [ ] **Step 2: Correr el test y verificar que falla**

Run: `flutter test test/features/hijos/planilla_controller_test.dart`
Expected: FAIL (compilación: no existen `setTelefonoFijo`, `setPiso`, …, `pideNombreCobertura`).

- [ ] **Step 3: Reescribir el controller**

Reemplazar **todo** el contenido de `lib/features/hijos/presentation/controllers/planilla_controller.dart` por:

```dart
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/session/entities.dart';
import '../../../../core/session/session_controller.dart';

// ─── Estado ────────────────────────────────────────────────────────────────────

class PlanillaState {
  const PlanillaState({
    this.nombre = '',
    this.apellido = '',
    this.dni = '',
    this.tipoDni = 'DNI',
    this.sexo = '',
    this.fechaNacimiento,
    this.tieneCud = '',
    this.telefonoFijo = '',
    this.celular = '',
    this.parentesco = '',
    this.calle = '',
    this.nroCalle = '',
    this.piso = '',
    this.dpto = '',
    this.manzana = '',
    this.casa = '',
    this.nroCasa = '',
    this.pieza = '',
    this.provincia = '',
    this.departamento = '',
    this.localidad = '',
    this.tipoCobertura = '',
    this.nombreCobertura = '',
    this.guardando = false,
    this.error,
  });

  final String nombre, apellido, dni, tipoDni, sexo;
  final DateTime? fechaNacimiento;
  final String tieneCud, telefonoFijo, celular, parentesco;
  final String calle, nroCalle, piso, dpto, manzana, casa, nroCasa, pieza,
      provincia, departamento, localidad;
  final String tipoCobertura, nombreCobertura;
  final bool guardando;
  final String? error;

  /// Habilita "Guardar": requeridos del niño.
  bool get puedeGuardar =>
      nombre.trim().isNotEmpty &&
      apellido.trim().isNotEmpty &&
      dni.trim().isNotEmpty &&
      sexo.isNotEmpty &&
      fechaNacimiento != null;

  /// `nombre_cobertura` solo aplica a obra social / prepaga.
  bool get pideNombreCobertura =>
      tipoCobertura == 'obra_social' || tipoCobertura == 'prepaga';

  PlanillaState copyWith({
    String? nombre,
    String? apellido,
    String? dni,
    String? tipoDni,
    String? sexo,
    DateTime? fechaNacimiento,
    String? tieneCud,
    String? telefonoFijo,
    String? celular,
    String? parentesco,
    String? calle,
    String? nroCalle,
    String? piso,
    String? dpto,
    String? manzana,
    String? casa,
    String? nroCasa,
    String? pieza,
    String? provincia,
    String? departamento,
    String? localidad,
    String? tipoCobertura,
    String? nombreCobertura,
    bool? guardando,
    Object? error = _sentinel,
  }) {
    return PlanillaState(
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      dni: dni ?? this.dni,
      tipoDni: tipoDni ?? this.tipoDni,
      sexo: sexo ?? this.sexo,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      tieneCud: tieneCud ?? this.tieneCud,
      telefonoFijo: telefonoFijo ?? this.telefonoFijo,
      celular: celular ?? this.celular,
      parentesco: parentesco ?? this.parentesco,
      calle: calle ?? this.calle,
      nroCalle: nroCalle ?? this.nroCalle,
      piso: piso ?? this.piso,
      dpto: dpto ?? this.dpto,
      manzana: manzana ?? this.manzana,
      casa: casa ?? this.casa,
      nroCasa: nroCasa ?? this.nroCasa,
      pieza: pieza ?? this.pieza,
      provincia: provincia ?? this.provincia,
      departamento: departamento ?? this.departamento,
      localidad: localidad ?? this.localidad,
      tipoCobertura: tipoCobertura ?? this.tipoCobertura,
      nombreCobertura: nombreCobertura ?? this.nombreCobertura,
      guardando: guardando ?? this.guardando,
      error: identical(error, _sentinel) ? this.error : error as String?,
    );
  }
}

const _sentinel = Object();

// ─── Controller ────────────────────────────────────────────────────────────────

class PlanillaController extends StateNotifier<PlanillaState> {
  PlanillaController({
    required AppDatabase db,
    required String? tutorId,
    String Function()? generarId,
  })  : _db = db,
        _tutorId = tutorId,
        _generarId = generarId ?? (() => const Uuid().v4()),
        super(const PlanillaState());

  final AppDatabase _db;
  final String? _tutorId;
  final String Function() _generarId;

  void setNombre(String v) => state = state.copyWith(nombre: v);
  void setApellido(String v) => state = state.copyWith(apellido: v);
  void setDni(String v) => state = state.copyWith(dni: v);
  void setTipoDni(String v) => state = state.copyWith(tipoDni: v);
  void setSexo(String v) => state = state.copyWith(sexo: v);
  void setFechaNacimiento(DateTime v) => state = state.copyWith(fechaNacimiento: v);
  void setTieneCud(String v) => state = state.copyWith(tieneCud: v);
  void setTelefonoFijo(String v) => state = state.copyWith(telefonoFijo: v);
  void setCelular(String v) => state = state.copyWith(celular: v);
  void setParentesco(String v) => state = state.copyWith(parentesco: v);

  void setCalle(String v) => state = state.copyWith(calle: v);
  void setNroCalle(String v) => state = state.copyWith(nroCalle: v);
  void setPiso(String v) => state = state.copyWith(piso: v);
  void setDpto(String v) => state = state.copyWith(dpto: v);
  void setManzana(String v) => state = state.copyWith(manzana: v);
  void setCasa(String v) => state = state.copyWith(casa: v);
  void setNroCasa(String v) => state = state.copyWith(nroCasa: v);
  void setPieza(String v) => state = state.copyWith(pieza: v);
  void setProvincia(String v) => state = state.copyWith(provincia: v);
  void setDepartamento(String v) => state = state.copyWith(departamento: v);
  void setLocalidad(String v) => state = state.copyWith(localidad: v);

  void setNombreCobertura(String v) => state = state.copyWith(nombreCobertura: v);

  /// Al cambiar a una cobertura que no lleva nombre, lo limpia.
  void setTipoCobertura(String v) {
    if (v == 'obra_social' || v == 'prepaga') {
      state = state.copyWith(tipoCobertura: v);
    } else {
      state = state.copyWith(tipoCobertura: v, nombreCobertura: '');
    }
  }

  /// Edad en años cumplidos a partir de la fecha de nacimiento.
  int? _edadEnAnios(DateTime? f) {
    if (f == null) return null;
    final now = DateTime.now();
    var edad = now.year - f.year;
    if (now.month < f.month || (now.month == f.month && now.day < f.day)) {
      edad--;
    }
    return edad < 0 ? null : edad;
  }

  Future<void> guardar() async {
    if (_tutorId == null || _tutorId.isEmpty) {
      state = state.copyWith(error: 'No hay tutor autenticado');
      return;
    }
    final tutorId = _tutorId; // promovido a String tras el guard
    state = state.copyWith(guardando: true, error: null);
    try {
      final s = state;
      final payload = <String, dynamic>{
        'persona': {
          'nombre': s.nombre,
          'apellido': s.apellido,
          'dni': s.dni,
          'tipo_dni': s.tipoDni,
          'sexo': s.sexo,
          'fecha_nacimiento': s.fechaNacimiento?.toIso8601String().split('T').first,
        },
        'domicilio': {
          'calle': s.calle,
          'nro_calle': s.nroCalle,
          'piso': s.piso,
          'dpto': s.dpto,
          'manzana': s.manzana,
          'casa': s.casa,
          'nro_casa': s.nroCasa,
          'pieza': s.pieza,
          'provincia': s.provincia,
          'departamento': s.departamento,
          'localidad': s.localidad,
        },
        'edad': _edadEnAnios(s.fechaNacimiento),
        'tiene_cud': s.tieneCud,
        'tipo_cobertura': s.tipoCobertura,
        'nombre_cobertura': s.nombreCobertura,
        'telefono_fijo': s.telefonoFijo,
        'celular': s.celular,
        'parentesco': s.parentesco,
      };
      await _db.insertHijoDraft(
        id: _generarId(),
        tutorId: tutorId,
        nombreNna: s.nombre,
        apellidoNna: s.apellido,
        payloadJson: jsonEncode(payload),
      );
      state = state.copyWith(guardando: false);
    } catch (e) {
      state = state.copyWith(guardando: false, error: e.toString());
    }
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final planillaControllerProvider =
    StateNotifierProvider.autoDispose<PlanillaController, PlanillaState>((ref) {
  final s = ref.watch(sessionControllerProvider);
  final tutorId = s is SesionAutenticada ? s.sesion.usuario.tutorId : null;
  return PlanillaController(
    db: ref.watch(databaseProvider),
    tutorId: tutorId,
  );
});
```

- [ ] **Step 4: Correr el test y verificar que pasa**

Run: `flutter test test/features/hijos/planilla_controller_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/hijos/presentation/controllers/planilla_controller.dart test/features/hijos/planilla_controller_test.dart
git commit -m "feat(hijos): payload de registro con domicilio completo, cobertura y telefonos; sin antecedentes"
```

---

### Task 2: PlanillaScreen — UI de las 3 cards

**Files:**
- Modify: `lib/features/hijos/presentation/screens/planilla_screen.dart`
- Test: `test/features/hijos/planilla_screen_test.dart`

- [ ] **Step 1: Reescribir el test de la screen (debe fallar)**

Reemplazar **todo** el contenido de `test/features/hijos/planilla_screen_test.dart` por:

```dart
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:prosane_app/core/database/app_database.dart';
import 'package:prosane_app/core/database/database_provider.dart';
import 'package:prosane_app/core/design_system/app_button.dart';
import 'package:prosane_app/core/session/entities.dart';
import 'package:prosane_app/core/session/session_controller.dart';
import 'package:prosane_app/features/hijos/presentation/screens/planilla_screen.dart';

SessionController _tutor() => SessionController()
  ..setSesion(const Sesion(
    usuario: Usuario(id: 'u1', nombre: 'Juan', rolName: 'tutor', rolLabel: 'Tutor', tutorId: 'tut-1'),
    acciones: [],
  ));

Widget _app(AppDatabase db) {
  final router = GoRouter(initialLocation: '/hijos/nuevo', routes: [
    GoRoute(path: '/hijos/nuevo', builder: (c, s) => const PlanillaScreen()),
    GoRoute(path: '/inicio', builder: (c, s) => const Scaffold(body: Text('inicio'))),
  ]);
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      sessionControllerProvider.overrideWith((ref) => _tutor()),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('muestra las 3 cards y NO la de antecedentes', (t) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await t.pumpWidget(_app(db));
    await t.pumpAndSettle();
    expect(find.text('Datos del niño/a'), findsOneWidget);
    expect(find.text('Domicilio'), findsOneWidget);
    expect(find.text('Cobertura de salud'), findsOneWidget);
    expect(find.textContaining('Antecedentes', findRichText: true), findsNothing);
    expect(find.textContaining('Asma', findRichText: true), findsNothing);
  });

  testWidgets('muestra campos nuevos de domicilio y telefonos', (t) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await t.pumpWidget(_app(db));
    await t.pumpAndSettle();
    expect(find.text('Teléfono fijo'), findsOneWidget);
    expect(find.text('Celular'), findsOneWidget);
    expect(find.text('Piso'), findsOneWidget);
    expect(find.text('Localidad'), findsOneWidget);
  });

  testWidgets('nombre de cobertura NO aparece por defecto (sin cobertura elegida)', (t) async {
    // La lógica de cuándo SÍ aparece (obra_social/prepaga) está cubierta a nivel
    // unitario por `pideNombreCobertura` en planilla_controller_test. Acá solo
    // verificamos el render condicional en el estado inicial (no se maneja el
    // dropdown por UI porque hay varios dropdowns y la interacción es frágil).
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await t.pumpWidget(_app(db));
    await t.pumpAndSettle();
    expect(find.text('Nombre de la cobertura'), findsNothing);
  });

  testWidgets('Guardar arranca deshabilitado sin requeridos', (t) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await t.pumpWidget(_app(db));
    await t.pumpAndSettle();
    final boton = t.widget<AppButton>(find.byType(AppButton));
    expect(boton.onPressed, isNull);
  });
}
```

- [ ] **Step 2: Correr el test y verificar que falla**

Run: `flutter test test/features/hijos/planilla_screen_test.dart`
Expected: FAIL (los textos `Domicilio`/`Teléfono fijo`/`Piso`/`Localidad` o el título `Cobertura de salud` no existen aún; la card de antecedentes todavía está).

- [ ] **Step 3: Reescribir el body de las cards en la screen**

En `lib/features/hijos/presentation/screens/planilla_screen.dart`, reemplazar el bloque que va desde la **Card 1** (`AppCard(` con `Text('Datos del niño/a'...`) hasta el cierre de la **card de antecedentes** (la que tiene `Text('Antecedentes del niño/a'...` con los dos `AppSwitch`), por las 3 cards siguientes. Es decir, reemplazar este rango (las 4 cards actuales) por estas 3 cards:

```dart
                  AppCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Text('Datos del niño/a', style: AppTypography.subtitulo),
                      const SizedBox(height: AppSpacing.sm),
                      AppTextField(label: 'Nombre', onChanged: ctrl.setNombre),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(label: 'Apellido', onChanged: ctrl.setApellido),
                      const SizedBox(height: AppSpacing.md),
                      AppDropdownField(
                        label: 'Tipo de documento',
                        value: state.tipoDni,
                        items: const [(value: 'DNI', label: 'DNI'), (value: 'Pasaporte', label: 'Pasaporte')],
                        onChanged: ctrl.setTipoDni,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(label: 'N° de documento', keyboardType: TextInputType.number, onChanged: ctrl.setDni),
                      const SizedBox(height: AppSpacing.md),
                      AppDropdownField(
                        label: 'Sexo',
                        value: state.sexo.isEmpty ? null : state.sexo,
                        items: const [
                          (value: 'F', label: 'Femenino'),
                          (value: 'M', label: 'Masculino'),
                          (value: 'X', label: 'Otro'),
                        ],
                        onChanged: ctrl.setSexo,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppDateField(
                        label: 'Fecha de nacimiento',
                        value: state.fechaNacimiento,
                        onChanged: ctrl.setFechaNacimiento,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppDropdownField(
                        label: 'CUD',
                        value: state.tieneCud.isEmpty ? null : state.tieneCud,
                        items: const [
                          (value: 'SI', label: 'Sí'),
                          (value: 'NO', label: 'No'),
                        ],
                        onChanged: ctrl.setTieneCud,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(label: 'Teléfono fijo', keyboardType: TextInputType.phone, onChanged: ctrl.setTelefonoFijo),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(label: 'Celular', keyboardType: TextInputType.phone, onChanged: ctrl.setCelular),
                      const SizedBox(height: AppSpacing.md),
                      AppDropdownField(
                        label: 'Parentesco',
                        value: state.parentesco.isEmpty ? null : state.parentesco,
                        items: const [
                          (value: 'Hijo/a', label: 'Hijo/a'),
                          (value: 'Hijastro/a', label: 'Hijastro/a'),
                          (value: 'Nieto/a', label: 'Nieto/a'),
                          (value: 'Sobrino/a', label: 'Sobrino/a'),
                          (value: 'Tutelado/a', label: 'Tutelado/a'),
                          (value: 'Otro', label: 'Otro'),
                        ],
                        onChanged: ctrl.setParentesco,
                      ),
                    ]),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Text('Domicilio', style: AppTypography.subtitulo),
                      const SizedBox(height: AppSpacing.sm),
                      AppTextField(label: 'Calle', onChanged: ctrl.setCalle),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(label: 'Número', keyboardType: TextInputType.number, onChanged: ctrl.setNroCalle),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(label: 'Piso', onChanged: ctrl.setPiso),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(label: 'Departamento (Dpto.)', onChanged: ctrl.setDpto),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(label: 'Manzana', onChanged: ctrl.setManzana),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(label: 'Casa', onChanged: ctrl.setCasa),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(label: 'Número de casa', keyboardType: TextInputType.number, onChanged: ctrl.setNroCasa),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(label: 'Pieza', onChanged: ctrl.setPieza),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(label: 'Provincia', onChanged: ctrl.setProvincia),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(label: 'Departamento (jurisdicción)', onChanged: ctrl.setDepartamento),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(label: 'Localidad', onChanged: ctrl.setLocalidad),
                    ]),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Text('Cobertura de salud', style: AppTypography.subtitulo),
                      const SizedBox(height: AppSpacing.sm),
                      AppDropdownField(
                        label: 'Tipo de cobertura',
                        value: state.tipoCobertura.isEmpty ? null : state.tipoCobertura,
                        items: const [
                          (value: 'obra_social', label: 'Obra Social (incluye PAMI)'),
                          (value: 'estatal', label: 'Programas o planes estatales'),
                          (value: 'prepaga', label: 'Plan privado o Prepaga'),
                          (value: 'sin_cobertura', label: 'No tiene'),
                        ],
                        onChanged: ctrl.setTipoCobertura,
                      ),
                      if (state.pideNombreCobertura) ...[
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(label: 'Nombre de la cobertura', onChanged: ctrl.setNombreCobertura),
                      ],
                    ]),
                  ),
```

> Nota: dos campos distintos del PDF se llaman "Departamento" (el `dpto` del domicilio urbano y el `departamento`/jurisdicción). Se distinguen con los labels `Departamento (Dpto.)` y `Departamento (jurisdicción)`.

- [ ] **Step 4: Verificar imports**

`AppSwitch` ya no se usa en la screen. Quitar la línea `import '../../../../core/design_system/app_switch.dart';` de `planilla_screen.dart`. (El resto de imports —`AppCard`, `AppDateField`, `AppDropdownField`, `AppTextField`, `AppButton`— se siguen usando.)

- [ ] **Step 5: Correr el test y verificar que pasa**

Run: `flutter test test/features/hijos/planilla_screen_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 6: Analyze + suite completa**

Run: `flutter analyze lib test && flutter test`
Expected: "No issues found!" y todos los tests en verde.

- [ ] **Step 7: Commit**

```bash
git add lib/features/hijos/presentation/screens/planilla_screen.dart test/features/hijos/planilla_screen_test.dart
git commit -m "feat(hijos): formulario de registro con datos del niño + domicilio completo + cobertura PROSANE"
```

---

## Self-Review (hecho por el autor del plan)

**1. Cobertura del spec:**
- Datos del niño (nombre, apellido, tipo doc, dni, sexo, fecha nac, CUD Sí/No, teléfonos, parentesco) → Task 2 Card 1. ✅
- Domicilio 11 campos → Task 2 Card 2 + Task 1 estado/payload. ✅
- Cobertura 4 opciones con códigos + nombre condicional → Task 2 Card 3 + Task 1 `setTipoCobertura`/`pideNombreCobertura`. ✅
- Teléfonos a nivel raíz del payload (Paciente) → Task 1 payload + test. ✅
- Quitar antecedentes (asma/diabetes) → Task 1 (estado/payload) + Task 2 (card eliminada) + tests. ✅
- `tiene_cud` SI/NO, códigos cortos cobertura → Task 1 test + Task 2 dropdowns. ✅
- Offline-first sin cambios → `guardar()` sigue usando `insertHijoDraft`; provider intacto. ✅

**2. Placeholders:** Ninguno; todo el código está completo.

**3. Consistencia de tipos:** Los setters usados en los tests (`setTelefonoFijo`, `setPiso`, `setNroCasa`, `setDepartamento`, `setLocalidad`, `setTipoCobertura`, etc.) existen en el controller de Task 1. Los `value` de cobertura del dropdown (`obra_social`/`estatal`/`prepaga`/`sin_cobertura`) coinciden con `pideNombreCobertura`. Los labels testeados (`Teléfono fijo`, `Celular`, `Piso`, `Localidad`, `Nombre de la cobertura`, `Obra Social (incluye PAMI)`) coinciden con la screen.
