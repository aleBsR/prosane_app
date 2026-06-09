# Fundación Flutter offline-first — Diseño

> **Estado:** aprobado (brainstorming Secciones 1–4). Próximo paso: plan de implementación (writing-plans).
> **Fecha:** 2026-06-08
> **App:** `prosane_app` (Flutter, mobile-first Android/iOS)
> **Backend:** `prosane_api` (Django REST + JWT). Es nuestro: lo diseñamos para sincronizar, no solo CRUD.

## Objetivo

Montar la **fundación profesional** de `prosane_app` —una app de salud escolar (circuito PROSANE)
que digitaliza el apto físico— y validarla con un **vertical slice de Auth** (Login + Signup)
completo de data→domain→presentation. La fundación es **offline-first** desde el día uno, aunque
Auth en sí sea remoto.

## Alcance

**Incluye (esta iteración):**
- Esqueleto de arquitectura completo (capas, theme/design-system, red, routing, sesión/permisos,
  base de datos local, motor de sync).
- Slice de Auth: Login + Signup wizard de 4 etapas, contra la API.
- Permisos como fuente de verdad del backend (`can()` / `PermissionGate`) desde el día uno.
- **Motor de sync construido y testeado contra un `FeatureSyncer` falso / de prueba**, no contra una
  feature real. La fundación queda cableada y testeada, sin construir una feature de dominio end-to-end.

**Difiere (no se construye ahora):**
- **Features de dominio completas** (p. ej. `apto_fisico`). Es la **primera integración real del
  `sync_engine`** y queda **fuera de esta iteración**; en el spec aparece solo como ejemplo de referencia
  de la forma que tendrá la capa `data/`.
- **ActionRegistry** / acciones server-driven por metadata con handlers tipados. No hay todavía una
  pantalla que lo necesite (Auth no lo usa). Se arma cuando existan los listados reales con acciones
  por fila, sobre casos concretos. Los permisos SÍ quedan; el registry de acciones NO.
- **Sync en background real** (WorkManager/BGTask). Arrancamos con sync en foreground.
- Web / desktop. Reanudar un signup a medias.

## Decisiones de arquitectura (cerradas)

| Decisión | Elección | Motivo |
|----------|----------|--------|
| Patrón | Clean Architecture **feature-first**, 3 capas, dependencia hacia adentro (presentation → domain → data) | Aísla dominio, testeable, escala a sistema grande |
| Estado | **Riverpod** (con code-gen) | Type-safe, testeable, poco boilerplate, DI integrada |
| Routing | **go_router** + guard de auth (`redirect`) | Declarativo, deep links, guard por sesión |
| Code-gen | **freezed + json_serializable + build_runner** | Estándar profesional, menos errores de boilerplate |
| Base de datos local | **Drift** | Relacional, type-safe, code-gen, `watch()` reactivo que se integra con Riverpod |
| Conectividad | **connectivity_plus** | Stream online/offline |
| Storage de secretos | **flutter_secure_storage** | Solo JWT/secretos, NO datos de dominio |
| Conflictos de sync | **Last-write-wins por `updated_at`** | Alcanza para este dominio |
| Outbox | **Flag por fila** (`syncStatus` + `updatedAt`) | Menos piezas, robusto para LWW, aprovecha el `BaseModel` del API |

## Regla de oro offline-first

- La **base local (Drift) es la única fuente de verdad.**
- La UI **nunca** habla con la API directo: lee/escribe contra la base local.
- La sincronización ocurre **por separado**, en segundo plano, cuando hay conexión.
- Puente reactivo: **Drift `.watch()` → Riverpod `StreamProvider`.** La pantalla observa una query
  local; el sync escribe en local; la pantalla se actualiza sola. Online u offline, el flujo de
  lectura es idéntico.

### Sinergia con el API ya construido

El `BaseModel` del API (PK **UUID** generada en cliente + `updated_at` + soft delete `deleted_at`)
es exactamente el sustrato que la sincronización necesita: UUIDs para crear offline, `updated_at`
para pull incremental y LWW, y `deleted_at` como **tombstone** para propagar borrados hechos offline.

## Modelo de sincronización

- **Metadata por fila:** cada tabla de dominio incluye el mixin `sync_columns` → `id` (UUID cliente),
  `updatedAt`, `syncStatus` (`pendiente` | `sincronizado` | `error`).
- **IDs en el cliente (UUID):** se puede crear offline sin esperar al server. Coincide con las PK del API.
- **Push (outbox = query):** "dame las filas `syncStatus = pendiente`" → se mandan **en lote** a la API.
- **Pull incremental:** `?updated_since=<watermark>` → solo lo que cambió.
- **Borrados:** `deleted_at` local + `pendiente` → sincroniza como una edición normal (tombstone).
  No hace falta mecánica aparte para deletes.

