# Entrega 2 — Antecedentes de salud del niño o adolescente (diseño)

**Fecha:** 2026-06-23
**Estado:** Diseño aprobado (pendiente review del spec por el usuario)
**Alcance:** Pantalla per-hijo para cargar los antecedentes de salud del niño (sección "Antecedentes de salud del niño o adolescente" del PDF PROSANE, parte "PARA SER COMPLETADO POR LA FAMILIA"), con persistencia **online + offline-first**, su **pendiente por hijo**, y el **handoff de backend** para el endpoint nuevo.

## Objetivo

Tras registrar un hijo (Entrega 1), el tutor puede cargar —**después**, desde Pendientes— los antecedentes de salud de ese niño. Espeja los **20 campos del modelo `AntecedentePersonal`** ya existente. Funciona sin conexión (borrador local que sincroniza cuando hay red) y con conexión (POST directo).

## Contexto del backend (lectura detallada — 2026-06-23)

- **`AntecedentePersonal`** (`apps/antecedentes/models/antecedentepersonal.py`, tabla `antecedentespersonales`): **FK** a `Paciente` (`id_paciente`, no OneToOne), hereda `BaseModel` (UUID + auditoría + soft-delete). 20 campos, todos `CharField` salvo `edad_primera_menstruacion` (`IntegerField`). **Sin `choices`** → acepta cualquier string. Defaults: la mayoría `"NO"`, `peso_nacimiento="0"`, `descripcion_tratamiento="NINGUNO"`, `ultima_consulta_medica="NINGUNA"`, `otros_problemas_salud="NINGUNO"`, `edad_primera_menstruacion=0`.
- **El alta de hijo ya crea un `AntecedentePersonal`**: `crear_hijo` (`apps/tutores/services/hijos.py`) hace `AntecedentePersonal.objects.create(paciente=paciente, **ant_personales)`. Como el front (Entrega 1) **ya no manda** `antecedentes_personales`, ese registro se crea con **todos los defaults**. → El endpoint nuevo **ACTUALIZA ese registro existente** (upsert por paciente), no crea uno nuevo.
- **La app `pacientes` no tiene `urls.py` ni `views.py`.** Los endpoints del tutor viven bajo `apps/tutores/` (`/api/v1/tutores/<pk>/...`) con la validación de pertenencia ya resuelta. → El endpoint nuevo va **bajo `tutores`**, no en `pacientes`.
- **Patrón de endpoint a reusar:** `TutorAntecedentesFamiliaresView` (gated por `require_action(...)`) + servicios en `apps/tutores/services/perfil_tutor.py` (`verificar_pertenencia_tutor`). Serializer ya existente: `AntecedentespersonalesSerializer` (`fields="__all__"`).
- **El alta de hijo ya devuelve el `id` del paciente** en el `201` (`HijoOutputSerializer`) → el front solo tiene que capturarlo; no hay que tocar el alta.

## Arquitectura frontend (offline-first, tabla propia)

Espeja el patrón de `HijosRows` + `HijosSyncer`.

### Nueva tabla Drift `AntecedentesNinoRows`
- Hereda `SyncColumns` (id UUID cliente, `updatedAt`, `syncStatus`, `deletedAt`, PK = id).
- Columnas propias: `hijoLocalId` (text — apunta al `id` local de `HijosRows`), `payloadJson` (text — body del POST).
- **Una por hijo** (invariante de upsert: si ya existe una `AntecedentesNinoRow` para ese `hijoLocalId`, se actualiza su `payloadJson`).
- Bump de esquema **5 → 6**: `m.createTable(antecedentesNinoRows)` + (ver siguiente) `addColumn` de `serverPacienteId` en `HijosRows`.

### Captura del id del paciente en `HijosSyncer`
- Agregar a `HijosRows` la columna `serverPacienteId` (text, nullable).
- En `HijosSyncer.pushLote`, al recibir el `201`, leer `response.data['id']` y guardarlo (`marcarHijoSincronizado` pasa a recibir/persistir el `serverPacienteId`). Sin esto, el syncer de antecedentes no sabe a qué paciente postear.

### Nuevo `AntecedentesNinoSyncer` (implements `FeatureSyncer`, `feature = 'antecedentes_nino'`)
- `idsPendientes`: ids de `AntecedentesNinoRows` con `syncStatus = pendiente`.
- `pushLote`: por cada borrador, busca su `HijosRow` por `hijoLocalId`:
  - si el hijo tiene `serverPacienteId` → `POST /tutores/<hijo.tutorId>/hijos/<serverPacienteId>/antecedentes-personales/` con el `payloadJson`; `200/201` → ok.
  - si el hijo **todavía no** tiene `serverPacienteId` (no sincronizó) → resultado **transitorio** (se reintenta en la próxima vuelta, cuando el hijo ya tenga su id).
  - `4xx` → permanente; `5xx`/red → transitorio.
