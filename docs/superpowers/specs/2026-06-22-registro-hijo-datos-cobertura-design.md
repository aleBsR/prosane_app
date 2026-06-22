# Entrega 1 — Registro de hijo: Datos del niño + Cobertura (rediseño del formulario)

**Fecha:** 2026-06-22
**Estado:** Diseño aprobado
**Alcance:** Solo la **Entrega 1**. La Entrega 2 (pantalla de "Antecedentes de salud del niño o adolescente" + su pendiente, online/offline) tiene su propio spec aparte.

## Objetivo

Ampliar el formulario de alta de hijo (`planilla_screen` + `planilla_controller`) para que capture **todos** los campos de las secciones "DATOS DEL NIÑO O ADOLESCENTE" y "Cobertura de salud" de la planilla PROSANE 2025 (`docs/04-recursos/planilla-prosane-2025.pdf`, bloque "PARA SER COMPLETADO POR LA FAMILIA"), y quitar de este formulario los antecedentes de salud (que pasan a la Entrega 2).

## Contexto / estado actual

El formulario hoy captura un subconjunto:
- **Datos del niño:** nombre, apellido, dni, tipo_dni, sexo, fecha_nacimiento, parentesco.
- **Domicilio:** calle, nro_calle, provincia (solo 3 de 11 campos del modelo).
- **Cobertura:** tipo_cobertura (3 opciones), nombre_cobertura, tiene_cud (con un valor `En trámite` que **no entra** en la columna del backend).
- **Antecedentes (a quitar):** dos `AppSwitch` sueltos — `asma_espasmos` y `diabetes`.

Persistencia: **offline-first**. `PlanillaController.guardar()` arma un `payload` JSON y lo escribe como borrador en Drift (`AppDatabase.insertHijoDraft`), que el `syncScheduler` empuja al backend después (`POST /api/v1/tutores/<tutor_id>/hijos/`). Esto **no cambia** en esta entrega.

El endpoint de alta ya acepta `persona` / `domicilio` / cobertura completos (ver `docs/contrato-hijos-backend.md`).

## Dependencia de backend (teléfonos)

El PDF pide **Teléfono fijo** y **Celular** en "Datos del niño", pero no existen en `Persona`/`Domicilio`/`Paciente`/`Tutor`. El lugar correcto es `Persona` (la persona del NNA). Hay un prompt de handoff entregado al backend para agregar `telefono_fijo` y `celular` a `Persona` (+migración) y aceptarlos en el bloque `persona` del alta de hijo.

**Decisión:** el front incluye los 2 campos **ya** y los envía dentro del bloque `persona`. Mientras el backend no los persista, los ignora (son opcionales) y **no rompe** el alta. No hay bloqueo para la Entrega 1.

## Inventario de campos y mapeo (PDF → estado → payload)

Restricciones de longitud del backend a respetar (valores enviados): `tiene_cud` ≤ 2, `tipo_cobertura` ≤ 20, `nombre_cobertura` ≤ 20, `nro_calle/piso/dpto/manzana/casa/nro_casa` ≤ 10, `pieza/provincia/departamento/localidad` ≤ 20, `telefono_fijo/celular` ≤ 20.

### Card 1 — "Datos del niño o adolescente"
| Campo PDF | Campo de estado | Widget | Bloque payload | Notas |
|---|---|---|---|---|
| Nombre | `nombre` | AppTextField | `persona.nombre` | requerido |
| Apellido | `apellido` | AppTextField | `persona.apellido` | requerido |
| Tipo de documento | `tipoDni` | AppDropdownField (DNI / Pasaporte) | `persona.tipo_dni` | default `DNI` |
| N° de documento | `dni` | AppTextField (numérico) | `persona.dni` | requerido |
| Sexo (F/M) | `sexo` | AppDropdownField (F / M / X) | `persona.sexo` | requerido; se mantiene `X=Otro` (superset del PDF) |
| Fecha de nacimiento | `fechaNacimiento` | AppDateField | `persona.fecha_nacimiento` (YYYY-MM-DD) | requerido; `edad` se deriva con `_edadEnAnios` |
| CUD (SI/NO) | `tieneCud` | AppDropdownField (Sí=`SI` / No=`NO`) | `tiene_cud` | **se mueve a esta card**; se quita `En trámite` (no entra en `max_length=2` ni está en el PDF) |
| Teléfono fijo | `telefonoFijo` | AppTextField (phone) | `persona.telefono_fijo` | **nuevo**; backend pendiente |
| Celular | `celular` | AppTextField (phone) | `persona.celular` | **nuevo**; backend pendiente |
| (parentesco — app) | `parentesco` | AppDropdownField | `parentesco` | se mantiene tal cual (no está en el PDF pero el backend lo usa) |

### Card 2 — "Domicilio" (los 11 campos del modelo `Domicilio`)
| Campo PDF | Campo de estado | payload `domicilio.*` |
|---|---|---|
| Calle | `calle` | `calle` |
| N° | `nroCalle` | `nro_calle` |
| Piso | `piso` | `piso` |
| Dpto. | `dpto` | `dpto` |
| Manzana | `manzana` | `manzana` |
| Casa | `casa` | `casa` |
| N° (casa) | `nroCasa` | `nro_casa` |
| Pieza | `pieza` | `pieza` |
| Provincia | `provincia` | `provincia` |
| Departamento | `departamento` | `departamento` |
| Localidad | `localidad` | `localidad` |

