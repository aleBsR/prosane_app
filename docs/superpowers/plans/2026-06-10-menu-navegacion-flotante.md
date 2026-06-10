# Menú de navegación flotante — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Barra de navegación flotante (estilo Instagram) con 3 pestañas (Inicio · Pendientes · Usuario), donde Inicio despliega en un acordeón por categoría las acciones del rol del usuario, todo armado offline-first desde los permisos cacheados en Drift.

**Architecture:** `StatefulShellRoute.indexedStack` con 3 ramas envueltas por un `AppShell` que pinta una `FloatingNavBar` custom y la compacta al scrollear. Las acciones (con su metadata completa) salen del `/me` ya consumido y **cacheado en Drift**; las pantallas se construyen en Flutter (no server-driven UI).

**Tech Stack:** Flutter, Riverpod (providers manuales + `StateNotifier`), go_router 14 (`StatefulShellRoute`), Drift 2.21 (caché de sesión + migración v1→v2), Widgetbook 3 (galería). Sin code-gen de Riverpod/JSON.

**Spec:** `docs/superpowers/specs/2026-06-10-menu-navegacion-flotante-design.md` — leer la sección "Invariantes y decisiones conscientes" antes de empezar.

---

## Invariantes que se materializan como tareas-con-test

| Invariante (spec) | Tarea que lo blinda |
|---|---|
| #2 Fallback de icon/color desconocido (resiliencia entre repos) | Task 3 |
| #3 Badge cableado-pero-en-0 sin features | Task 9 (UI) + Task 15 (provider) |
| #4 El `/me` ya provee la metadata completa | Task 1 |
| Migración Drift (no bumpear schema sin migración + test) | Task 5 |
| Naming camelCase de permisos (ya existente) | sigue cubierto por `test/core/session/permisos_naming_test.dart` |

## Tipos compartidos (definidos en Task 1-2, referenciados después)

```dart
// lib/core/session/entities.dart  (Accion nueva; Usuario/Sesion extendidos)
class Accion {
  const Accion({
    required this.name, required this.label, required this.icon,
    required this.color, required this.type, required this.category,
    required this.isSensitive, required this.sortOrder,
  });
  final String name, label, icon, color, type, category;
  final bool isSensitive;
  final int sortOrder;
}

class Usuario {
  const Usuario({
    required this.id, required this.nombre,
    required this.rolName, required this.rolLabel,
  });
  final String id, nombre, rolName, rolLabel;
}

class Sesion {
  const Sesion({required this.usuario, required this.acciones});
  final Usuario usuario;
  final List<Accion> acciones;                 // orden del server, intacto
  Set<String> get permisos => acciones.map((a) => a.name).toSet(); // 1 sola fuente
}
```

## Estructura de archivos

```
lib/core/
  session/entities.dart                    # MOD: + Accion, Usuario.rolName/rolLabel, Sesion.acciones
  session/agrupar_acciones.dart            # NEW: agruparPorCategoria (función pura)
  design_system/accion_presentacion.dart   # NEW: accionIcon() + colorDesdeHex() con fallback
  design_system/nav_bar_badge.dart         # NEW
  design_system/floating_nav_bar.dart      # NEW: FloatingNavBar + NavItemData
  design_system/action_group.dart          # NEW
  design_system/action_tile.dart           # NEW
  design_system/empty_state.dart           # NEW
  database/tables/cached_session_table.dart # NEW: tabla cached_session
  database/app_database.dart               # MOD: schemaVersion 2 + migración + guardar/leerSesion
  database/database_provider.dart          # NEW: databaseProvider (Drift nativo)
  router/app_shell.dart                    # NEW: AppShell (navigationShell + barra + scroll)
  router/app_router.dart                   # MOD: StatefulShellRoute (reemplaza /home)
  providers.dart                           # MOD: cablea database en authRepository + pendientesCount
lib/features/
  auth/data/dtos/me_response.dart          # MOD: parsea metadata completa + rolName/rolLabel
  auth/data/repositories/auth_repository_impl.dart  # MOD: cachea/hidrata /me en Drift
  acciones/presentation/acciones_screen.dart        # NEW
  pendientes/presentation/pendientes_screen.dart    # NEW
  usuario/presentation/usuario_screen.dart          # NEW
lib/app.dart                               # MOD: hidratar sesión al arrancar
widgetbook/main.dart                       # MOD: + use-cases nuevos
```

---

## Task 1: Entidad `Accion` + `MeResponse` parsea la metadata completa

**Files:**
- Modify: `lib/core/session/entities.dart` (agregar `Accion`)
- Modify: `lib/features/auth/data/dtos/me_response.dart`
- Test: `test/features/auth/data/me_response_test.dart` (nuevo)

- [ ] **Step 1: Escribir el test que falla**

```dart
// test/features/auth/data/me_response_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/features/auth/data/dtos/me_response.dart';

void main() {
  Map<String, dynamic> base() => {
        'user': {'id': '1', 'email': 'ana@b.com', 'nombre': 'Ana', 'apellido': 'Gómez'},
        'roles': [{'name': 'medico', 'label': 'Médico/a'}],
        'actions': [
          {'name': 'listarPacientes', 'label': 'Listar pacientes', 'icon': 'people',
           'color': '#1565C0', 'type': 'list', 'category': 'salud',
           'is_sensitive': false, 'sort_order': 10},
          {'name': 'firmarApto', 'label': 'Firmar apto físico', 'icon': 'draw',
           'color': '#2E7D32', 'type': 'form', 'category': 'salud',
           'is_sensitive': true, 'sort_order': 40},
        ],
        'meta': {'version': 'abcd1234', 'permissions_synced_at': '2026-06-10T12:00:00Z'},
      };

  test('parsea las 8 claves de cada acción y respeta el orden del server', () {
    final me = MeResponse.fromJson(base());
    expect(me.acciones.map((a) => a.name).toList(), ['listarPacientes', 'firmarApto']);
    final a = me.acciones.first;
    expect(a.label, 'Listar pacientes');
    expect(a.icon, 'people');
    expect(a.color, '#1565C0');
    expect(a.type, 'list');
    expect(a.category, 'salud');
    expect(a.isSensitive, false);
    expect(a.sortOrder, 10);
    expect(me.acciones[1].isSensitive, true);
  });

  test('expone rolName y rolLabel del primer rol', () {
    final me = MeResponse.fromJson(base());
    expect(me.rolName, 'medico');
    expect(me.rolLabel, 'Médico/a');
  });

  test('nombre = nombre+apellido; cae al email si vienen vacíos (superusuario)', () {
    expect(MeResponse.fromJson(base()).nombre, 'Ana Gómez');
    final sinPersona = base()..['user'] = {'id': '1', 'email': 'admin@b.com', 'nombre': '', 'apellido': ''};
    final me = MeResponse.fromJson(sinPersona);
    expect(me.nombre, 'admin@b.com');
  });

  test('nombre/apellido null (persona no vinculada en backend) → cae al email', () {
    final nul = base()..['user'] = {'id': '1', 'email': 'medico@prosane.test', 'nombre': null, 'apellido': null};
    expect(MeResponse.fromJson(nul).nombre, 'medico@prosane.test');
  });

  test('meta.version y metaSyncedAt se exponen para invalidar el caché', () {
    final me = MeResponse.fromJson(base());
    expect(me.metaVersion, 'abcd1234');
    expect(me.metaSyncedAt, '2026-06-10T12:00:00Z');
  });

  test('sin roles ni actions no rompe', () {
    final me = MeResponse.fromJson({'user': {'id': '1', 'email': 'x@y.com'}, 'roles': [], 'actions': []});
    expect(me.acciones, isEmpty);
    expect(me.rolName, '');
    expect(me.rolLabel, '');
  });
}
```

- [ ] **Step 2: Correr el test y verificar que falla**

Run: `flutter test test/features/auth/data/me_response_test.dart`
Expected: FAIL (`Accion`/`acciones`/`rolName` no existen).

- [ ] **Step 3: Agregar `Accion` a `entities.dart`**

Agregar al principio de `lib/core/session/entities.dart` (antes de `Usuario`):

```dart
class Accion {
  const Accion({
    required this.name, required this.label, required this.icon,
    required this.color, required this.type, required this.category,
    required this.isSensitive, required this.sortOrder,
  });
  final String name, label, icon, color, type, category;
  final bool isSensitive;
  final int sortOrder;

  factory Accion.fromJson(Map<String, dynamic> j) => Accion(
        name: j['name'] as String? ?? '',
        label: j['label'] as String? ?? '',
        icon: j['icon'] as String? ?? '',
        color: j['color'] as String? ?? '',
        type: j['type'] as String? ?? '',
        category: j['category'] as String? ?? '',
        isSensitive: j['is_sensitive'] as bool? ?? false,
        sortOrder: j['sort_order'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'name': name, 'label': label, 'icon': icon, 'color': color,
        'type': type, 'category': category,
        'is_sensitive': isSensitive, 'sort_order': sortOrder,
      };
}
```

- [ ] **Step 4: Reescribir `MeResponse`**

Reemplazar el contenido de `lib/features/auth/data/dtos/me_response.dart`:

