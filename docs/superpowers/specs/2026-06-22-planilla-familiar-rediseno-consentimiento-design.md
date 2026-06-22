# Rediseño de la planilla familiar + consentimiento por hijo — Design

**Fecha:** 2026-06-22
**Repos:** `prosane_app` (Flutter, principal) · `prosane_api` (Django, cambio aditivo en `/me`)
**Rama base:** se trabaja sobre la línea de `dev` (app) / `dev-base` (api).

## Objetivo
Cerrar la parte **tutor + hijo** de PROSANE: rediseñar la planilla familiar (formulario **por hijo**) para que respete el design system del registro, e incorporar el **consentimiento como primera parte del formulario**, tal como la planilla PDF oficial ("Evaluación Integral de Salud — Para ser completado por la familia").

## Contexto
- La planilla actual (`lib/features/hijos/presentation/screens/planilla_screen.dart`) es un scroll de `AppTextField`/`AppSwitch` sobre el gradiente, con campos tipeados a mano (sexo "M/F/X", fecha "AAAA-MM-DD", tipo doc, edad, CUD "Sí/No"). No respeta la simetría del wizard de registro, que usa `DropdownButtonFormField`, date picker y `AppCard` con labels oscuros.
- El registro duplica la decoración de dropdown en `step_documento.dart` y `step_datos_personales.dart` → se extrae a componentes reutilizables.
- Según el PDF, el **consentimiento es por hijo** y es la primera parte del formulario familiar (autorización del adulto responsable a la evaluación integral). La firma/persistencia "fuerte" (firma_hash / entidad `Consentimiento` propia) queda **pendiente de decisión del equipo** y fuera de este alcance.

## Decisiones tomadas (con el usuario)
- Estructura: **misma pantalla con scroll**, cada sección en su `AppCard` (no wizard multi-paso).
- Parentesco: **dropdown**. Provincia: **texto** por ahora. **Sin** refactor del registro.
- Consentimiento: **por hijo**, primera sección del formulario. Checkbox "Acepto los términos del consentimiento" + link "Ver términos de consentimiento" → **modal** con texto breve y resaltado.
- Adulto responsable: **prefill desde la sesión, bloqueado** (read-only).
- Regla "≥13 no requiere firma de adulto": **omitida por ahora** (siempre adulto responsable).
- Contrato del payload de creación de hijo: **sin cambios** (sigue mandando el bloque `consentimiento` con los datos del adulto cuando se acepta).

---

## Arquitectura / Componentes

### 1. Componentes nuevos en `lib/core/design_system/`

#### `AppDropdownField`
Label (`AppTypography.subtitulo`) + `DropdownButtonFormField<String>` con la decoración estándar (fill `AppColors.campo`, radio `AppRadii.campo`, borde transparente, focus `AppColors.primario` 1.5).
- Props: `label` (String), `hint` (String?), `value` (String?), `items` (`List<({String value, String label})>`), `onChanged` (`ValueChanged<String>`), `key`.
- Oculta el detalle de `DropdownMenuItem` (los arma desde `items`).

#### `AppDateField`
Label + recuadro tappable (`AppColors.campo`, radio `AppRadii.campo`) que muestra `dd/mm/aaaa` (o `hint` si null) + ícono calendario, y abre `showDatePicker`.
- Props: `label`, `value` (DateTime?), `onChanged` (`ValueChanged<DateTime>`), `firstDate`, `lastDate`, `hint`, `key`.

> Estos componentes replican el patrón ya probado del registro; el registro **no** se refactoriza ahora (se podría más adelante para DRY).

### 2. Prerrequisito backend — extender `/me` (aditivo)
Para el prefill bloqueado del adulto responsable se necesitan nombre, apellido, tipo de documento y DNI del tutor. Hoy `/me` devuelve solo `nombre` + `apellido`.

- **`prosane_api`** `apps/usuarios/views.py` `MeView`: agregar a `user` los campos `tipo_documento` y `dni` desde `user.persona` (apellido ya está). Cambio **aditivo** (no rompe el contrato congelado).
- **`prosane_app`**:
  - `MeResponse` DTO: parsear `apellido`, `tipo_documento`, `dni` por separado (hoy junta nombre+apellido).
  - `Usuario` entity (`core/session/entities.dart`): agregar `apellido`, `tipoDocumento`, `dni` (opcionales).
  - Threading: del DTO a la sesión y al cache de Drift (`cached_session`).

### 3. Rediseño de `PlanillaScreen` (formulario por hijo, en `AppCard`s)

