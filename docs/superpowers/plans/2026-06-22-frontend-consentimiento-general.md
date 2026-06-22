# Frontend — Consentimiento general + Antecedentes familiares + Pendientes (mazo) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) o superpowers:executing-plans. Steps usan checkbox (`- [ ]`).

**Goal:** Implementar en la app el consentimiento general del tutor (checkbox, sin firma), los antecedentes familiares generales, el gating de "Registrar hijo", la planilla per-hijo sin esos bloques, y los Pendientes como mazo apilado.

**Architecture:** Nuevo módulo `lib/features/familia/` (consentimiento + antecedentes a nivel tutor) con datasource sobre `dioV1Provider`. La sesión transporta 2 flags nuevos (`consentimientoAceptado`, `antecedentesFamiliaresCompletos`) desde `/me`, cacheados en Drift. Tras aceptar/guardar se **re-fetchea `/me`** (`refrescarSesion`) para que el server sea la fuente de verdad. La planilla per-hijo pierde consentimiento y antecedentes familiares. Los pendientes se muestran en un widget de mazo apilado.

**Tech Stack:** Flutter 3.44, Riverpod, Drift, dio, go_router.

**⚠️ Dependencia de backend:** Este plan asume el contrato `docs/contrato-consentimiento-general-backend.md`. Endpoints/keys marcados "(contrato)" deben coincidir con lo que finalice el compañero; si cambian nombres, ajustar en NF1/NF2/NF3. **No ejecutar hasta que el backend esté disponible** (o mockear en tests, que es lo que hacen los pasos de test).

**Estado previo:** T1–T4 ya hechas (componentes `AppDropdownField`/`AppDateField`, `/me` con `tipo_dni`+`dni`, identidad del tutor en sesión+cache, Drift schema 4). Este plan continúa sobre eso.

---

## File Structure

- Modify: `lib/core/session/entities.dart` — `Usuario` +`consentimientoAceptado`, +`antecedentesFamiliaresCompletos` (+`copyWith`).
- Modify: `lib/features/auth/data/dtos/me_response.dart` — parsear los 2 flags.
- Modify: `lib/features/auth/data/repositories/auth_repository_impl.dart` — mapear flags; agregar `refrescarSesion()`.
- Modify: `lib/features/auth/domain/repositories/auth_repository.dart` — declarar `refrescarSesion()`.
- Modify: `lib/core/database/tables/cached_session_table.dart` — +2 columnas bool.
- Modify: `lib/core/database/app_database.dart` — schema 4→5 + migración + guardar/leer.
- Modify: `lib/core/session/session_controller.dart` — `refrescar()` (setea sesión nueva).
- Create: `lib/features/familia/data/familia_remote_datasource.dart` — endpoints consentimiento + antecedentes.
- Create: `lib/features/familia/presentation/consentimiento_screen.dart` + controller.
- Create: `lib/features/familia/presentation/antecedentes_familiares_screen.dart` + controller.
- Modify: `lib/core/providers.dart` — `familiaRemoteDataSourceProvider`.
- Modify: `lib/core/router/app_router.dart` — rutas `/consentimiento`, `/antecedentes-familiares`.
- Modify: `lib/features/acciones/presentation/acciones_screen.dart` — gating de `registrarHijo`.
- Modify: `lib/features/hijos/presentation/controllers/planilla_controller.dart` — sacar consentimiento + antecedentes_familiares; edad derivada; `puedeGuardar`.
- Modify: `lib/features/hijos/presentation/screens/planilla_screen.dart` — AppCards + inputs, sin consentimiento ni antecedentes familiares.
- Create: `lib/core/design_system/stacked_cards_deck.dart` — mazo apilado.
- Modify: `lib/features/pendientes/presentation/pendientes_screen.dart` + `pendientes_count_provider.dart` — items (consent + antecedentes + hijos) y mazo.
- Tests espejo en `test/`.

---

## NF1: Sesión/`/me`/cache transportan los 2 flags + `refrescarSesion`

**Files:** entities.dart, me_response.dart, auth_repository(.dart/_impl), session_controller.dart, cached_session_table.dart, app_database.dart (+ `.g.dart`), tests.

- [ ] **Step 1: Test MeResponse (falla)** — agregar a `test/features/auth/data/me_response_test.dart`:

