# Primera parte — Frontend (prosane_app) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Que el tutor se registre contra `dev-base` y entre logueado, y pueda cargar un hijo con la planilla familiar + consentimiento offline-first desde el menú de acciones, con sync por la cola.

**Architecture:** Clean architecture + Riverpod + go_router (redirect por sesión) + Drift (offline-first con `SyncColumns` + `FeatureSyncer`). Reutilizamos el wizard de signup existente (adaptándolo al contrato de `dev-base`) y agregamos el feature `hijos` (planilla familiar) con su tabla Drift y su syncer.

**Tech Stack:** Flutter, flutter_riverpod, go_router, dio, drift, mocktail/http_mock_adapter (tests).

**Spec:** `docs/superpowers/specs/2026-06-20-primera-parte-registro-familiar-design.md`
**Depende de:** Plan Backend (B0–B5) ya mergeado/levantado en `dev-base`.

**Prerrequisito:** backend corriendo en rama `dev-base`. Comando de tests: `flutter test <ruta>`. Codegen: `dart run build_runner build --delete-conflicting-outputs`.

---

### Task 0: Rama de trabajo

- [ ] **Step 1: Crear rama de feature**

```bash
cd prosane_app
git checkout -b feat/primera-parte-registro-familiar
```

---

### Task 1: F1 — Apuntar a `dev-base` + smoke

El contrato de paths (`/token/`, `/token/refresh/`, `/me/`) ya quedó alineado por B0, así que el datasource actual funciona. Solo hay que apuntar la base URL al backend en `dev-base`.

**Files:**
- Modify: `lib/core/config/app_config.dart`

- [ ] **Step 1: Apuntar la base URL**

En `lib/core/config/app_config.dart`, dejar el default apuntando al backend `dev-base` (o pasarlo por `--dart-define=API_BASE_URL=...`). Verificar que el sufijo siga siendo `/api/v1/auth`.

- [ ] **Step 2: Smoke manual**

Levantar el backend en `dev-base` y correr:
```bash
flutter run --dart-define=API_BASE_URL=http://<HOST-dev-base>:8000/api/v1/auth
```
Expected: login de un usuario seed (`seed_permissions` + un tutor) entra y `/me` trae sus acciones.

- [ ] **Step 3: Commit**

```bash
git add lib/core/config/app_config.dart
git commit -m "chore(config): base URL apuntando a dev-base"
```

---

### Task 2: F2a — Datasource `registerTutor` (devuelve tokens)

`dev-base` registra en `POST /register/tutor/` y **devuelve `{user, access, refresh}`**. El datasource actual usa `POST /register/` y devuelve void.

**Files:**
- Modify: `lib/features/auth/data/datasources/auth_remote_datasource.dart`
- Test: `test/features/auth/data/auth_remote_datasource_test.dart` (crear)

- [ ] **Step 1: Escribir el test que falla**

Crear `test/features/auth/data/auth_remote_datasource_test.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:prosane_app/features/auth/data/datasources/auth_remote_datasource.dart';

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late AuthRemoteDataSourceImpl ds;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://x/api/v1/auth'));
    adapter = DioAdapter(dio: dio);
    ds = AuthRemoteDataSourceImpl(dio);
  });

  test('registerTutor postea a /register/tutor/ y devuelve tokens', () async {
    adapter.onPost(
      '/register/tutor/',
      (s) => s.reply(201, {
        'user': {'id': 'u1', 'email': 'a@a.com', 'nombre': 'Ana', 'apellido': 'G'},
        'access': 'ACCESS',
        'refresh': 'REFRESH',
      }),
      data: Matchers.any,
    );

    final t = await ds.registerTutor({'email': 'a@a.com'});
    expect(t.access, 'ACCESS');
    expect(t.refresh, 'REFRESH');
  });
}
```

- [ ] **Step 2: Correr y verificar que falla**

Run: `flutter test test/features/auth/data/auth_remote_datasource_test.dart`
Expected: FAIL (`registerTutor` no existe).