- Registrarlo en el `SyncScheduler` junto a `HijosSyncer`.

### Controller + pantalla
- `AntecedentesNinoController` (StateNotifier) parametrizado por `hijoLocalId`. Al crearse: precarga el borrador existente (si hay) desde Drift. El `sexo` del hijo se lee del `payloadJson` de su `HijosRow` (para el bloque menstruación).
- `AntecedentesNinoScreen` (per-hijo): mismas cards/design system. Guardar → **upsert** del borrador (insert o update por `hijoLocalId`) + `dispararPorEscritura()` + **notificación** "¡Antecedentes guardados!" + volver atrás.
- **Ruta:** `/hijos/:hijoLocalId/antecedentes`.

### Pendiente por hijo
- En `pendientes_count_provider`: por cada `HijosRow` **vivo** (no borrado) que **no** tenga `AntecedentesNinoRow` asociada → un `ItemPendiente` "Antecedentes de salud de \<nombre\>" que rutea a `/hijos/<id>/antecedentes`.
- Detección **100% local** (un dispositivo): reactiva vía watch de Drift (join hijos ↔ antecedentes_nino). Suma al badge como el resto.

## Campos y mapeo (20 campos de `AntecedentePersonal`)

Valores Sí/No/No sabe: **`'si'` / `'no'` / `'no_sabe'`** (consistente con `AntecedenteFamiliarTutor`). Dropdown sin selección → se envía `'no_sabe'`.

**Card "Nacimiento"**
| Campo PDF | Modelo | Widget |
|---|---|---|
| ¿Nació prematuro? | `nacio_prematuro` | Dropdown Sí/No/No sabe |
| Peso de nacimiento (kg) | `peso_nacimiento` | AppTextField numérico (decimal); se envía como string |

**Card "Antecedentes" (11 dropdowns Sí/No/No sabe)**
`convulsiones_epilepsia`, `mareos_desmayos`, `infecciones_urinarias`, `asma_espasmos`, `tuberculosis`, `diabetes`, `hipertension` (presión alta), `cardiopatia_congenita`, `traumatismo_internacion`, `diarrea_frecuente`, `infecciones_oido`.

**Card "Internación / tratamiento / otros"**
| Campo PDF | Modelo | Widget |
|---|---|---|
| Causa de internación (si estuvo internado) | `causa_hospitalizacion` | AppTextField (opcional) |
| ¿Recibe algún tratamiento? | `rabia_tratamiento` | Dropdown Sí/No/No sabe |
| ¿Cuál? (tratamiento) | `descripcion_tratamiento` | AppTextField — **solo si** `rabia_tratamiento == 'si'` |
| ¿Última vez que un médico lo pesó/midió/controló vacunas? | `ultima_consulta_medica` | Dropdown: `menos_1_anio` / `mas_1_anio` / `no_recuerda` |
| Otro problema de salud no detallado (¿cuál?) | `otros_problemas_salud` | AppTextField (opcional) |

**Card "Menstruación"** — visible **solo si el hijo es sexo `F`**
| Campo PDF | Modelo | Widget |
|---|---|---|
| ¿Tuvo la primera menstruación? | `primera_menstruacion` | Dropdown Sí/No/No sabe |
| Edad (años) | `edad_primera_menstruacion` | AppTextField numérico (int) — **solo si** `primera_menstruacion == 'si'` |

> **Fuera de alcance (decidido):** "¿Hay algo de la salud que le preocupa?" + "¿Qué le preocupa?" y la "Fecha" de la primera menstruación NO están en el modelo → no se implementan en esta entrega (se agregarían con un handoff aparte si se necesitan).

## Payload (`AntecedentesNinoController.guardar` → `payloadJson`)

```jsonc
{
  "nacio_prematuro": "si|no|no_sabe",
  "peso_nacimiento": "3.450",
  "convulsiones_epilepsia": "si|no|no_sabe",
  "mareos_desmayos": "...", "infecciones_urinarias": "...",
  "asma_espasmos": "...", "tuberculosis": "...", "diabetes": "...",
  "hipertension": "...", "cardiopatia_congenita": "...",
  "traumatismo_internacion": "...", "diarrea_frecuente": "...",
  "infecciones_oido": "...",
  "causa_hospitalizacion": "<texto o vacío>",
  "rabia_tratamiento": "si|no|no_sabe",
  "descripcion_tratamiento": "<texto si aplica>",
  "ultima_consulta_medica": "menos_1_anio|mas_1_anio|no_recuerda",
  "otros_problemas_salud": "<texto o vacío>",
  "primera_menstruacion": "si|no|no_sabe",
  "edad_primera_menstruacion": 0
}
```