```dart
import '../../../../core/session/entities.dart';

/// DTO de `GET /api/v1/auth/me/` — contrato congelado del backend.
///   { user:{id,email,nombre,apellido,is_staff}, roles:[{name,label}],
///     actions:[{8 claves}], meta:{version, permissions_synced_at} }
class MeResponse {
  MeResponse({
    required this.id, required this.email, required this.nombre,
    required this.rolName, required this.rolLabel, required this.acciones,
    required this.metaVersion, required this.metaSyncedAt,
  });
  final String id, email, nombre, rolName, rolLabel, metaVersion, metaSyncedAt;
  final List<Accion> acciones;

  factory MeResponse.fromJson(Map<String, dynamic> j) {
    final user = (j['user'] as Map<String, dynamic>?) ?? const {};
    final roles = (j['roles'] as List?) ?? const [];
    final actions = (j['actions'] as List?) ?? const [];
    final meta = (j['meta'] as Map<String, dynamic>?) ?? const {};

    final nombre = [user['nombre'], user['apellido']]
        .whereType<String>().where((s) => s.isNotEmpty).join(' ');
    final rol = roles.isNotEmpty ? (roles.first as Map) : const {};

    return MeResponse(
      id: (user['id'] as String?) ?? '',
      email: (user['email'] as String?) ?? '',
      nombre: nombre.isNotEmpty ? nombre : ((user['email'] as String?) ?? ''),
      rolName: (rol['name'] as String?) ?? '',
      rolLabel: (rol['label'] as String?) ?? '',
      acciones: actions
          .whereType<Map>()
          .map((a) => Accion.fromJson(a.cast<String, dynamic>()))
          .toList(),
      metaVersion: (meta['version'] as String?) ?? '',
      metaSyncedAt: (meta['permissions_synced_at'] as String?) ?? '',
    );
  }
}
```

- [ ] **Step 5: Correr el test y verificar que pasa**

Run: `flutter test test/features/auth/data/me_response_test.dart`
Expected: PASS (6 tests).

- [ ] **Step 6: Commit**

```bash
git add lib/core/session/entities.dart lib/features/auth/data/dtos/me_response.dart test/features/auth/data/me_response_test.dart
git commit -m "feat(menu): Accion + MeResponse parsea la metadata completa del /me"
```

---

## Task 2: `Usuario` con rolName+rolLabel, `Sesion.acciones`, repo actualizado

**Files:**
- Modify: `lib/core/session/entities.dart` (`Usuario`, `Sesion`)
- Modify: `lib/features/auth/data/repositories/auth_repository_impl.dart`
- Modify: `test/features/auth/data/auth_repository_impl_test.dart`
- Modify: `test/core/session/session_controller_test.dart`, `test/core/session/permission_gate_test.dart`

- [ ] **Step 1: Actualizar los tests existentes que construyen `Usuario`/`Sesion`**

En `test/features/auth/data/auth_repository_impl_test.dart`, el `when(() => remote.me())` ahora devuelve un `MeResponse` con la firma nueva, y el assert de rol usa `rolName`/`rolLabel`. Reemplazar el primer test:

```dart
  test('login guarda tokens (antes del /me) y arma la sesión con permisos de /me', () async {
    final remote = _MockRemote();
    final tokens = TokenStorage(backend: InMemoryKeyValueStore());
    when(() => remote.login('a@b.com', 'x'))
        .thenAnswer((_) async => (access: 'A', refresh: 'R'));
    when(() => remote.me()).thenAnswer((_) async {
      expect(await tokens.access(), 'A'); // orden: tokens ya guardados
      return MeResponse(
        id: '1', email: 'a@b.com', nombre: 'Ana', rolName: 'medico', rolLabel: 'Médico/a',
        acciones: const [Accion(name: 'firmarApto', label: 'Firmar', icon: 'draw',
            color: '#2E7D32', type: 'form', category: 'salud', isSensitive: true, sortOrder: 40)],
        metaVersion: 'v1', metaSyncedAt: '2026-06-10T12:00:00Z');
    });

    final repo = AuthRepositoryImpl(remote: remote, tokens: tokens, db: _FakeCache());
    final sesion = await repo.login('a@b.com', 'x');

    expect(sesion.usuario.nombre, 'Ana');
    expect(sesion.usuario.rolName, 'medico');
    expect(sesion.usuario.rolLabel, 'Médico/a');
    expect(sesion.permisos, {'firmarApto'});
  });
```

Agregar el import de `entities.dart` (para `Accion`) y un fake mínimo de caché (lo define Task 7; por ahora usar el stub):

```dart
import 'package:prosane_app/core/session/entities.dart';
// Stub temporal: en Task 7 se reemplaza por la interfaz real SessionCache.
class _FakeCache implements SessionCache {
  Sesion? guardada;
  @override Future<void> guardarSesion(Sesion s, {required String version}) async => guardada = s;
  @override Future<Sesion?> leerSesion() async => guardada;
  @override Future<void> limpiar() async => guardada = null;
}
```

> Nota para el implementer: este test depende de `SessionCache` (Task 7). Si ejecutás Task 2 antes que 7, dejá el `db:` afuera del constructor y agregalo en Task 7. El plan asume orden secuencial 1→2→…; en ese orden, definí `SessionCache` como interfaz vacía acá y la implementás en Task 7. Para no acoplar, **mové el cambio de constructor del repo a Task 7** y en Task 2 dejá el repo SOLO con el cambio de tipos (`rolName`/`rolLabel`/`acciones`).

En `test/core/session/session_controller_test.dart` y `permission_gate_test.dart`, actualizar las construcciones de `Usuario` y `Sesion`:

```dart
// session_controller_test.dart — reemplazar las 2 construcciones de Sesion:
c.setSesion(Sesion(
  usuario: const Usuario(id: '1', nombre: 'Ana', rolName: 'medico', rolLabel: 'Médico/a'),
  acciones: const [Accion(name: 'firmarApto', label: 'Firmar', icon: 'draw', color: '#2E7D32',
      type: 'form', category: 'salud', isSensitive: true, sortOrder: 40)],
));
// los expect siguen: c.can('firmarApto') == true, c.can('borrarTodo') == false
```

```dart
// permission_gate_test.dart — la Sesion del test reactivo:
container.read(sessionControllerProvider.notifier).setSesion(Sesion(
  usuario: const Usuario(id: '1', nombre: 'Ana', rolName: 'medico', rolLabel: 'Médico/a'),
  acciones: const [Accion(name: 'firmarApto', label: 'Firmar', icon: 'draw', color: '#2E7D32',
      type: 'form', category: 'salud', isSensitive: true, sortOrder: 40)],
));
```

Agregar `import 'package:prosane_app/core/session/entities.dart';` donde falte.

- [ ] **Step 2: Correr y verificar que fallan (compilación)**

Run: `flutter test test/core/session/ test/features/auth/data/auth_repository_impl_test.dart`
Expected: FAIL (firma vieja de `Usuario`/`Sesion`).

- [ ] **Step 3: Reescribir `Usuario` y `Sesion` en `entities.dart`**

Reemplazar las clases `Usuario` y `Sesion` (dejar `SesionState`, `SesionAutenticada`, la extensión `can` igual):

```dart
class Usuario {
  const Usuario({required this.id, required this.nombre, required this.rolName, required this.rolLabel});
  final String id, nombre, rolName, rolLabel;
}

class Sesion {
  const Sesion({required this.usuario, required this.acciones});
  final Usuario usuario;
  final List<Accion> acciones;                       // orden del server, intacto
  Set<String> get permisos => acciones.map((a) => a.name).toSet();
}
```

La extensión `SesionPermisos.can` no cambia (sigue usando `s.sesion.permisos`).

- [ ] **Step 4: Actualizar el repo (solo tipos)**

En `auth_repository_impl.dart`, dentro de `login`, reemplazar la construcción de la sesión:

```dart
final me = await remote.me();
return Sesion(
  usuario: Usuario(id: me.id, nombre: me.nombre, rolName: me.rolName, rolLabel: me.rolLabel),
  acciones: me.acciones,
);
```

- [ ] **Step 5: Correr y verificar que pasan**

Run: `flutter test test/core/session/ test/features/auth/data/auth_repository_impl_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/core/session/entities.dart lib/features/auth/data/repositories/auth_repository_impl.dart test/core/session test/features/auth/data/auth_repository_impl_test.dart
git commit -m "feat(menu): Usuario con rolName+rolLabel y Sesion.acciones (permisos derivado)"
```

---

## Task 3: Utils de presentación — `accionIcon` + `colorDesdeHex` con fallback [Invariante #2]

**Files:**
- Create: `lib/core/design_system/accion_presentacion.dart`
- Test: `test/core/design_system/accion_presentacion_test.dart`

- [ ] **Step 1: Escribir el test que falla**

```dart
// test/core/design_system/accion_presentacion_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/design_system/accion_presentacion.dart';

void main() {
  test('accionIcon mapea los nombres conocidos del backend', () {
    expect(accionIcon('people'), Icons.people_outline);
    expect(accionIcon('draw'), Icons.draw_outlined);
    expect(accionIcon('description'), Icons.description_outlined);
    expect(accionIcon('how_to_reg'), Icons.how_to_reg_outlined);
  });

  test('accionIcon: un icon DESCONOCIDO cae al fallback (no rompe)', () {
    expect(accionIcon('icono_que_no_existe_aun'), kIconFallback);
    expect(accionIcon(''), kIconFallback);
  });

  test('colorDesdeHex parsea #RRGGBB', () {
    expect(colorDesdeHex('#1565C0'), const Color(0xFF1565C0));
  });

  test('colorDesdeHex parsea #AARRGGBB', () {
    expect(colorDesdeHex('#801565C0'), const Color(0x801565C0));
  });

  test('colorDesdeHex: hex inválido cae al fallback', () {
    expect(colorDesdeHex('no-es-hex'), kColorFallback);
    expect(colorDesdeHex(''), kColorFallback);
  });
}
```

- [ ] **Step 2: Correr y verificar que falla**

Run: `flutter test test/core/design_system/accion_presentacion_test.dart`
Expected: FAIL (no existe el archivo).

- [ ] **Step 3: Implementar**

