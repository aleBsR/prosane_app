# Mejoras post-smoke — Logging backend + UX mobile

> Mejoras pedidas durante el smoke e2e de "la primera parte" (2026-06-22).
> Backend en `prosane_api` @ `feat/primera-parte-registro-familiar`.
> Mobile en `prosane_app` @ `feat/primera-parte-registro-familiar`.
> Entorno: backend usa `./venv/bin/python` (3.13) + tests con `--noinput`. Flutter 3.44.2.

## Contexto: dónde quedó el smoke
- Backend e2e probado en vivo con curl: register/tutor → /me (con tutor_id) → POST hijos (agregado atómico, antecedentes + consentimiento, adulto_dni no expuesto) → list. ✅
- Frontend: F2–F6 + scheduler de sync cableado. Suite 152✅/6❌ (los 6 son pre-existentes de `usuario_screen_test`).
- Fix aplicado durante el smoke: `AppSwitch` (overflow del label → `Flexible` + `HitTestBehavior.opaque`).
- Pendiente de diagnosticar: la app dio `400` en `POST /api/v1/auth/register/tutor/` (se ve en el log del server). La Tarea 1 (logging) lo va a revelar.

---

## Tarea 1 (Backend): Recuperar el logging de desarrollo desde `dev`

**Qué:** `dev-base` no tiene logging. La rama `dev` tiene un middleware verboso que loguea request/response con bodies JSON **redactados** (Ley 25.326: sin DNI/diagnósticos/emails/tokens) + config `LOGGING`.

**Files:**
- Create: `common/dev_logging.py` (portar de `dev`: `git show dev:common/dev_logging.py`)
- Modify: `config/settings/local.py` (agregar `MIDDLEWARE += [...]` + bloque `LOGGING`, portar de `git show dev:config/settings/local.py`)

**Pasos:**
1. `git show dev:common/dev_logging.py > common/dev_logging.py` y revisar que no referencie modelos/paths que en `dev-base` cambiaron (apps/ vs módulos sueltos). Ajustar imports si hace falta.
2. Agregar a `config/settings/local.py`:
   - `MIDDLEWARE = MIDDLEWARE + ['common.dev_logging.RequestResponseLoggingMiddleware']`
   - el bloque `LOGGING` de `dev` (formatters dev/raw, handlers console/console_raw, loggers `prosane.api` y `django.request`, root INFO).
3. `./venv/bin/python manage.py runserver 0.0.0.0:8000` y verificar que loguea requests con bodies redactados.
4. **Diagnosticar el 400 del registro:** con el logging puesto, registrar desde la app y leer el body que llega + el error de validación. Causa probable: email/dni duplicado de pruebas anteriores, o algún campo. Ajustar lo que corresponda.
5. Commit: `feat(dev): logging de requests/responses redactado en local (port de dev)`

---

## Tarea 2 (Mobile): Estado visual "deshabilitado" del AppButton

**Qué:** `AppButton` (`lib/core/design_system/app_button.dart`) calcula `disabled = isLoading || onPressed == null` pero NO cambia el aspecto → "SIGUIENTE" gateado parece habilitado. (La lógica de gating ya existe: `etapaValida(0)` incluye `aceptaPolitica`.)

**Files:** Modify `lib/core/design_system/app_button.dart`; Test `test/core/design_system/app_button_test.dart`.

**Pasos (TDD):**
1. Test: cuando `onPressed == null`, el botón se renderiza atenuado (ej. envuelto en `Opacity` con `opacity < 1`, o un widget/flag detectable). Verificar también que sigue sin disparar onTap.
2. Implementar: cuando `disabled`, envolver el `Container` en `Opacity(opacity: 0.5, ...)` (o aplicar un gradiente gris). No tocar la lógica de `onTap` (ya respeta `disabled`).
3. `flutter test test/core/design_system/` + `flutter analyze`.
4. Commit: `feat(ui): AppButton atenuado cuando esta deshabilitado`.

**Nota:** esto cierra el pedido del usuario: "SIGUIENTE deshabilitado hasta aceptar la política" — funcionalmente ya estaba; esto lo hace visible.

---

## Tarea 3 (Mobile): Cerrar teclado al tocar afuera

**Qué:** no hay dismiss de teclado en ningún lado. Tocar fuera de un input no lo cierra.

**Files:** Modify `lib/core/design_system/app_gradient_scaffold.dart` (lo usan todas las pantallas); Test el comportamiento si es factible.

**Pasos:**
1. Envolver el contenido de `AppGradientScaffold` en un `GestureDetector(behavior: HitTestBehavior.translucent, onTap: () => FocusScope.of(context).unfocus(), child: ...)`. `translucent` para no robar taps a los hijos.
2. Verificar manualmente (teclado se cierra al tocar el fondo) y `flutter analyze` + suite verde (que el GestureDetector no rompa tests de tap existentes; si algún test de tap se ve afectado, ajustar).
3. Commit: `feat(ui): cerrar teclado al tocar fuera de los inputs (AppGradientScaffold)`.

---

## Fuera de alcance / notas
- El warning iOS `NSLayoutConstraint ... TUIKeyplane.right.width == -1.5` es ruido benigno del teclado nativo de iOS, no accionable desde Flutter. Ignorar.
- Deuda pre-existente (no de esto): 6 tests rojos de `usuario_screen_test` (front) + 17 de `common.tests` (backend), de las ramas base.
- Limitaciones v1 ya documentadas en el plan frontend: `lugar/país` no se envían, planilla mono-pantalla, sync push-only, nudge por conteo local, `tutor_id` no cacheado.

## Orden sugerido
Tarea 1 (logging — desbloquea diagnóstico del 400) → Tarea 2 → Tarea 3. Cada una es chica e independiente.