### Invariantes de sync (no negociables)

1. **Watermark por feature, nunca global.** Cada `FeatureSyncer` guarda su propio `lastSyncedAt` en
   una tabla `sync_state` (clave = nombre de feature/entidad → watermark).
   - El watermark **avanza solo si el merge de esa feature se commiteó entero** (transacción Drift).
     Si el pull se pagina, avanza recién al confirmar la última página. Pull a medias → el watermark
     no se mueve y el próximo ciclo re-baja desde donde estaba.
   - **Cursor `>=` + upsert idempotente por UUID:** re-bajar una fila del borde (mismo timestamp) es
     inofensivo. Preferible perder eficiencia que perder un registro.
   - El `updated_at` que manda el server es la autoridad (evita clock-skew del cliente).
2. **Push con confirmación fila-por-fila, no todo-o-nada.** `pushLote` devuelve un resultado por ítem;
   se marca `sincronizado` **solo** lo que el server confirmó; el resto queda como estaba.
   - **Transitorio** (sin red / `5xx` / timeout del lote) → todo queda `pendiente`, reintenta con backoff.
   - **Rechazo permanente del ítem** (`4xx` de validación de esa fila) → la fila pasa a `error` con el
     motivo, aparece en el indicador, y **deja de auto-reintentarse** (necesita intervención). Las demás
     del lote siguen su curso.

### Invariante de migraciones de Drift (no negociable)

En offline-first los datos locales del usuario **son la fuente de verdad**: una migración mal hecha los
destruye. Por eso, desde el día uno (aunque arranquemos con pocas tablas):

- Las migraciones de Drift se **versionan explícitamente**: nunca se bumpea `schemaVersion` sin escribir
  la migración correspondiente.
- Se **testean con la utilidad de schema verification de Drift** (`drift_dev schema dump` + generación de
  tests de migración), para garantizar que ningún cambio de esquema destruya datos locales preexistentes
  en el dispositivo.

## Estructura de carpetas

```
lib/
  main.dart
  app.dart                       # ProviderScope + MaterialApp.router + theme
  core/
    config/                      # env, baseUrl, flavors (dev/prod)
    theme/                       # app_colors, app_typography (Nunito/Rubik), app_spacing, app_radii, app_theme
    design_system/               # un archivo por componente (ver Design System)
    network/                     # dio_client, interceptors (auth/refresh/logging), Result<T>, ApiException
    error/                       # Failure + error_mapper
    router/                      # app_router (go_router) + guard de auth
    session/                     # session_controller (usuario+token+permisos CACHEADOS), permissions (can/PermissionGate)
    storage/                     # flutter_secure_storage → SOLO secretos (JWT)
    database/                    # Drift
      app_database.dart          #   @DriftDatabase: conexión, migraciones, versión de esquema
      tables/                    #   tablas Drift (alumnos, aptos_fisicos, antecedentes…)
      daos/                      #   DAOs por agregado: queries + watch()
      converters/                #   type converters (enums, DateTime, sync_status)
      sync_columns.dart          #   mixin reutilizable: id(UUID) + updatedAt + syncStatus (espejo de BaseModel)
    sync/                        # motor de sincronización
      connectivity_service.dart  #   connectivity_plus → stream online/offline
      sync_engine.dart           #   orquesta push (pendientes) + pull (incremental); registra FeatureSyncers
      feature_syncer.dart        #   interfaz que cada feature real implementa para enchufarse al engine
      sync_status.dart           #   enum pendiente|sincronizado|error
      sync_scheduler.dart        #   dispara sync: al recuperar conexión, al abrir/resumir, tras escribir (debounced)
    # core/actions/ → DIFERIDO
  features/
    auth/                        # REMOTO (excepción justificada)
      data/
        dtos/                    # login_request, token_response, register_request, me_response
        datasources/auth_remote_datasource.dart
        repositories/auth_repository_impl.dart      # login/register/me; cachea permisos en DB
      domain/
        entities/                # usuario, sesion, permiso
        repositories/auth_repository.dart
        usecases/                # Login, Register, GetMe, Logout
      presentation/
        controllers/             # login_controller, signup_controller
        screens/                 # login_screen, signup_wizard_screen
        widgets/                 # step_documento, step_datos_personales, step_contacto, step_acceso, wizard_progress, wizard_nav_buttons
    apto_fisico/                 # FEATURE REAL → local-first + sync (ejemplo de referencia)
      data/
        dtos/                    # apto_fisico_dto + mapeos
        datasources/
          apto_fisico_local_datasource.dart   # Drift — fuente de verdad
          apto_fisico_remote_datasource.dart  # Dio — lo usa el sync, NO la UI
        repositories/apto_fisico_repository_impl.dart   # local-first + encola sync
      domain/
        entities/apto_fisico.dart
        repositories/apto_fisico_repository.dart
        usecases/                # CrearApto, ListarAptos, EditarApto
      presentation/
        controllers/ screens/ widgets/
  shared/                        # extensions/helpers puntuales
```