Cada sección en su propia `AppCard` con label oscuro (`_SectionTitle` pasa a estilo oscuro dentro de card).

**Sección 0 — Consentimiento (primera parte):**
- Línea introductoria + **checkbox** "Acepto los términos del consentimiento" (`AppSwitch` o checkbox; usar `AppSwitch` para consistencia).
- Link **"Ver términos de consentimiento"** (`AppLink`) → abre **modal** (`showDialog` / `AlertDialog` o bottom sheet) con el texto breve y resaltado:
  > Autorizo que el equipo de salud le realice a **[nombre del hijo/a]** un **examen clínico y odontológico** y le aplique las **vacunas** correspondientes para completar el calendario si fuese necesario. Los datos brindados serán tratados con **máxima confidencialidad**. Ante cualquier duda puedo acercarme a la escuela o al centro de salud.
- **Adulto responsable** (prefill bloqueado desde la sesión, no editable): Nombre, Apellido, Tipo de documento, N° de documento. Se muestran como texto read-only (no inputs).

**Sección 1 — Datos del niño/a:**
- Nombre, Apellido, DNI → `AppTextField`.
- Tipo de documento → `AppDropdownField` (DNI / Pasaporte).
- Sexo → `AppDropdownField` (Femenino=F / Masculino=M / Otro=X).
- Fecha de nacimiento → `AppDateField`.
- Edad → **derivada** de la fecha de nacimiento (read-only, se calcula y se sigue enviando en el payload).
- Parentesco → `AppDropdownField` (Hijo/a, Hijastro/a, Nieto/a, Sobrino/a, Tutelado/a, Otro).

**Sección 2 — Domicilio:** Calle, Número (`AppTextField`), Provincia (`AppTextField`, texto por ahora).

**Sección 3 — Cobertura médica:**
- Tipo de cobertura → `AppDropdownField` (Obra social / Prepaga / Sin cobertura).
- Nombre de la cobertura → `AppTextField`.
- Tiene CUD → `AppDropdownField` (Sí / No / En trámite).

**Sección 4 — Antecedentes:** `AppSwitch` (sin cambios).

### 4. Comportamiento
- **"Guardar" atenuado** (usa el estado disabled de `AppButton` ya implementado) hasta cumplir: nombre, apellido, DNI, fecha de nacimiento y sexo del niño completos **y** consentimiento aceptado.
- **Edad derivada**: `planilla_controller` calcula `edad` a partir de `fechaNacimiento` (en años cumplidos) y la incluye en el payload; ya no hay setter manual de edad desde la UI.
- **Adulto responsable**: el controller toma nombre/apellido/tipoDoc/dni de la sesión (no de inputs). El bloque `consentimiento` del payload se arma con esos datos cuando `consentimientoAceptado == true`.
- **Nudge/badge de Pendientes**: cambiar la copia del nudge de `"Completá el consentimiento de tu hijo"` a `"Completá la evaluación de tu hijo"` (representa el formulario familiar completo, no solo el consentimiento). La lógica del badge no cambia.

### 5. Payload (sin cambios de contrato)
Se mantiene la forma actual de `POST /tutores/<id>/hijos/`:
```jsonc
{
  "persona": { "nombre","apellido","dni","tipo_dni","sexo","fecha_nacimiento" },
  "domicilio": { "calle","nro_calle","provincia" },
  "edad": <int derivado>,
  "tiene_cud": "...", "tipo_cobertura": "...", "nombre_cobertura": "...",
  "parentesco": "...",
  "antecedentes_personales": { "asma_espasmos","diabetes" },
  "antecedentes_familiares": { "asma","diabetes" },
  "consentimiento": { "adulto_nombre","adulto_apellido","adulto_tipo_documento","adulto_dni" } // si aceptado, desde la sesión
}
```

## Fuera de alcance
- Persistencia "firma" fuerte (firma_hash / entidad `Consentimiento` propia en `apps/`) → pendiente de decisión del equipo.
- Regla ≥13 (autonomía progresiva / `firma_tipo=nna_mayor_13`).
- Refactor del wizard de registro para usar los nuevos componentes.
- Dropdown de provincias.
- Remodelado de los campos de consentimiento en `Paciente` (se respeta "no modificar Paciente" por ahora).

## ⚠️ REVISIÓN (2026-06-22, tarde) — Nuevo modelo (consentimiento general por checkbox)

Durante la ejecución el usuario redefinió el consentimiento. Lo ya hecho (T1–T4: `AppDropdownField`/`AppDateField`, `/me` con `tipo_dni`+`dni`, identidad del tutor en sesión + cache con `tutorId`) **queda commiteado y sigue siendo válido**. **T5–T7 del plan original quedan obsoletos** (la planilla ya NO lleva el consentimiento ni los antecedentes familiares); se re-planean.

