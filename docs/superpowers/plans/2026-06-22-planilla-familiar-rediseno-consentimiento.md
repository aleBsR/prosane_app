# Rediseño planilla familiar + consentimiento por hijo — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rediseñar la planilla familiar (formulario por hijo) alineada al design system, con el consentimiento como primera sección (checkbox + modal de términos + adulto responsable prefilleado y bloqueado desde la sesión).

**Architecture:** Se extraen 2 componentes reutilizables (`AppDropdownField`, `AppDateField`). Se extiende `/me` (aditivo) y la sesión/cache para transportar la identidad del tutor (incl. `tutorId`, hoy no cacheado). El controller deriva la edad y siembra el adulto desde la sesión. La pantalla se reescribe en `AppCard`s con inputs correctos y "Guardar" gateado.

**Tech Stack:** Flutter 3.44, Riverpod, Drift, go_router; Django 6 + DRF (solo `/me`).

**Entorno backend:** usar `./venv/bin/python`; tests `./venv/bin/python manage.py test <app> --noinput`. **Entorno app:** `flutter test`, `flutter analyze`, `dart format`. Rama: `feat/primera-parte-registro-familiar` (ambos repos).

**Contrato de payload de `POST /tutores/<id>/hijos/`: NO cambia.**

---

## File Structure

**prosane_api**
- Modify: `apps/usuarios/views.py` (`MeView`: agregar `tipo_dni` + `dni` a `user`).
- Test: `apps/usuarios/tests/` (o `apps/usuarios/tests.py`) — `/me` incluye los campos nuevos.

**prosane_app**
- Create: `lib/core/design_system/app_dropdown_field.dart`
- Create: `lib/core/design_system/app_date_field.dart`
- Modify: `lib/features/auth/data/dtos/me_response.dart` (exponer `nombrePila`, `apellido`, `tipoDni`, `dni`)
- Modify: `lib/core/session/entities.dart` (`Usuario`: +`nombrePila`, `apellido`, `tipoDni`, `dni`)
- Modify: `lib/features/auth/data/repositories/auth_repository_impl.dart` (mapear los campos nuevos en login/register)
- Modify: `lib/core/database/tables/cached_session_table.dart` (+`tutorId`, `nombrePila`, `apellido`, `tipoDni`, `dni`)
- Modify: `lib/core/database/app_database.dart` (`schemaVersion` 3→4 + migración; `guardarSesion`/`leerSesion`)
- Modify: `lib/features/hijos/presentation/controllers/planilla_controller.dart` (edad derivada; adulto desde constructor/provider; sin `setEdad`)
- Modify: `lib/features/hijos/presentation/screens/planilla_screen.dart` (reescritura: AppCards + consentimiento + inputs)
- Modify: `lib/features/pendientes/presentation/pendientes_screen.dart` (copia del nudge)
- Tests: en `test/` espejando cada archivo.

---

## Task 1: Backend `/me` expone `tipo_dni` y `dni` (aditivo)

**Files:**
- Modify: `prosane_api/apps/usuarios/views.py:50-58`
- Test: `prosane_api/apps/usuarios/tests.py` (agregar test; si ya hay paquete `tests/`, agregar archivo `test_me_identidad.py`)

- [ ] **Step 1: Escribir el test que falla**

Agregar en `apps/usuarios/tests.py` (ajustar imports/login helper a los existentes en el repo; el patrón estándar: crear usuario+persona, autenticar con JWT y pegarle a `/api/v1/me/`):

```python
from django.urls import reverse
from rest_framework.test import APITestCase
from apps.usuarios.models import Usuario
from apps.personas.models import Persona


class MeIdentidadTest(APITestCase):
    def test_me_incluye_tipo_dni_y_dni_de_la_persona(self):
        persona = Persona.objects.create(
            nombre="Juan", apellido="Arquipa", dni="43949474", tipo_dni="DNI"
        )
        user = Usuario.objects.create_user(email="juan@test.com", password="secret123")
        user.persona = persona
        user.save()
        self.client.force_authenticate(user=user)

        resp = self.client.get("/api/v1/me/")

        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp.data["user"]["tipo_dni"], "DNI")
        self.assertEqual(resp.data["user"]["dni"], "43949474")
```

> Nota: si el modelo `Usuario` no tiene `create_user` o la relación `persona` se setea distinto, copiar el patrón de un test existente en `apps/usuarios/`. La aserción clave (claves `tipo_dni`/`dni` en `user`) no cambia.

- [ ] **Step 2: Correr el test y verque falle**

Run: `./venv/bin/python manage.py test apps.usuarios --noinput`
Expected: FAIL (`KeyError: 'tipo_dni'` o las claves no están).