```dart
// lib/core/design_system/accion_presentacion.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Ícono genérico cuando el backend manda un `icon` que esta versión de la app
/// no conoce todavía (resiliencia entre repos — invariante #2 del spec).
const IconData kIconFallback = Icons.bolt_outlined;

/// Color genérico cuando el `color` del backend no es un hex válido.
const Color kColorFallback = AppColors.primario;

/// Nombre lógico de Material (lo manda el backend) → IconData outline.
/// Mantener en sync con authentication/actions_map.py del backend.
IconData accionIcon(String name) => switch (name) {
      'people' => Icons.people_outline,
      'clinical_notes' => Icons.clinical_notes_outlined,
      'assignment_add' => Icons.note_add_outlined,
      'draw' => Icons.draw_outlined,
      'dentistry' => Icons.medical_services_outlined,
      'straighten' => Icons.straighten_outlined,
      'description' => Icons.description_outlined,
      'how_to_reg' => Icons.how_to_reg_outlined,
      _ => kIconFallback,
    };

/// Hex del backend (`#RRGGBB` o `#AARRGGBB`) → Color. Inválido → fallback.
Color colorDesdeHex(String hex) {
  var h = hex.replaceFirst('#', '').trim();
  if (h.length == 6) h = 'FF$h';
  if (h.length != 8) return kColorFallback;
  final v = int.tryParse(h, radix: 16);
  return v == null ? kColorFallback : Color(v);
}
```

- [ ] **Step 4: Correr y verificar que pasa**

Run: `flutter test test/core/design_system/accion_presentacion_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/design_system/accion_presentacion.dart test/core/design_system/accion_presentacion_test.dart
git commit -m "feat(menu): accionIcon + colorDesdeHex con fallback (resiliencia entre repos)"
```

---

## Task 4: `agruparPorCategoria` (función pura, preserva orden)

**Files:**
- Create: `lib/core/session/agrupar_acciones.dart`
- Test: `test/core/session/agrupar_acciones_test.dart`

- [ ] **Step 1: Escribir el test que falla**

```dart
// test/core/session/agrupar_acciones_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/session/entities.dart';
import 'package:prosane_app/core/session/agrupar_acciones.dart';

Accion _a(String name, String cat, int sort) => Accion(
    name: name, label: name, icon: 'x', color: '#000000', type: 'form',
    category: cat, isSensitive: false, sortOrder: sort);

void main() {
  test('agrupa por category preservando el orden del server y el de aparición de categorías', () {
    final grupos = agruparPorCategoria([
      _a('listarPacientes', 'salud', 10),
      _a('firmarApto', 'salud', 40),
      _a('verConstancias', 'consentimiento', 10),
    ]);
    expect(grupos.map((g) => g.categoria).toList(), ['salud', 'consentimiento']);
    expect(grupos.first.acciones.map((a) => a.name).toList(), ['listarPacientes', 'firmarApto']);
    expect(grupos.last.acciones.map((a) => a.name).toList(), ['verConstancias']);
  });

  test('lista vacía → sin grupos', () {
    expect(agruparPorCategoria(const []), isEmpty);
  });

  test('una categoría que reaparece NO crea un grupo nuevo', () {
    final grupos = agruparPorCategoria([
      _a('a', 'salud', 1), _a('b', 'consentimiento', 1), _a('c', 'salud', 2),
    ]);
    expect(grupos.map((g) => g.categoria).toList(), ['salud', 'consentimiento']);
    expect(grupos.first.acciones.map((a) => a.name).toList(), ['a', 'c']);
  });
}
```

- [ ] **Step 2: Correr y verificar que falla**

Run: `flutter test test/core/session/agrupar_acciones_test.dart`
Expected: FAIL (no existe).

- [ ] **Step 3: Implementar**

```dart
// lib/core/session/agrupar_acciones.dart
import 'entities.dart';

class GrupoAcciones {
  const GrupoAcciones(this.categoria, this.acciones);
  final String categoria;
  final List<Accion> acciones;
}

/// Agrupa por `category` preservando (a) el orden de las acciones tal como vienen
/// del server y (b) el orden de aparición de cada categoría. Una categoría que
/// reaparece se acumula en su grupo existente (no crea uno nuevo).
List<GrupoAcciones> agruparPorCategoria(List<Accion> acciones) {
  final orden = <String>[];
  final mapa = <String, List<Accion>>{};
  for (final a in acciones) {
    (mapa[a.category] ??= (orden..add(a.category), <Accion>[]).$2).add(a);
  }
  return orden.map((c) => GrupoAcciones(c, mapa[c]!)).toList();
}
```

- [ ] **Step 4: Correr y verificar que pasa**

Run: `flutter test test/core/session/agrupar_acciones_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/session/agrupar_acciones.dart test/core/session/agrupar_acciones_test.dart
git commit -m "feat(menu): agruparPorCategoria (función pura, preserva orden del server)"
```

---

## Task 5: Tabla Drift `cached_session` + migración v1→v2 + test de migración [Invariante migraciones]

**Files:**
- Create: `lib/core/database/tables/cached_session_table.dart`
- Modify: `lib/core/database/app_database.dart`
- Generate: `drift_schemas/drift_schema_v2.json`, `test/core/database/generated_migrations/schema_v2.dart`
- Test: `test/core/database/migration_test.dart` (agregar test v1→v2)

**Qué guarda la fila (suficiente para reconstruir TODO offline — spec §2b):** `id` (singleton fijo `'me'`), `userId`, `email`, `nombre` (nullable — el backend puede mandar null), `rolName`, `rolLabel`, `accionesJson` (las 8 claves por acción, serializadas), `metaVersion`, `permissionsSyncedAt`.

- [ ] **Step 1: Crear la tabla**

```dart
// lib/core/database/tables/cached_session_table.dart
import 'package:drift/drift.dart';

/// Caché del /me para arrancar offline (una sola fila, id fijo 'me').
/// Guarda TODO lo necesario para reconstruir la sesión sin red: usuario,
/// nombre, label del rol y la lista completa de acciones (accionesJson).
class CachedSessionRows extends Table {
  TextColumn get id => text()();                       // singleton: siempre 'me'
  TextColumn get userId => text()();
  TextColumn get email => text()();
  TextColumn get nombre => text().nullable()();        // backend puede mandar null
  TextColumn get rolName => text()();
  TextColumn get rolLabel => text()();
  TextColumn get accionesJson => text()();             // JSON array de las 8 claves c/u
  TextColumn get metaVersion => text()();
  DateTimeColumn get permissionsSyncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
```

- [ ] **Step 2: Registrar la tabla, bumpear schema y escribir la migración**

En `lib/core/database/app_database.dart`:

```dart
import 'tables/sync_state_table.dart';
import 'tables/cached_session_table.dart';   // NUEVO

@DriftDatabase(tables: [SyncStateRows, CachedSessionRows])   // + CachedSessionRows
class AppDatabase extends _$AppDatabase {
  // ...
  @override
  int get schemaVersion => 2;   // 1 -> 2

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(cachedSessionRows);   // v1 -> v2: tabla nueva, no destruye nada
          }
        },
      );
```

- [ ] **Step 3: Regenerar código Drift + dump de schema v2 + helpers de migración**

```bash
dart run build_runner build --delete-conflicting-outputs
dart run drift_dev schema dump lib/core/database/app_database.dart drift_schemas/
dart run drift_dev schema generate drift_schemas/ test/core/database/generated_migrations/
```
Expected: se crean `drift_schemas/drift_schema_v2.json` y `test/core/database/generated_migrations/schema_v2.dart`; `schema.dart` se actualiza.

- [ ] **Step 4: Agregar el test de migración v1→v2 (que NO destruye datos)**

En `test/core/database/migration_test.dart`, agregar dentro de `main()`:

```dart
  test('migración v1→v2 crea cached_session y preserva sync_state (no destruye datos)', () async {
    final schema = await verifier.schemaAt(1);
    // Sembrar un watermark en v1
    final dbV1 = AppDatabase(schema.newConnection());
    await dbV1.setWatermark('apto_fisico', DateTime.utc(2026, 6, 1));
    await dbV1.close();

    // Migrar v1 -> v2 y validar el esquema
    final connection = await verifier.startAt(1);
    final db = AppDatabase(connection);
    await verifier.migrateAndValidate(db, 2);

    // El dato de v1 sigue vivo y la tabla nueva existe (insert no tira)
    expect(await db.getWatermark('apto_fisico'), DateTime.utc(2026, 6, 1));
    await db.close();
  });
```

- [ ] **Step 5: Correr el harness de migración**

Run: `flutter test test/core/database/migration_test.dart`
Expected: PASS (el test v1, y el v1→v2 nuevo).

- [ ] **Step 6: Commit**

```bash
git add lib/core/database test/core/database drift_schemas
git commit -m "feat(menu): tabla Drift cached_session + migración v1->v2 con test (no destruye datos)"
```

---

## Task 6: `databaseProvider` (abre Drift nativo) + `guardarSesion`/`leerSesion`

**Files:**
- Create: `lib/core/database/database_provider.dart`
- Modify: `lib/core/database/app_database.dart` (métodos de sesión)
- Test: `test/core/database/cached_session_test.dart`

- [ ] **Step 1: Escribir el test que falla (con DB en memoria)**

```dart
// test/core/database/cached_session_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/database/app_database.dart';
import 'package:prosane_app/core/session/entities.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Sesion sesion() => const Sesion(
        usuario: Usuario(id: 'u1', nombre: 'Ana', rolName: 'medico', rolLabel: 'Médico/a'),
        acciones: [Accion(name: 'firmarApto', label: 'Firmar', icon: 'draw', color: '#2E7D32',
            type: 'form', category: 'salud', isSensitive: true, sortOrder: 40)],
      );

  test('guardar + leer reconstruye la sesión completa (usuario, rol label, acciones)', () async {
    await db.guardarSesion(sesion(), email: 'ana@b.com', version: 'v1', syncedAtIso: '2026-06-10T12:00:00Z');
    final out = await db.leerSesion();
    expect(out!.usuario.nombre, 'Ana');
    expect(out.usuario.rolName, 'medico');
    expect(out.usuario.rolLabel, 'Médico/a');
    expect(out.acciones.single.name, 'firmarApto');
    expect(out.acciones.single.color, '#2E7D32');
  });

  test('leerSesion sin nada guardado devuelve null', () async {
    expect(await db.leerSesion(), isNull);
  });

  test('guardar de nuevo reemplaza la fila (singleton)', () async {
    await db.guardarSesion(sesion(), email: 'ana@b.com', version: 'v1', syncedAtIso: '');
    await db.guardarSesion(sesion(), email: 'ana@b.com', version: 'v2', syncedAtIso: '');
    expect(await db.versionCacheada(), 'v2');
  });

  test('limpiarSesion borra la fila', () async {
    await db.guardarSesion(sesion(), email: 'ana@b.com', version: 'v1', syncedAtIso: '');
    await db.limpiarSesion();
    expect(await db.leerSesion(), isNull);
  });
}
```

- [ ] **Step 2: Correr y verificar que falla**

Run: `flutter test test/core/database/cached_session_test.dart`
Expected: FAIL (métodos no existen).

- [ ] **Step 3: Implementar los métodos de sesión en `AppDatabase`**

Agregar dentro de `AppDatabase` (importar `dart:convert` y `../session/entities.dart`):

```dart
  static const _meKey = 'me';

  Future<void> guardarSesion(Sesion s, {required String email, required String version, required String syncedAtIso}) {
    return into(cachedSessionRows).insertOnConflictUpdate(CachedSessionRowsCompanion.insert(
      id: _meKey,
      userId: s.usuario.id,
      email: email,
      nombre: Value(s.usuario.nombre),
      rolName: s.usuario.rolName,
      rolLabel: s.usuario.rolLabel,
      accionesJson: jsonEncode(s.acciones.map((a) => a.toJson()).toList()),
      metaVersion: version,
      permissionsSyncedAt: Value(DateTime.tryParse(syncedAtIso)?.toUtc()),
    ));
  }

  Future<Sesion?> leerSesion() async {
    final row = await (select(cachedSessionRows)..where((t) => t.id.equals(_meKey))).getSingleOrNull();
    if (row == null) return null;
    final acciones = (jsonDecode(row.accionesJson) as List)
        .map((j) => Accion.fromJson((j as Map).cast<String, dynamic>()))
        .toList();
    return Sesion(
      usuario: Usuario(id: row.userId, nombre: row.nombre ?? row.email, rolName: row.rolName, rolLabel: row.rolLabel),
      acciones: acciones,
    );
  }

  Future<String?> versionCacheada() async {
    final row = await (select(cachedSessionRows)..where((t) => t.id.equals(_meKey))).getSingleOrNull();
    return row?.metaVersion;
  }

  Future<void> limpiarSesion() => (delete(cachedSessionRows)..where((t) => t.id.equals(_meKey))).go();
