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

## Cómo levantar la app (guía para el equipo)

### Requisitos
- **Flutter 3.41+** (canal `stable`) y **Dart SDK ≥ 3.11**. Verificá con `flutter --version` y `flutter doctor`.
- iOS: **Xcode** (+ una Apple ID en Xcode para firmar). Android: **Android Studio** / SDK.

### 1. Dependencias y code-gen
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```
> `build_runner` genera los `*.g.dart` (Drift) y `*.freezed.dart`. Es **obligatorio** después de clonar
> o de tocar modelos/tablas; sin esto la app **no compila**.

### 2. Apuntar al backend (`--dart-define`, no hay `.env`)
La URL del backend se inyecta al correr. Elegí según dónde corra la app:

| Dónde corre la app | `API_BASE_URL` |
|---|---|
| Simulador iOS / escritorio (misma Mac que el backend) | `http://127.0.0.1:8000/api/v1/auth` |
| Emulador Android | `http://10.0.2.2:8000/api/v1/auth` |
| **Celular físico** (iPhone/Android) | `http://<IP-LAN-de-tu-Mac>:8000/api/v1/auth` |

> La IP de la Mac la sacás con `ipconfig getifaddr en0` (cambia al cambiar de red). El default
> hardcodeado en `lib/core/config/app_config.dart` puede estar viejo → **inyectá siempre** la URL.

### 3. Correr
```bash
flutter devices   # ver el id del dispositivo
flutter run -d <id-del-dispositivo> --dart-define=API_BASE_URL=http://<IP>:8000/api/v1/auth
```

### 4. Backend local (repo `prosane_api`)
Para que un **celular físico** llegue, bindeá el server a la LAN (no solo `localhost`) y poné el cel
en la **misma Wi-Fi** que la Mac:
```bash
python manage.py runserver 0.0.0.0:8000
```
Usuarios de prueba (seed del backend): `{superadmin, medico, odontologo, ayudante, tutor}@prosane.test`
(la contraseña la define el seed). Cada rol ve sus propias acciones en el menú.

### Dispositivo físico iOS (primera vez)
1. Ajustes → Privacidad y seguridad → **Modo de desarrollador** → activar (reinicia el teléfono).
2. Abrí `ios/Runner.xcworkspace` en Xcode → target *Runner* → **Signing & Capabilities** → elegí tu **Team**.
3. Tras instalar: Ajustes → General → **VPN y gestión de dispositivos** → **confiá** tu perfil de desarrollador.
4. El HTTP en LAN ya está habilitado (ATS en `ios/Runner/Info.plist`) — no tocás nada.

### Probar el offline-first
La app es **offline-first de sesión**: el **login necesita red** (autentica y cachea el `/me`), pero al
**reabrir** la app funciona sin red. Para probarlo: logueate online → **apagá el backend** (Ctrl-C) →
cerrá y reabrí la app → arranca **autenticado**, sin pedir login.
> No uses *modo avión* con Apple ID gratis: rompe la verificación del certificado de iOS. Apagá solo el backend.

### Tests y galería de componentes
```bash
flutter test                          # suite de tests
flutter analyze                       # análisis estático (debe dar limpio)
flutter run -t widgetbook/main.dart   # galería Widgetbook (componentes del design system)
```