- [ ] **Step 3: Implementar**

En `apps/usuarios/views.py`, dentro de `data["user"]`, agregar dos claves (después de `"apellido"`):

```python
            "user": {
                "id": str(user.id),
                "email": user.email,
                "nombre": getattr(persona, "nombre", "") or "",
                "apellido": getattr(persona, "apellido", "") or "",
                "tipo_dni": getattr(persona, "tipo_dni", "") or "",
                "dni": getattr(persona, "dni", "") or "",
                "is_staff": user.is_staff,
                "tutor_id": str(tutor.id) if tutor else None,
            },
```

- [ ] **Step 4: Correr el test y verque pase**

Run: `./venv/bin/python manage.py test apps.usuarios --noinput`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git -C ../prosane_api add apps/usuarios/views.py apps/usuarios/tests.py
git -C ../prosane_api commit -m "feat(auth): /me expone tipo_dni y dni del tutor (aditivo)"
```

---

## Task 2: Componente `AppDropdownField`

**Files:**
- Create: `lib/core/design_system/app_dropdown_field.dart`
- Test: `test/core/design_system/app_dropdown_field_test.dart`

- [ ] **Step 1: Escribir el test que falla**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/design_system/app_dropdown_field.dart';

void main() {
  testWidgets('muestra label y opciones; dispara onChanged con el value', (tester) async {
    String? elegido;
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: AppDropdownField(
        label: 'Sexo',
        items: const [(value: 'F', label: 'Femenino'), (value: 'M', label: 'Masculino')],
        onChanged: (v) => elegido = v,
      ),
    )));
    expect(find.text('Sexo'), findsOneWidget);
    await tester.tap(find.byType(AppDropdownField));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Femenino').last);
    await tester.pumpAndSettle();
    expect(elegido, 'F');
  });
}
```

- [ ] **Step 2: Correr y verificar que falle**

Run: `flutter test test/core/design_system/app_dropdown_field_test.dart`
Expected: FAIL (no existe `app_dropdown_field.dart`).

- [ ] **Step 3: Implementar**

```dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Campo de selección estándar: label + DropdownButtonFormField con la
/// decoración del design system (campo lavanda, focus violeta). Reemplaza la
/// decoración duplicada del wizard de registro.
class AppDropdownField extends StatelessWidget {
  const AppDropdownField({
    super.key,
    required this.label,
    required this.items,
    required this.onChanged,
    this.value,
    this.hint = 'Seleccioná',
  });

  final String label;
  final List<({String value, String label})> items;
  final ValueChanged<String> onChanged;
  final String? value;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: AppTypography.subtitulo),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: (value == null || value!.isEmpty) ? null : value,
          hint: Text(hint),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.campo,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.campo),
              borderSide: const BorderSide(color: Colors.transparent),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.campo),
              borderSide: const BorderSide(color: AppColors.primario, width: 1.5),
            ),
          ),
          items: [
            for (final it in items)
              DropdownMenuItem(value: it.value, child: Text(it.label)),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Correr y verificar que pase**

Run: `flutter test test/core/design_system/app_dropdown_field_test.dart` → PASS
Run: `flutter analyze lib/core/design_system/app_dropdown_field.dart` → No issues

- [ ] **Step 5: Commit**

```bash
git add lib/core/design_system/app_dropdown_field.dart test/core/design_system/app_dropdown_field_test.dart
git commit -m "feat(ui): AppDropdownField reutilizable"
```

---

## Task 3: Componente `AppDateField`

**Files:**
- Create: `lib/core/design_system/app_date_field.dart`
- Test: `test/core/design_system/app_date_field_test.dart`

- [ ] **Step 1: Escribir el test que falla**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/design_system/app_date_field.dart';

void main() {
  testWidgets('muestra hint sin valor y la fecha formateada con valor', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: AppDateField(label: 'Fecha', value: null, onChanged: (_) {}),
    )));
    expect(find.text('Seleccionar fecha'), findsOneWidget);

    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: AppDateField(label: 'Fecha', value: DateTime(2015, 3, 7), onChanged: (_) {}),
    )));
    expect(find.text('07/03/2015'), findsOneWidget);
  });

  testWidgets('abre el date picker al tocar', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: AppDateField(label: 'Fecha', value: null, onChanged: (_) {}),
    )));
    await tester.tap(find.byType(AppDateField));
    await tester.pumpAndSettle();
    // El picker de Material muestra el botón OK.
    expect(find.text('OK'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Correr y verificar que falle**

Run: `flutter test test/core/design_system/app_date_field_test.dart`
Expected: FAIL (no existe `app_date_field.dart`).

- [ ] **Step 3: Implementar**

```dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Campo de fecha estándar: label + recuadro tappable que abre showDatePicker
/// y muestra dd/mm/aaaa (o un hint si no hay valor).
class AppDateField extends StatelessWidget {
  const AppDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint = 'Seleccionar fecha',
    this.firstDate,
    this.lastDate,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final String hint;
  final DateTime? firstDate;
  final DateTime? lastDate;

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _abrir(BuildContext context) async {
    final ahora = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? DateTime(ahora.year - 8, ahora.month, ahora.day),
      firstDate: firstDate ?? DateTime(1900),
      lastDate: lastDate ?? ahora,
      helpText: label,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: AppTypography.subtitulo),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => _abrir(context),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.campo,
              borderRadius: BorderRadius.circular(AppRadii.campo),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value != null ? _fmt(value!) : hint,
                    style: AppTypography.campo),
                const Icon(Icons.calendar_today_outlined,
                    size: 18, color: AppColors.link),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Correr y verificar que pase**