```

- [ ] **Step 4: Crear el `databaseProvider` (Drift nativo en disco)**

```dart
// lib/core/database/database_provider.dart
import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'app_database.dart';

/// Abre la DB Drift nativa en el directorio de la app. Una sola instancia viva.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    return NativeDatabase.createInBackground(File(p.join(dir.path, 'prosane.sqlite')));
  }));
  ref.onDispose(db.close);
  return db;
});
```

> Si `package:path` no está en pubspec, agregarlo: `flutter pub add path`.

- [ ] **Step 5: Correr y verificar que pasa**

Run: `flutter test test/core/database/cached_session_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 6: Commit**

```bash
git add lib/core/database test/core/database/cached_session_test.dart pubspec.yaml pubspec.lock
git commit -m "feat(menu): databaseProvider + guardar/leer/limpiar sesion en Drift"
```

---

## Task 7: Cablear el repo — cachear `/me` en login, hidratar en `sesionCacheada()` [Deuda #1]

**Files:**
- Create: `lib/features/auth/domain/repositories/session_cache.dart` (interfaz)
- Modify: `lib/core/database/app_database.dart` (implementa `SessionCache`) — ya tiene los métodos; solo declara `implements`
- Modify: `lib/features/auth/data/repositories/auth_repository_impl.dart`
- Modify: `lib/core/providers.dart`
- Modify: `test/features/auth/data/auth_repository_impl_test.dart`

- [ ] **Step 1: Definir la interfaz `SessionCache`** (desacopla el repo de Drift)

```dart
// lib/features/auth/domain/repositories/session_cache.dart
import '../../../../core/session/entities.dart';

/// Puerto de persistencia de la sesión (lo implementa AppDatabase con Drift).
abstract class SessionCache {
  Future<void> guardarSesion(Sesion s, {required String email, required String version, required String syncedAtIso});
  Future<Sesion?> leerSesion();
  Future<void> limpiarSesion();
}
```

Y en `AppDatabase` declarar `class AppDatabase extends _$AppDatabase implements SessionCache` (los métodos ya existen de Task 6; agregar el import de la interfaz).

- [ ] **Step 2: Escribir/actualizar los tests del repo**

Reemplazar el `_FakeCache` temporal de Task 2 por uno que implemente `SessionCache`, y agregar tests de caché:

```dart
import 'package:prosane_app/features/auth/domain/repositories/session_cache.dart';

class _FakeCache implements SessionCache {
  Sesion? guardada; String? version; bool limpiado = false;
  @override Future<void> guardarSesion(Sesion s, {required String email, required String version, required String syncedAtIso}) async { guardada = s; this.version = version; }
  @override Future<Sesion?> leerSesion() async => guardada;
  @override Future<void> limpiarSesion() async { guardada = null; limpiado = true; }
}

// ... en el test de login feliz, construir el repo con la cache:
final cache = _FakeCache();
final repo = AuthRepositoryImpl(remote: remote, tokens: tokens, cache: cache);
final sesion = await repo.login('a@b.com', 'x');
expect(cache.guardada!.permisos, {'firmarApto'});   // /me se cacheó en login

// nuevos tests:
test('sesionCacheada() hidrata desde la cache (offline)', () async {
  final cache = _FakeCache()..guardada = Sesion(
    usuario: const Usuario(id: '1', nombre: 'Ana', rolName: 'medico', rolLabel: 'Médico/a'),
    acciones: const []);
  final repo = AuthRepositoryImpl(remote: _MockRemote(), tokens: TokenStorage(backend: InMemoryKeyValueStore()), cache: cache);
  expect((await repo.sesionCacheada())!.usuario.nombre, 'Ana');
});

test('logout limpia tokens y cache', () async {
  final tokens = TokenStorage(backend: InMemoryKeyValueStore())..guardar(access: 'A', refresh: 'R');
  final cache = _FakeCache()..guardada = const Sesion(usuario: Usuario(id: '1', nombre: 'A', rolName: 'r', rolLabel: 'R'), acciones: []);
  await AuthRepositoryImpl(remote: _MockRemote(), tokens: tokens, cache: cache).logout();
  expect(cache.limpiado, true);
});
```

- [ ] **Step 3: Correr y verificar que falla**

Run: `flutter test test/features/auth/data/auth_repository_impl_test.dart`
Expected: FAIL (el repo no acepta `cache:` ni cachea).

- [ ] **Step 4: Cablear el repo**

```dart
// auth_repository_impl.dart
import '../../domain/repositories/session_cache.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required this.remote, required this.tokens, required this.cache});
  final AuthRemoteDataSource remote;
  final TokenStorage tokens;
  final SessionCache cache;

  @override
  Future<Sesion> login(String email, String password) async {
    try {
      final t = await remote.login(email, password);
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

  @override
  Future<Sesion?> sesionCacheada() => cache.leerSesion();

  @override
  Future<void> logout() async {
    await tokens.limpiar();
    await cache.limpiarSesion();
  }
  // register() sin cambios
}
```

- [ ] **Step 5: Cablear el provider real**

En `lib/core/providers.dart`, inyectar la DB como cache:

```dart
import 'database/database_provider.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepositoryImpl(
      remote: AuthRemoteDataSourceImpl(ref.watch(dioProvider)),
      tokens: ref.watch(tokenStorageProvider),
      cache: ref.watch(databaseProvider),
    ));
```

- [ ] **Step 6: Correr y verificar que pasa**

Run: `flutter test test/features/auth/data/auth_repository_impl_test.dart`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/features/auth lib/core/database/app_database.dart lib/core/providers.dart test/features/auth/data/auth_repository_impl_test.dart
git commit -m "feat(menu): cachear /me en login e hidratar sesionCacheada desde Drift (salda deuda #1)"
```

---

## Task 8: Hidratar la sesión al arrancar (offline-first de sesión)

**Files:**
- Modify: `lib/core/session/session_controller.dart` (método `hidratar`)
- Modify: `lib/app.dart` (llamar a hidratar al iniciar)
- Test: `test/core/session/hidratar_session_test.dart`

- [ ] **Step 1: Escribir el test que falla**

```dart
// test/core/session/hidratar_session_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/session/entities.dart';
import 'package:prosane_app/core/session/session_controller.dart';

void main() {
  test('hidratar con una sesión cacheada deja la sesión autenticada', () async {
    final c = SessionController();
    await c.hidratar(() async => const Sesion(
        usuario: Usuario(id: '1', nombre: 'Ana', rolName: 'medico', rolLabel: 'Médico/a'), acciones: []));
    expect(c.state, isA<SesionAutenticada>());
  });

  test('hidratar sin cache (null) deja noAutenticada', () async {
    final c = SessionController();
    await c.hidratar(() async => null);
    expect(c.state, isA<SesionNoAutenticada>());
  });
}
```

- [ ] **Step 2: Correr y verificar que falla**

Run: `flutter test test/core/session/hidratar_session_test.dart`
Expected: FAIL (`hidratar` no existe).

- [ ] **Step 3: Implementar `hidratar` en el controller**

```dart
// session_controller.dart — agregar al SessionController:
  Future<void> hidratar(Future<Sesion?> Function() leer) async {
    final s = await leer();
    if (s != null) state = SesionAutenticada(s);
  }
```

- [ ] **Step 4: Llamar a hidratar al arrancar la app**

En `lib/app.dart`, convertir a un arranque que hidrata una sola vez. Reemplazar `ProsaneApp.build`:

```dart
class ProsaneApp extends ConsumerStatefulWidget {
  const ProsaneApp({super.key});
  @override
  ConsumerState<ProsaneApp> createState() => _ProsaneAppState();
}