- [ ] **Step 3: Agregar `registerTutor` al datasource**

En `lib/features/auth/data/datasources/auth_remote_datasource.dart`, agregar al `abstract class`:

```dart
  Future<Tokens> registerTutor(Map<String, dynamic> datos);
```

Y en `AuthRemoteDataSourceImpl`:

```dart
  @override
  Future<Tokens> registerTutor(Map<String, dynamic> datos) async {
    final r = await _dio.post('/register/tutor/', data: datos);
    return (access: r.data['access'] as String, refresh: r.data['refresh'] as String);
  }
```

(El `register` viejo puede quedar o eliminarse; ya no se usa tras la Task 4.)

- [ ] **Step 4: Correr y verificar que pasa**

Run: `flutter test test/features/auth/data/auth_remote_datasource_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/data/datasources/auth_remote_datasource.dart test/features/auth/data/auth_remote_datasource_test.dart
git commit -m "feat(auth): datasource registerTutor (/register/tutor/, devuelve tokens)"
```

---

### Task 3: F2b — Repository: registro que loguea (devuelve `Sesion`)

`dev-base` devuelve tokens al registrar → guardamos tokens, traemos `/me`, cacheamos y devolvemos `Sesion` (igual que `login`).

**Files:**
- Modify: `lib/features/auth/domain/repositories/auth_repository.dart`
- Modify: `lib/features/auth/data/repositories/auth_repository_impl.dart`
- Modify: `lib/features/auth/domain/usecases/register.dart`
- Test: `test/features/auth/data/auth_repository_impl_test.dart` (agregar caso)

- [ ] **Step 1: Escribir el test que falla**

Agregar a `test/features/auth/data/auth_repository_impl_test.dart` un test que registre y devuelva `Sesion` (seguir el patrón de mocks del test de `login` ya existente en ese archivo: mockear `remote.registerTutor` → tokens, `remote.me()` → MeResponse, y verificar `tokens.guardar` + `cache.guardarSesion`). Estructura:

```dart
test('register: guarda tokens, trae /me y devuelve Sesion', () async {
  when(() => remote.registerTutor(any())).thenAnswer((_) async => (access: 'A', refresh: 'R'));
  when(() => tokens.guardar(access: any(named: 'access'), refresh: any(named: 'refresh')))
      .thenAnswer((_) async {});
  when(() => remote.me()).thenAnswer((_) async => meResponseFake); // reusar el fake del test de login
  when(() => cache.guardarSesion(any(),
      email: any(named: 'email'), version: any(named: 'version'), syncedAtIso: any(named: 'syncedAtIso')))
      .thenAnswer((_) async {});

  final sesion = await repo.register({'email': 'a@a.com'});

  expect(sesion.usuario.rolName, meResponseFake.rolName);
  verify(() => tokens.guardar(access: 'A', refresh: 'R')).called(1);
});
```

- [ ] **Step 2: Correr y verificar que falla**

Run: `flutter test test/features/auth/data/auth_repository_impl_test.dart`
Expected: FAIL (`register` devuelve void).

- [ ] **Step 3: Cambiar el contrato del repositorio**

En `lib/features/auth/domain/repositories/auth_repository.dart`, cambiar la firma:

```dart
  Future<Sesion> register(Map<String, dynamic> datos);
```

- [ ] **Step 4: Implementar register que loguea**

En `lib/features/auth/data/repositories/auth_repository_impl.dart`, reemplazar `register`:

```dart
  @override
  Future<Sesion> register(Map<String, dynamic> datos) async {
    try {
      final t = await remote.registerTutor(datos);
      await tokens.guardar(access: t.access, refresh: t.refresh);
      try {
        final me = await remote.me();
        final sesion = Sesion(
          usuario: Usuario(id: me.id, nombre: me.nombre, rolName: me.rolName, rolLabel: me.rolLabel),
          acciones: me.acciones,
        );
        await cache.guardarSesion(sesion, email: me.email, version: me.metaVersion, syncedAtIso: me.metaSyncedAt);
        return sesion;
      } catch (_) {
        await tokens.limpiar();
        rethrow;
      }
    } on Failure {
      rethrow;
    } catch (e) {
      throw mapDioError(e);
    }
  }
```