Run: `flutter test test/core/design_system/app_date_field_test.dart` → PASS
Run: `flutter analyze lib/core/design_system/app_date_field.dart` → No issues

- [ ] **Step 5: Commit**

```bash
git add lib/core/design_system/app_date_field.dart test/core/design_system/app_date_field_test.dart
git commit -m "feat(ui): AppDateField reutilizable"
```

---

## Task 4: Transportar identidad del tutor (sesión + cache, Drift 3→4)

Hace que `Usuario` lleve `nombrePila`, `apellido`, `tipoDni`, `dni` y que el cache persista además `tutorId` (hoy no cacheado).

**Files:**
- Modify: `lib/core/session/entities.dart`
- Modify: `lib/features/auth/data/dtos/me_response.dart`
- Modify: `lib/features/auth/data/repositories/auth_repository_impl.dart`
- Modify: `lib/core/database/tables/cached_session_table.dart`
- Modify: `lib/core/database/app_database.dart`
- Test: `test/features/auth/data/me_response_test.dart` (si no existe, crear), `test/core/database/cached_session_test.dart`

- [ ] **Step 1: Test de `MeResponse` (falla)**

Agregar a `test/features/auth/data/me_response_test.dart` (crear el archivo si no existe):

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/features/auth/data/dtos/me_response.dart';

void main() {
  test('MeResponse parsea nombrePila, apellido, tipoDni y dni por separado', () {
    final me = MeResponse.fromJson({
      'user': {
        'id': 'u1', 'email': 'j@t.com', 'nombre': 'Juan', 'apellido': 'Arquipa',
        'tipo_dni': 'DNI', 'dni': '43949474', 'tutor_id': 'tut-1',
      },
      'roles': [{'name': 'tutor', 'label': 'Tutor'}],
      'actions': [],
      'meta': {'version': '1', 'permissions_synced_at': '2026-06-22T00:00:00Z'},
    });
    expect(me.nombre, 'Juan Arquipa');        // display: sin cambios
    expect(me.nombrePila, 'Juan');
    expect(me.apellido, 'Arquipa');
    expect(me.tipoDni, 'DNI');
    expect(me.dni, '43949474');
  });
}
```

- [ ] **Step 2: Correr y verificar que falle**

Run: `flutter test test/features/auth/data/me_response_test.dart`
Expected: FAIL (getters inexistentes).

- [ ] **Step 3: `Usuario` entity — agregar campos**

En `lib/core/session/entities.dart`, reemplazar la clase `Usuario`:

```dart
class Usuario {
  const Usuario({
    required this.id,
    required this.nombre,
    required this.rolName,
    required this.rolLabel,
    this.tutorId,
    this.nombrePila,
    this.apellido,
    this.tipoDni,
    this.dni,
  });
  final String id, nombre, rolName, rolLabel;
  final String? tutorId;
  // Identidad desagregada del tutor (para prefill del adulto responsable).
  final String? nombrePila;
  final String? apellido;
  final String? tipoDni;
  final String? dni;
}
```

- [ ] **Step 4: `MeResponse` — exponer y parsear los campos**

En `lib/features/auth/data/dtos/me_response.dart`: agregar campos al constructor/clase y parsearlos. Reemplazar el constructor y el `return`:

```dart
  MeResponse({
    required this.id, required this.email, required this.nombre,
    required this.rolName, required this.rolLabel, required this.acciones,
    required this.metaVersion, required this.metaSyncedAt,
    this.tutorId, this.nombrePila, this.apellido, this.tipoDni, this.dni,
  });
  final String id, email, nombre, rolName, rolLabel, metaVersion, metaSyncedAt;
  final String? tutorId;
  final String? nombrePila, apellido, tipoDni, dni;
  final List<Accion> acciones;