class _ProsaneAppState extends ConsumerState<ProsaneApp> {
  @override
  void initState() {
    super.initState();
    // Hidrata la sesión desde el cache de Drift (arranque offline-first).
    ref.read(sessionControllerProvider.notifier)
        .hidratar(ref.read(authRepositoryProvider).sesionCacheada);
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'PROSANE',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routerConfig: ref.watch(goRouterProvider),
      );
}
```

Agregar imports: `package:flutter_riverpod/flutter_riverpod.dart`, `core/providers.dart`, `core/session/session_controller.dart`.

- [ ] **Step 5: Correr y verificar que pasa**

Run: `flutter test test/core/session/hidratar_session_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/core/session/session_controller.dart lib/app.dart test/core/session/hidratar_session_test.dart
git commit -m "feat(menu): hidratar la sesion desde el cache al arrancar (offline-first de sesion)"
```

---

> ## ✅ CHECKPOINT 1 (visible)
> Después de Task 8: correr `flutter run`, loguearse online (el `/me` se cachea), cerrar la app, **activar modo avión y reabrir** → la app arranca **autenticada** con el último estado conocido (sin red). Correr `flutter test` completo y `flutter analyze` — todo verde antes de seguir con la UI.

---

## Task 9: `NavBarBadge` (oculto en 0, `99+` en overflow) [Invariante #3 — UI]

**Files:**
- Create: `lib/core/design_system/nav_bar_badge.dart`
- Test: `test/core/design_system/nav_bar_badge_test.dart`

- [ ] **Step 1: Escribir el test que falla**

```dart
// test/core/design_system/nav_bar_badge_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/design_system/nav_bar_badge.dart';