- [ ] **Step 5: Actualizar el usecase**

En `lib/features/auth/domain/usecases/register.dart`:

```dart
import '../../../../core/session/entities.dart';
import '../repositories/auth_repository.dart';

class Register {
  Register(this._repo);
  final AuthRepository _repo;
  Future<Sesion> call(Map<String, dynamic> datos) => _repo.register(datos);
}
```

- [ ] **Step 6: Correr y verificar que pasa**

Run: `flutter test test/features/auth/data/auth_repository_impl_test.dart`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/features/auth/domain/repositories/auth_repository.dart lib/features/auth/data/repositories/auth_repository_impl.dart lib/features/auth/domain/usecases/register.dart test/features/auth/data/auth_repository_impl_test.dart
git commit -m "feat(auth): registro loguea (guarda tokens + /me + cache, devuelve Sesion)"
```

---

### Task 4: F2c — Signup controller: payload anidado + setea sesión

**Files:**
- Modify: `lib/features/auth/presentation/controllers/signup_controller.dart`
- Modify: `lib/features/auth/presentation/screens/signup_wizard_screen.dart`
- Test: `test/features/auth/presentation/signup_controller_test.dart` (agregar caso)

- [ ] **Step 1: Escribir el test que falla**

Agregar a `test/features/auth/presentation/signup_controller_test.dart` un test que, con un `Register` fake que captura el payload, verifique que `enviar()` manda el shape anidado de `dev-base`:

```dart
test('enviar arma payload anidado para dev-base', () async {
  Map<String, dynamic>? capturado;
  final ctrl = SignupController(
    register: _RegisterFake((p) => capturado = p),
    onAutenticado: (_) {},
  );
  // completar el form mínimo válido (tipoDoc, dni, nombre, apellido, sexo, fecha, email, password)
  // ... setters ...
  await ctrl.enviar();

  expect(capturado!['email'], isNotNull);
  expect(capturado!['persona'], isA<Map>());
  expect((capturado!['persona'] as Map)['dni'], isNotNull);
  expect((capturado!['persona'] as Map)['tipo_dni'], isNotNull);
  expect(capturado!.containsKey('lugar_nacimiento'), isFalse); // no se envía
});
```

(El fake `_RegisterFake` extiende `Register` y captura el payload; `Register.call` ahora devuelve `Future<Sesion>`, así que el fake devuelve una `Sesion` dummy.)

- [ ] **Step 2: Correr y verificar que falla**

Run: `flutter test test/features/auth/presentation/signup_controller_test.dart`
Expected: FAIL (payload plano / `onAutenticado` no existe).

- [ ] **Step 3: Adaptar el controller**

En `lib/features/auth/presentation/controllers/signup_controller.dart`:

1. Agregar el callback al constructor:
```dart
  SignupController({required Register register, required this.onAutenticado})
      : _register = register,
        super(const SignupState());

  final Register _register;
  final void Function(Sesion) onAutenticado;
```
(importar `entities.dart` para `Sesion`.)

2. Reemplazar el cuerpo de `enviar()` (parte del payload + envío):
```dart
    final f = state.formData;
    final payload = <String, dynamic>{
      'email': f.email,
      'password': f.password,
      'persona': {
        'nombre': f.nombre,
        'apellido': f.apellido,
        'dni': f.numeroDocumento,
        'tipo_dni': f.tipoDocumento,
        'sexo': f.sexo,
        'fecha_nacimiento': f.fechaNacimiento?.toIso8601String(),
      },
    };
    try {
      final sesion = await _register(payload);
      onAutenticado(sesion);
      state = state.copyWith(isSubmitting: false, registrado: true);
    } on Failure catch (f) {
      state = state.copyWith(isSubmitting: false, error: f.mensaje);
    } catch (_) {
      state = state.copyWith(isSubmitting: false, error: 'Hubo un problema, probá de nuevo');
    }
