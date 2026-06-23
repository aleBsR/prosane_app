# PROSANE App (Frontend)

Aplicación móvil construida en **Flutter** para digitalizar el circuito del Programa Nacional de Salud Escolar (PROSANE).

Requiere el backend [`prosane_api`](https://github.com/aleBsR/prosane_api) corriendo para funcionar.

---

## Requisitos

- **Flutter 3.41+** (canal `stable`) y **Dart SDK ≥ 3.11**.
- Verificar con: `flutter --version` y `flutter doctor`
- **Android Studio** / SDK para Android
- **Xcode** (+ Apple ID) solo para iOS

### Dependencias principales

| Paquete | Propósito |
|---------|-----------|
| `flutter_riverpod` | Estado e inyección de dependencias |
| `go_router` | Navegación con guardias de autenticación |
| `dio` | Cliente HTTP con interceptores |
| `drift` | SQLite local (offline-first) |
| `flutter_secure_storage` | Almacenamiento seguro de JWT |
| `connectivity_plus` | Detección de conectividad |
| `freezed` | Clases de datos inmutables |

---

## Instalación y ejecución

### 1. Clonar y entrar

```bash
git clone <repo-url> prosane_app
cd prosane_app
```

### 2. Obtener dependencias y generar código

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

> `build_runner` genera los `*.g.dart` (Drift) y `*.freezed.dart`. Es **obligatorio** después de clonar o de tocar modelos/tablas — sin esto la app **no compila**.

### 3. Configurar la URL del backend (`--dart-define`)

La URL del backend **no va en un `.env`**, se inyecta al compilar. Elegí según dónde corra la app:

| Dónde corre la app | `API_BASE_URL` |
|---|---|
| Emulador Android | `http://10.0.2.2:8000/api/v1/auth` |
| Escritorio / web | `http://localhost:8000/api/v1/auth` |
| Celular/tablet físico (misma red) | `http://<IP-LAN-de-tu-PC>:8000/api/v1/auth` |

Para obtener tu IP en la red local:
```bash
# Linux
ip -4 addr show | grep -oP 'inet \K[\d.]+' | grep -v '127.0.0.1'

# macOS
ipconfig getifaddr en0
```

### 4. Correr la app

```bash
flutter devices   # listar dispositivos disponibles
flutter run -d <device-id> --dart-define=API_BASE_URL=http://<IP>:8000/api/v1/auth
```

> El default hardcodeado en `lib/core/config/app_config.dart` puede no ser el correcto para tu red. **Siempre inyectá la URL con `--dart-define`**.

---

## Backend (`prosane_api`)

La app depende del backend para autenticación y datos. Ver [`prosane_api/README.md`](https://github.com/aleBsR/prosane_api) para instrucciones completas.

### Resumen rápido

```bash
# 1. Activar entorno virtual y arrancar Django
cd prosane_api
source venv/bin/activate
python manage.py migrate
python manage.py loaddata actions users roles

# 2. Iniciar servidor (accesible desde la red local)
python manage.py runserver 0.0.0.0:8000
```

### Usuarios de prueba (password: `prosane123`)

| Email | Rol |
|-------|-----|
| `superadmin@prosane.test` | Superadmin — acceso total |
| `medico@prosane.test` | Médico |
| `odontologo@prosane.test` | Odontólogo |
| `ayudante@prosane.test` | Ayudante — gestión de operativos |
| `tutor@prosane.test` | Tutor — registro de hijos |

Cada rol ve sus propias acciones en el menú, definidas por el sistema de permisos data-driven.

---

## Probar el offline-first

La app es **offline-first de sesión**:
1. Iniciar sesión con el backend corriendo (autentica y cachea el perfil en SQLite)
2. Apagar el backend (Ctrl+C)
3. Cerrar y reabrir la app
4. Arranca **autenticada** sin pedir login

> El login inicial **siempre necesita red**. Solo la sesión cacheada funciona offline.

---

## Tests

```bash
flutter test                          # suite completa
flutter analyze                       # análisis estático (debe dar limpio)
flutter run -t widgetbook/main.dart   # galería Widgetbook de componentes
```

---

## Arquitectura

El proyecto usa arquitectura **Feature-First** con capas de *Presentación*, *Dominio* y *Datos* dentro de cada feature.

```
lib/
├── core/           → Funciones compartidas, tema, red, DB local, sync
│   ├── config/       → URL del backend
│   ├── design_system/ → Componentes UI reutilizables
│   ├── network/      → Cliente Dio, interceptors (auth, refresh, logging)
│   ├── database/     → Drift (SQLite), tablas offline
│   ├── session/      → Estado de sesión, permisos
│   ├── sync/         → Motor de sincronización offline
│   └── router/       → GoRouter con guardias de autenticación
└── features/       → Módulos funcionales
    ├── auth/         → Login, registro wizard
    ├── acciones/     → Menú de acciones según permisos
    ├── pendientes/   → Elementos pendientes de sincronizar
    ├── usuario/      → Perfil y cerrar sesión
    ├── familia/      → Antecedentes familiares, consentimiento
    └── hijos/        → Planilla familiar, registro de hijos
```