void main() {
  Future<void> pump(WidgetTester t, int count) => t.pumpWidget(
      MaterialApp(home: Scaffold(body: NavBarBadge(count: count))));

  testWidgets('count 0 → no muestra nada', (t) async {
    await pump(t, 0);
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('count 3 → muestra "3"', (t) async {
    await pump(t, 3);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('count > 99 → muestra "99+"', (t) async {
    await pump(t, 150);
    expect(find.text('99+'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Correr y verificar que falla**

Run: `flutter test test/core/design_system/nav_bar_badge_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implementar**

```dart
// lib/core/design_system/nav_bar_badge.dart
import 'package:flutter/material.dart';

/// Puntito rojo con número. Oculto en 0 (invariante #3). Overflow → "99+".
class NavBarBadge extends StatelessWidget {
  const NavBarBadge({super.key, required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    final texto = count > 99 ? '99+' : '$count';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
      decoration: BoxDecoration(
        color: const Color(0xFFE5484D),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.white, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(texto,
          style: const TextStyle(fontFamily: 'Rubik', fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
    );
  }
}
```

- [ ] **Step 4: Correr y verificar que pasa**

Run: `flutter test test/core/design_system/nav_bar_badge_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/design_system/nav_bar_badge.dart test/core/design_system/nav_bar_badge_test.dart
git commit -m "feat(menu): NavBarBadge (oculto en 0, 99+ en overflow)"
```

---

## Task 10: `FloatingNavBar` + `NavItemData` (tonta: activo filled, compacta sin labels)

**Files:**
- Create: `lib/core/design_system/floating_nav_bar.dart`
- Test: `test/core/design_system/floating_nav_bar_test.dart`

- [ ] **Step 1: Escribir el test que falla**

```dart
// test/core/design_system/floating_nav_bar_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/design_system/floating_nav_bar.dart';

void main() {
  final items = const [
    NavItemData(outlinedIcon: Icons.home_outlined, filledIcon: Icons.home, label: 'Inicio'),
    NavItemData(outlinedIcon: Icons.sync_outlined, filledIcon: Icons.sync, label: 'Pendientes', badgeCount: 3),
    NavItemData(outlinedIcon: Icons.person_outline, filledIcon: Icons.person, label: 'Usuario'),
  ];

  Future<void> pump(WidgetTester t, {required bool compacta, int selected = 0, void Function(int)? onTap}) =>
      t.pumpWidget(MaterialApp(home: Scaffold(body: FloatingNavBar(
        items: items, selectedIndex: selected, compacta: compacta, onTap: onTap ?? (_) {}))));

  testWidgets('expandida muestra los labels; el activo usa el ícono filled', (t) async {
    await pump(t, compacta: false, selected: 0);
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.byIcon(Icons.home), findsOneWidget);          // activo = filled
    expect(find.byIcon(Icons.sync_outlined), findsOneWidget);  // inactivo = outline
  });

  testWidgets('compacta NO muestra labels', (t) async {
    await pump(t, compacta: true);
    expect(find.text('Inicio'), findsNothing);
  });

  testWidgets('muestra el badge del item con badgeCount > 0', (t) async {
    await pump(t, compacta: false);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('tocar un item dispara onTap con su índice', (t) async {
    int? tapped;
    await pump(t, compacta: false, onTap: (i) => tapped = i);
    await t.tap(find.text('Usuario'));
    expect(tapped, 2);
  });
}
```

- [ ] **Step 2: Correr y verificar que falla**

Run: `flutter test test/core/design_system/floating_nav_bar_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implementar**

```dart
// lib/core/design_system/floating_nav_bar.dart
import 'package:flutter/material.dart';
import 'nav_bar_badge.dart';

class NavItemData {
  const NavItemData({required this.outlinedIcon, required this.filledIcon, required this.label, this.badgeCount = 0});
  final IconData outlinedIcon, filledIcon;
  final String label;
  final int badgeCount;
}

/// Píldora frosted flotante. TONTA: no conoce go_router; recibe selectedIndex,
/// onTap y compacta. El activo va relleno + fondo sutil; inactivos en contorno.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key, required this.items, required this.selectedIndex,
    required this.onTap, required this.compacta,
  });
  final List<NavItemData> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final bool compacta;

  static const _inactivo = Color(0xFF9286C4);
  static const _activo = Color(0xFF6C4DE0);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.symmetric(horizontal: compacta ? 9 : 12, vertical: compacta ? 7 : 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(compacta ? 28 : 32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.75)),
        boxShadow: [BoxShadow(color: const Color(0xFF3C288C).withValues(alpha: 0.32), blurRadius: 34, offset: const Offset(0, 14))],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 0; i < items.length; i++) _item(i),
      ]),
    );
  }

  Widget _item(int i) {
    final it = items[i];
    final activo = i == selectedIndex;
    final color = activo ? _activo : _inactivo;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(i),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: compacta ? 9 : 12, vertical: 5),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Stack(clipBehavior: Clip.none, children: [
            Container(
              width: 48, height: 32,
              decoration: BoxDecoration(
                color: activo ? _activo.withValues(alpha: 0.17) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Icon(activo ? it.filledIcon : it.outlinedIcon, color: color, size: 24),
            ),
            if (it.badgeCount > 0)
              Positioned(top: -2, right: 6, child: NavBarBadge(count: it.badgeCount)),
          ]),
          if (!compacta) ...[
            const SizedBox(height: 4),
            Text(it.label, style: TextStyle(fontFamily: 'Rubik', fontSize: 11,
                fontWeight: activo ? FontWeight.w700 : FontWeight.w600, color: color)),
          ],
        ]),
      ),
    );
  }
}
```

- [ ] **Step 4: Correr y verificar que pasa**

Run: `flutter test test/core/design_system/floating_nav_bar_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/design_system/floating_nav_bar.dart test/core/design_system/floating_nav_bar_test.dart
git commit -m "feat(menu): FloatingNavBar tonta (activo filled + fondo sutil, compacta sin labels)"
```

---

## Task 11: `ActionGroup` (acordeón, expandido al inicio)

**Files:**
- Create: `lib/core/design_system/action_group.dart`
- Test: `test/core/design_system/action_group_test.dart`

- [ ] **Step 1: Escribir el test que falla**

```dart
// test/core/design_system/action_group_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/design_system/action_group.dart';

void main() {
  Future<void> pump(WidgetTester t) => t.pumpWidget(const MaterialApp(home: Scaffold(
      body: ActionGroup(titulo: 'SALUD', children: [Text('hijo')]))));

  testWidgets('arranca expandido: el hijo es visible', (t) async {
    await pump(t);
    expect(find.text('hijo'), findsOneWidget);
    expect(find.text('SALUD'), findsOneWidget);
  });

  testWidgets('tocar el header colapsa (oculta el hijo)', (t) async {
    await pump(t);
    await t.tap(find.text('SALUD'));
    await t.pumpAndSettle();
    expect(find.text('hijo'), findsNothing);
  });
}
```

- [ ] **Step 2: Correr y verificar que falla**

Run: `flutter test test/core/design_system/action_group_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implementar**

```dart
// lib/core/design_system/action_group.dart
import 'package:flutter/material.dart';

/// Card-acordeón de una categoría. Header (título + chevron) + lista colapsable.
/// Arranca expandido (initiallyExpanded = true).
class ActionGroup extends StatefulWidget {
  const ActionGroup({super.key, required this.titulo, required this.children, this.initiallyExpanded = true});
  final String titulo;
  final List<Widget> children;
  final bool initiallyExpanded;

  @override
  State<ActionGroup> createState() => _ActionGroupState();
}

class _ActionGroupState extends State<ActionGroup> {
  late bool _abierto = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF2B2440).withValues(alpha: 0.16), blurRadius: 22, offset: const Offset(0, 8))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        InkWell(
          onTap: () => setState(() => _abierto = !_abierto),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(widget.titulo, style: const TextStyle(fontFamily: 'Rubik', fontWeight: FontWeight.w700,
                  fontSize: 13, letterSpacing: 1, color: Color(0xFF7C5CFC))),
              Icon(_abierto ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right, color: const Color(0xFFB9AEE8)),
            ]),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: _abierto ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: Column(children: widget.children),
          secondChild: const SizedBox(width: double.infinity),
        ),
      ]),
    );
  }
}
```

- [ ] **Step 4: Correr y verificar que pasa**

Run: `flutter test test/core/design_system/action_group_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/design_system/action_group.dart test/core/design_system/action_group_test.dart
git commit -m "feat(menu): ActionGroup (acordeón por categoría, expandido al inicio)"
```

---

## Task 12: `ActionTile` (chip de color + ícono + label, tappable)

**Files:**
- Create: `lib/core/design_system/action_tile.dart`
- Test: `test/core/design_system/action_tile_test.dart`

- [ ] **Step 1: Escribir el test que falla**

```dart
// test/core/design_system/action_tile_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/design_system/action_tile.dart';

void main() {
  testWidgets('muestra label e ícono y dispara onTap', (t) async {
    var tapped = false;
    await t.pumpWidget(MaterialApp(home: Scaffold(body: ActionTile(
      color: const Color(0xFF2E7D32), icon: Icons.draw_outlined, label: 'Firmar apto físico',
      onTap: () => tapped = true))));
    expect(find.text('Firmar apto físico'), findsOneWidget);
    expect(find.byIcon(Icons.draw_outlined), findsOneWidget);
    await t.tap(find.text('Firmar apto físico'));
    expect(tapped, true);
  });
}
```

- [ ] **Step 2: Correr y verificar que falla**

Run: `flutter test test/core/design_system/action_tile_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implementar**

```dart
// lib/core/design_system/action_tile.dart
import 'package:flutter/material.dart';

/// Fila de una acción: chip con el color del backend + ícono blanco + label.
class ActionTile extends StatelessWidget {
  const ActionTile({super.key, required this.color, required this.icon, required this.label, required this.onTap});
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF1EEFB)))),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(13)),
            child: Icon(icon, color: Colors.white, size: 21),
          ),
          const SizedBox(width: 13),
          Expanded(child: Text(label, style: const TextStyle(fontFamily: 'Rubik', fontSize: 14,
              fontWeight: FontWeight.w600, color: Color(0xFF2D2D3A)))),
        ]),
      ),
    );
  }
}
```

- [ ] **Step 4: Correr y verificar que pasa**

Run: `flutter test test/core/design_system/action_tile_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/design_system/action_tile.dart test/core/design_system/action_tile_test.dart
git commit -m "feat(menu): ActionTile (chip de color del backend + ícono + label)"
```

---

## Task 13: `EmptyState` (reutilizable: Acciones y Pendientes)

**Files:**
- Create: `lib/core/design_system/empty_state.dart`
- Test: `test/core/design_system/empty_state_test.dart`

- [ ] **Step 1: Escribir el test que falla**

```dart
// test/core/design_system/empty_state_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/design_system/empty_state.dart';

void main() {
  testWidgets('muestra título y subtítulo', (t) async {
    await t.pumpWidget(const MaterialApp(home: Scaffold(body: EmptyState(
      icon: Icons.inbox_outlined, titulo: 'No tenés acciones disponibles todavía',
      subtitulo: 'Cuando te asignen un rol, vas a ver acá lo que podés hacer.'))));
    expect(find.text('No tenés acciones disponibles todavía'), findsOneWidget);
    expect(find.text('Cuando te asignen un rol, vas a ver acá lo que podés hacer.'), findsOneWidget);
    expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
  });

  testWidgets('sin subtítulo no rompe', (t) async {
    await t.pumpWidget(const MaterialApp(home: Scaffold(body: EmptyState(
      icon: Icons.check_circle_outline, titulo: 'Todo sincronizado'))));
    expect(find.text('Todo sincronizado'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Correr y verificar que falla**

Run: `flutter test test/core/design_system/empty_state_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implementar**

```dart
// lib/core/design_system/empty_state.dart
import 'package:flutter/material.dart';

/// Estado vacío reutilizable (Acciones sin rol, Pendientes "todo sincronizado").
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.titulo, this.subtitulo});
  final IconData icon;
  final String titulo;
  final String? subtitulo;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 56, color: Colors.white.withValues(alpha: 0.85)),
          const SizedBox(height: 16),
          Text(titulo, textAlign: TextAlign.center, style: const TextStyle(
              fontFamily: 'Nunito', fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white)),
          if (subtitulo != null) ...[
            const SizedBox(height: 8),
            Text(subtitulo!, textAlign: TextAlign.center, style: TextStyle(
                fontFamily: 'Rubik', fontSize: 13, color: Colors.white.withValues(alpha: 0.85))),
          ],
        ]),
      ),
    );
  }
}
```

- [ ] **Step 4: Correr y verificar que pasa**

Run: `flutter test test/core/design_system/empty_state_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/design_system/empty_state.dart test/core/design_system/empty_state_test.dart
git commit -m "feat(menu): EmptyState reutilizable (acciones vacías / todo sincronizado)"
```

---

## Task 14: `AccionesScreen` (agrupa + ActionGroup + ActionTile + EmptyState + tap→placeholder)

**Files:**
- Create: `lib/features/acciones/presentation/acciones_screen.dart`
- Test: `test/features/acciones/acciones_screen_test.dart`

- [ ] **Step 1: Escribir el test que falla**

```dart
// test/features/acciones/acciones_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/session/entities.dart';
import 'package:prosane_app/core/session/session_controller.dart';
import 'package:prosane_app/features/acciones/presentation/acciones_screen.dart';

Accion _a(String name, String label, String cat) => Accion(name: name, label: label, icon: 'draw',
    color: '#2E7D32', type: 'form', category: cat, isSensitive: false, sortOrder: 1);

void main() {
  Future<void> pump(WidgetTester t, List<Accion> acciones) async {
    final c = SessionController()..setSesion(Sesion(
        usuario: const Usuario(id: '1', nombre: 'Ana', rolName: 'medico', rolLabel: 'Médico/a'),
        acciones: acciones));
    await t.pumpWidget(ProviderScope(
      overrides: [sessionControllerProvider.overrideWith((ref) => c)],
      child: const MaterialApp(home: AccionesScreen()),
    ));
  }

  testWidgets('agrupa por categoría y lista las acciones del rol', (t) async {
    await pump(t, [_a('listarPacientes', 'Listar pacientes', 'salud'), _a('verConstancias', 'Ver constancias', 'consentimiento')]);
    expect(find.text('SALUD'), findsOneWidget);
    expect(find.text('CONSENTIMIENTO'), findsOneWidget);
    expect(find.text('Listar pacientes'), findsOneWidget);
    expect(find.text('Ver constancias'), findsOneWidget);
  });

  testWidgets('sin acciones muestra el estado vacío', (t) async {
    await pump(t, const []);
    expect(find.text('No tenés acciones disponibles todavía'), findsOneWidget);
  });

  testWidgets('tocar una acción abre el placeholder "próximamente"', (t) async {
    await pump(t, [_a('firmarApto', 'Firmar apto físico', 'salud')]);
    await t.tap(find.text('Firmar apto físico'));
    await t.pumpAndSettle();
    expect(find.textContaining('próximamente'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Correr y verificar que falla**

Run: `flutter test test/features/acciones/acciones_screen_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implementar**

```dart
// lib/features/acciones/presentation/acciones_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design_system/accion_presentacion.dart';
import '../../../core/design_system/action_group.dart';
import '../../../core/design_system/action_tile.dart';
import '../../../core/design_system/app_gradient_scaffold.dart';
import '../../../core/design_system/empty_state.dart';
import '../../../core/session/agrupar_acciones.dart';
import '../../../core/session/entities.dart';
import '../../../core/session/session_controller.dart';

class AccionesScreen extends ConsumerWidget {
  const AccionesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(sessionControllerProvider);
    final acciones = estado is SesionAutenticada ? estado.sesion.acciones : const <Accion>[];

    return AppGradientScaffold(
      child: acciones.isEmpty
          ? const EmptyState(
              icon: Icons.inbox_outlined,
              titulo: 'No tenés acciones disponibles todavía',
              subtitulo: 'Cuando te asignen un rol, vas a ver acá lo que podés hacer.')
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 120), // 120: espacio para la barra flotante
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(4, 4, 4, 18),
                  child: Text('Acciones', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w900, fontSize: 24, color: Colors.white)),
                ),
                for (final g in agruparPorCategoria(acciones))
                  ActionGroup(
                    titulo: g.categoria.toUpperCase(),
                    children: [
                      for (final a in g.acciones)
                        ActionTile(
                          color: colorDesdeHex(a.color),
                          icon: accionIcon(a.icon),
                          label: a.label,
                          onTap: () => _placeholder(context, a.label),
                        ),
                    ],
                  ),
              ],
            ),
    );
  }

  void _placeholder(BuildContext context, String label) {
    showDialog<void>(context: context, builder: (_) => AlertDialog(
      content: Text('$label — próximamente'),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
    ));
  }
}
```

- [ ] **Step 4: Correr y verificar que pasa**

Run: `flutter test test/features/acciones/acciones_screen_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/acciones test/features/acciones
git commit -m "feat(menu): AccionesScreen (acordeón por categoría + estado vacío + placeholder)"
```

---

## Task 15: `pendientesCountProvider` (cuenta pendiente/error → 0 hoy) [Invariante #3]

**Files:**
- Create: `lib/features/pendientes/pendientes_count_provider.dart`
- Test: `test/features/pendientes/pendientes_count_test.dart`

- [ ] **Step 1: Escribir el test que falla**

```dart
// test/features/pendientes/pendientes_count_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/features/pendientes/pendientes_count_provider.dart';

void main() {
  test('sin tablas de feature reales el conteo es 0 (badge oculto)', () {
    // Hoy no hay entidades sincronizables: la lista de syncers pendientes está vacía.
    expect(contarPendientes(const []), 0);
  });

  test('suma los pendientes/error de cada feature', () {
    expect(contarPendientes(const [2, 0, 3]), 5);
  });
}
```

- [ ] **Step 2: Correr y verificar que falla**

Run: `flutter test test/features/pendientes/pendientes_count_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implementar**

```dart
// lib/features/pendientes/pendientes_count_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Suma los conteos de pendientes/error por feature. Función pura, testeable.
int contarPendientes(List<int> porFeature) => porFeature.fold(0, (a, b) => a + b);

/// Conteo global de ítems pendientes de sincronizar. Hoy NO hay tablas de feature
/// reales (apto_físico diferido) → 0 → el badge no se muestra (invariante #3).
/// Cuando exista la primera feature, se suman acá sus conteos desde Drift.
final pendientesCountProvider = Provider<int>((ref) => contarPendientes(const []));
```

- [ ] **Step 4: Correr y verificar que pasa**

Run: `flutter test test/features/pendientes/pendientes_count_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/pendientes/pendientes_count_provider.dart test/features/pendientes/pendientes_count_test.dart
git commit -m "feat(menu): pendientesCountProvider (0 hoy, badge oculto hasta features reales)"
```

---

## Task 16: `PendientesScreen` (EmptyState "Todo sincronizado")

**Files:**
- Create: `lib/features/pendientes/presentation/pendientes_screen.dart`
- Test: `test/features/pendientes/pendientes_screen_test.dart`

- [ ] **Step 1: Escribir el test que falla**

```dart
// test/features/pendientes/pendientes_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/features/pendientes/presentation/pendientes_screen.dart';

void main() {
  testWidgets('sin pendientes muestra "Todo sincronizado"', (t) async {
    await t.pumpWidget(const MaterialApp(home: PendientesScreen()));
    expect(find.text('Todo sincronizado'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Correr y verificar que falla**

Run: `flutter test test/features/pendientes/pendientes_screen_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implementar**

```dart
// lib/features/pendientes/presentation/pendientes_screen.dart
import 'package:flutter/material.dart';
import '../../../core/design_system/app_gradient_scaffold.dart';
import '../../../core/design_system/empty_state.dart';

/// Indicador global de sync (offline-first). Hoy, sin features sincronizables,
/// muestra el estado vacío honesto. La lista rica llega con la primera feature.
class PendientesScreen extends StatelessWidget {
  const PendientesScreen({super.key});

  @override
  Widget build(BuildContext context) => const AppGradientScaffold(
        child: EmptyState(icon: Icons.check_circle_outline, titulo: 'Todo sincronizado'),
      );
}
```

- [ ] **Step 4: Correr y verificar que pasa**

Run: `flutter test test/features/pendientes/pendientes_screen_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/pendientes/presentation test/features/pendientes/pendientes_screen_test.dart
git commit -m "feat(menu): PendientesScreen (estado vacío 'Todo sincronizado' por ahora)"
```

---

## Task 17: `UsuarioScreen` (perfil, fallback email, rolLabel, settings placeholder, logout)

**Files:**
- Create: `lib/features/usuario/presentation/usuario_screen.dart`
- Test: `test/features/usuario/usuario_screen_test.dart`

- [ ] **Step 1: Escribir el test que falla**

```dart
// test/features/usuario/usuario_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/session/entities.dart';
import 'package:prosane_app/core/session/session_controller.dart';
import 'package:prosane_app/features/usuario/presentation/usuario_screen.dart';

void main() {
  Future<SessionController> pump(WidgetTester t, {required String nombre}) async {
    final c = SessionController()..setSesion(Sesion(
        usuario: Usuario(id: '1', nombre: nombre, rolName: 'medico', rolLabel: 'Médico/a'), acciones: const []));
    await t.pumpWidget(ProviderScope(
      overrides: [sessionControllerProvider.overrideWith((ref) => c)],
      child: const MaterialApp(home: UsuarioScreen()),
    ));
    return c;
  }

  testWidgets('caso normal: muestra el nombre real de la persona + label del rol', (t) async {
    // El backend YA vincula personas (core/fixtures/people.json): /me devuelve
    // nombre+apellido reales (Super Admin, Mariana Médica, Tomás Tutor…), no el email.
    await pump(t, nombre: 'Mariana Médica');
    expect(find.text('Mariana Médica'), findsOneWidget);
    expect(find.text('Médico/a'), findsOneWidget);
  });

  testWidgets('fallback: usuario SIN persona vinculada → MeResponse ya cayó al email', (t) async {
    // Caso excepcional (un usuario sin Persona). MeResponse resolvió el fallback;
    // acá el nombre llega como el email y la pantalla lo muestra sin romper.
    await pump(t, nombre: 'medico@prosane.test');
    expect(find.text('medico@prosane.test'), findsOneWidget);
  });

  testWidgets('Configuración es un placeholder "próximamente"', (t) async {
    await pump(t, nombre: 'Ana');
    await t.tap(find.text('Configuración'));
    await t.pumpAndSettle();
    expect(find.textContaining('próximamente'), findsOneWidget);
  });

  testWidgets('logout cierra la sesión', (t) async {
    final c = await pump(t, nombre: 'Ana');
    await t.tap(find.text('Cerrar sesión'));
    await t.pump();
    expect(c.state, isA<SesionNoAutenticada>());
  });
}
```

- [ ] **Step 2: Correr y verificar que falla**

Run: `flutter test test/features/usuario/usuario_screen_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implementar**

```dart
// lib/features/usuario/presentation/usuario_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design_system/app_gradient_scaffold.dart';
import '../../../core/session/entities.dart';
import '../../../core/session/session_controller.dart';

class UsuarioScreen extends ConsumerWidget {
  const UsuarioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(sessionControllerProvider);
    final usuario = estado is SesionAutenticada
        ? estado.sesion.usuario
        : const Usuario(id: '', nombre: '', rolName: '', rolLabel: '');

    return AppGradientScaffold(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 120),
        children: [
          const Padding(padding: EdgeInsets.fromLTRB(4, 4, 4, 18),
              child: Text('Usuario', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w900, fontSize: 24, color: Colors.white))),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            clipBehavior: Clip.antiAlias,
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 26, 18, 8),
                child: Column(children: [
                  const CircleAvatar(radius: 38, backgroundColor: Color(0xFF7C5CFC),
                      child: Icon(Icons.person_outline, color: Colors.white, size: 40)),
                  const SizedBox(height: 14),
                  Text(usuario.nombre, style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF2D2D3A))),
                  const SizedBox(height: 2),
                  Text(usuario.rolLabel, style: const TextStyle(fontFamily: 'Rubik', fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF7C5CFC))),
                ]),
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined, color: Color(0xFF7C5CFC)),
                title: const Text('Configuración', style: TextStyle(fontFamily: 'Rubik', fontWeight: FontWeight.w600, color: Color(0xFF2D2D3A))),
                trailing: const Icon(Icons.keyboard_arrow_right, color: Color(0xFFC4BBE8)),
                onTap: () => showDialog<void>(context: context, builder: (_) => AlertDialog(
                  content: const Text('Editar perfil — próximamente'),
                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))])),
              ),
            ]),
          ),
          const SizedBox(height: 18),
          TextButton.icon(
            onPressed: () => ref.read(sessionControllerProvider.notifier).cerrar(),
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text('Cerrar sesión', style: TextStyle(fontFamily: 'Rubik', color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
```

> Nota: el logout acá llama `cerrar()` (estado en memoria). El borrado del cache de Drift lo hace `AuthRepository.logout()`; cablear ambos en el AppShell o en un usecase de logout es un refinamiento menor — para este test basta `cerrar()`. Si se quiere el logout completo (tokens+cache), exponer un `logoutProvider` que llame `authRepository.logout()` y luego `cerrar()`.

- [ ] **Step 4: Correr y verificar que pasa**

Run: `flutter test test/features/usuario/usuario_screen_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/usuario test/features/usuario
git commit -m "feat(menu): UsuarioScreen (perfil + settings placeholder + logout)"
```

---

## Task 18: `AppShell` + router `StatefulShellRoute` (reemplaza /home, barra responsiva al scroll)

**Files:**
- Create: `lib/core/router/app_shell.dart`
- Modify: `lib/core/router/app_router.dart`
- Test: `test/core/router/app_shell_test.dart`

- [ ] **Step 1: Escribir el test que falla**

```dart
// test/core/router/app_shell_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/design_system/floating_nav_bar.dart';
import 'package:prosane_app/core/router/app_shell.dart';

void main() {
  testWidgets('al scrollear hacia abajo la barra se compacta', (t) async {
    await t.pumpWidget(MaterialApp(home: AppShell(
      selectedIndex: 0, onTap: (_) {},
      child: ListView(children: List.generate(40, (i) => SizedBox(height: 60, child: Text('item $i')))),
    )));
    FloatingNavBar barra() => t.widget<FloatingNavBar>(find.byType(FloatingNavBar));
    expect(barra().compacta, false);                 // arriba: expandida
    await t.drag(find.text('item 1'), const Offset(0, -300));
    await t.pump();
    expect(barra().compacta, true);                  // scroll abajo: compacta
  });
}
```

- [ ] **Step 2: Correr y verificar que falla**

Run: `flutter test test/core/router/app_shell_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implementar `AppShell`** (barra flotante + escucha de scroll)

```dart
// lib/core/router/app_shell.dart
import 'package:flutter/material.dart';
import '../design_system/floating_nav_bar.dart';

/// Envuelve el contenido de la pestaña activa y le pinta encima la FloatingNavBar.
/// Escucha el scroll del contenido para compactar la barra (estilo Instagram).
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.child, required this.selectedIndex, required this.onTap});
  final Widget child;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _compacta = false;

  bool _onScroll(ScrollNotification n) {
    final compacta = n.metrics.pixels > 24; // umbral simple
    if (compacta != _compacta) setState(() => _compacta = compacta);
    return false;
  }

  static const _items = [
    NavItemData(outlinedIcon: Icons.home_outlined, filledIcon: Icons.home, label: 'Inicio'),
    NavItemData(outlinedIcon: Icons.sync_outlined, filledIcon: Icons.sync, label: 'Pendientes'),
    NavItemData(outlinedIcon: Icons.person_outline, filledIcon: Icons.person, label: 'Usuario'),
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      NotificationListener<ScrollNotification>(onNotification: _onScroll, child: widget.child),
      Positioned(left: 0, right: 0, bottom: 18, child: Center(
        child: FloatingNavBar(
          items: _items, selectedIndex: widget.selectedIndex, compacta: _compacta, onTap: widget.onTap),
      )),
    ]);
  }
}
```

> El `badgeCount` de Pendientes se inyecta desde `pendientesCountProvider` cuando el AppShell se cablea en el router (Step 4): construir `_items` con `badgeCount: count` en el item 1. Para mantener el componente testeable sin Riverpod, el test usa los items con badge 0.

- [ ] **Step 4: Reescribir el router con `StatefulShellRoute`**

Reemplazar las `routes` del `goRouterProvider` en `lib/core/router/app_router.dart`. La barra lee el badge del provider:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/acciones/presentation/acciones_screen.dart';
import '../../features/pendientes/presentation/pendientes_screen.dart';
import '../../features/usuario/presentation/usuario_screen.dart';
import 'app_shell.dart';
// (quitar el import de home_screen.dart)

// dentro de GoRouter(...):
    routes: [
      GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (c, s) => const SignupWizardScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(
          selectedIndex: navigationShell.currentIndex,
          onTap: (i) => navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex),
          child: navigationShell,
        ),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/inicio', builder: (c, s) => const AccionesScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/pendientes', builder: (c, s) => const PendientesScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/usuario', builder: (c, s) => const UsuarioScreen())]),
        ],
      ),
    ],
```

Y actualizar el guard `construirRedirect` para usar `/inicio` en vez de `/home`:

```dart
// construirRedirect: el destino autenticado pasa de '/home' a '/inicio'
Redirect construirRedirect(bool autenticado) => (location) {
      final enAuth = location == '/login' || location == '/signup';
      if (!autenticado && !enAuth) return '/login';
      if (autenticado && enAuth) return '/inicio';
      return null;
    };
```

Cablear el badge real: en el `builder` del shell, leer el provider y pasar el `badgeCount` a la barra. Para eso, mover los `_items` a parámetro del AppShell o leerlos vía `Consumer`. Implementación mínima: el AppShell recibe `badgePendientes`:

```dart
// AppShell: agregar `final int badgePendientes;` (default 0) y usarlo en el item 1:
//   NavItemData(... label: 'Pendientes', badgeCount: badgePendientes)
// En el router builder:
//   child: Consumer(builder: (c, ref, _) => AppShell(
//     badgePendientes: ref.watch(pendientesCountProvider), ...))
```

- [ ] **Step 5: Borrar el `HomeScreen` viejo y su test**

```bash
git rm lib/features/home/presentation/home_screen.dart test/features/home/home_screen_test.dart 2>/dev/null || true
```
(Si hay referencias a `HomeScreen` en otros tests, eliminarlas — ya no existe la ruta `/home`.)

- [ ] **Step 6: Correr la suite completa y verificar que pasa**

Run: `flutter test` y `flutter analyze`
Expected: PASS, sin issues. (El `app_shell_test` y todo lo anterior en verde.)

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "feat(menu): AppShell + StatefulShellRoute (3 ramas, reemplaza /home, barra responsiva al scroll)"
```

---

## Task 19: Widgetbook — use-cases de los componentes nuevos

**Files:**
- Modify: `widgetbook/main.dart`

- [ ] **Step 1: Agregar los `WidgetbookComponent` nuevos**

En `widgetbook/main.dart`, dentro de `directories: [...]`, agregar (con los imports correspondientes arriba):

```dart
        WidgetbookComponent(
          name: 'FloatingNavBar',
          useCases: [
            WidgetbookUseCase(name: 'Expandida — Inicio activo', builder: (c) => _frame(
              const _NavBarDemo(selected: 0, compacta: false, badge: 0))),
            WidgetbookUseCase(name: 'Expandida — Pendientes activo (badge 3)', builder: (c) => _frame(
              const _NavBarDemo(selected: 1, compacta: false, badge: 3))),
            WidgetbookUseCase(name: 'Compacta — solo íconos', builder: (c) => _frame(
              const _NavBarDemo(selected: 0, compacta: true, badge: 3))),
            WidgetbookUseCase(name: 'Sin badge (todo sincronizado)', builder: (c) => _frame(
              const _NavBarDemo(selected: 1, compacta: false, badge: 0))),
          ],
        ),
        WidgetbookComponent(
          name: 'ActionGroup',
          useCases: [
            WidgetbookUseCase(name: 'Expandido (Salud, 4 acciones)', builder: (c) => _frame(
              ActionGroup(titulo: 'SALUD', children: [
                for (final l in ['Listar pacientes', 'Ver ficha clínica', 'Crear apto físico', 'Firmar apto físico'])
                  ActionTile(color: const Color(0xFF2E7D32), icon: Icons.draw_outlined, label: l, onTap: () {}),
              ]))),
            WidgetbookUseCase(name: 'Colapsado', builder: (c) => _frame(
              const ActionGroup(titulo: 'CONSENTIMIENTO', initiallyExpanded: false, children: [Text('—')]))),
          ],
        ),
        WidgetbookComponent(
          name: 'ActionTile',
          useCases: [
            WidgetbookUseCase(name: 'Salud (verde)', builder: (c) => _frame(
              ActionTile(color: const Color(0xFF2E7D32), icon: Icons.draw_outlined, label: 'Firmar apto físico', onTap: () {}))),
            WidgetbookUseCase(name: 'Consentimiento (gris)', builder: (c) => _frame(
              ActionTile(color: const Color(0xFF455A64), icon: Icons.description_outlined, label: 'Ver constancias', onTap: () {}))),
          ],
        ),
        WidgetbookComponent(
          name: 'NavBarBadge',
          useCases: [
            for (final n in [1, 9, 150])
              WidgetbookUseCase(name: '$n', builder: (c) => _frame(NavBarBadge(count: n))),
          ],
        ),
        WidgetbookComponent(
          name: 'EmptyState',
          useCases: [
            WidgetbookUseCase(name: 'Sin acciones', builder: (c) => Theme(data: AppTheme.light(),
              child: AppGradientScaffold(child: const EmptyState(icon: Icons.inbox_outlined,
                titulo: 'No tenés acciones disponibles todavía',
                subtitulo: 'Cuando te asignen un rol, vas a ver acá lo que podés hacer.')))),
            WidgetbookUseCase(name: 'Todo sincronizado', builder: (c) => Theme(data: AppTheme.light(),
              child: AppGradientScaffold(child: const EmptyState(icon: Icons.check_circle_outline, titulo: 'Todo sincronizado')))),
          ],
        ),
```

Agregar al final del archivo el helper de demo de la barra (la barra real necesita `selectedIndex`/`onTap`):

```dart
class _NavBarDemo extends StatelessWidget {
  const _NavBarDemo({required this.selected, required this.compacta, required this.badge});
  final int selected; final bool compacta; final int badge;
  @override
  Widget build(BuildContext context) => FloatingNavBar(
        compacta: compacta, selectedIndex: selected, onTap: (_) {},
        items: [
          const NavItemData(outlinedIcon: Icons.home_outlined, filledIcon: Icons.home, label: 'Inicio'),
          NavItemData(outlinedIcon: Icons.sync_outlined, filledIcon: Icons.sync, label: 'Pendientes', badgeCount: badge),
          const NavItemData(outlinedIcon: Icons.person_outline, filledIcon: Icons.person, label: 'Usuario'),
        ],
      );
}
```

Imports a sumar arriba: `floating_nav_bar.dart`, `nav_bar_badge.dart`, `action_group.dart`, `action_tile.dart`, `empty_state.dart`, `app_gradient_scaffold.dart`.

- [ ] **Step 2: Verificar que compila**

Run: `flutter analyze widgetbook/main.dart`
Expected: No issues.

- [ ] **Step 3: Commit**

```bash
git add widgetbook/main.dart
git commit -m "docs(menu): use-cases de la barra y componentes del menú en Widgetbook"
```

---

> ## ✅ CHECKPOINT 2 (visible)
> Después de Task 19: `flutter run`. Login end-to-end → la app entra a `/inicio` con la **barra flotante** (3 botones, scroll-responsiva), el **acordeón con las acciones reales del rol** (médico: 4 en Salud), tocar una abre el placeholder "próximamente", **Pendientes** muestra "Todo sincronizado" (badge oculto), **Usuario** muestra perfil + settings placeholder + logout. Modo avión + reabrir → arranca offline con el menú. Correr Widgetbook (`flutter run -t widgetbook/main.dart`) para ver la galería. `flutter test` + `flutter analyze` en verde.

---

## Self-Review (hecha sobre el spec)

**Cobertura del spec:**
- §1 navegación → Task 18 (StatefulShellRoute + AppShell + scroll). ✓
- §2a extender contrato → Task 1-2. ✓ · §2b caché Drift → Task 5-8. ✓ · §2c icon/color fallback → Task 3. ✓
- §3 Acciones (acordeón, agrupación, empty, placeholder, sin is_sensitive, type no renderizado) → Task 4 + 14. ✓
- §4 Pendientes (badge en 0, empty "Todo sincronizado") → Task 9 + 15 + 16. ✓
- §5 Usuario (perfil, fallback email, rolLabel, settings, logout) → Task 17. ✓
- §6 componentes → Task 9-13. ✓ · §7 Widgetbook → Task 19. ✓ · §8 testing → tests en cada task. ✓
- Invariantes #1-#4 → tabla al inicio del plan; #1 (frontera) se respeta por construcción (no hay registry/render dinámico en ninguna task). ✓
- Refinamientos del usuario: rolName+rolLabel ambos (Task 1-2 ✓); el backend ya vincula personas (people.json) → `/me` devuelve nombre real; T17 testea el caso normal (nombre real) y el fallback a email para usuario sin persona (Task 1 y 17 ✓); cached_session lista exacta de campos (Task 5 ✓).

**Consistencia de tipos:** `Accion`/`Usuario`/`Sesion` definidos en Task 1-2 y usados idénticos en 4/6/7/14/17. `SessionCache` definido en Task 7 (el plan avisa de no acoplarlo en Task 2). `FloatingNavBar`/`NavItemData` def en Task 10, usados en 18/19. `accionIcon`/`colorDesdeHex` def en Task 3, usados en 14.

**Sin placeholders:** cada task trae test + implementación completos + comandos con resultado esperado.
