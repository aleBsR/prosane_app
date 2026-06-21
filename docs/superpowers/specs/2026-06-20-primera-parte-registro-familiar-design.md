# Spec — "Primera parte": registro de tutor + planilla familiar + consentimiento

> Diseño validado en brainstorming (2026-06-20). Cubre **dos repos**: `prosane_api`
> (rama **`dev-base`**) y `prosane_app`. Reemplaza el encuadre idealizado de
> `flujo-completo.md` con lo que realmente hay en `dev-base`.

## 1. Objetivo y alcance

Construir el circuito de **la familia/tutor**: que un tutor se registre, cargue a su
hijo (NNA) con la planilla familiar y deje el consentimiento, todo offline-first.

**Incluye**
- Registro de **tutor** (solo este rol), wizard multi-paso guiado por `formulario-registro.jpeg`.
- Menú de acciones del tutor (`registrarHijo`, `verHijos`) data-driven desde `/me`.
- Wizard de **planilla familiar** (grilla `Grilla para ser completada por la familia V2.png`):
  datos del NNA + domicilio + cobertura + antecedentes personales + familiares + consentimiento inline.
- **Endpoint agregado** que crea todo en una transacción.
- Borrador offline (Drift) + envío por la cola de sync.
- **Nudge** en Pendientes cuando el tutor no cargó ningún hijo.

**Fuera de alcance (parkeado)**
- Operativo / rol ayudante, CIS, profesional y validación de matrícula (REFEPS).
- Registro multi-rol y endpoint público de "opciones de registro" (descartado).
- `firma_tipo = nna_mayor_13` (autonomía progresiva ≥13), modelo `Consentimiento` separado
  con `firma_hash`, generación de PDF, edición/revocación de consentimiento, vacunas.

## 2. Decisiones tomadas (y su porqué)

| # | Decisión | Por qué |
|---|----------|---------|
| 1 | Backend = rama **`dev-base`** | Reestructura limpia a `apps/`, `register/tutor` ya devuelve JWT, endpoint `hijos` con capa de servicios, schema propio (`managed=True`). |
| 2 | Registro **solo tutor**, wizard multi-paso (mockup) | YAGNI; los otros roles difieren (médico = matrícula/REFEPS) y son segunda parte. |
| 3 | `dev-base` **se alinea al contrato congelado del app** | El app ya tiene caché Drift + interceptor + tests contra `/auth/token/`, `/auth/token/refresh/` y el `/me` con forma fija. |
| 4 | Entry point = **menú de acciones** + **nudge** en Pendientes | El `AccionesScreen` ya renderiza `actions[]`; el nudge empuja el consentimiento (objetivo legal). |
| 5 | Acciones `registrarHijo` + `verHijos` = **solo menú** | Gating de endpoints se mantiene en `IsAuthenticated` + dueño; no se agregan `require_action`. |
| 6 | Submit = **endpoint agregado** (1 `@transaction.atomic`) | Atomicidad (consentimiento legal) + 1 solo ítem en la cola offline-first. |
| 7 | Consentimiento = **campos mínimos en `Paciente`** (sin modelo aparte) | "Directo" según el equipo; igual se guarda quién aceptó y cuándo (Ley 26.529). |
| 8 | Offline = **borrador Drift + cola de sync** | Form largo; no perder datos; alineado a la fundación offline-first. |

## 3. Contrato congelado del app (referencia)

`prosane_app` espera (base URL `…/api/v1/auth`):
- `POST /token/` `{email, password}` → tokens.
- `POST /token/refresh/` (interceptor de refresh).
- `POST /register/` (registro) y `GET /me/`, `POST /logout/`.
- `/me` → `{ user:{id,email,nombre,apellido,is_staff}, roles:[{name,label}],
  actions:[{name,label,icon,color,type,category,is_sensitive,sort_order}], meta:{version, permissions_synced_at} }`.

Las **8 claves** de cada acción coinciden 1:1 con el modelo `Action` de `dev-base`
(`name, label, icon, color, type, category, is_sensitive, sort_order`).

## 4. Backend — `prosane_api` @ `dev-base`

### B0 · Reconciliar contrato auth/`/me` (prerrequisito)
- Exponer `POST /api/v1/auth/token/` y `POST /api/v1/auth/token/refresh/` (hoy `dev-base`
  usa `/auth/login/` y `/auth/refresh/`).
- `GET /api/v1/auth/me/` debe devolver la forma congelada: `roles:[{name,label}]`
  (hoy `[{id,rol}]`), `actions:[{8 claves}]` y `meta:{version, permissions_synced_at}`.

### B1' · Campos de consentimiento en `Paciente`
Agregar a `apps/pacientes/models/paciente.py` + migración (`managed=True`):
- `consentimiento_aceptado: bool` (default False)
- `fecha_consentimiento: datetime null`
- `adulto_nombre`, `adulto_apellido`, `adulto_tipo_documento`, `adulto_dni` (snapshot del adulto que consintió)

> No se expone `adulto_dni` en las respuestas (dato sensible).

### B2 · Acciones del tutor (solo menú)
Crear en los fixtures de `apps/usuarios` y asignar al rol `tutor`:
- `registrarHijo` — label "Registrar hijo", category "familia", `is_sensitive=true`.
- `verHijos` — label "Mis hijos", category "familia", `is_sensitive=false`.

