# Menú de navegación flotante — Diseño

> **Fase visual:** barra de navegación flotante (estilo Instagram) + las tres pantallas
> que cuelgan de ella. Sigue a la fundación offline-first
> (`2026-06-08-fundacion-flutter-offline-first.md`).

**Objetivo:** una barra flotante persistente con 3 pestañas (**Inicio · Pendientes ·
Usuario**) sobre el design system violeta existente, donde **Inicio** despliega — en un
acordeón por categoría — las acciones que el rol del usuario puede hacer, armadas desde
los permisos cacheados en Drift (offline-first).

**Arquitectura:** `StatefulShellRoute.indexedStack` de go_router con 3 ramas, envueltas
por un `AppShell` que pinta la barra flotante custom y la compacta al scrollear. Los datos
de las acciones (label/icon/color/category/type/sort_order) salen del `/me` ya consumido y
**cacheado en Drift**; la app construye las pantallas en Flutter (no hay render dinámico).

**Tech stack:** Flutter + Riverpod (providers manuales + `StateNotifier`), go_router
(`StatefulShellRoute`), Drift (caché de sesión), Widgetbook (galería). Sin code-gen de
Riverpod/JSON.

---

## Invariantes y decisiones conscientes (leer primero)

Estas cuatro quedan **congeladas** en este spec — no son "a decidir", ya se decidieron:

1. **Frontera: NO es server-driven UI / NO hay ActionRegistry.** El backend provee
   *datos* (la lista de acciones con su metadata); **las pantallas y el menú se construyen
   en Flutter**. No se arma un motor de renderizado dinámico ni handlers tipados por
   metadata. Los permisos sí son data-driven (salen del `/me`); la UI no.

2. **Fallback de icon desconocido (resiliencia entre repos).** El backend manda el `icon`
   como nombre lógico de Material (`people`, `draw`, …). El front lo mapea con
   `accionIcon(name) → IconData`. Si llega un `icon` que el mapa no conoce (porque el
   backend agregó una acción nueva y la app todavía no se actualizó), la UI **muestra un
   ícono genérico de fallback y sigue** — nunca crashea. La app vieja tolera datos nuevos.

3. **Badge de Pendientes: cableado pero en 0 hasta que existan features sincronizables.**
   El contador del badge sale de contar filas con `syncStatus ∈ {pendiente, error}` en las
   tablas de feature. Hoy **no existe ninguna tabla de feature real** (apto_físico está
   diferido), así que el contador da **0** y el badge **no se muestra**. La infraestructura
   queda lista y se "enciende" sola cuando exista la primera entidad sincronizable. **No se
   hardcodean datos mock** para simularlo.

4. **El `/me` ya provee toda la metadata hoy — este spec NO requiere cambios de backend.**
   El endpoint `GET /api/v1/auth/me/` (rama `feat/permisos-data-driven` del backend) ya
   devuelve cada acción con las 8 claves del contrato congelado, dedup y ordenada por
   `sort_order`. El único cambio es del lado del front: hoy `MeResponse` **descarta** todo
   menos `name`; hay que dejar de tirar la metadata.

---

## Contrato real del `/me` (fuente de verdad, no inventar)

`GET /api/v1/auth/me/` devuelve (contrato congelado, backend `authentication/me.py`):

```json
{
  "user":  { "id", "email", "nombre", "apellido", "is_staff" },
  "roles": [ { "name", "label" } ],
  "actions": [
    { "name", "label", "icon", "color", "type", "category", "is_sensitive", "sort_order" }
  ],
  "meta":  { "permissions_synced_at", "version" }
}
```

- `actions` viene **deduplicada por `name`** y **ordenada por `(sort_order, name)`** del
  server. El front **respeta ese orden tal cual** — no reordena.
- `meta.version` es un hash corto del conjunto de `name`; cambia si y sólo si cambia el set
  de acciones del usuario. **Se usa para invalidar el caché** (offline-first).
