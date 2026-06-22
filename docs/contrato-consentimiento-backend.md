# Contrato backend — Consentimiento (Slice B)

> Handoff del backend (`prosane_api`) para el front. Estado: **implementado y andando**
> en `feat/permisos-data-driven` (commits hasta `bb8104f`). Verificado con smoke real.
> Spec: `prosane_api/docs/superpowers/specs/2026-06-11-consentimiento-slice-b-design.md`.
> Complementa a `contrato-apto-backend.md`.

El **consentimiento** es obligatorio antes de cualquier control (Ley 26.529). Lo registra
la familia (`darConsentimiento`, rol **tutor**). Es **un acto en un paso** (crear = consentir):
no hay borrador ni edición posterior — un consentimiento dado es inmutable.

## Autenticación
`Authorization: Bearer <access_token>`. Gating por **acción** (403 si el rol no la tiene):
- `darConsentimiento` — crear (rol **tutor**).
- `verConsentimiento` — listar / ver (roles **medico, odontologo, tutor**: el profesional
  verifica que haya consentimiento antes del control; la familia ve el suyo).

Ambas vienen en `GET /api/v1/auth/me` → `actions[]`. Usá `can('darConsentimiento')` /
`can('verConsentimiento')` para el menú. **camelCase**.

## Recurso `Consentimiento`
**`id` es UUID.**

Forma del objeto en las respuestas:
```jsonc
{
  "id": "1f44ae02-...-uuid",
  "paciente": 12,                       // id (int) del Paciente (NNA)
  "firma_tipo": "adulto_responsable",   // "adulto_responsable" | "nna_mayor_13"
  "adulto_nombre": "Marta",             // identidad de quien consiente (snapshot)
  "adulto_apellido": "Tutora",
  "adulto_tipo_documento": "DNI",
  "firma_hash": "ce5409d3...",          // SHA-256 (integridad/trazabilidad, no firma criptográfica)
  "fecha_firma": "2026-06-11T12:00:00Z"
}
```
> ⚠️ El **`adulto_dni` NO se devuelve** (dato sensible). Se manda al crear, no se expone.
> `firma_tipo='nna_mayor_13'` se usa cuando consiente el propio adolescente ≥13 (autonomía
> progresiva); en ese caso los campos `adulto_*` llevan los datos del NNA.

## Endpoints (base `/api/v1/consentimientos/`)

### 1. Registrar consentimiento — acción `darConsentimiento` (tutor)
```
POST /api/v1/consentimientos/
body: {
  "paciente": <id_int>,
  "firma_tipo": "adulto_responsable" | "nna_mayor_13",
  "adulto_nombre": "...", "adulto_apellido": "...",
  "adulto_tipo_documento": "DNI", "adulto_dni": "22333444"
}
→ 201  { ...Consentimiento (con firma_hash + fecha_firma, sin adulto_dni)... }
→ 400  body inválido (falta campo / firma_tipo fuera de las opciones)
→ 403  sin la acción   |   401 sin auth
```

### 2. Listar / ver — acción `verConsentimiento` (medico, odontologo, tutor)
```
GET /api/v1/consentimientos/            → 200 [ ...Consentimientos... ]
GET /api/v1/consentimientos/<uuid>/     → 200 { ...Consentimiento... }   | 404 si no existe
```

## Flujo típico en el front
1. La familia (tutor) completa los datos y `POST /consentimientos/` → 201 (queda firmado).
2. El profesional, antes de crear el apto/control, hace `GET /consentimientos/` para
   verificar que exista el consentimiento del paciente.

## Pendiente conocido (no bloquea el front)
- Hoy es **standalone** (linkeado al Paciente); cuando exista el CIS se enganchará
  (`cis_id`), sin cambiar esta forma de respuesta.
- La regla "no se puede crear un apto/control sin consentimiento previo" **todavía no se
  fuerza** server-side (se hará cuando esté el CIS). Por ahora el front puede chequear con
  el GET.
- Revocación de consentimiento: futuro.