```

3. Actualizar el provider para inyectar el callback de sesión:
```dart
final signupControllerProvider = StateNotifierProvider.autoDispose<
    SignupController, SignupState>(
  (ref) => SignupController(
    register: ref.watch(registerUseCaseProvider),
    onAutenticado: (s) => ref.read(sessionControllerProvider.notifier).setSesion(s),
  ),
);
```
(importar `session_controller.dart`.)

> Nota: `lugarNacimiento` y `paisResidencia` siguen en el form (no se rompe la UI ni sus tests) pero **no se envían**. Hacerlos opcionales en `etapaValida` es polish posterior.

- [ ] **Step 4: Ajustar la navegación post-registro**

En `lib/features/auth/presentation/screens/signup_wizard_screen.dart`, dentro del `ref.listen` de `registrado`, **quitar** `context.go('/login')` (ahora la sesión queda autenticada y el redirect del router lleva `/signup → /inicio` solo). Dejar el SnackBar de éxito si se quiere.

- [ ] **Step 5: Correr y verificar que pasa**

Run: `flutter test test/features/auth/presentation/`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/auth/presentation/ test/features/auth/presentation/signup_controller_test.dart
git commit -m "feat(auth): signup arma payload anidado y deja la sesion logueada"
```

---

### Task 5: F3 — Cablear menú de acciones a rutas reales

`registrarHijo` → wizard de planilla; `verHijos` → listado. El resto mantiene el placeholder.

**Files:**
- Create: `lib/features/hijos/presentation/screens/planilla_screen.dart` (stub navegable)
- Create: `lib/features/hijos/presentation/screens/hijos_list_screen.dart` (stub navegable)
- Modify: `lib/core/router/app_router.dart` (rutas `/hijos` y `/hijos/nuevo`)
- Modify: `lib/features/acciones/presentation/acciones_screen.dart` (onTap por `name`)
- Test: `test/features/acciones/acciones_screen_test.dart` (agregar caso de navegación)

- [ ] **Step 1: Crear pantallas stub**

`lib/features/hijos/presentation/screens/planilla_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/app_gradient_scaffold.dart';

class PlanillaScreen extends ConsumerWidget {
  const PlanillaScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      const AppGradientScaffold(child: Center(child: Text('Planilla familiar')));
}
```
`lib/features/hijos/presentation/screens/hijos_list_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/app_gradient_scaffold.dart';

class HijosListScreen extends ConsumerWidget {
  const HijosListScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      const AppGradientScaffold(child: Center(child: Text('Mis hijos')));
}
```

- [ ] **Step 2: Registrar rutas**

En `lib/core/router/app_router.dart`, importar las dos pantallas y agregar dos `GoRoute` top-level (fuera del shell, como `/login`):
```dart
      GoRoute(path: '/hijos', builder: (c, s) => const HijosListScreen()),
      GoRoute(path: '/hijos/nuevo', builder: (c, s) => const PlanillaScreen()),
```
Ajustar `construirRedirect`: estas rutas requieren auth (ya lo cubre el guard: no están en `enAuth`, así que un no-autenticado va a `/login`). ✅

- [ ] **Step 3: Cablear el onTap por `name`**

En `lib/features/acciones/presentation/acciones_screen.dart`, reemplazar `onTap: () => _placeholder(context, a.label)` por:
```dart
                          onTap: () {
                            switch (a.name) {
                              case 'registrarHijo':
                                context.go('/hijos/nuevo');
                              case 'verHijos':
                                context.go('/hijos');
                              default:
                                _placeholder(context, a.label);
                            }
                          },
```
(importar `package:go_router/go_router.dart`.)

- [ ] **Step 4: Test de navegación**

Agregar a `test/features/acciones/acciones_screen_test.dart` un test que monte el router con una sesión que tenga la acción `registrarHijo`, tap en el tile, y verifique que la ubicación es `/hijos/nuevo` (seguir el patrón de montaje de `app_router_test.dart`).