- `name` está garantizado en **camelCase** (invariante ya testeada en el front:
  `test/core/session/permisos_naming_test.dart`).

**Acciones reales hoy** (referencia — salen del backend, no se hardcodean en el front):

| name | label | icon | color | type | category | is_sensitive |
|---|---|---|---|---|---|---|
| `listarPacientes` | Listar pacientes | `people` | `#1565C0` | list | salud | false |
| `registrarAntropometria` | Registrar antropometría | `straighten` | `#EF6C00` | form | salud | true |
| `verFichaClinica` | Ver ficha clínica | `clinical_notes` | `#6A1B9A` | form | salud | true |
| `verFichaOdontologica` | Ver ficha odontológica | `dentistry` | `#00838F` | form | salud | true |
| `crearApto` | Crear apto físico | `assignment_add` | `#2E7D32` | form | salud | true |
| `firmarApto` | Firmar apto físico | `draw` | `#2E7D32` | form | salud | true |
| `verConstancias` | Ver constancias | `description` | `#455A64` | list | consentimiento | false |
| `darConsentimiento` | Dar consentimiento | `how_to_reg` | `#455A64` | form | consentimiento | true |

Categorías presentes hoy: **`salud`** y **`consentimiento`**. El diseño no las hardcodea:
agrupa por la `category` que venga.

---

## 1 · Arquitectura de navegación

Hoy el router es plano (`/login`, `/signup`, `/home`). Se reemplaza por un shell con barra
persistente que **preserva el estado de cada pestaña** (scroll, posición del acordeón).

```
StatefulShellRoute.indexedStack  (barra flotante persistente, detrás del guard de sesión)
├── branch 0: /inicio      → AccionesScreen
├── branch 1: /pendientes  → PendientesScreen
└── branch 2: /usuario      → UsuarioScreen
```

- **`AppShell`** envuelve el `navigationShell` y pinta encima la `FloatingNavBar` custom
  (NO el `BottomNavigationBar` de Material — es flotante, con márgenes, frosted).
- `IndexedStack` mantiene las 3 ramas vivas → cambiar de pestaña no reconstruye ni pierde
  scroll.
- El guard actual (`construirRedirect`) no cambia: sin sesión → `/login`; las 3 rutas del
  shell quedan detrás del guard. Se elimina `/home` (lo reemplaza `/inicio`).
- **Las 3 pestañas son navegación fija, NO permisos** — siempre visibles, no pasan por
  `can()`.

**Comportamiento responsivo al scroll (estilo Instagram):** la barra está **expandida**
(ancha, con labels) cuando la pantalla activa está arriba, y se **compacta** (se achica,
solo íconos) al scrollear hacia abajo. `AppShell` escucha el scroll de la pantalla activa
(umbral simple) y anima la transición (`AnimatedContainer`/`AnimatedScale`,
`cubic-bezier` suave ~280 ms). La barra **no es de tamaño fijo**.

**Alternativa descartada:** `Scaffold + IndexedStack` manual sin branches de go_router —
funciona, pero pierde deep-linking por rama y back-stack por pestaña que
`StatefulShellRoute` da gratis.

---

## 2 · Capa de datos / offline-first

El menú **se arma desde Drift**, no desde la red. Acá se saldan los dos gaps detectados.

### 2a · Extender el contrato en el front (hoy se tira la metadata)

- Nueva entidad de dominio **`Accion`**: `{ name, label, icon, color, type, category,
  isSensitive, sortOrder }` — las 8 claves del contrato.
- **`MeResponse`** pasa a parsear las acciones **completas** (no solo `name`). Se mantiene
  el fallback de `nombre` al email para superusuarios sin persona.
- **`Sesion`** gana `List<Accion> acciones`, **además** del `Set<String> permisos` que ya
  tiene para `can()`. El `Set<String>` se deriva de `acciones.map((a) => a.name)` — una
  sola fuente, sin desincronizar. Orden de `acciones`: **el del server, intacto**.