```

Y en el `return MeResponse(...)` agregar:

```dart
      tutorId: user['tutor_id'] as String?,
      nombrePila: user['nombre'] as String?,
      apellido: user['apellido'] as String?,
      tipoDni: user['tipo_dni'] as String?,
      dni: user['dni'] as String?,
```

- [ ] **Step 5: Correr el test de MeResponse → pasa**

Run: `flutter test test/features/auth/data/me_response_test.dart` → PASS

- [ ] **Step 6: Mapear en login/register**

En `lib/features/auth/data/repositories/auth_repository_impl.dart`, en **ambos** lugares donde se construye `Usuario` (líneas ~26 y ~52), reemplazar por:

```dart
          usuario: Usuario(
            id: me.id, nombre: me.nombre, rolName: me.rolName, rolLabel: me.rolLabel,
            tutorId: me.tutorId, nombrePila: me.nombrePila, apellido: me.apellido,
            tipoDni: me.tipoDni, dni: me.dni,
          ),
```

- [ ] **Step 7: Cache — columnas nuevas en la tabla**

En `lib/core/database/tables/cached_session_table.dart`, agregar antes de `permissionsSyncedAt`:

```dart
  TextColumn get tutorId => text().nullable()();
  TextColumn get nombrePila => text().nullable()();
  TextColumn get apellido => text().nullable()();
  TextColumn get tipoDni => text().nullable()();
  TextColumn get dni => text().nullable()();
```

- [ ] **Step 8: Cache — schemaVersion + migración + guardar/leer**

En `lib/core/database/app_database.dart`:

1. Subir `schemaVersion` de `3` a `4`.
2. En `migration.onUpgrade`, agregar:

```dart
      if (from < 4) {
        await m.addColumn(cachedSessionRows, cachedSessionRows.tutorId);
        await m.addColumn(cachedSessionRows, cachedSessionRows.nombrePila);
        await m.addColumn(cachedSessionRows, cachedSessionRows.apellido);
        await m.addColumn(cachedSessionRows, cachedSessionRows.tipoDni);
        await m.addColumn(cachedSessionRows, cachedSessionRows.dni);
      }
```

3. En `guardarSesion`, agregar al `CachedSessionRowsCompanion.insert(...)`:

```dart
        tutorId: Value(s.usuario.tutorId),
        nombrePila: Value(s.usuario.nombrePila),
        apellido: Value(s.usuario.apellido),
        tipoDni: Value(s.usuario.tipoDni),
        dni: Value(s.usuario.dni),
```

4. En `leerSesion`, reemplazar la construcción de `Usuario` por:

```dart
      usuario: Usuario(
        id: row.userId,
        nombre: row.nombre ?? row.email,
        rolName: row.rolName,
        rolLabel: row.rolLabel,
        tutorId: row.tutorId,
        nombrePila: row.nombrePila,
        apellido: row.apellido,
        tipoDni: row.tipoDni,
        dni: row.dni,
      ),
```

- [ ] **Step 9: Regenerar código Drift**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: regenera `app_database.g.dart` sin errores.

- [ ] **Step 10: Test de cache (round-trip de identidad)**

Agregar a `test/core/database/cached_session_test.dart` un test:

```dart
  test('cachea y restaura la identidad del tutor (tutorId + adulto)', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    const u = Usuario(
      id: 'u1', nombre: 'Juan Arquipa', rolName: 'tutor', rolLabel: 'Tutor',
      tutorId: 'tut-1', nombrePila: 'Juan', apellido: 'Arquipa', tipoDni: 'DNI', dni: '43949474',
    );
    await db.guardarSesion(const Sesion(usuario: u, acciones: []),
        email: 'j@t.com', version: '1', syncedAtIso: '2026-06-22T00:00:00Z');

    final leida = await db.leerSesion();
    expect(leida!.usuario.tutorId, 'tut-1');
    expect(leida.usuario.nombrePila, 'Juan');
    expect(leida.usuario.apellido, 'Arquipa');
    expect(leida.usuario.tipoDni, 'DNI');
    expect(leida.usuario.dni, '43949474');
    await db.close();
  });
```

(Asegurar imports: `package:drift/native.dart`, `app_database.dart`, `entities.dart`.)

- [ ] **Step 11: Correr tests + analyze**

Run: `flutter test test/core/database/ test/features/auth/data/` → PASS
Run: `flutter analyze lib/core lib/features/auth` → No issues

- [ ] **Step 12: Commit**

```bash
git add lib/core/session/entities.dart lib/features/auth/data/dtos/me_response.dart \
  lib/features/auth/data/repositories/auth_repository_impl.dart \
  lib/core/database/tables/cached_session_table.dart lib/core/database/app_database.dart \
  lib/core/database/app_database.g.dart \
  test/features/auth/data/me_response_test.dart test/core/database/cached_session_test.dart