No gatean endpoints (siguen `IsAuthenticated` + chequeo de dueño).

### B3' · Endpoint agregado (extender `hijos`)
Extender `HijoCreateSerializer` + `apps/tutores/services/hijos.py::crear_hijo` para que, en
el `@transaction.atomic` que ya existe, además de Persona + Domicilio + Paciente cree:
- `AntecedentePersonal` (modelo ya existe en `apps/antecedentes`, hoy **sin endpoint**)
- `AntecedenteFamiliar` (ídem)
- y grabe los campos de consentimiento en el `Paciente`.

`POST /api/v1/tutores/<uuid:pk>/hijos/` — body:
```jsonc
{
  "persona":   { "nombre","apellido","dni","tipo_dni","sexo","fecha_nacimiento" },
  "domicilio": { "calle","nro_calle","piso","dpto","manzana","casa","nro_casa","pieza",
                 "provincia","departamento","localidad" },
  "edad": 9, "tiene_cud": "NO",
  "tipo_cobertura": "obra_social", "nombre_cobertura": "OSDE",
  "parentesco": "madre",
  "antecedentes_personales": { "nacio_prematuro":"No", "convulsiones_epilepsia":"No", ... },
  "antecedentes_familiares": { "problemas_salud","detalle_problema_salud","familiar_con_muerte_subita" },
  "consentimiento": { "adulto_nombre","adulto_apellido","adulto_tipo_documento","adulto_dni" }
}
→ 201  { ...hijo completo (sin adulto_dni)... }
```
- El `tutor` se resuelve de la URL + dueño (`request.user`); 403 si no es el dueño.
- `consentimiento_aceptado=true` y `fecha_consentimiento=now` se setean al crear.
- `parentesco` vive en el modelo `Tutor` (no en `Paciente`): al cargar el hijo se setea/actualiza
  `Tutor.parentesco`. Para v1 se asume un parentesco por tutor (suficiente para el caso típico).

### B4 · Tests (pytest)
Happy path atómico; rollback ante fallo parcial; 403 si no es dueño / 401 sin auth;
consentimiento guardado; antecedentes creados.

### B5 · Contrato `.md`
Handoff del `hijos` extendido en `prosane_app/docs/` (mismo estilo que
`contrato-apto-backend.md` / `contrato-consentimiento-backend.md`).

## 5. Frontend — `prosane_app`

### F1 · Apuntar a `dev-base`
Configurar base URL contra `dev-base` (funciona tras B0). Smoke de login + `/me`.

### F2 · Signup del tutor (wizard 4 pasos, `formulario-registro.jpeg`)
| Paso | Campos | Destino |
|------|--------|---------|
| 1/4 Comencemos | Tipo de documento, Nº de documento + toggle "Acepto términos" | `persona.tipo_dni`, `persona.dni` |
| 2/4 Información Personal | Nombre, Apellido, Sexo, Fecha de nacimiento | `persona.nombre/apellido/sexo/fecha_nacimiento` |
| 3/4 Información de Contacto | Correo, Confirmar correo | `email` |
| 4/4 Información de Acceso | Contraseña, Confirmar contraseña → REGISTRARSE | `password` |

- Se **omiten** "Lugar de Nacimiento" y "País de Residencia" (sin columna en `Persona`).
- `parentesco` **no** se pide en el signup; se pide al cargar el hijo (es por hijo).
- `register/tutor` devuelve `{user, access, refresh}` → guardar tokens → `GET /me` → entrar
  (sin login encadenado).

### F3 · Cablear menú de acciones
En `AccionesScreen`, mapear el `onTap` de las acciones del `/me`:
- `registrarHijo` → abre el wizard de planilla familiar (F4).
- `verHijos` → listado de hijos del tutor (`GET /tutores/<id>/hijos/`).

### F4 · Wizard de planilla familiar (grilla V2)
Pasos: datos del NNA → domicilio → cobertura → antecedentes personales → antecedentes
familiares → **consentimiento** (identidad del adulto prellenada con los datos del tutor +
checkbox + fecha; sin `firma_hash`). Borrador en **Drift** con autosave por paso.

Mapeo: NNA→`Persona`+`edad`; domicilio→`Domicilio`; cobertura→campos de `Paciente`;
antecedentes→`AntecedentePersonal`/`AntecedenteFamiliar`; consentimiento→campos del `Paciente`.

### F5 · Submit (offline-first)
Confirmar → encolar **1 mutación** (POST agregado de B3') en la cola de sync. Online → enviar;
**201** → guardar hijo en local, borrar el borrador, limpiar el nudge. Error → reintentar.

### F6 · Nudge en Pendientes
Inferir desde `GET /tutores/<id>/hijos/`: si está vacío, mostrar en `PendientesScreen`
"Completá el consentimiento de tu hijo" con deep-link a la acción `registrarHijo`.

## 6. Orden de implementación
`B0 → B1' → B2 → B3' → B4/B5 → F1 → F2 → F3 → F4 → F5 → F6`

**Primer entregable testeable:** B0 + F1 (el app habla con `dev-base`).

## 7. Riesgos / notas
- B0 toca el contrato de auth de `dev-base`: validar que no rompa a otros consumidores de esa rama.
- `dev-base` no tiene CORS configurado → afecta solo a Flutter **Web** (no a nativo/emulador).
- Los antecedentes hoy guardan Sí/No/No sabe como texto; el front manda strings consistentes.
