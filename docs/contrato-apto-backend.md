# Contrato backend — Apto físico (Slice A)

> Handoff del backend (`prosane_api`) para el front. Estado: **implementado y andando**
> en `feat/permisos-data-driven` (commits hasta `5cd833c`). Verificado con smoke real.
> Spec de origen: `prosane_api/docs/superpowers/specs/2026-06-11-apto-fisico-slice-a-design.md`.

El **"apto físico"** del menú (`crearApto`/`firmarApto`/`verApto`) ya tiene endpoints reales.
Es un certificado con ciclo **borrador editable → firmado inmutable**.

## Autenticación
Todos los endpoints requieren `Authorization: Bearer <access_token>` (el mismo token de
`/api/v1/auth/token/`). Además, gating por **acción** (server-side): el usuario tiene que
tener la acción correspondiente o recibe **403**. Médico y odontólogo ya las tienen.

Las acciones que habilitan el menú vienen en `GET /api/v1/auth/me` → `actions[]`:
- `crearApto` — crear / editar borrador
- `firmarApto` — firmar
- `verApto` — listar / ver

(Usá `can('crearApto')` etc. desde el payload de `/me`. **camelCase**, sin excepción.)

## Recurso `Apto`
**`id` es UUID** (no entero). Ojo con el routing del front.

Forma del objeto en las respuestas (JSON):
```jsonc
{
  "id": "4356ab87-13a2-4dea-977a-7709903a6faf",
  "paciente": 12,                  // id (int) del Paciente (NNA)
  "profesional": "9b2c...-0001",   // id (uuid) del Usuario que lo creó/firmó
  "estado": "borrador",            // "borrador" | "firmado"
  "peso_kg": "40.50",              // editable en borrador (decimal como string)
  "altura_cm": "145.00",           // editable en borrador
  "observaciones": "",             // editable en borrador
  // --- snapshots: null en borrador, se completan AL FIRMAR ---
  "nna_nombre_completo": "Smoke2 NNA",
  "nna_edad": 9,
  "profesional_nombre": "Mariana Médica",
  "matricula_firmante": null,      // por ahora null (pendiente reconciliar professionals)
  "fecha_emision": "2026-06-11",
  "validez_hasta": "2027-06-11",   // +1 año
  "firma_hash": "d2a88b40...",     // SHA-256 (integridad, no firma criptográfica)
  "timestamp_firma": "2026-06-11T12:00:00Z"
}
```
> ⚠️ El **DNI del NNA NO se expone** (dato sensible de menor). No lo pidas por acá.

## Endpoints (base `/api/v1/aptos/`)

### 1. Crear apto (borrador) — acción `crearApto`
```
POST /api/v1/aptos/
body: { "paciente": <id_int_del_paciente> }
→ 201  { ...Apto en estado "borrador"... }
→ 400  si falta "paciente"   |  403 sin la acción  |  401 sin auth
```

### 2. Listar / ver — acción `verApto`
```
GET /api/v1/aptos/            → 200 [ ...Aptos... ]
GET /api/v1/aptos/<uuid>/     → 200 { ...Apto... }   | 404 si no existe
```

### 3. Editar borrador — acción `crearApto`
```
PATCH /api/v1/aptos/<uuid>/
body: { "peso_kg"?, "altura_cm"?, "observaciones"? }
→ 200  { ...Apto actualizado... }
→ 409  si el apto YA está firmado (es inmutable)
```

### 4. Firmar — acción `firmarApto`
```
POST /api/v1/aptos/<uuid>/firmar/
(sin body)
→ 200  { ...Apto en estado "firmado", con snapshots + firma_hash... }
→ 409  si ya estaba firmado
```

## Flujo típico en el front (médico)
1. Elegir un paciente → `POST /aptos/ {paciente}` → guardás el `id` (uuid).
2. Cargar peso/altura/observaciones → `PATCH /aptos/<id>/`.
3. Revisar y `POST /aptos/<id>/firmar/` → queda inmutable; mostrás el certificado.
4. Listar los aptos del sistema con `GET /aptos/`.

## Pendiente conocido (no bloquea el front)
- `matricula_firmante` viene `null` hasta que el backend reconcilie `professionals`.
- No hay generación de PDF todavía (`pdf_url` no existe aún).
- El apto hoy es **standalone**; cuando exista el CIS se enganchará (`cis_id`), sin romper
  esta forma de respuesta.

## Prerequisito para probar
Hace falta al menos un **Paciente** cargado (NNA). Usuarios de prueba: `medico@prosane.test`
/ `prosane-dev-2026` (tras `reset_permissions_data --with-users` en el backend).
