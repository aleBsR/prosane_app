# Seguimiento — deuda de la fundación Flutter

Issues de seguimiento surgidos de la review final de la rama
`feat/fundacion-flutter-offline-first` (no bloqueantes para el PR de la fundación).

## Prioritarios

### 1. `sesionCacheada()` devuelve `null` → arranque de sesión NO es offline-first todavía
- **Qué:** `AuthRepositoryImpl.sesionCacheada()` retorna siempre `null` y `SessionController`
  arranca siempre en `SesionNoAutenticada`. El spec pide hidratar la sesión desde el `/me`
  cacheado en el arranque para funcionar offline.
- **Dependencia:** atado al endpoint **`GET /me`** del backend (`prosane_api`), que está por
  construirse. **Cuando `/me` exista**, hay que: (a) cachear usuario+permisos en Drift al
  loguear, y (b) hidratar la sesión desde ese cache al arrancar. Hasta entonces el
  offline-first de la *sesión* queda a medias.
- **Archivos:** `lib/features/auth/data/repositories/auth_repository_impl.dart`,
  `lib/core/session/session_controller.dart`.

### 2. `apiBaseUrl` default HTTP → forzar HTTPS antes de cualquier deploy
- **Qué:** `AppConfig.apiBaseUrl` tiene default `http://10.0.2.2:8000/...` (HTTP, emulador
  Android). Correcto para dev, inyectable por `--dart-define`.
- **Acción obligatoria pre-deploy:** producción debe usar **HTTPS** y un base URL inyectado.
  Son datos de salud de menores (Ley 25.326): **HTTP no puede ir a prod.**
- **Archivo:** `lib/core/config/app_config.dart`.

## Menores

- **Refresh de `/me` + invalidación por `meta.version` (pendiente):** el cache guarda
  `metaVersion` y `permissionsSyncedAt` y existe `versionCacheada()`, pero NADA los
  consume todavía — `hidratar()` lee el cache y no re-fetchea `/me`. Una sesión cuyos
  permisos cambian en el server mantiene el menú viejo hasta un logout/login manual.
  Falta: tras `hidratar()`, refrescar `/me` en background cuando hay red y, si
  `meta.version` difiere, reemplazar el cache (la mitad de storage ya está construida).
  Archivos clave: `lib/core/session/session_controller.dart`,
  `lib/features/auth/data/repositories/auth_repository_impl.dart`.
- **Token sweep del design system (ampliar):** además del separador/sombra ya anotados,
  quedan sin token el rojo del badge (`0xFFE5484D`), el violeta inactivo de la barra
  (`0xFF9286C4`) y el tint activo. Incluirlos cuando se haga el pase de tokens.
- **`recordarme` no se persiste:** en `LoginScreen` el toggle "Recordarme" es estado local que
  no llega al controller ni persiste nada. Campo muerto hoy; definir su semántica (o quitarlo).
  `lib/features/auth/presentation/screens/login_screen.dart`.
- **`MeResponse` parsea a mano:** sin `json_serializable` (se quitó la dep). Es trivial y seguro;
  si crecen los DTOs, evaluar reintroducir code-gen de JSON.
- **Dropdowns del wizard con `initialValue`:** funcionan por el `IndexedStack` que mantiene los
  widgets vivos; si se cambia a `PageView`, migrar a `value:` (controlled). Y considerar extraer
  un `AppDropdownField` al design system (hoy el `InputDecoration` se repite en 3 steps).
- **`acepta_politica` en el payload de registro:** decisión de contrato backend (consentimiento,
  Ley 25.326). Definir si el registro debe enviarlo.

## Resueltos

- **Logout best-effort contra el backend** (2026-06-11): el logout manual
  (`AuthRepositoryImpl.logout()`, vía `logoutProvider` / botón "Cerrar sesión") llama
  `POST /api/v1/auth/logout/` con el refresh token **antes** de limpiar el storage, de
  modo que el interceptor Bearer puede añadir el header. La llamada es best-effort:
  envuelta en `try/catch`, un fallo de red o error HTTP no bloquea ni revierte el
  logout local; los tokens y el cache de Drift se limpian igual. Si no hay refresh
  token guardado, la llamada al backend se omite directamente. El logout **involuntario**
  (`dioProvider.onLogout`, disparado cuando el servidor ya rechazó el refresh) NO llama
  al endpoint de blacklist — el token ya está muerto — y permanece inalterado
  (solo limpieza local: tokens + cache + `cerrar()`).
  Archivos: `lib/features/auth/data/datasources/auth_remote_datasource.dart`,
  `lib/features/auth/data/repositories/auth_repository_impl.dart`,
  `test/features/auth/data/auth_repository_impl_test.dart`.

- **Invariante de naming de permisos camelCase** (2026-06-10): el front pedía permisos en
  `snake_case` (`firmar_apto` en `home_screen.dart`) pero el backend los emite en `camelCase`
  (`firmarApto`), así que `can()` nunca matcheaba y todo caía al fallback "Sin permisos".
  Alineado a camelCase, documentado como invariante en el spec (§"Sesión y permisos") y blindado
  con `test/core/session/permisos_naming_test.dart` (escanea `lib/` y falla ante cualquier clave
  no-camelCase pasada a `can(...)`/`PermissionGate(permiso: ...)`).

## Diferidos de diseño (ya documentados en el spec, no son deuda)

- Feature real `apto_fisico` (primera integración real del `sync_engine`).
- ActionRegistry / acciones server-driven por metadata.
- Sync en background real (WorkManager/BGTask).
- Web/desktop; reanudar un signup a medias.