- **Label del rol para mostrar:** hoy `MeResponse`/`Usuario` guardan el `name` del rol
  (`"medico"`); la pantalla Usuario necesita el `label` (`"Médico/a"`, que el `/me` ya manda
  en `roles[].label`). Se conserva ese `label` (campo `rolLabel` en `Usuario`, o se cambia
  `rol` para que guarde el label y se agregue `rolName` si hiciera falta). Decisión de
  detalle para el plan; el dato **ya viene en el `/me`**, no requiere backend.

### 2b · Cachear la sesión en Drift (salda la deuda #1 del seguimiento)

- Tabla Drift nueva **`cached_session`** (una sola fila): guarda el payload `/me` necesario
  (usuario + acciones) + `meta.version` + `permissions_synced_at`.
- **Login (online):** trae `/me` → arma sesión → **persiste en Drift**.
- **Arranque:** `sesionCacheada()` (hoy devuelve `null`) lee Drift → si hay fila, **hidrata
  la sesión sin red** → la app abre offline con el último estado conocido.
- **Refresco:** con conexión, pide `/me`; si `meta.version` **difiere** del cacheado,
  reemplaza el cache (y la sesión); si es **igual**, no toca nada (no reconstruye el menú al
  pedo).
- **Logout:** limpia el cache de Drift + el estado de sesión.

### 2c · Mapeo de icon lógico → IconData

- Función pura **`accionIcon(String name) → IconData`**: mapa explícito de los nombres
  conocidos del backend (`people`, `clinical_notes`, `assignment_add`, `draw`, `dentistry`,
  `straighten`, `description`, `how_to_reg`) a `Icons.*` de Material.
- **Fallback** (ej. `Icons.bolt`/`Icons.widgets`) para cualquier `icon` desconocido — ver
  invariante #2. La UI nunca rompe por un icon nuevo.