- [ ] **Step 5: Correr y verificar que pasa**

Run: `flutter test test/features/acciones/`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/hijos/ lib/core/router/app_router.dart lib/features/acciones/ test/features/acciones/
git commit -m "feat(hijos): cablea registrarHijo/verHijos del menu a sus rutas"
```

---

### Task 6: F4 — Tabla Drift `HijosRows` + migración

Offline-first: una fila por hijo, con `SyncColumns` (id UUID cliente, updatedAt, syncStatus, deletedAt) + `tutorId`, datos de display y `payloadJson` (el body exacto del POST agregado).

**Files:**
- Create: `lib/core/database/tables/hijos_table.dart`
- Modify: `lib/core/database/app_database.dart` (registrar tabla, `schemaVersion` 3, migración)
- Test: `test/core/database/migration_test.dart` (agregar paso v2→v3)

- [ ] **Step 1: Definir la tabla**

`lib/core/database/tables/hijos_table.dart`:
```dart
import 'package:drift/drift.dart';
import '../sync_columns.dart';

/// Un hijo (Paciente) cargado por el tutor. Offline-first: se crea local
/// (pendiente) y el HijosSyncer lo empuja al endpoint agregado.
class HijosRows extends Table with SyncColumns {
  TextColumn get tutorId => text()();
  TextColumn get nombreNna => text().withDefault(const Constant(''))();
  TextColumn get apellidoNna => text().withDefault(const Constant(''))();
  TextColumn get payloadJson => text()(); // body exacto del POST /tutores/<id>/hijos/
}
```

- [ ] **Step 2: Registrar la tabla + migración (test primero)**

Agregar a `test/core/database/migration_test.dart` un caso que verifique que al abrir con `schemaVersion` 3 existe la tabla `hijos_rows` (seguir el patrón existente del archivo para v1→v2).

- [ ] **Step 3: Correr y verificar que falla**

Run: `flutter test test/core/database/migration_test.dart`
Expected: FAIL (tabla no existe).

- [ ] **Step 4: Registrar en `AppDatabase`**

En `lib/core/database/app_database.dart`:
- importar `tables/hijos_table.dart`
- agregar `HijosRows` a `@DriftDatabase(tables: [...])`
- subir `schemaVersion` a `3`
- en `onUpgrade`, agregar:
```dart
          if (from < 3) {
            await m.createTable(hijosRows);
          }
```

- [ ] **Step 5: Codegen + correr**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/core/database/migration_test.dart
```
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/core/database/ test/core/database/migration_test.dart
git commit -m "feat(db): tabla hijos_rows (offline-first) + migracion v2->v3"
```

---

### Task 7: F4 — Queries de hijos en `AppDatabase`

**Files:**
- Modify: `lib/core/database/app_database.dart`
- Test: `test/core/database/app_database_test.dart` (agregar casos)

- [ ] **Step 1: Test que falla**

Agregar a `test/core/database/app_database_test.dart` (usa `AppDatabase.forTesting(NativeDatabase.memory())`):
```dart
test('insertHijoDraft crea fila pendiente y contarHijosPendientes la cuenta', () async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  await db.insertHijoDraft(
    id: 'h1', tutorId: 't1', nombreNna: 'Juana', apellidoNna: 'Pérez',
    payloadJson: '{}',
  );
  expect(await db.contarHijosPendientes(), 1);
  await db.close();
});
```

- [ ] **Step 2: Correr y verificar que falla**

Run: `flutter test test/core/database/app_database_test.dart`
Expected: FAIL (métodos no existen).

- [ ] **Step 3: Implementar las queries**

Agregar a `AppDatabase`:
```dart
  Future<void> insertHijoDraft({
    required String id,
    required String tutorId,
    required String nombreNna,
    required String apellidoNna,
    required String payloadJson,
  }) =>
      into(hijosRows).insert(HijosRowsCompanion.insert(
        id: id,
        tutorId: tutorId,
        nombreNna: Value(nombreNna),
        apellidoNna: Value(apellidoNna),
        payloadJson: payloadJson,
      ));

  Future<int> contarHijosPendientes() async {
    final q = selectOnly(hijosRows)
      ..addColumns([hijosRows.id.count()])
      ..where(hijosRows.syncStatus.equalsValue(SyncStatus.pendiente));
    final row = await q.getSingle();
    return row.read(hijosRows.id.count()) ?? 0;
  }

  Future<List<HijosRow>> hijosPendientes() =>
      (select(hijosRows)..where((t) => t.syncStatus.equalsValue(SyncStatus.pendiente))).get();

  Future<void> marcarHijoSincronizado(String id) =>
      (update(hijosRows)..where((t) => t.id.equals(id)))
          .write(const HijosRowsCompanion(syncStatus: Value(SyncStatus.sincronizado)));
