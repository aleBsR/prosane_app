# PROSANE App (Frontend)

Aplicación móvil construida en **Flutter** para digitalizar el circuito del Programa Nacional de Salud Escolar (PROSANE).

## Descripción del Proyecto
Esta app está diseñada para facilitar la recolección de datos y la visualización del estado del Control Integral de Salud (CIS) de niños, niñas y adolescentes, eliminando el uso de papel y la doble carga manual.

### Roles y Flujos de Uso
La aplicación se adapta dinámicamente según el rol del usuario autenticado:
- **Familia / Tutor:** Puede llenar la primera parte de la planilla (datos personales y antecedentes), ver el estado del trámite y descargar la constancia digital en PDF.
- **Escuela:** Visualiza tableros de sus cursos para saber qué alumnos ya cumplieron con el CIS, facilitando el control y envío de reportes.
- **Equipo de Salud:** Médicos y odontólogos completan el bloque clínico en la app (con posible soporte offline) y firman digitalmente el control validando su matrícula (REFEPS).
- **Administrador:** Gestiona instituciones y altas.

## Arquitectura
El proyecto utiliza una arquitectura **Feature-First** (basada en funcionalidades).
La gestión del estado y la inyección de dependencias se maneja a través de **Riverpod**.

La estructura principal es:
- `lib/core/`: Funciones compartidas, temas, constantes y utilidades.
- `lib/features/`: Módulos principales de la aplicación (ej. auth, forms, dashboard). Cada feature está dividida en las capas de *Presentación*, *Dominio* y *Datos*.

### ¿Cómo correr el proyecto?
1. Asegúrate de tener el Flutter SDK instalado.
2. Clona el repositorio.
3. Descarga las dependencias: `flutter pub get`
4. Ejecuta la aplicación en un emulador o dispositivo conectado: `flutter run`