```dart
  test('MeResponse parsea los flags de consentimiento y antecedentes', () {
    final me = MeResponse.fromJson({
      'user': {'id': 'u1', 'email': 'j@t.com', 'nombre': 'Juan', 'apellido': 'A',
               'consentimiento_aceptado': true, 'antecedentes_familiares_completos': false},
      'roles': [{'name': 'tutor', 'label': 'Tutor'}], 'actions': [],
      'meta': {'version': '1', 'permissions_synced_at': 'x'},
    });
    expect(me.consentimientoAceptado, true);
    expect(me.antecedentesFamiliaresCompletos, false);
  });
```

- [ ] **Step 2: Correr → FALLA.** `flutter test test/features/auth/data/me_response_test.dart`

- [ ] **Step 3: `Usuario` — agregar flags + copyWith.** En `lib/core/session/entities.dart`, reemplazar la clase `Usuario`:

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
    this.consentimientoAceptado = false,
    this.antecedentesFamiliaresCompletos = false,
  });
  final String id, nombre, rolName, rolLabel;
  final String? tutorId;
  final String? nombrePila;
  final String? apellido;
  final String? tipoDni;
  final String? dni;
  final bool consentimientoAceptado;
  final bool antecedentesFamiliaresCompletos;

  Usuario copyWith({bool? consentimientoAceptado, bool? antecedentesFamiliaresCompletos}) =>
      Usuario(
        id: id, nombre: nombre, rolName: rolName, rolLabel: rolLabel,
        tutorId: tutorId, nombrePila: nombrePila, apellido: apellido,
        tipoDni: tipoDni, dni: dni,
        consentimientoAceptado: consentimientoAceptado ?? this.consentimientoAceptado,
        antecedentesFamiliaresCompletos:
            antecedentesFamiliaresCompletos ?? this.antecedentesFamiliaresCompletos,
      );
}
```

- [ ] **Step 4: `MeResponse` — campos + parseo.** En `me_response.dart`: agregar al constructor `this.consentimientoAceptado = false, this.antecedentesFamiliaresCompletos = false,`; agregar `final bool consentimientoAceptado, antecedentesFamiliaresCompletos;`; y en el `return`:

```dart
      consentimientoAceptado: user['consentimiento_aceptado'] as bool? ?? false,
      antecedentesFamiliaresCompletos: user['antecedentes_familiares_completos'] as bool? ?? false,
```

- [ ] **Step 5: Correr test MeResponse → PASA.**

- [ ] **Step 6: Mapear en login/register + agregar `refrescarSesion`.** En `auth_repository_impl.dart`:
  - Extraer un helper privado que construye la Sesión desde `me` y la cachea (DRY con login/register), e incluir los 2 flags en `Usuario(...)`:
```dart
  Future<Sesion> _sesionDesdeMe() async {
    final me = await remote.me();
    final sesion = Sesion(
      usuario: Usuario(
        id: me.id, nombre: me.nombre, rolName: me.rolName, rolLabel: me.rolLabel,
        tutorId: me.tutorId, nombrePila: me.nombrePila, apellido: me.apellido,
        tipoDni: me.tipoDni, dni: me.dni,
        consentimientoAceptado: me.consentimientoAceptado,
        antecedentesFamiliaresCompletos: me.antecedentesFamiliaresCompletos,
      ),
      acciones: me.acciones,
    );
    await cache.guardarSesion(sesion, email: me.email, version: me.metaVersion, syncedAtIso: me.metaSyncedAt);
    return sesion;
  }
```
  - En `login()` y `register()`, reemplazar el bloque que hacía `me()` + construir Sesion + guardarSesion por `final sesion = await _sesionDesdeMe();` (mantener el try/catch que limpia tokens si falla).
  - Agregar el método público:
```dart
  @override
  Future<Sesion> refrescarSesion() => _sesionDesdeMe();
```
  - En `auth_repository.dart` (interface) agregar `Future<Sesion> refrescarSesion();`.

- [ ] **Step 7: `SessionController.refrescar`.** En `session_controller.dart` agregar:
```dart
  void refrescar(Sesion s) => state = SesionAutenticada(s);
```
(equivale a setSesion; nombre explícito para el flujo de post-consentimiento.)

- [ ] **Step 8: Cache — 2 columnas bool.** En `cached_session_table.dart`, antes de `permissionsSyncedAt`:
```dart
  BoolColumn get consentimientoAceptado => boolean().withDefault(const Constant(false))();
  BoolColumn get antecedentesFamiliaresCompletos => boolean().withDefault(const Constant(false))();