```
(importar `sync_columns.dart` para `SyncStatus` si no está.)

- [ ] **Step 4: Correr y verificar que pasa**

Run: `flutter test test/core/database/app_database_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/database/app_database.dart test/core/database/app_database_test.dart
git commit -m "feat(db): queries de hijos (draft, pendientes, contar, marcar)"
```

---

### Task 8: F4 — Wizard de planilla familiar (escribe el draft)

Formulario de la grilla V2 (datos NNA + domicilio + cobertura + antecedentes clave + consentimiento). Para v1: un form scrolleable con secciones; al confirmar, arma el payload, genera UUID e **inserta la fila pendiente** (eso es la persistencia offline). El autosave por paso de un borrador incompleto queda como polish.

**Files:**
- Create: `lib/features/hijos/presentation/controllers/planilla_controller.dart`
- Modify: `lib/features/hijos/presentation/screens/planilla_screen.dart`
- Modify: `lib/core/providers.dart` (provider de `tutorId` desde la sesión)
- Test: `test/features/hijos/planilla_controller_test.dart` (crear)

- [ ] **Step 1: Provider del tutorId**

El `tutorId` es el `id` del Tutor. Para v1 lo tomamos del `id` del usuario de la sesión (el backend resuelve el dueño por `request.user`; si el endpoint usa `<tutor_pk>`, el front usa el id del usuario logueado). Agregar a `lib/core/providers.dart`:
```dart
final databaseProvider2 = databaseProvider; // (referencia existente; ver nota)
```
> Nota de integración: el endpoint es `/tutores/<tutor_pk>/hijos/`. Confirmar con el contrato (`contrato-hijos-backend.md`) si `<tutor_pk>` = id del Tutor o del Usuario; el `/me` devuelve `user.id`. Si difieren, exponer el `tutor_id` en `/me` (ajuste menor de B0). **Bloqueante de integración: resolver antes de la Task 9.**

- [ ] **Step 2: Test del controller (arma payload + inserta draft)**

`test/features/hijos/planilla_controller_test.dart`: con una `AppDatabase.forTesting`, completar los campos mínimos, llamar `guardar()`, y verificar `db.contarHijosPendientes() == 1` y que el `payloadJson` parsea con `persona`, `domicilio`, `consentimiento`.

- [ ] **Step 3: Implementar `PlanillaController`**

`lib/features/hijos/presentation/controllers/planilla_controller.dart`: `StateNotifier` con los campos del form + `guardar()` que arma el map (igual shape que el contrato: `persona`, `domicilio`, `edad`, `tiene_cud`, `tipo_cobertura`, `nombre_cobertura`, `parentesco`, `antecedentes_personales`, `antecedentes_familiares`, `consentimiento`), genera `uuid.v4()`, y llama `db.insertHijoDraft(...)` con `payloadJson = jsonEncode(map)`. Prefijar `consentimiento.adulto_*` con los datos del tutor desde la sesión.

- [ ] **Step 4: UI del form**

En `planilla_screen.dart`: un `SingleChildScrollView` con secciones (usar `AppTextField`, `AppSwitch`/checkbox de consentimiento, date picker) que escriben en el controller, y un botón "Guardar" que llama `guardar()` y hace `context.go('/inicio')`. (Polish iterativo: partir en sub-pantallas tipo wizard como el de signup.)

- [ ] **Step 5: Codegen (si usa freezed) + correr**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/features/hijos/planilla_controller_test.dart
```
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/hijos/ lib/core/providers.dart test/features/hijos/planilla_controller_test.dart
git commit -m "feat(hijos): wizard de planilla familiar que persiste el draft offline"
```

---

### Task 9: F5 — `HijosSyncer` (push del POST agregado) + wiring del engine

**Files:**
- Create: `lib/features/hijos/data/hijos_syncer.dart`
- Modify: `lib/core/providers.dart` (registrar el syncer en el `SyncEngine`)
- Modify: `lib/features/pendientes/pendientes_count_provider.dart` (sumar hijos pendientes)
- Test: `test/features/hijos/hijos_syncer_test.dart` (crear)

- [ ] **Step 1: Test del syncer**

`test/features/hijos/hijos_syncer_test.dart`: con `AppDatabase.forTesting` + un Dio mockeado (http_mock_adapter respondiendo 201 a `/tutores/.../hijos/`), insertar un draft, correr `pushLote(await idsPendientes())`, y verificar que devuelve `PushOutcome.ok` y que tras `marcarSincronizado` queda 0 pendientes.

- [ ] **Step 2: Correr y verificar que falla**

Run: `flutter test test/features/hijos/hijos_syncer_test.dart`
Expected: FAIL (no existe).

- [ ] **Step 3: Implementar el syncer**

`lib/features/hijos/data/hijos_syncer.dart` implementando `FeatureSyncer`:
```dart
import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/database/app_database.dart';
import '../../../core/sync/feature_syncer.dart';