git commit -m "feat(session): transportar identidad del tutor + cachear tutorId (Drift 3->4)"
```

---

## Task 5: `planilla_controller` — edad derivada + adulto desde la sesión

**Files:**
- Modify: `lib/features/hijos/presentation/controllers/planilla_controller.dart`
- Test: `test/features/hijos/planilla_controller_test.dart` (reescribir)

- [ ] **Step 1: Reescribir el test (falla)**

Reemplazar el contenido de `test/features/hijos/planilla_controller_test.dart`:

```dart
import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/database/app_database.dart';
import 'package:prosane_app/features/hijos/presentation/controllers/planilla_controller.dart';

void main() {
  test('guardar arma payload: edad derivada de la fecha + adulto desde el constructor', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final ctrl = PlanillaController(
      db: db, tutorId: 'tut-1', generarId: () => 'hijo-1',
      adultoNombre: 'Pedro', adultoApellido: 'Pérez',
      adultoTipoDocumento: 'DNI', adultoDni: '40000000',
    );
    ctrl.setNombre('Juana');
    ctrl.setApellido('Pérez');
    ctrl.setDni('70000000');
    ctrl.setSexo('F');
    ctrl.setFechaNacimiento(DateTime(2015, 6, 1));
    ctrl.setConsentimientoAceptado(true);

    await ctrl.guardar();

    final row = (await db.hijosPendientes()).single;
    final body = jsonDecode(row.payloadJson) as Map<String, dynamic>;
    expect((body['persona'] as Map)['dni'], '70000000');
    // edad derivada: 2015-06-01 → al menos 9 años a la fecha de corrida.
    expect(body['edad'], greaterThanOrEqualTo(9));
    // adulto sembrado desde el constructor (sesión), no por setters de UI.
    expect((body['consentimiento'] as Map)['adulto_nombre'], 'Pedro');
    expect((body['consentimiento'] as Map)['adulto_dni'], '40000000');
    await db.close();
  });

  test('puedeGuardar exige requeridos del niño + consentimiento aceptado', () {
    const base = PlanillaState();
    expect(base.puedeGuardar, isFalse);
    final ok = base.copyWith(
      nombre: 'Juana', apellido: 'Pérez', dni: '70000000',
      sexo: 'F', fechaNacimiento: DateTime(2015, 6, 1), consentimientoAceptado: true,
    );
    expect(ok.puedeGuardar, isTrue);
    expect(ok.copyWith(consentimientoAceptado: false).puedeGuardar, isFalse);
  });
}
```

- [ ] **Step 2: Correr y verificar que falle**

Run: `flutter test test/features/hijos/planilla_controller_test.dart`
Expected: FAIL (`puedeGuardar` no existe; constructor sin params de adulto; edad no derivada).

- [ ] **Step 3: Implementar en el controller**

En `planilla_controller.dart`:

1. Agregar getter a `PlanillaState` (antes de `copyWith`):

```dart
  /// Habilita "Guardar": requeridos del niño + consentimiento aceptado.
  bool get puedeGuardar =>
      nombre.trim().isNotEmpty &&
      apellido.trim().isNotEmpty &&
      dni.trim().isNotEmpty &&
      sexo.isNotEmpty &&
      fechaNacimiento != null &&
      consentimientoAceptado;
```

2. Constructor de `PlanillaController`: aceptar la identidad del adulto y sembrarla en el estado inicial:

```dart
  PlanillaController({
    required AppDatabase db,
    required String? tutorId,
    String adultoNombre = '',
    String adultoApellido = '',
    String adultoTipoDocumento = 'DNI',
    String adultoDni = '',
    String Function()? generarId,
  })  : _db = db,
        _tutorId = tutorId,
        _generarId = generarId ?? (() => const Uuid().v4()),
        super(PlanillaState(
          adultoNombre: adultoNombre,
          adultoApellido: adultoApellido,
          adultoTipoDocumento: adultoTipoDocumento,
          adultoDni: adultoDni,
        ));
```

3. Borrar el método `setEdad` (la edad ya no se ingresa a mano).

4. Agregar helper de edad (al final de la clase, antes del cierre):

```dart
  int? _edadEnAnios(DateTime? f) {
    if (f == null) return null;
    final now = DateTime.now();
    var edad = now.year - f.year;
    if (now.month < f.month || (now.month == f.month && now.day < f.day)) {
      edad--;
    }
    return edad < 0 ? null : edad;
  }