## Handoff de backend (para el compañero)

> **Modelo:** ya existe `AntecedentePersonal` (FK Paciente) — **no crear nada nuevo de modelo**.
>
> **Endpoint nuevo (bajo `apps/tutores/`, patrón de `TutorAntecedentesFamiliaresView`):**
> ```
> GET  /api/v1/tutores/<uuid:pk>/hijos/<uuid:paciente_id>/antecedentes-personales/
> POST /api/v1/tutores/<uuid:pk>/hijos/<uuid:paciente_id>/antecedentes-personales/   (upsert)
> ```
> - Gatear con `require_action("cargarAntecedentesNino")`.
> - Validar pertenencia: el tutor `<pk>` es del usuario autenticado (reusar `verificar_pertenencia_tutor`) **y** el `Paciente <paciente_id>` pertenece a ese tutor (`paciente.tutor_id == tutor.id`) → si no, 403/404.
> - **Upsert sobre el registro existente:** el alta ya creó un `AntecedentePersonal` para el paciente; el POST **actualiza ese** (`AntecedentePersonal.objects.filter(paciente=paciente).first()`; si no existe, crearlo). Setear los campos recibidos. Responder `200` con el objeto.
> - GET: devolver el `AntecedentePersonal` del paciente (o crearlo con defaults si no existe). Reusar `AntecedentespersonalesSerializer`.
> - Servicio nuevo en `apps/tutores/services/` (ej. `antecedentes_nino.py`) siguiendo `perfil_tutor.py`.
>
> **Permisos:** agregar la acción `cargarAntecedentesNino` a `apps/usuarios/fixtures/actions.json` (shape igual a `cargarAntecedentesFamiliares`: `type:"action"`, `category:"familia"`, `icon:"medical_information"`, `color:"#6A4C93"`, `is_sensitive:true`, `sort_order:54`) y a `ROLE_ACTIONS["tutor"]` en `seed_permissions.py`; **correr `seed_permissions`**.
>
> **Valores:** Sí/No/No sabe como `'si'`/`'no'`/`'no_sabe'`. (Opcional: agregar `choices` a `AntecedentePersonal` para consistencia con `AntecedenteFamiliarTutor`; no bloqueante.)
>
> **Entorno:** `./venv/bin/python`. Tests: `./venv/bin/python manage.py test apps.tutores --noinput`.

## Flujo offline/online (resumen)

1. Hijo nuevo (offline) → draft `HijosRow` (sin `serverPacienteId`).
2. Tutor carga antecedentes desde Pendientes → draft `AntecedentesNinoRow` (pendiente). El pendiente desaparece.
3. Hay red → `HijosSyncer` postea el alta, **captura `serverPacienteId`**.
4. `AntecedentesNinoSyncer` ve que el hijo ya tiene `serverPacienteId` → postea al endpoint nuevo → marca sincronizado.
   - Si los antecedentes se cargan **online** (hijo ya sincronizado), el paso 4 ocurre en la siguiente vuelta sin esperar.

## Testing

- `AntecedentesNinoController`: precarga desde borrador existente; `guardar()` arma el payload de los 20 campos (con condicionales); upsert (segundo guardar actualiza, no duplica).
- `AntecedentesNinoSyncer`: postea a `/tutores/<t>/hijos/<serverPacienteId>/antecedentes-personales/` cuando el hijo tiene `serverPacienteId`; resultado transitorio cuando no.
- `HijosSyncer`: captura y persiste `serverPacienteId` del `201`.
- Pendiente: aparece para hijo sin antecedentes; desaparece al cargarlos (watch reactivo).
- Migración 5→6: crea `AntecedentesNinoRows` y agrega `serverPacienteId` a `HijosRows` (guard `if (from >= ...)` como las otras).
- Pantalla: render de cards; menstruación visible solo con sexo F; `descripcion_tratamiento`/`edad_primera_menstruacion` condicionales.

## Fuera de alcance

- Campos del PDF que no están en el modelo (preocupa, fecha menstruación).
- Pull incremental / multi-dispositivo (la detección de pendientes es local).
- La etapa de operativo (médicos + escuela).
