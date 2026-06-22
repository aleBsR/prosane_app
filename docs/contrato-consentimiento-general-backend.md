# Contrato backend — Consentimiento general + Antecedentes familiares (a nivel TUTOR)

> **Handoff del front (`prosane_app`) al backend (`prosane_api`).** Lo que la app necesita
> que exista en el backend para cerrar la "primera parte" (tutor + hijo).
> Base: rama `dev-base` (apps/ con UUID + BaseModel + permisos data-driven).
> **Importante:** en esta etapa el consentimiento es **solo un checkbox de aceptación**.
> **No hay firma** (ni dibujada, ni `firma_hash`, ni entidad criptográfica) — la firma es
> una etapa futura. No agregar nada de firma todavía.

## Contexto del modelo (qué cambió y por qué)
- El **consentimiento es general del tutor**, NO por hijo. Es un acto de aceptación (checkbox).
- Es **precondición**: un tutor sin consentimiento aceptado **no puede registrar hijos**.
- Los **antecedentes de salud del padre/madre/hermanos** (sección del PDF "ANTECEDENTES DE
  SALUD DEL PADRE/MADRE Y/O HERMANOS DEL NIÑO O ADOLESCENTE") son **del tutor**, se cargan
  **una sola vez** (no por hijo).
- En consecuencia, el alta de hijo (`POST /tutores/<id>/hijos/`) **deja de recibir** los
  bloques `consentimiento` y `antecedentes_familiares` (pasan a nivel tutor).

---

## 1) Modelo `Tutor` — flags de consentimiento

Agregar al modelo `Tutor`:
- `consentimiento_aceptado: BooleanField(default=False)`
- `fecha_consentimiento: DateTimeField(null=True, blank=True)`

+ migración.

## 2) Endpoint — aceptar consentimiento (checkbox)

```
POST /api/v1/tutores/<uuid:tutor_id>/consentimiento/
Auth: Bearer <access>    (rol tutor; gatear con acción, ver "Permisos")
Body: {}                  # vacío; es solo la aceptación del checkbox
                          # (aceptar opcionalmente {"aceptado": true})

→ 200 OK
{
  "consentimiento_aceptado": true,
  "fecha_consentimiento": "2026-06-22T18:30:00Z"
}
→ 403 si el rol no tiene la acción | 401 sin auth | 404 si el tutor no existe / no es del usuario
```
- **Idempotente:** si ya estaba aceptado, responde 200 igual (no error). Setea
  `fecha_consentimiento = now()` la primera vez (o la deja; a criterio, pero que no rompa).
- Debe validar que el `tutor_id` corresponde al usuario autenticado (igual que ya se hace en
  `TutorHijosView._verificar_tutor`).

## 3) Modelo `AntecedentesFamiliares` (FK Tutor, uno por tutor)

Modelo nuevo con `BaseModel` (UUID + auditoría), **FK/OneToOne a `Tutor`** (uno por tutor).
Campos (de la sección del PDF):
- `problema_salud_importante`: choices `('si','no','no_sabe')` (CharField)
- `problema_salud_cual`: `CharField/TextField(blank=True, null=True)`  # detalle si "si"
- `muerte_subita_familiar`: choices `('si','no','no_sabe')` (CharField)

+ migración.

## 4) Endpoint — antecedentes familiares (upsert, 1 por tutor)

```
GET  /api/v1/tutores/<uuid:tutor_id>/antecedentes-familiares/
→ 200 { ...antecedentes... }   | 404 si todavía no cargó

POST /api/v1/tutores/<uuid:tutor_id>/antecedentes-familiares/   (crea o actualiza — upsert)
Auth: Bearer <access> (rol tutor)
Body:
{
  "problema_salud_importante": "si" | "no" | "no_sabe",
  "problema_salud_cual": "string (opcional)",
  "muerte_subita_familiar": "si" | "no" | "no_sabe"
}
→ 200/201 { ...antecedentes guardados... }
→ 400 body inválido | 403 sin acción | 401 sin auth | 404 tutor inexistente/ajeno
```
- **Upsert:** un solo registro por tutor. Segundo POST actualiza el existente.
- Validar pertenencia del tutor al usuario autenticado.

## 5) `/me` — exponer estado de las tareas generales (aditivo)

En `GET /api/v1/auth/me/`, dentro de `user`, agregar **dos booleanos** (la app los usa para
el gating y para los pendientes):
```jsonc
"user": {
  ... (lo actual: id, email, nombre, apellido, tipo_dni, dni, is_staff, tutor_id) ...,
  "consentimiento_aceptado": true,          // de Tutor.consentimiento_aceptado
  "antecedentes_familiares_completos": true // true si existe el registro AntecedentesFamiliares del tutor
}
```
- Para usuarios sin tutor (otros roles) → ambos `false` (o el valor que corresponda); no romper.
- Es **aditivo** (no cambiar/quitar las claves existentes).

## 6) Alta de hijo — quitar consentimiento y antecedentes familiares

En `POST /api/v1/tutores/<id>/hijos/` (serializer `HijoCreateSerializer` + servicio `crear_hijo`):
- **Dejar de requerir/usar** los bloques `consentimiento` y `antecedentes_familiares`. El front
  **ya no los va a enviar**. Que el alta funcione sin ellos (no 400 por ausencia).
- Lo que el front **seguirá enviando** en el alta de hijo:
```jsonc
{
  "persona": { "nombre","apellido","dni","tipo_dni","sexo","fecha_nacimiento" },
  "domicilio": { "calle","nro_calle","provincia" },
  "edad": <int>,
  "tiene_cud": "Sí|No|En trámite",
  "tipo_cobertura": "Obra social|Prepaga|Sin cobertura",
  "nombre_cobertura": "string",
  "parentesco": "Hijo/a|...",
  "antecedentes_personales": { "asma_espasmos": bool, "diabetes": bool }
}
```
  (Es decir: **se va `consentimiento` y se va `antecedentes_familiares`** del payload de hijo.)
- **Recomendado (defensa server-side):** rechazar el alta de hijo si el tutor no tiene
  `consentimiento_aceptado` (ej. `409`/`403` con `{"detail": "consentimiento_requerido"}`).
  El front igual gatea con alerta, pero está bueno reforzarlo. Si lo agregan, avisen el código
  y el body exacto del error para mapearlo.
- Si los campos de consentimiento que se habían agregado a `Paciente` (`consentimiento_aceptado`,
  `fecha_consentimiento`, `adulto_*`) quedan sin uso, pueden **dejarse** por ahora (no es
  bloqueante) o limpiarse en una pasada aparte — a criterio del backend.

## 7) Permisos (data-driven)

Reusar el esquema de acciones/seed existente. Sugerencia de acciones (rol **tutor**):
- `darConsentimiento` → endpoints de §2 (aceptar consentimiento).
- `cargarAntecedentesFamiliares` (o reusar una existente) → endpoints de §4.
- (`verConsentimiento` / lectura si hace falta para otros roles, a futuro.)

Agregarlas a `apps/usuarios/fixtures/actions.json` + `ROLE_ACTIONS["tutor"]` en
`seed_permissions`, y correr el seed. Si prefieren no agregar acciones nuevas y gatear solo por
rol tutor, está OK — avisen cómo quedó así el front no asume gating por acción.

## 8) Entorno (recordatorio)
- venv del repo: `./venv/bin/python` (Python 3.13). Tests: `./venv/bin/python manage.py test <app> --noinput`.

---

## Resumen de lo que el FRONT necesita (checklist para el backend)
1. `Tutor.consentimiento_aceptado` + `fecha_consentimiento` (+migración).
2. `POST /tutores/<id>/consentimiento/` (aceptar, idempotente) → `{consentimiento_aceptado, fecha_consentimiento}`.
3. Modelo `AntecedentesFamiliares` (FK Tutor, 1x) (+migración).
4. `GET`/`POST` `/tutores/<id>/antecedentes-familiares/` (upsert).
5. `/me` → `user.consentimiento_aceptado` + `user.antecedentes_familiares_completos` (aditivo).
6. Alta de hijo sin `consentimiento` ni `antecedentes_familiares` (no romper); opcional: rechazar alta sin consentimiento.
7. Acciones/seed de permisos para tutor (o gating por rol) — avisar cuál.

## Lo que el FRONT enviará / consumirá (resumen)
- **Enviará:** POST vacío a consentimiento; POST antecedentes con los 3 campos; alta de hijo sin los 2 bloques removidos.
- **Consumirá:** los 2 flags en `/me` (para gatear "Registrar hijo" y armar los pendientes); el GET de antecedentes para precargar/editar.