class HijosSyncer implements FeatureSyncer {
  HijosSyncer(this._db, this._dio);
  final AppDatabase _db;
  final Dio _dio;

  @override
  String get feature => 'hijos';

  @override
  Future<List<String>> idsPendientes() async =>
      (await _db.hijosPendientes()).map((r) => r.id).toList();

  @override
  Future<List<PushItemResult>> pushLote(List<String> ids) async {
    final pendientes = await _db.hijosPendientes();
    final results = <PushItemResult>[];
    for (final row in pendientes.where((r) => ids.contains(r.id))) {
      try {
        final body = jsonDecode(row.payloadJson) as Map<String, dynamic>;
        await _dio.post('/tutores/${row.tutorId}/hijos/', data: body);
        results.add(PushItemResult(row.id, PushOutcome.ok));
      } on DioException catch (e) {
        final code = e.response?.statusCode ?? 0;
        results.add(PushItemResult(
          row.id, code >= 400 && code < 500 ? PushOutcome.permanente : PushOutcome.transitorio));
      }
    }
    return results;
  }

  @override
  Future<void> marcarSincronizado(String id) => _db.marcarHijoSincronizado(id);

  @override
  Future<DateTime?> getWatermark() => _db.getWatermark(feature);

  @override
  Future<void> setWatermark(DateTime ts) => _db.setWatermark(feature, ts);