Todos texto, todos opcionales. `calle`, `nroCalle`, `provincia` ya existen; se agregan los otros 8.

### Card 3 — "Cobertura de salud" (selección única entre 4, como el PDF)
`AppDropdownField` con **códigos cortos** como `value` (para `tipo_cobertura` ≤ 20) y el texto del PDF como `label`:

| Opción PDF | `value` (→ `tipo_cobertura`) |
|---|---|
| Obra Social (incluye PAMI) | `obra_social` |
| Programas o planes estatales de Salud | `estatal` |
| Plan privado o Prepaga | `prepaga` |
| No tiene Obra Social, Prepaga o Plan estatal | `sin_cobertura` |

- **Nombre de la cobertura** (`nombreCobertura` → `nombre_cobertura`, AppTextField, opcional): visible **solo** cuando `tipoCobertura ∈ {obra_social, prepaga}`. Si el usuario cambia a `estatal`/`sin_cobertura`, se limpia el valor.

### Se quita del formulario
La card "Antecedentes del niño/a" con los `AppSwitch` de `asma_espasmos` y `diabetes`, su estado (`asmaEspasmos`, `diabetes`), sus setters y el bloque `antecedentes_personales` del payload. Pasan a la Entrega 2.

## Payload resultante (`PlanillaController.guardar`)

```jsonc
{
  "persona": {
    "nombre", "apellido", "dni", "tipo_dni", "sexo",
    "fecha_nacimiento",        // YYYY-MM-DD
    "telefono_fijo", "celular" // nuevos
  },
  "domicilio": {
    "calle","nro_calle","piso","dpto","manzana","casa",
    "nro_casa","pieza","provincia","departamento","localidad"
  },
  "edad": <int derivado de fecha_nacimiento>,
  "tiene_cud": "SI" | "NO",
  "tipo_cobertura": "obra_social" | "estatal" | "prepaga" | "sin_cobertura",
  "nombre_cobertura": "<texto o vacío>",
  "parentesco": "<...>"
  // ya NO se envía "antecedentes_personales"
}
```

## Componentes a modificar

1. **`lib/features/hijos/presentation/controllers/planilla_controller.dart`**
   - `PlanillaState`: agregar `telefonoFijo, celular, piso, dpto, manzana, casa, nroCasa, pieza, departamento, localidad` (String, default `''`); **quitar** `asmaEspasmos, diabetes`. Actualizar `copyWith`.
   - `puedeGuardar`: sin cambios (nombre, apellido, dni, sexo, fechaNacimiento).
   - Setters: agregar los nuevos; quitar `setAsmaEspasmos`, `setDiabetes`.
   - `guardar()`: armar el payload de arriba.
2. **`lib/features/hijos/presentation/screens/planilla_screen.dart`**
   - Card 1: agregar Teléfono fijo, Celular; mover CUD acá (Sí/No); CUD pasa a valores `SI`/`NO`.
   - Card 2: agregar los 8 campos de domicilio faltantes.
   - Card 3: dropdown de cobertura a 4 opciones con códigos; `nombre_cobertura` condicional.
   - Quitar la card de antecedentes (asma/diabetes).

Sin cambios en el provider, en la base de datos local, ni en el scheduler.

## Flujo de datos y errores

- Igual que hoy: `guardar()` escribe el borrador en Drift (offline-first) y, al volver con `error == null`, la screen dispara `syncScheduler.dispararPorEscritura()` y navega a `/inicio`.
- Errores de escritura local → `state.error` (ya se muestra en la screen). Errores de sync (incl. validación backend de los nuevos campos) → los maneja el scheduler/reintento existente; fuera de alcance de esta entrega.

## Testing

- **`planilla_controller_test`**: actualizar/crear casos que verifiquen el shape del payload nuevo (persona con teléfonos, domicilio con 11 campos, `tiene_cud` `SI/NO`, `tipo_cobertura` con códigos, **ausencia** de `antecedentes_personales`); `puedeGuardar` con requeridos.
- **`planilla_screen_test`**: render de las 3 cards y sus campos; la card de antecedentes **no** está; `nombre_cobertura` aparece solo con `obra_social`/`prepaga`; CUD muestra Sí/No.

## Fuera de alcance (Entrega 2, spec aparte)

- Pantalla "Antecedentes de salud del niño o adolescente" (los 20 campos de `AntecedentePersonal`: 18 Sí/No/No sabe, `peso_nacimiento` numérico, menstruación condicional, + los campos de texto "¿Cuál?/causa/preocupa" y el gap de "¿Hay algo de la salud que le preocupa?" que hoy no está en el modelo).
- Su pendiente por hijo (detección de hijos sin antecedentes — requiere flag del backend).
- Persistencia **online + offline-first** de esos antecedentes.
- Endpoint nuevo de antecedentes por paciente (handoff backend).
