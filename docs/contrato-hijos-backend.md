# Contrato backend — Registro de hijo (planilla familiar)

> Handoff de `prosane_api` @ rama `feat/primera-parte-registro-familiar` (sale de `dev-base`)
> para el front. Endpoint **agregado**: crea el hijo (NNA) con antecedentes y consentimiento
> en una sola transacción. Verificado con tests (`apps/tutores/tests.py::CrearHijoAgregadoTest`).

## Auth
`Authorization: Bearer <access>`. Solo el **tutor dueño** (`request.user == tutor.usuario`); si no, **403**.
El `tutor_id` (id del Tutor, distinto del id del Usuario) viene en `GET /api/v1/auth/me` →
`user.tutor_id`.

## POST /api/v1/tutores/<uuid:tutor_id>/hijos/
Crea Persona + Domicilio + Paciente + AntecedentePersonal + AntecedenteFamiliar y graba el
consentimiento en el Paciente, todo en una `transaction.atomic` (todo o nada).

```jsonc
body: {
  "persona":   { "nombre","apellido","dni","tipo_dni","sexo","fecha_nacimiento" },
  "domicilio": { "calle","nro_calle","piso","dpto","manzana","casa","nro_casa","pieza",
                 "provincia","departamento","localidad" },   // todos opcionales salvo los que tu UI exija
  "edad": 10,
  "tiene_cud": "NO",
  "tipo_cobertura": "obra_social",
  "nombre_cobertura": "OSDE",
  "parentesco": "padre",                                      // opcional; se guarda en el Tutor
  "antecedentes_personales": { "asma_espasmos":"SI", "diabetes":"NO", ... },  // opcional; campos con default
  "antecedentes_familiares": { "problemas_salud":"SI", "detalle_problema_salud":"...",
                               "familiar_con_muerte_subita":"NO" },           // opcional
  "consentimiento": { "adulto_nombre","adulto_apellido","adulto_tipo_documento","adulto_dni" } // opcional pero recomendado
}

→ 201 {
  "id", "persona", "domicilio", "tutor", "edad", "tiene_cud",
  "tipo_cobertura", "nombre_cobertura",
  "consentimiento_aceptado", "fecha_consentimiento",
  "adulto_nombre", "adulto_apellido", "adulto_tipo_documento"
}                                  // ⚠️ adulto_dni NO se expone (dato sensible)
→ 400  dni duplicado / body inválido
→ 403  no es el tutor dueño
→ 401  sin auth
```

## GET /api/v1/tutores/<uuid:tutor_id>/hijos/
Lista los hijos del tutor (mismo shape de salida, sin `adulto_dni`).

## Notas / invariantes
- `consentimiento_aceptado=true` y `fecha_consentimiento=now` los setea el server cuando viene
  el bloque `consentimiento`. Si no viene, quedan `false`/`null`.
- `parentesco` vive en el `Tutor` (un parentesco por tutor en v1): cada alta lo sobrescribe.
- Antecedentes Sí/No/No sabe viajan como **strings**.
- `firma_tipo` no aplica en v1: el consentimiento es siempre del adulto responsable (el tutor).

## Deuda conocida (no bloquea)
- `BaseModel.save(update_fields=...)` en el repo no incluye `updated_year/month` de forma
  sistémica (patrón pre-existente en `common/models.py`); en este endpoint se mitigó en el
  `save` del parentesco, pero conviene arreglarlo de raíz en `BaseModel`.