> **Frontera (invariante #1):** el backend manda *datos*; las pantallas se construyen en
> Flutter. No hay motor de render dinámico.

---

## 3 · Pantalla Inicio / Acciones (el acordeón)

Muestra las acciones del usuario **agrupadas por `category`**, cada grupo colapsable.
Todo desde `sesion.acciones` (cacheada, sin red).

1. Toma `sesion.acciones` (ya dedup + ordenada por `sort_order`).
2. **Agrupa por `category`** preservando: (a) el orden de las acciones dentro del grupo, y
   (b) el orden de aparición de cada categoría (la categoría sale en el orden en que aparece
   su primera acción → estable). Hoy: `salud`, luego `consentimiento`. Una `category` nueva
   aparece sola, sin tocar código.
3. Cada grupo = un `ActionGroup` (card-acordeón) con header (título de categoría + chevron)
   y la lista de acciones.
4. Cada acción = `ActionTile`: chip con el `color` del backend + `accionIcon(name)` blanco
   + `label`.

**Gating:** el acordeón lista **solo** lo que está en `sesion.acciones`, que ya es el set
permitido por rol (sale del `/me`). No hay un `can()` por tile — la lista *es* el resultado
del gating del backend. (`can()` sigue existiendo para gatear acciones puntuales en otras
pantallas.)

**Interacciones:**
- Grupos **expandidos al inicio** (`initiallyExpanded = true`). Toggle por header, animado.
- Tocar una acción → **placeholder** `"{label} — próximamente"`. Las features destino están
  diferidas; el destino futuro será un wizard por etapas que **reusa el patrón de signup**.
- **`is_sensitive`:** **sin indicador visual** (casi todas las de salud son sensibles; un
  candado en todas pierde sentido). El dato viaja en `Accion` por si después se usa.
- **`type`** (`list`/`form`): **se lleva en `Accion` pero no se renderiza** hoy. Mañana
  decide el tipo de pantalla destino. YAGNI visual, pero el dato viaja.

**Estado vacío (rol sin acciones — un usuario nuevo sin rol asignado SÍ puede pasar):**
- `EmptyState` centrado: *"No tenés acciones disponibles todavía"* + subtítulo *"Cuando te
  asignen un rol, vas a ver acá lo que podés hacer."* Nunca pantalla en blanco ni crash.

> Reemplaza al `HomeScreen` placeholder actual (el del botón "Firmar apto"): ese se elimina.

---

## 4 · Pantalla Pendientes (sync offline-first)

El **indicador global de sincronización**: ventana al estado del `sync_engine` (que empuja
en background).

**El badge de la barra** (número rojo) — ver invariante #3:
- Sale de `pendientesCountProvider`, que cuenta filas con `syncStatus ∈ {pendiente, error}`
  en las tablas de feature.
- Hoy **no hay tablas de feature reales** → da **0** → badge **oculto**. Cableado pero
  apagado; se enciende solo con la primera feature sincronizable. **Sin datos mock.**
- Con pendientes: badge con el número; en cero: desaparece.

**La pantalla:**
- Diseñada para listar ítems pendientes/en error/subiendo, agrupados por estado, cada uno
  con su chip de estado (pendiente=naranja, error=rojo, subiendo=azul).
- Hoy, sin features: **estado vacío real** `EmptyState` *"Todo sincronizado"* — honesto,
  sin lista inventada.

**Diferido (NO en este spec):** botón "reintentar" por ítem en error que dispara
`sync_engine.ciclo()`; la pantalla rica con la lista real (llega con la primera feature).

---

## 5 · Pantalla Usuario (perfil)

Datos del usuario logueado (desde la sesión cacheada) + entrada a configuración.

- **Header de perfil:** avatar (placeholder con ícono persona), `usuario.nombre`,
  `usuario.rol` (label del rol, ej. "Médico/a").
- **Fila "Configuración"** (ícono settings) → **placeholder** *"Editar perfil —
  próximamente"*. La edición real es feature futura aparte.
- **NO** tiene el acordeón de acciones (es solo perfil).
- **Logout:** vive acá (se saca del AppBar del `HomeScreen` viejo). →
  `sessionControllerProvider.cerrar()` + limpia el cache de Drift.

---

## 6 · Componentes nuevos del design system

En `lib/core/design_system/` (salvo utilidades), lenguaje violeta, testeables en aislamiento
y documentados en Widgetbook.

| Componente | Responsabilidad | API (esbozo) |
|---|---|---|
| `FloatingNavBar` | Píldora frosted flotante. Renderiza N items, maneja expandida/compacta animado. **No sabe de routing.** | `FloatingNavBar({items, selectedIndex, onTap, compacta})` |
| `NavItemData` (modelo) | Datos de un item: ícono outline, ícono filled, label, badge opcional. | `NavItemData({outlinedIcon, filledIcon, label, badgeCount})` |
| `NavBarBadge` | Puntito rojo con número. Se oculta si `count == 0`. Overflow `99+`. | `NavBarBadge({count})` |
| `ActionGroup` | Card-acordeón de una categoría: header + lista colapsable animada. | `ActionGroup({titulo, children, initiallyExpanded = true})` |
| `ActionTile` | Fila de acción: chip de color + ícono + label, tappable. | `ActionTile({color, icon, label, onTap})` |
| `EmptyState` | Estado vacío reutilizable (Acciones y Pendientes). | `EmptyState({icon, titulo, subtitulo})` |

**Dos utilidades (en `core`, no son widgets de DS):**
- `accionIcon(String name) → IconData` — mapa con fallback (§2c, invariante #2).
- `AppShell` — envuelve el `navigationShell` del `StatefulShellRoute`, pinta la
  `FloatingNavBar` y escucha el scroll para compactar.

**Separación clave (decisión consciente):** `FloatingNavBar` es **tonta** (no conoce
go_router → se documenta y testea sola en Widgetbook sin router); `AppShell` la conecta con
`StatefulShellRoute` y el scroll. La barra recibe `selectedIndex`/`onTap`/`compacta`; no los
calcula.

---

## 7 · Documentación en Widgetbook

Se suma al `widgetbook/main.dart` actual (manual, sin code-gen — se sigue el patrón
existente). Cada use-case envuelto en el `_frame()` con `AppTheme.light()`, sobre el
degradado violeta para que la barra frosted se vea en contexto.

- **`FloatingNavBar`:** `Expandida — Inicio activo` · `Expandida — Pendientes activo (badge 3)`
  · `Compacta — solo íconos` · `Sin badge (todo sincronizado)`
- **`ActionGroup`:** `Expandido (Salud, 4 acciones)` · `Colapsado`
- **`ActionTile`:** `Salud (verde)` · `Consentimiento (gris)`
- **`NavBarBadge`:** `1` · `9` · `99+`
- **`EmptyState`:** `Sin acciones` · `Todo sincronizado`

Da a Ramiro y Ale la galería viva de la barra y sus estados.

---

## 8 · Estrategia de testing (pirámide, TDD por componente)

- **Widget tests** de cada componente: `FloatingNavBar` (item activo resaltado/relleno,
  badge oculto en 0, compacta esconde labels), `ActionGroup` (toggle expande/colapsa),
  `ActionTile` (dispara `onTap`), `NavBarBadge` (oculto en 0, `99+` en overflow),
  `EmptyState`.
- **`accionIcon`:** cada nombre conocido → su `IconData`; un nombre **desconocido → el
  fallback** (resiliencia entre repos, invariante #2).
- **Agrupación por categoría:** función pura `List<Accion>` → grupos; respeta orden del
  server y orden de aparición de categorías.
- **`MeResponse.fromJson` extendido:** parsea las 8 claves de cada acción (no solo `name`);
  conserva el caso superusuario→email.
- **Caché Drift:** `sesionCacheada()` devuelve lo guardado tras login; arranque hidrata sin
  red; `meta.version` distinto reemplaza, igual no toca.
- **Navegación:** `StatefulShellRoute` cambia de branch y **preserva estado** (scroll de una
  pestaña se mantiene al volver).
- **`pendientesCountProvider`:** da 0 sin tablas de feature → badge oculto.
- **Invariante camelCase:** el test existente (`permisos_naming_test.dart`) sigue cubriendo
  que las claves de acción son camelCase.

---

## Fuera de alcance (diferido)

- Features destino reales (apto_físico y el wizard por etapas que reusa signup).
- "Reintentar" por ítem en error en Pendientes + disparar `sync_engine.ciclo()` desde la UI;
  la pantalla rica de Pendientes con la lista real.
- Edición real de perfil (la ruedita de settings es placeholder).
- El tercer/N-ésimo botón futuro de la barra (hoy 3 fijos).
- Sync en background real (WorkManager/BGTask) — ya estaba diferido en la fundación.
- ActionRegistry / server-driven UI — explícitamente **fuera** (invariante #1, §2).

---

## Estructura de archivos (esbozo)

```
lib/
  core/
    design_system/
      floating_nav_bar.dart      # FloatingNavBar + NavItemData
      nav_bar_badge.dart         # NavBarBadge
      action_group.dart          # ActionGroup (acordeón)
      action_tile.dart           # ActionTile
      empty_state.dart           # EmptyState
      icons/accion_icon.dart     # accionIcon(name) → IconData + fallback
    router/
      app_shell.dart             # AppShell (envuelve navigationShell + barra + scroll)
      app_router.dart            # + StatefulShellRoute (reemplaza /home)
    database/
      cached_session.dart        # tabla Drift cached_session
    session/
      entities.dart              # + Accion, Sesion.acciones
  features/
    acciones/presentation/acciones_screen.dart
    pendientes/presentation/pendientes_screen.dart
    usuario/presentation/usuario_screen.dart
    auth/data/dtos/me_response.dart          # parsea metadata completa
    auth/data/repositories/auth_repository_impl.dart  # cachea/hidrata /me en Drift
widgetbook/main.dart             # + use-cases de los componentes nuevos
```