```
(Asegurar `import 'package:drift/drift.dart';` ya presente.)

- [ ] **Step 9: app_database — schema 5 + migración + guardar/leer.**
  - `schemaVersion => 5;`
  - En `onUpgrade` agregar:
```dart
      if (from >= 2 && from < 5) {
        await m.addColumn(cachedSessionRows, cachedSessionRows.consentimientoAceptado);
        await m.addColumn(cachedSessionRows, cachedSessionRows.antecedentesFamiliaresCompletos);
      }
```
  (Mismo criterio del guard de la v4: si `from < 2` la tabla se crea entera vía `createTable`.)
  - En `guardarSesion` companion: `consentimientoAceptado: Value(s.usuario.consentimientoAceptado), antecedentesFamiliaresCompletos: Value(s.usuario.antecedentesFamiliaresCompletos),`
  - En `leerSesion`, en el `Usuario(...)`: `consentimientoAceptado: row.consentimientoAceptado, antecedentesFamiliaresCompletos: row.antecedentesFamiliaresCompletos,`

- [ ] **Step 10: Codegen.** `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 11: Migración test + cache round-trip.** Seguir el patrón de la v4 en `test/core/database/migration_test.dart` + `generated_migrations/schema_v5.dart` (generar con `dart run drift_dev schema dump` o copiar el patrón de schema_v4): agregar test `migración v4→v5` que valida y que los flags sobreviven. Agregar al `cached_session_test.dart` aserción de que los 2 flags hacen round-trip (extender el test de identidad existente o uno nuevo). Si generar schema_v5 es complejo, como mínimo: test de `cached_session` que guarda con flags true y los lee true.

- [ ] **Step 12: Correr suite + analyze.** `flutter test test/core/database/ test/features/auth/` y `flutter analyze lib/core lib/features/auth` → verde.

- [ ] **Step 13: Commit.** `git add ... && git commit -m "feat(session): flags de consentimiento/antecedentes en /me + cache (Drift 4->5) + refrescarSesion"`

---

## NF2: Datasource + pantalla de Consentimiento general

**Files:** familia_remote_datasource.dart, consentimiento_screen.dart (+controller), providers.dart, app_router.dart, tests.

- [ ] **Step 1: Datasource (con test de que pega al endpoint correcto).** Crear `lib/features/familia/data/familia_remote_datasource.dart`:

```dart
import 'package:dio/dio.dart';

/// Llama a los endpoints de familia (consentimiento + antecedentes), base /api/v1.
class FamiliaRemoteDataSource {
  FamiliaRemoteDataSource(this._dio);
  final Dio _dio;

  // (contrato) POST /tutores/<id>/consentimiento/  -> acepta el consentimiento (checkbox)
  Future<void> aceptarConsentimiento(String tutorId) =>
      _dio.post('/tutores/$tutorId/consentimiento/', data: const {});

  // (contrato) GET /tutores/<id>/antecedentes-familiares/
  Future<Map<String, dynamic>?> getAntecedentes(String tutorId) async {
    try {
      final r = await _dio.get('/tutores/$tutorId/antecedentes-familiares/');
      return (r.data as Map).cast<String, dynamic>();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null; // todavía no cargó
      rethrow;
    }
  }

  // (contrato) POST /tutores/<id>/antecedentes-familiares/  (upsert)
  Future<void> guardarAntecedentes(String tutorId, Map<String, dynamic> body) =>
      _dio.post('/tutores/$tutorId/antecedentes-familiares/', data: body);
}
```
Test con `http_mock_adapter` (mismo patrón que tests de datasource existentes en `test/features/auth/` o `test/features/hijos/hijos_syncer_test.dart`): verificar que `aceptarConsentimiento('t1')` hace POST a `/tutores/t1/consentimiento/`.

- [ ] **Step 2: Provider.** En `lib/core/providers.dart`:
```dart
final familiaRemoteDataSourceProvider =
    Provider<FamiliaRemoteDataSource>((ref) => FamiliaRemoteDataSource(ref.watch(dioV1Provider)));
```
(import del datasource).

- [ ] **Step 3: Controller del consentimiento.** Crear en `consentimiento_screen.dart` (o archivo aparte) un `StateNotifier`/provider `autoDispose` con estado `{aceptado: bool, enviando: bool, error: String?}` y un método `aceptar()` que: si `tutorId` existe → `aceptarConsentimiento(tutorId)` → `refrescarSesion()` → `sessionController.refrescar(sesion)`. Maneja error (sin conexión → mensaje).