```

5. En `guardar()`, cambiar la línea `'edad': s.edad,` por:

```dart
        'edad': _edadEnAnios(s.fechaNacimiento),
```

6. Actualizar el provider para sembrar el adulto desde la sesión:

```dart
final planillaControllerProvider =
    StateNotifierProvider.autoDispose<PlanillaController, PlanillaState>((ref) {
  final s = ref.watch(sessionControllerProvider);
  final u = s is SesionAutenticada ? s.sesion.usuario : null;
  return PlanillaController(
    db: ref.watch(databaseProvider),
    tutorId: u?.tutorId,
    adultoNombre: u?.nombrePila ?? '',
    adultoApellido: u?.apellido ?? '',
    adultoTipoDocumento: u?.tipoDni ?? 'DNI',
    adultoDni: u?.dni ?? '',
  );
});
```

- [ ] **Step 4: Correr y verificar que pase**

Run: `flutter test test/features/hijos/planilla_controller_test.dart` → PASS
Run: `flutter analyze lib/features/hijos/presentation/controllers/planilla_controller.dart` → No issues

- [ ] **Step 5: Commit**

```bash
git add lib/features/hijos/presentation/controllers/planilla_controller.dart test/features/hijos/planilla_controller_test.dart
git commit -m "feat(hijos): edad derivada de la fecha + adulto responsable desde la sesion"
```

---

## Task 6: Reescritura de `PlanillaScreen` (AppCards + consentimiento + inputs)

**Files:**
- Modify: `lib/features/hijos/presentation/screens/planilla_screen.dart` (reescritura completa)
- Test: `test/features/hijos/planilla_screen_test.dart` (crear)

- [ ] **Step 1: Test de pantalla (falla)**

Crear `test/features/hijos/planilla_screen_test.dart`:

```dart
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:prosane_app/core/database/app_database.dart';
import 'package:prosane_app/core/database/database_provider.dart';
import 'package:prosane_app/core/session/entities.dart';
import 'package:prosane_app/core/session/session_controller.dart';
import 'package:prosane_app/features/hijos/presentation/screens/planilla_screen.dart';