### Decisión clave sobre la "firma"
- **Ahora el consentimiento es SOLO un checkbox** (aceptar términos). **No hay firma** (ni dibujada, ni firma_hash, ni entidad criptográfica) en esta etapa.
- La **firma** se hará en **otra fase/etapa de desarrollo** (futuro). → Esto **desbloquea** el rediseño: no se necesita la decisión del equipo sobre persistencia de firma para avanzar.

### Modelo nuevo (acordado)
- **Consentimiento = general del tutor** (NO por hijo, sin campo "a qué hijo"). Es un **checkbox** de aceptación. Se **renueva por año** (la renovación anual se deja para más adelante).
- Es **precondición**: sin consentimiento aceptado, el tutor **no puede registrar un hijo**. Al intentarlo → **notificación/alerta de obligatorio** y redirección a completarlo.
- **Antecedentes de salud familiares** (padre/madre/hermanos) = **general del tutor**, se completa una vez (no por hijo).
- **Dos tareas generales SEPARADAS** → (1) Consentimiento (gatea el registro de hijos) y (2) Antecedentes familiares.
- **Per-hijo:** la planilla "Para ser completado por la familia" = datos del niño + domicilio + cobertura + **antecedentes DEL NIÑO** (sin consentimiento, sin antecedentes familiares).
- **Pendientes:** **mazo de cards apiladas/superpuestas** (estilo de la captura `Captura de pantalla 2026-06-22 ... 4.41.54 p. m.`); cuando hay **más de 3** tareas, las extra se **acumulan al fondo** como un mazo. Items: las 2 tareas generales (hasta completarse) + una por cada hijo (su formulario familiar).

### Persistencia (decidido) — backend mínimo a nivel Tutor
- **`Tutor`**: agregar `consentimiento_aceptado` (bool, default False) + `fecha_consentimiento` (datetime null). Endpoint para aceptar el consentimiento (checkbox). `/me` expone `consentimiento_aceptado` para el gating en el front.
- **Antecedentes familiares**: modelo propio `AntecedentesFamiliares` con **FK a `Tutor`** (uno por tutor) + endpoint para crear/actualizar. Lleva las preguntas del PDF "ANTECEDENTES DE SALUD DEL PADRE/MADRE Y/O HERMANOS".
- **Gating**: el front bloquea "Registrar hijo" si `consentimiento_aceptado == false` (lo lee de `/me`/sesión) y muestra alerta/notificación. (Opcional defensa server-side: rechazar el alta de hijo sin consentimiento.)
- La **firma** NO entra (fase futura).

### Task breakdown nuevo (a re-planear formalmente con writing-plans)
**Backend (`prosane_api`):**
- NB1: `Tutor.consentimiento_aceptado` + `fecha_consentimiento` (+migración) + endpoint aceptar consentimiento; `/me` expone `consentimiento_aceptado`.
- NB2: modelo `AntecedentesFamiliares` (FK Tutor) + endpoint crear/actualizar.
**Frontend (`prosane_app`):**
- NF1: sesión/`/me`/cache transportan `consentimientoAceptado` (patrón T4).
- NF2: pantalla general **Consentimiento** (checkbox + modal de términos) → POST.
- NF3: pantalla general **Antecedentes familiares** → POST.
- NF4: **gating** de "Registrar hijo" + alerta de obligatorio + redirección.
- NF5: **planilla per-hijo**: quitar consentimiento y antecedentes familiares; dejar datos del niño + antecedentes del niño; ajustar payload de `hijos`.
- NF6: **Pendientes** como mazo apilado (colapsa >3): consentimiento + antecedentes familiares + 1 por hijo.

---

## Testing
- **Componentes**: `AppDropdownField` (renderiza items, dispara onChanged), `AppDateField` (muestra fecha formateada, abre picker, dispara onChanged).
- **PlanillaScreen**: el "Guardar" queda atenuado sin requeridos/consentimiento; el modal de términos abre y muestra el texto; el adulto responsable se muestra read-only desde la sesión.
- **planilla_controller**: edad derivada de la fecha; el bloque `consentimiento` se arma desde la sesión cuando se acepta; payload correcto.
- **MeResponse / sesión**: parseo de apellido/tipo_documento/dni; threading a la sesión y al cache.
- **Backend `/me`**: incluye `tipo_documento` y `dni` (test en `apps/usuarios`).
- Suite completa verde (mantener 180/0 + nuevos tests).