- [ ] **Step 4: Pantalla `ConsentimientoScreen`.** `AppGradientScaffold` + `AppCard`: texto introductorio, `AppSwitch` "Acepto los términos del consentimiento", `AppLink` "Ver términos de consentimiento" → modal (`showDialog`/`AlertDialog`) con el texto del PDF resaltado (reusar el `Text.rich` con negritas: "examen clínico y odontológico", "vacunas", "máxima confidencialidad"). `AppButton` "Confirmar" atenuado hasta `aceptado == true`. Al confirmar OK → `notificacionProvider.exito('¡Consentimiento registrado!')` y `context.go('/inicio')` (o pop). Mostrar error con `notificacionProvider.error(...)` si falla.

- [ ] **Step 5: Ruta.** En `app_router.dart`, agregar `GoRoute(path: '/consentimiento', builder: (c, s) => const ConsentimientoScreen())` (fuera del shell, como `/hijos/nuevo`).

- [ ] **Step 6: Test de pantalla.** Widget test con overrides (`sessionControllerProvider` tutor, `familiaRemoteDataSourceProvider` fake): el modal abre con "Ver términos"; "Confirmar" deshabilitado sin aceptar; al aceptar + confirmar se llama `aceptarConsentimiento`.

- [ ] **Step 7: analyze + commit.** `git commit -m "feat(familia): pantalla de consentimiento general (checkbox + términos)"`

---

## NF3: Pantalla de Antecedentes familiares

**Files:** antecedentes_familiares_screen.dart (+controller), app_router.dart, tests.

- [ ] **Step 1: Controller.** Estado con los 3 campos (`problemaSalud: 'si'|'no'|'no_sabe'|''`, `problemaCual: String`, `muerteSubita: ...`), `cargando/enviando/error`. `cargar()` → `getAntecedentes(tutorId)` (precarga si existe). `guardar()` → `guardarAntecedentes(tutorId, {problema_salud_importante, problema_salud_cual, muerte_subita_familiar})` → `refrescarSesion()` → `refrescar`.

- [ ] **Step 2: Pantalla `AntecedentesFamiliaresScreen`.** `AppGradientScaffold` + `AppCard`. Usar `AppDropdownField` para los 2 de Sí/No/No sabe (`items: [(value:'si',label:'Sí'),(value:'no',label:'No'),(value:'no_sabe',label:'No sabe')]`) y `AppTextField` para "¿Cuál/es?". `AppButton` "Guardar". Textos del PDF: "¿Tienen o han tenido algún problema de salud importante?" y "¿Algún familiar directo menor de 50 años sufrió muerte súbita o repentina?". Al guardar OK → notificación de éxito + volver.

- [ ] **Step 3: Ruta.** `GoRoute(path: '/antecedentes-familiares', builder: (c, s) => const AntecedentesFamiliaresScreen())`.

- [ ] **Step 4: Test de pantalla.** Render de los 3 campos; guardar llama `guardarAntecedentes` con el body correcto.

- [ ] **Step 5: analyze + commit.** `git commit -m "feat(familia): pantalla de antecedentes familiares del tutor"`

---

## NF4: Gating de "Registrar hijo" (consentimiento obligatorio)

**Files:** acciones_screen.dart, test.

- [ ] **Step 1: Test (falla).** En `test/features/acciones/acciones_screen_test.dart`, agregar: tutor con `consentimientoAceptado=false` que toca "Registrar hijo" → NO navega a `/hijos/nuevo`, sino que dispara una alerta/notificación y/o navega a `/consentimiento`. (Construir sesión con el flag en false y una acción `registrarHijo`.)

- [ ] **Step 2: Implementar el gating.** En `acciones_screen.dart`, cambiar el `case 'registrarHijo'`:
```dart
                              case 'registrarHijo':
                                final u = estado is SesionAutenticada ? estado.sesion.usuario : null;
                                if (u != null && !u.consentimientoAceptado) {
                                  ref.read(notificacionProvider.notifier).info(
                                      'Primero aceptá el consentimiento para registrar a tu hijo/a.');
                                  context.go('/consentimiento');
                                } else {
                                  context.go('/hijos/nuevo');
                                }
```
(import del `notificacionProvider`; `estado` ya está disponible en `build`.)

- [ ] **Step 3: Test pasa; analyze; commit.** `git commit -m "feat(acciones): gating de registrar hijo sin consentimiento + alerta"`

---

## NF5: Planilla per-hijo sin consentimiento ni antecedentes familiares (alineada al design system)