SessionController _tutor() => SessionController()
  ..setSesion(const Sesion(
    usuario: Usuario(
      id: 'u1', nombre: 'Juan Arquipa', rolName: 'tutor', rolLabel: 'Tutor',
      tutorId: 'tut-1', nombrePila: 'Juan', apellido: 'Arquipa', tipoDni: 'DNI', dni: '43949474',
    ),
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
  testWidgets('muestra el adulto responsable prefilleado desde la sesión', (t) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await t.pumpWidget(_app(db));
    await t.pumpAndSettle();
    expect(find.textContaining('Juan'), findsWidgets);     // nombre del adulto
    expect(find.textContaining('43949474'), findsOneWidget); // dni del adulto
  });

  testWidgets('el modal de términos abre con el link "Ver términos de consentimiento"', (t) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await t.pumpWidget(_app(db));
    await t.pumpAndSettle();
    await t.tap(find.text('Ver términos de consentimiento'));
    await t.pumpAndSettle();
    expect(find.text('Términos del consentimiento'), findsOneWidget);
    expect(find.textContaining('examen clínico'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Correr y verificar que falle**

Run: `flutter test test/features/hijos/planilla_screen_test.dart`
Expected: FAIL (la pantalla actual no tiene el link ni el prefill).

- [ ] **Step 3: Reescribir `planilla_screen.dart`**

Reemplazar el archivo completo por:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/app_date_field.dart';
import '../../../../core/design_system/app_dropdown_field.dart';
import '../../../../core/design_system/app_gradient_scaffold.dart';
import '../../../../core/design_system/app_link.dart';
import '../../../../core/design_system/app_switch.dart';
import '../../../../core/design_system/app_text_field.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/providers.dart';
import '../controllers/planilla_controller.dart';

class PlanillaScreen extends ConsumerWidget {
  const PlanillaScreen({super.key});

  void _verTerminos(BuildContext context, String nombreHijo) {
    final quien = nombreHijo.trim().isEmpty ? 'mi hijo/a' : nombreHijo.trim();
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Términos del consentimiento'),
        content: SingleChildScrollView(
          child: Text.rich(TextSpan(
            style: AppTypography.texto,
            children: [
              const TextSpan(text: 'Autorizo que el equipo de salud le realice a '),
              TextSpan(text: quien, style: const TextStyle(fontWeight: FontWeight.bold)),
              const TextSpan(text: ' un '),
              const TextSpan(text: 'examen clínico y odontológico', style: TextStyle(fontWeight: FontWeight.bold)),
              const TextSpan(text: ' y le aplique las '),
              const TextSpan(text: 'vacunas', style: TextStyle(fontWeight: FontWeight.bold)),
              const TextSpan(text: ' correspondientes para completar el calendario si fuese necesario. '),
              const TextSpan(text: 'Los datos brindados serán tratados con '),
              const TextSpan(text: 'máxima confidencialidad', style: TextStyle(fontWeight: FontWeight.bold)),
              const TextSpan(text: '. Ante cualquier duda puedo acercarme a la escuela o al centro de salud.'),
            ],
          )),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(planillaControllerProvider);
    final ctrl = ref.read(planillaControllerProvider.notifier);

    return AppGradientScaffold(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.blanco),
                onPressed: () => context.pop(),
              ),
              Text('Evaluación de tu hijo/a',
                  style: AppTypography.titulo.copyWith(color: AppColors.blanco, fontSize: 22)),
            ]),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Consentimiento (primera parte) ──────────────────────────
                  AppCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Consentimiento', style: AppTypography.subtitulo),
                      const SizedBox(height: AppSpacing.sm),
                      AppSwitch(
                        label: 'Acepto los términos del consentimiento',
                        value: state.consentimientoAceptado,
                        onChanged: ctrl.setConsentimientoAceptado,
                      ),
                      const SizedBox(height: 4),
                      AppLink(
                        text: 'Ver términos de consentimiento',
                        onTap: () => _verTerminos(context, state.nombre),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text('Adulto responsable', style: AppTypography.subtitulo),
                      const SizedBox(height: 4),
                      _ReadOnly('Nombre y apellido',
                          '${state.adultoNombre} ${state.adultoApellido}'.trim()),
                      _ReadOnly('Documento',
                          '${state.adultoTipoDocumento} ${state.adultoDni}'.trim()),
                    ]),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ── Datos del niño/a ────────────────────────────────────────
                  AppCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Text('Datos del niño/a', style: AppTypography.subtitulo),
                      const SizedBox(height: AppSpacing.sm),
                      AppTextField(label: 'Nombre', onChanged: ctrl.setNombre),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(label: 'Apellido', onChanged: ctrl.setApellido),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(label: 'DNI', keyboardType: TextInputType.number, onChanged: ctrl.setDni),
                      const SizedBox(height: AppSpacing.md),
                      AppDropdownField(
                        label: 'Tipo de documento',
                        value: state.tipoDni,
                        items: const [(value: 'DNI', label: 'DNI'), (value: 'Pasaporte', label: 'Pasaporte')],
                        onChanged: ctrl.setTipoDni,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppDropdownField(
                        label: 'Sexo',
                        value: state.sexo,
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

                  // ── Domicilio ───────────────────────────────────────────────
                  AppCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Text('Domicilio', style: AppTypography.subtitulo),
                      const SizedBox(height: AppSpacing.sm),
                      AppTextField(label: 'Calle', onChanged: ctrl.setCalle),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(label: 'Número', keyboardType: TextInputType.number, onChanged: ctrl.setNroCalle),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(label: 'Provincia', onChanged: ctrl.setProvincia),
                    ]),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ── Cobertura médica ────────────────────────────────────────
                  AppCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Text('Cobertura médica', style: AppTypography.subtitulo),
                      const SizedBox(height: AppSpacing.sm),
                      AppDropdownField(
                        label: 'Tipo de cobertura',
                        value: state.tipoCobertura.isEmpty ? null : state.tipoCobertura,
                        items: const [
                          (value: 'Obra social', label: 'Obra social'),
                          (value: 'Prepaga', label: 'Prepaga'),
                          (value: 'Sin cobertura', label: 'Sin cobertura'),
                        ],
                        onChanged: ctrl.setTipoCobertura,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(label: 'Nombre de la cobertura', onChanged: ctrl.setNombreCobertura),
                      const SizedBox(height: AppSpacing.md),
                      AppDropdownField(
                        label: 'Tiene CUD',
                        value: state.tieneCud.isEmpty ? null : state.tieneCud,
                        items: const [
                          (value: 'Sí', label: 'Sí'),
                          (value: 'No', label: 'No'),
                          (value: 'En trámite', label: 'En trámite'),
                        ],
                        onChanged: ctrl.setTieneCud,
                      ),
                    ]),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ── Antecedentes ────────────────────────────────────────────
                  AppCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Antecedentes personales', style: AppTypography.subtitulo),
                      const SizedBox(height: AppSpacing.sm),
                      AppSwitch(label: 'Asma / espasmos bronquiales', value: state.asmaEspasmos, onChanged: ctrl.setAsmaEspasmos),
                      AppSwitch(label: 'Diabetes', value: state.diabetes, onChanged: ctrl.setDiabetes),
                      const SizedBox(height: AppSpacing.md),
                      Text('Antecedentes familiares', style: AppTypography.subtitulo),
                      const SizedBox(height: AppSpacing.sm),
                      AppSwitch(label: 'Asma en familia', value: state.antFamAsma, onChanged: ctrl.setAntFamAsma),
                      AppSwitch(label: 'Diabetes en familia', value: state.antFamDiabetes, onChanged: ctrl.setAntFamDiabetes),
                    ]),
                  ),

                  if (state.error != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(state.error!,
                        style: AppTypography.texto.copyWith(color: AppColors.error),
                        textAlign: TextAlign.center),
                  ],

                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: 'Guardar',
                    isLoading: state.guardando,
                    onPressed: (state.puedeGuardar && !state.guardando)
                        ? () async {
                            await ctrl.guardar();
                            if (context.mounted &&
                                ref.read(planillaControllerProvider).error == null) {
                              ref.read(syncSchedulerProvider).dispararPorEscritura();
                              context.go('/inicio');
                            }
                          }
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fila de solo-lectura para el adulto responsable (prefilleado, no editable).
class _ReadOnly extends StatelessWidget {
  const _ReadOnly(this.label, this.value);
  final String label, value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 130, child: Text(label, style: AppTypography.texto)),
          Expanded(child: Text(value.isEmpty ? '—' : value,
              style: AppTypography.texto.copyWith(fontWeight: FontWeight.w600))),
        ]),
      );
}
```

- [ ] **Step 4: Correr y verificar que pase**

Run: `flutter test test/features/hijos/planilla_screen_test.dart` → PASS
Run: `flutter analyze lib/features/hijos/presentation/screens/planilla_screen.dart` → No issues

- [ ] **Step 5: Commit**

```bash
git add lib/features/hijos/presentation/screens/planilla_screen.dart test/features/hijos/planilla_screen_test.dart
git commit -m "feat(hijos): planilla en AppCards con consentimiento, dropdowns y date picker"
```

---

## Task 7: Copia del nudge de Pendientes

**Files:**
- Modify: `lib/features/pendientes/presentation/pendientes_screen.dart:62-72`
- Test: `test/features/pendientes/pendientes_screen_test.dart` (actualizar la aserción de copia)

- [ ] **Step 1: Actualizar el test (falla)**

En `test/features/pendientes/pendientes_screen_test.dart`, en los tests que buscan `find.textContaining('Completá el consentimiento')`, cambiar la cadena buscada a `'Completá la evaluación'`. Ej.:

```dart
    expect(find.textContaining('Completá la evaluación'), findsOneWidget);
