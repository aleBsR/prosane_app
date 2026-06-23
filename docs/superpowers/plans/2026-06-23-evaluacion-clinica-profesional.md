# Plan: Evaluación Clínica del Profesional (Entrega 4)

**Fecha:** 2026-06-23
**Alcance:** Planilla COMPLETA (2 hojas). Formulario según rol (médico ≠ odontólogo).
**Objetivo:** Médico/odontólogo evalúan cada alumno del operativo; escuela completa su parte por alumno; ayudante finaliza cuando todo está completo.

---

## Mapeo de la planilla → modelo de datos

### Sección ESCUELA (por alumno) — campos nuevos en `OperativoAlumno`
- `escuela_preocupa_salud` (bool) + `escuela_preocupa_detalle` (text)
- `escuela_dificultad_lenguaje` (bool) + `escuela_bajo_tratamiento` (bool)
- `escuela_completado` (bool)

### Sección EQUIPO DE SALUD → modelo nuevo `EvaluacionMedica` (OneToOne con OperativoAlumno)
**Hoja 1:**
- `examen_realizado` (bool), `motivo_no_examen` (choices: negativa_familiar/negativa_nino/ausente/otros), `lugar_examen` (escuela/centro_salud)
- Vacunación: `trajo_carnet` (bool), `carnet_completo` (bool), `vacunas_aplicadas` (text), `vacunas_indicadas` (text)

**Hoja 2:**
- Antropometría: `peso` (decimal), `talla` (decimal), `imc` (decimal), `percentil_talla` (choice), `percentil_imc` (choice)
- Presión: `pas` (int), `pad` (int), `presion_clasificacion` (choice)
- Agudeza visual: `agudeza_evaluada` (bool), `ojo_derecho` (char), `ojo_izquierdo` (char), `usa_lentes` (bool)
- Audiometría: `audiometria_realizada` (bool), `audiometria_resultado` (pasa/no_pasa)
- **Hallazgos clínicos (11 sistemas)** → JSONField `hallazgos` con shape:
  ```json
  { "piel": {"estado": "con|sin|no_eval", "detalle": "..."}, "partes_blandas": {...}, "cardiovascular": {...}, "respiratorio": {...}, "abdominal": {...}, "genitourinario": {...}, "osteoarticular": {...}, "neurologico": {...}, "salud_visual": {...}, "fonoaudiologica": {...}, "icv": {...} }
  ```
- Derivaciones → JSONField `derivaciones`: `{ "odontologia": {"deriva": true, "motivo": "..."}, ... }`
- `profesional` (FK Usuario), `fecha_evaluacion` (datetime)

### Sección ODONTÓLOGO → modelo nuevo `EvaluacionOdontologica` (OneToOne con OperativoAlumno)
- `salud_bucal` (con_hallazgos/sin/no_eval)
- `lesiones_tejidos_blandos` (bool), `maloclusion` (bool), `fluorosis` (bool), `caries` (bool), `otros` (text)
- `topicacion_fluor` (bool), `ensenanza_cepillado` (bool), `alta_basica` (bool)
- CPO/ceo: `cpo_c`, `cpo_p`, `cpo_o`, `ceo_c`, `ceo_e`, `ceo_o` (ints)
- `odontograma` (JSONField: estado por pieza dental)
- `profesional` (FK Usuario), `fecha_evaluacion` (datetime)

---

## Fases

### FASE 1 — Backend: modelos + migración
- `apps/operativos/models/evaluacion.py`: `EvaluacionMedica`, `EvaluacionOdontologica`
- Campos escuela en `OperativoAlumno`
- Migración. Tests de modelo.

### FASE 2 — Backend: serializers + endpoints
- Serializers de cada evaluación (todos los campos)
- `GET/PUT /operativos/<id>/alumnos/<alumno_id>/evaluacion-medica/`
- `GET/PUT /operativos/<id>/alumnos/<alumno_id>/evaluacion-odontologica/`
- `PATCH .../seccion-escuela/` (campos escuela)
- Validar: solo el profesional asignado con ese rol puede cargar su evaluación
- Permisos nuevos: `cargarEvaluacionMedica`, `cargarEvaluacionOdontologica`, `cargarSeccionEscuela`

### FASE 3 — Backend: completitud + gating de finalización
- Propiedad `OperativoAlumno.completo` (médico+odonto+escuela según presentes)
- `Operativo.puede_finalizar` (todos los presentes completos)
- `finalizar_operativo` valida completitud → 409 si falta algo
- Endpoint `GET /operativos/<id>/completitud/` (resumen: X/Y alumnos completos)

### FASE 4 — App: listar alumnos del operativo
- Endpoint ya existe (`GET /operativos/<id>/alumnos/`)
- Repo: `listarAlumnos()`, controller, sección en detalle que muestra lista de alumnos con badge (pendiente/evaluado)
- Tap alumno → ruta a la pantalla de evaluación

### FASE 5 — App: formulario evaluación MÉDICA (según rol)
- Pantalla multi-card espejando hoja 1 + hoja 2 (antropometría, presión, agudeza, hallazgos 11 sistemas, vacunación, derivaciones)
- Solo visible/editable si el usuario es médico asignado

### FASE 6 — App: formulario evaluación ODONTOLÓGICA (según rol)
- Pantalla con salud bucal, CPO/ceo, odontograma
- Solo visible/editable si el usuario es odontólogo asignado

### FASE 7 — App: sección escuela por alumno + finalización con gating
- Form corto de las 2 preguntas escuela (lo carga el ayudante)
- En el detalle del ayudante: indicador de completitud (X/Y alumnos) + botón Finalizar habilitado solo cuando está completo
- Pendientes del médico/odonto: operativos con alumnos sin evaluar

---

## Orden sugerido de ejecución
Fases 1→2→3 (backend completo y testeado) antes de tocar la app.
Luego 4 (lista) → 5/6 (forms) → 7 (gating).

## Notas
- Es trabajo de varias sesiones. Cada fase compila/testea antes de seguir.
- Entorno backend: `./venv/bin/python`. Tests: `./venv/bin/python manage.py test apps.operativos --noinput`.
- App: `flutter analyze lib` debe pasar limpio en cada fase.