**Files:** planilla_controller.dart, planilla_screen.dart, tests.

> Nota: esto reemplaza el T5/T6 obsoletos. La planilla queda: Datos del niño/a, Domicilio, Cobertura, **Antecedentes DEL NIÑO**. SIN consentimiento, SIN antecedentes familiares.

- [ ] **Step 1: Test del controller (falla).** Reescribir `test/features/hijos/planilla_controller_test.dart`:
```dart
import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/database/app_database.dart';
import 'package:prosane_app/features/hijos/presentation/controllers/planilla_controller.dart';

void main() {
  test('guardar: edad derivada y payload SIN consentimiento ni antecedentes_familiares', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final ctrl = PlanillaController(db: db, tutorId: 'tut-1', generarId: () => 'h1');
    ctrl.setNombre('Juana'); ctrl.setApellido('Pérez'); ctrl.setDni('70000000');
    ctrl.setSexo('F'); ctrl.setFechaNacimiento(DateTime(2015, 6, 1));
    await ctrl.guardar();
    final body = jsonDecode((await db.hijosPendientes()).single.payloadJson) as Map<String, dynamic>;
    expect(body['edad'], greaterThanOrEqualTo(9));
    expect(body.containsKey('consentimiento'), isFalse);
    expect(body.containsKey('antecedentes_familiares'), isFalse);
    expect((body['antecedentes_personales'] as Map)['asma_espasmos'], isA<bool>());
    await db.close();
  });

  test('puedeGuardar exige nombre/apellido/dni/fecha/sexo', () {
    const base = PlanillaState();
    expect(base.puedeGuardar, isFalse);
    final ok = base.copyWith(nombre: 'J', apellido: 'P', dni: '1', sexo: 'F',
        fechaNacimiento: DateTime(2015, 6, 1));
    expect(ok.puedeGuardar, isTrue);
  });
}
```

- [ ] **Step 2: Correr → FALLA.**

- [ ] **Step 3: Controller.** En `planilla_controller.dart`:
  - Quitar del estado/`copyWith`/setters TODO lo de consentimiento y adulto (`adultoNombre/adultoApellido/adultoTipoDocumento/adultoDni/consentimientoAceptado` + sus setters) y los antecedentes familiares (`antFamAsma/antFamDiabetes` + setters).
  - Quitar `setEdad`; agregar helper `_edadEnAnios(DateTime?)` (años cumplidos) y usarlo en el payload (`'edad': _edadEnAnios(s.fechaNacimiento)`).
  - Quitar del payload los bloques `consentimiento` y `antecedentes_familiares`.
  - Agregar getter en `PlanillaState`:
```dart
  bool get puedeGuardar =>
      nombre.trim().isNotEmpty && apellido.trim().isNotEmpty &&
      dni.trim().isNotEmpty && sexo.isNotEmpty && fechaNacimiento != null;
```
  - El provider queda sin sembrar adulto: `PlanillaController(db: ..., tutorId: u?.tutorId)`.

- [ ] **Step 4: Pantalla.** Reescribir `planilla_screen.dart` en `AppCard`s con los inputs correctos (igual que el diseño original PERO sin la sección de consentimiento y sin antecedentes familiares):
  - Datos del niño/a: Nombre, Apellido, DNI (`AppTextField`); Tipo doc (`AppDropdownField` DNI/Pasaporte); Sexo (`AppDropdownField` F/M/X); Fecha nac. (`AppDateField`); Parentesco (`AppDropdownField`).
  - Domicilio: Calle, Número, Provincia (`AppTextField`).
  - Cobertura: Tipo cobertura (`AppDropdownField`), Nombre cobertura (`AppTextField`), Tiene CUD (`AppDropdownField` Sí/No/En trámite).
  - **Antecedentes del niño**: `AppSwitch` Asma/espasmos, Diabetes.
  - `AppButton` "Guardar" con `onPressed: (state.puedeGuardar && !state.guardando) ? ... : null` (atenuado). Al guardar OK → `syncScheduler.dispararPorEscritura()` + `context.go('/inicio')`.
  (El código completo de la pantalla sigue el patrón del spec original, quitando la sección 0 de consentimiento y la de antecedentes familiares.)

- [ ] **Step 5: Test de pantalla (opcional pero recomendado).** Que el "Guardar" esté atenuado sin requeridos.

- [ ] **Step 6: Correr controller + screen tests + analyze.** Verde.