```

(Hacerlo en los dos tests del nudge: "tutor con 0 hijos ve el nudge..." y "tocar nudge navega...".)

- [ ] **Step 2: Correr y verificar que falle**

Run: `flutter test test/features/pendientes/pendientes_screen_test.dart`
Expected: FAIL (la pantalla aún dice "Completá el consentimiento de tu hijo").

- [ ] **Step 3: Implementar**

En `lib/features/pendientes/presentation/pendientes_screen.dart`, en `_NudgeConsentimiento`, cambiar el título y bajada:

```dart
                      Text(
                        'Completá la evaluación de tu hijo',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tocá para registrar a tu hijo y completar la evaluación integral.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
```

- [ ] **Step 4: Correr y verificar que pase**

Run: `flutter test test/features/pendientes/pendientes_screen_test.dart` → PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/pendientes/presentation/pendientes_screen.dart test/features/pendientes/pendientes_screen_test.dart
git commit -m "feat(pendientes): nudge habla de evaluacion (no solo consentimiento)"
```

---

## Cierre

- [ ] **Suite completa verde**

Run: `flutter test` → all pass (mantener/superar 180/0 + nuevos tests)
Run: `flutter analyze` → No issues
Run (backend): `./venv/bin/python manage.py test apps.usuarios --noinput` → OK

- [ ] **Smoke manual (opcional)**: hot restart → registrar tutor → "Completá la evaluación de tu hijo" en Pendientes → planilla con adulto prefilleado/bloqueado, dropdowns y date picker → "Guardar" atenuado hasta requeridos + consentimiento.

## Notas / fuera de alcance
- Persistencia "firma" fuerte (firma_hash / entidad `Consentimiento`) → pendiente del equipo.
- Regla ≥13, dropdown de provincias, refactor del wizard de registro → fuera de alcance.
- Contrato del payload de `hijos` sin cambios (solo se quita el `setEdad` de UI; `edad` se sigue enviando, ahora derivada).