## Ejemplo de referencia: capa `data/` de `apto_fisico`

Define la **forma** que toda feature real va a seguir (Auth es la excepción remota).

```dart
// domain/repositories/apto_fisico_repository.dart — interfaz pura (sin Drift ni Dio)
abstract class AptoFisicoRepository {
  Stream<List<AptoFisico>> watchAptos(String alumnoId); // observa LOCAL
  Future<AptoFisico> getById(String id);
  Future<void> crear(AptoFisico apto);   // escribe LOCAL + marca pendiente
  Future<void> editar(AptoFisico apto);  // idem
  Future<void> eliminar(String id);      // soft delete LOCAL + pendiente
}

// data/datasources/apto_fisico_local_datasource.dart — Drift, fuente de verdad
class AptoFisicoLocalDataSource {
  Stream<List<AptoFisicoRow>> watch(String alumnoId);
  Future<void> upsert(AptoFisicoRow row);              // setea updatedAt + syncStatus=pendiente
  Future<void> softDelete(String id);                  // deleted_at + pendiente
  Future<List<AptoFisicoRow>> pendientes();            // syncStatus = pendiente  ← el "outbox"
  Future<void> marcarSincronizado(String id, DateTime serverUpdatedAt);
  Future<void> upsertDesdeServidor(List<AptoFisicoRow> remotos); // merge del pull (LWW)
}

// data/datasources/apto_fisico_remote_datasource.dart — Dio, solo lo usa el sync
class AptoFisicoRemoteDataSource {
  Future<List<AptoFisicoDto>> pullDesde(DateTime since);            // GET …?updated_since=
  Future<List<PushItemResult>> pushLote(List<AptoFisicoDto> pend);  // POST batch → resultado por ítem
}

// data/repositories/apto_fisico_repository_impl.dart — orquesta local-first
class AptoFisicoRepositoryImpl implements AptoFisicoRepository {
  Stream<List<AptoFisico>> watchAptos(String alumnoId) =>
      _local.watch(alumnoId).map(_mapRowsToEntities);   // lecturas SIEMPRE del local
  Future<void> crear(AptoFisico a) =>
      _local.upsert(_toRow(a, SyncStatus.pendiente));    // escrituras SIEMPRE al local + pendiente
  // editar / eliminar igual. NUNCA llama a _remote directo.
}
```

El **`sync_engine`** (en `core/sync/`) es el único que cruza local↔remote: por cada `FeatureSyncer`
lee `pendientes()` → `pushLote` (confirma fila-por-fila) → marca `sincronizado`; y `pullDesde(watermark)`
→ `upsertDesdeServidor` (LWW). Las features no orquestan red; solo escriben local.

## Design System

Bajamos los 3 mockups a **tokens** + **widgets**. Regla: ninguna pantalla hardcodea estilos.

**Dónde viven los mockups (fuente del design system):** en `docs/design/` del repo, trazables —
`docs/design/diseno-login.jpeg`, `docs/design/diseno-inputs.jpeg`, `docs/design/formulario-registro.jpeg`.
"Calibrar los tokens contra el diseño real" significa contrastar contra esos archivos.

**`core/theme/`** (tokens de arranque, a calibrar contra el diseño):
- `app_colors`: primario `#7C5CFC`, gradiente fondo `#9B7DF0→#7B5BE0`, campo `#F1F0F5`,
  error `#C0392B` (+gradiente), texto `#2D2D3A`, link `#6C4DE0`.
- `app_typography`: **Nunito** (títulos, Black), **Rubik** (subtítulo SemiBold / campo / texto / botón SemiBold).
  Los "pt" del mockup son relativos a la maqueta; se calibran a tamaños lógicos manteniendo jerarquía y pesos.
- `app_spacing`, `app_radii`, `app_theme` (arma el `ThemeData`).

**`core/design_system/`** (un archivo por componente, todos los estados):
- `app_text_field`: normal / focus / validado / error, label, ayuda y error, ícono de validación
  (check / X), modo password con ojo. Estado visual cableado a la validación del form.