- [ ] **Step 7: Commit.** `git commit -m "feat(hijos): planilla per-hijo (sin consentimiento ni antecedentes familiares) alineada al design system"`

---

## NF6: Pendientes como mazo apilado

**Files:** stacked_cards_deck.dart (nuevo), pendientes_screen.dart, pendientes_count_provider.dart, tests.

> Items de pendientes: (1) Consentimiento — si `!consentimientoAceptado`; (2) Antecedentes familiares — si `!antecedentesFamiliaresCompletos`; (3) una card por hijo registrado localmente (su formulario familiar). Mazo apilado: se ven hasta 3; con más, se acumulan al fondo.

- [ ] **Step 1: Modelo de item + provider de la lista.** En `pendientes_count_provider.dart` (o un nuevo `pendientes_items_provider.dart`), exponer una lista de items pendientes:
```dart
class ItemPendiente {
  const ItemPendiente({required this.titulo, required this.subtitulo, required this.ruta, required this.icono});
  final String titulo, subtitulo, ruta;
  final IconData icono;
}
```
Un provider (reactivo a sesión + Drift `watchHijosVivos`) que arma la lista:
  - si `esTutor && !consentimientoAceptado` → item Consentimiento (ruta `/consentimiento`).
  - si `esTutor && !antecedentesFamiliaresCompletos` → item Antecedentes (ruta `/antecedentes-familiares`).
  - por cada hijo vivo → item "Evaluación de <nombre>" (ruta `/hijos/...` — definir; por ahora `/hijos`).
El `pendientesCountProvider` (badge) pasa a derivar de `length` de esta lista (mantener API `.value ?? 0` en el router).
**Pure function** `List<ItemPendiente> armarPendientes({...})` testeable.

- [ ] **Step 2: Test de la pure function.** tutor sin consentimiento ni antecedentes y 0 hijos → 2 items; con ambos completos y 1 hijo → 1 item; no-tutor → 0.

- [ ] **Step 3: Widget `StackedCardsDeck`.** Crear `lib/core/design_system/stacked_cards_deck.dart`: recibe `List<Widget> cards`. Muestra las primeras 3 con offset/escala decreciente (efecto mazo: cada una detrás un poco más arriba/chica y con sombra), y si hay más de 3, las extra se "acumulan al fondo" (se dibujan apenas asomando detrás de la 3ª, sin ser tappables individualmente). La card de adelante es interactiva. Implementar con `Stack` + `Positioned`/`Transform`. Test: con 5 cards, renderiza el front y a lo sumo 3 capas visibles + indicador "+2".

- [ ] **Step 4: PendientesScreen.** Reemplazar el contenido: si la lista está vacía → `EmptyState('Todo sincronizado')`; si no → `StackedCardsDeck` con una card por item (cada card = `AppCard` con ícono+título+subtítulo+chevron, tappable → `context.go(item.ruta)`). Quitar el nudge viejo de consentimiento.

- [ ] **Step 5: Tests.** PendientesScreen: tutor con 2 pendientes muestra el mazo con la card de Consentimiento al frente; tocarla navega a `/consentimiento`.

- [ ] **Step 6: analyze + commit.** `git commit -m "feat(pendientes): mazo de cards apiladas (consentimiento + antecedentes + hijos)"`

---

## Cierre
- [ ] `flutter test` → verde (mantener todo lo previo + nuevos).
- [ ] `flutter analyze` → No issues.
- [ ] Smoke manual cuando el backend esté: registrar tutor → Pendientes muestra mazo con Consentimiento + Antecedentes → aceptar consentimiento habilita "Registrar hijo" → completar planilla per-hijo.

## Notas / dependencias
- **Bloqueado por backend** (contrato `docs/contrato-consentimiento-general-backend.md`): endpoints `/tutores/<id>/consentimiento/` y `/antecedentes-familiares/`, y los 2 flags en `/me`. Los tests usan fakes/mocks, así que NF1/NF5/NF6 (datos+UI) pueden avanzar antes; NF2/NF3 dependen de los endpoints reales para el smoke.
- **Per-hijo "segunda parte"**: la semántica exacta del pendiente por hijo (¿alta mínima + completar formulario después, o el alta YA es el formulario?) quedó por confirmar con el usuario; NF6 asume "una card por hijo vivo → su evaluación". Ajustar cuando se defina.
- **Offline-first** del consentimiento/antecedentes: por ahora son POST online (requieren conexión una vez). Encolarlos offline = mejora futura.
- **Firma**: fuera de alcance (fase futura).