  @override
  Future<void> pullDesdeYMergear(DateTime? since) async {
    // v1: pull simple (no incremental). GET hijos del tutor para reflejar lo del server.
    // Implementación mínima: no-op si no hay endpoint de listado por watermark.
  }
}
```
> El Dio del syncer debe llevar el `Bearer` (usar el `dioProvider` con interceptors, igual que el resto).

- [ ] **Step 4: Registrar el syncer y el count**

En `lib/core/providers.dart`, crear el `SyncEngine` con el syncer (o agregar a la lista existente de syncers):
```dart
final hijosSyncerProvider = Provider((ref) => HijosSyncer(ref.watch(databaseProvider), ref.watch(dioProvider)));
final syncEngineProvider = Provider((ref) => SyncEngine([ref.watch(hijosSyncerProvider)]));
```
En `lib/features/pendientes/pendientes_count_provider.dart`, convertir `pendientesCountProvider` para sumar `await db.contarHijosPendientes()` (usar un `StreamProvider`/`FutureProvider` o recalcular tras cada sync; mantener `contarPendientes` puro para el test existente).

- [ ] **Step 5: Codegen (si aplica) + correr**

```bash
flutter test test/features/hijos/hijos_syncer_test.dart
```
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/hijos/data/ lib/core/providers.dart lib/features/pendientes/pendientes_count_provider.dart test/features/hijos/hijos_syncer_test.dart
git commit -m "feat(hijos): HijosSyncer (push del POST agregado) + wiring del sync engine"
```

---

### Task 10: F6 — Nudge en Pendientes

Si el tutor no tiene hijos cargados (local + server), mostrar en `PendientesScreen` "Completá el consentimiento de tu hijo" con deep-link a `/hijos/nuevo`.

**Files:**
- Modify: `lib/features/pendientes/presentation/pendientes_screen.dart`
- Test: `test/features/pendientes/pendientes_screen_test.dart` (agregar caso)

- [ ] **Step 1: Test que falla**

Agregar a `test/features/pendientes/pendientes_screen_test.dart`: con un provider override que reporte "0 hijos" y sesión de tutor, montar `PendientesScreen` y verificar que aparece el texto del nudge y que tocarlo navega a `/hijos/nuevo`.

- [ ] **Step 2: Correr y verificar que falla**

Run: `flutter test test/features/pendientes/pendientes_screen_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implementar el nudge**

En `pendientes_screen.dart`, agregar un provider (`FutureProvider`) que devuelva si el tutor tiene ≥1 hijo (local `contarHijos()` o `GET /tutores/<id>/hijos/`), y si es 0 y el rol es tutor, renderizar una tarjeta tappable (`AppCard`) que hace `context.go('/hijos/nuevo')`. Si hay hijos, mantener el `EmptyState` actual ("Todo sincronizado").

- [ ] **Step 4: Correr y verificar que pasa**

Run: `flutter test test/features/pendientes/`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/pendientes/ test/features/pendientes/pendientes_screen_test.dart
git commit -m "feat(pendientes): nudge 'completa el consentimiento' con deep-link"
```

---

### Task 11: Verificación final

- [ ] **Step 1: Suite completa + análisis**

```bash
flutter analyze
flutter test
```
Expected: sin errores de análisis; todos los tests verdes.

- [ ] **Step 2: Smoke end-to-end (manual, backend en dev-base)**

Registrar tutor → entrar logueado → menú "Registrar hijo" → completar planilla → guardar (offline) → reconectar → verificar que sincroniza (pendiente → sincronizado) y el nudge desaparece.

---

## Self-review (cobertura del spec)

- **F1** → Task 1 (base URL dev-base). ✅
- **F2** → Tasks 2–4 (datasource registerTutor + repo login-after-register + controller payload anidado + nav). ✅
- **F3** → Task 5 (menú → rutas). ✅
- **F4** → Tasks 6–8 (tabla Drift + queries + wizard que persiste draft). ✅
- **F5** → Task 9 (HijosSyncer + wiring + count). ✅
- **F6** → Task 10 (nudge). ✅
- Verificación → Task 11. ✅

## Deudas / decisiones explícitas (no placeholders, son alcance v1)
- `lugar_nacimiento` / `pais_residencia`: se siguen pidiendo en el form pero no se envían (hacerlos opcionales = polish).
- Wizard de planilla: form scrolleable en v1; partir en sub-pantallas (como signup) es polish.
- Pull del `HijosSyncer`: no incremental en v1 (push es lo crítico para esta parte).
- **Bloqueante de integración (Task 8/9):** confirmar si `<tutor_pk>` de la URL es id de Tutor o de Usuario, y exponerlo en `/me` si hace falta.