- `app_button`: normal / cargando (spinner) / validado (check) / no-validado (gradiente rojo + X), con degradado e ícono.
- `app_switch`, `app_checkbox`: toggle on/off.
- `app_link`: texto-botón violeta.
- `app_gradient_scaffold` + `app_card`: fondo violeta degradado + card blanca redondeada.

**Fuentes:** **bundled** (`.ttf` en `assets/fonts/`), NO `google_fonts` en runtime (descargaría online —
incompatible con offline-first).

**Galería viva:** previsualización de componentes/estados con **widgetbook** (equivalente mobile-nativo de
una herramienta de diseño; doble como documentación para el equipo). No se diseña en web/HTML porque no
porta a Flutter.

## Slice de Auth

Auth es **remoto** pero **monta y ejercita la fundación**; su único toque a la DB es cachear `/me`.

### Login (mockup 1)
- Pantalla con el design system: `AppGradientScaffold` + `AppCard`, "Bienvenido", `AppTextField` (email),
  `AppTextField` password con ojo, `AppSwitch` ("Recordarme"), `AppLink` ("¿Olvidaste tu contraseña?"),
  `AppButton` ("INICIAR SESIÓN", estado cargando), `AppLink` ("Regístrese aquí").
- Estado (`LoginController`, `Notifier`): `{ email, password, recordarme, obscurePassword, isLoading, error }`.
- Flujo: submit → usecase `Login` → `authRepository.login()` → `auth_remote_datasource` POST login (JWT
  simplejwt) → guarda access+refresh en secure storage → trae `/me` → **cachea usuario+permisos en Drift**
  → `SessionController` pasa a autenticado → guard de go_router redirige al home.

### Taxonomía de errores de login (invariante)
El `error_mapper` clasifica por categoría; el controller **nunca** cae en "credenciales" por descarte:
- Sin conexión (sin red / DNS) → "Necesitás conexión para iniciar sesión".
- `401` → "Credenciales incorrectas" (**solo** ante 401 real).
- `5xx` / timeout / inesperado → "Hubo un problema, probá de nuevo".
- Fallback de error no previsto → el genérico, jamás "credenciales incorrectas".

### Signup — wizard de 4 etapas (mockup 3)
Es **un solo formulario lógico** partido en 4 páginas; todo el estado vive en el controller.

- Estado (`SignupController`, `Notifier<SignupState>`):
  - `SignupFormData` (freezed): `tipoDocumento, numeroDocumento, aceptaPolitica` (etapa 1);
    `nombre, apellido, sexo, fechaNacimiento, lugarNacimiento` (etapa 2);
    `paisResidencia, email, confirmEmail` (etapa 3); `password, confirmPassword` (etapa 4).
  - `SignupState`: `{ formData, currentStep (0..3), isSubmitting, error }`.
- Páginas: `StepDocumento`, `StepDatosPersonales`, `StepContacto`, `StepAcceso` + `WizardProgress`
  ("Etapa N/4") + `WizardNavButtons` (ANTERIOR/SIGUIENTE/REGISTRARSE).
- Validación por etapa (gatea "SIGUIENTE", cableada a estados validado/error): documento requerido +
  formato; etapa 1 exige aceptar política; `email == confirmEmail`; `password == confirmPassword` +
  fortaleza; requeridos. Fecha con date-picker; tipo de doc / sexo / país con dropdowns.
- Submit final ("REGISTRARSE") → usecase `Register` → `POST /register` (ya andando). El backend crea
  **Usuario + Persona** de forma atómica (`@transaction.atomic`). Éxito → **redirige a `/login` con un
  mensaje de éxito** (no auto-login: más simple y el usuario confirma sus credenciales recién creadas).

### Ciclo de vida del wizard (invariante): efímero, a propósito
- El estado del signup es **efímero**: si el usuario cierra la app o abandona el flujo, **se pierde**.
  Decisión deliberada — es un alta no reanudable, y hay password/datos sensibles que no queremos
  persistir a medias (menores, Ley 25.326).
- `SignupController` es `autoDispose` scopeado a la ruta del wizard. Salir del flujo o cerrar la app lo
  dispone → estado borrado. **Nada del wizard se escribe en Drift ni en secure storage.**
- Distinción: moverse entre las 4 etapas NO dispone el provider (misma ruta) → "ANTERIOR" conserva lo
  cargado. Solo abandonar el flujo entero lo borra.
- Reanudar registro, si algún día se quiere, será una feature explícita aparte (nunca persistiendo la contraseña).

## Sesión y permisos (desde el día uno)

- `SessionController` (Riverpod `Notifier`) mantiene `Sesion` (usuario, presencia de token, permisos).
  - **login** → JWT a secure storage, trae `/me`, cachea usuario+permisos en DB local, marca activa.
  - **arranque** → lee secure storage; si hay token, hidrata desde el `/me` cacheado (funciona offline) y
    refresca `/me` cuando hay conexión.
  - **logout** → limpia storage + estado.
- `permissions`: `can('firmar_apto')` + `PermissionGate(permiso, child)`. Permisos del backend,
  **cacheados local** para que `can()` ande sin conexión.
- Guard de go_router (`redirect`) lee el estado de sesión → sin sesión va a `/login`.

## Red (`core/network/`)

- `dio_client`: Dio con baseUrl, timeouts y la cadena de interceptors.
- `auth_interceptor`: agrega `Authorization: Bearer <token>` desde secure storage.
- `refresh_interceptor`: ante `401` intenta `POST /token/refresh`, reintenta el request; si el refresh
  falla → logout. Con lock para que varios 401 simultáneos no disparen N refreshes.
- `logging_interceptor` (solo dev): **redacción obligatoria** — nunca loguear DNI/diagnósticos/email/token
  en texto plano (Ley 25.326, datos de menores).
- `Result<T>` (sealed `Success/Failure`) + `ApiException`. En offline-first la mayoría de los errores de
  red no llegan a la UI (ver Manejo de errores).

## Manejo de errores (en planos)

1. **Local:** casi nunca falla; si la DB falla, es error de app.
2. **Red/sync:** **no bloquea la UI.** Se registra como `syncStatus = error` + reintento con backoff;
   indicador global ("X con error") + "reintentar". Esto es lo que hace que la app se sienta offline-first.
3. **Auth (necesita red):** errores mostrados en pantalla con los estados del mockup, según la taxonomía
   de login. `401` a mitad de sesión → refresh → si falla, logout.

## Estrategia de testing (pirámide, con TDD)

- **Unit (la base):**
  - usecases (`Login`, `Register`, `GetMe`) con repos mockeados (`mocktail`).
  - controllers/notifiers con `ProviderContainer` + overrides: login éxito/fallo, navegación y gating del
    wizard, persistencia del estado al ir/volver entre etapas.
  - validadores y mappers DTO↔entidad.
  - **`sync_engine` desde ya** (aunque Auth no lo use): testear los invariantes — push confirma
    fila-por-fila (transitorio vs rechazo permanente), watermark avanza solo si el merge commitea entero,
    merge LWW. Con un `FeatureSyncer` falso.
- **Repositorio:** Drift in-memory (`NativeDatabase.memory()`) + remoto mockeado → verifica local-first
  (escritura va a local + pendiente; lectura sale del stream local).
- **Widget:** cada estado de `AppTextField`/`AppButton`; `LoginScreen` (validación + error); wizard (gating por etapa).
- **Golden (pocos):** congelan estados visuales del design system (normal/focus/validado/error/cargando).
- **Herramientas:** `flutter_test`, `mocktail`, utilidades de test de Riverpod, Drift in-memory, goldens.

## Dependencias a sumar

`flutter_riverpod` (+ `riverpod_annotation`, dev `riverpod_generator`), `go_router`, `dio`,
`flutter_secure_storage`, `drift` (+ dev `drift_dev`), `connectivity_plus`,
`freezed` + `json_serializable` (+ dev `build_runner`, `freezed_annotation`, `json_annotation`),
fuentes Nunito/Rubik (assets), dev: `mocktail`, `widgetbook`.

## Contrato con el backend (`prosane_api`) — a coordinar

Es nuestro API; lo diseñamos para sincronizar. Necesita:
- **`GET /me`** → usuario + rol + permisos (no existe hoy). Necesario para sesión/permisos.
- **`POST /token/refresh`** → refresh de JWT (no existe hoy; el `CLAUDE.md` ya lo marca).
- **Endpoints batch** que acepten lotes de pendientes y respondan **`200` con un array de resultados
  por ítem** (`{id, status: ok|error, motivo}`), aunque algunos fallen — NO un único `400` que aborta
  el lote. Sin esto, el push fila-por-fila no se puede implementar bien.
- **`updated_at` en todo** para pull incremental (`?updated_since=`). Ya está en `BaseModel`.
- **Aceptar UUID generados por el cliente.** Ya está en `BaseModel` (PK UUID).

## Fuera de alcance / diferido

- ActionRegistry / acciones server-driven por metadata (se arma con los listados reales).
- Sync en background real (WorkManager/BGTask).
- Web/desktop. Reanudar signup a medias.
