# Fundación Flutter offline-first — Plan de implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Montar la fundación profesional offline-first de `prosane_app` y validarla con un vertical slice de Auth (Login + Signup) completo data→domain→presentation.

**Architecture:** Clean Architecture feature-first (presentation → domain → data) con Riverpod, go_router y code-gen (freezed + json_serializable + riverpod). Base local Drift = única fuente de verdad; la UI observa Drift vía `StreamProvider` y un `sync_engine` aparte cruza local↔remoto. Auth es la excepción remota pero monta toda la fundación.

**Tech Stack:** Flutter (Dart 3.11), Riverpod, go_router, Dio, Drift, flutter_secure_storage, connectivity_plus, freezed, json_serializable, build_runner; tests con flutter_test + mocktail + Drift in-memory + goldens.

**Spec de referencia:** `docs/superpowers/specs/2026-06-08-fundacion-flutter-offline-first.md`

---

## Notas para quien implementa

- **TDD siempre:** test que falla → correr y ver fallar → implementación mínima → correr y ver pasar → commit.
- **Code-gen:** tras tocar archivos con `@freezed`, `@riverpod`, `@DriftDatabase` o `part`, correr
  `dart run build_runner build --delete-conflicting-outputs`. Los archivos `*.g.dart` / `*.freezed.dart` se commitean.
- **Verificación rápida sin test:** para tareas de scaffolding, `flutter analyze` debe pasar sin errores y `flutter test` en verde.
- **Idioma del dominio:** español (nombres de dominio, mensajes de usuario). Código/identificadores en español salvo términos técnicos.
- **Convención de commits:** `feat:`, `test:`, `chore:`, `refactor:`.
- **No commitear secretos.** La baseUrl de dev va por `--dart-define` / archivo de config, no hardcodeada con credenciales.

## Mapa de archivos (qué crea cada fase)

| Fase | Carpeta principal | Responsabilidad |
|------|-------------------|-----------------|
| 0 Setup | `pubspec.yaml`, `lib/main.dart`, `lib/app.dart`, `lib/core/config/` | deps, fuentes, app corriendo, config/env |
| 1 Design system | `lib/core/theme/`, `lib/core/design_system/` | tokens + widgets de los mockups + galería |
| 2 Core infra | `lib/core/error/`, `lib/core/network/`, `lib/core/storage/` | Failure/mapeo, Dio+interceptors, secure storage |
| 3 DB + sync | `lib/core/database/`, `lib/core/sync/` | Drift + migraciones testeadas + motor de sync (FeatureSyncer falso) |
| 4 Sesión | `lib/core/session/`, `lib/core/router/` | SessionController, can()/PermissionGate, go_router + guard |
| 5 Auth slice | `lib/features/auth/` | domain + data (remoto, cachea /me) + presentation (login + wizard) |

---

# FASE 0 — Setup del proyecto

### Task 1: Dependencias, fuentes y skeleton de carpetas

**Files:**
- Modify: `pubspec.yaml`
- Create: `assets/fonts/` (Nunito + Rubik `.ttf`)
- Create: `docs/design/diseno-login.jpeg`, `docs/design/diseno-inputs.jpeg`, `docs/design/formulario-registro.jpeg` (mover desde la raíz, renombrando sin acentos)
- Create: directorios vacíos con `.gitkeep` según el mapa de archivos

- [ ] **Step 1: Mover los mockups a `docs/design/`**

```bash
mkdir -p docs/design
git mv "diseño_login.jpeg" docs/design/diseno-login.jpeg 2>/dev/null || mv "diseño_login.jpeg" docs/design/diseno-login.jpeg
mv "diseño_inputs.jpeg" docs/design/diseno-inputs.jpeg
mv "formulario_registro.jpeg" docs/design/formulario-registro.jpeg
```

- [ ] **Step 2: Descargar fuentes Nunito y Rubik**

Descargar de Google Fonts (Nunito: Black 900; Rubik: Regular 400 + SemiBold 600) y colocarlas en `assets/fonts/`:
`Nunito-Black.ttf`, `Rubik-Regular.ttf`, `Rubik-SemiBold.ttf`.

- [ ] **Step 3: Editar `pubspec.yaml`** — agregar deps, dev_deps, fuentes y assets:

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1
  go_router: ^14.6.2
  dio: ^5.7.0
  drift: ^2.21.0
  sqlite3_flutter_libs: ^0.5.26
  path_provider: ^2.1.5
  path: ^1.9.0
  flutter_secure_storage: ^9.2.2
  connectivity_plus: ^6.1.0
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0
  uuid: ^4.5.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  build_runner: ^2.4.13
  riverpod_generator: ^2.6.3
  freezed: ^2.5.7
  json_serializable: ^6.8.0
  drift_dev: ^2.21.0
  mocktail: ^1.0.4
  widgetbook: ^3.11.0

flutter:
  uses-material-design: true
  assets:
    - docs/design/
  fonts:
    - family: Nunito
      fonts:
        - asset: assets/fonts/Nunito-Black.ttf
          weight: 900
    - family: Rubik
      fonts:
        - asset: assets/fonts/Rubik-Regular.ttf
          weight: 400
        - asset: assets/fonts/Rubik-SemiBold.ttf
          weight: 600
```

- [ ] **Step 4: Crear skeleton de carpetas con `.gitkeep`**

```bash
for d in core/config core/theme core/design_system core/network core/error core/router \
         core/session core/storage core/database/tables core/database/daos core/database/converters \
         core/sync features/auth/data/dtos features/auth/data/datasources features/auth/data/repositories \
         features/auth/domain/entities features/auth/domain/repositories features/auth/domain/usecases \
         features/auth/presentation/controllers features/auth/presentation/screens features/auth/presentation/widgets \
         shared; do mkdir -p "lib/$d" && touch "lib/$d/.gitkeep"; done
```

- [ ] **Step 5: Resolver e instalar**

Run: `flutter pub get`
Expected: resuelve sin conflictos.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "chore: add dependencies, fonts, mockups and folder skeleton"
```

### Task 2: App corriendo (ProviderScope + theme placeholder)

**Files:**
- Create: `lib/core/config/app_config.dart`
- Modify: `lib/main.dart`
- Create: `lib/app.dart`
- Test: `test/app_smoke_test.dart`

- [ ] **Step 1: Escribir el test de humo que falla**

```dart
// test/app_smoke_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/app.dart';

void main() {
  testWidgets('la app arranca y muestra un MaterialApp', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ProsaneApp()));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
```

- [ ] **Step 2: Correr y ver fallar**

Run: `flutter test test/app_smoke_test.dart`
Expected: FAIL (no existe `ProsaneApp` / `app.dart`).

- [ ] **Step 3: Implementar config + app**

```dart
// lib/core/config/app_config.dart
class AppConfig {
  /// Inyectar con --dart-define=API_BASE_URL=...
  static const apiBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8000/api/v1');
}
```

```dart
// lib/app.dart
import 'package:flutter/material.dart';

class ProsaneApp extends StatelessWidget {
  const ProsaneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PROSANE',
      debugShowCheckedModeBanner: false,
      home: const Scaffold(body: Center(child: Text('PROSANE'))),
    );
  }
}
```

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prosane_app/app.dart';

void main() {
  runApp(const ProviderScope(child: ProsaneApp()));
}
```

- [ ] **Step 4: Correr y ver pasar**

Run: `flutter test test/app_smoke_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat: app boots with ProviderScope and config"
```

---

# FASE 1 — Design system

### Task 3: Tokens de theme (colores, tipografía, espaciado, ThemeData)

**Files:**
- Create: `lib/core/theme/app_colors.dart`, `app_typography.dart`, `app_spacing.dart`, `app_radii.dart`, `app_theme.dart`
- Test: `test/core/theme/app_theme_test.dart`

- [ ] **Step 1: Test que falla** (verifica que el theme expone primario y familias correctas)

```dart
// test/core/theme/app_theme_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/theme/app_colors.dart';
import 'package:prosane_app/core/theme/app_theme.dart';

void main() {
  test('AppTheme usa el violeta primario y la familia Rubik por defecto', () {
    final theme = AppTheme.light();
    expect(theme.colorScheme.primary, AppColors.primario);
    expect(theme.textTheme.bodyMedium?.fontFamily, 'Rubik');
  });
}
```

- [ ] **Step 2: Correr y ver fallar** — `flutter test test/core/theme/app_theme_test.dart` → FAIL.

- [ ] **Step 3: Implementar tokens** (valores de arranque del spec; calibrar contra `docs/design/`)

```dart
// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  static const primario = Color(0xFF7C5CFC);
  static const gradienteFondoInicio = Color(0xFF9B7DF0);
  static const gradienteFondoFin = Color(0xFF7B5BE0);
  static const campo = Color(0xFFF1F0F5);
  static const error = Color(0xFFC0392B);
  static const texto = Color(0xFF2D2D3A);
  static const link = Color(0xFF6C4DE0);
  static const blanco = Color(0xFFFFFFFF);

  static const gradienteFondo = LinearGradient(
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
    colors: [gradienteFondoInicio, gradienteFondoFin],
  );
}
```

```dart
// lib/core/theme/app_spacing.dart
class AppSpacing {
  static const xs = 4.0, sm = 8.0, md = 16.0, lg = 24.0, xl = 32.0;
}
```

```dart
// lib/core/theme/app_radii.dart
class AppRadii {
  static const campo = 14.0, boton = 24.0, card = 28.0;
}
```

```dart
// lib/core/theme/app_typography.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  // Calibrados a tamaños lógicos manteniendo la jerarquía del mockup.
  static const titulo = TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w900, fontSize: 28, color: AppColors.primario);
  static const subtitulo = TextStyle(fontFamily: 'Rubik', fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.texto);
  static const campo = TextStyle(fontFamily: 'Rubik', fontWeight: FontWeight.w400, fontSize: 15, color: AppColors.texto);
  static const texto = TextStyle(fontFamily: 'Rubik', fontWeight: FontWeight.w400, fontSize: 13, color: AppColors.texto);
  static const boton = TextStyle(fontFamily: 'Rubik', fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.blanco);
}
```

```dart
// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(primary: AppColors.primario),
      textTheme: base.textTheme.apply(fontFamily: 'Rubik', bodyColor: AppColors.texto).copyWith(
        titleLarge: AppTypography.titulo,
        titleMedium: AppTypography.subtitulo,
        bodyLarge: AppTypography.campo,
        bodyMedium: AppTypography.texto,
      ),
      scaffoldBackgroundColor: AppColors.blanco,
    );
  }
}
```

- [ ] **Step 4: Correr y ver pasar** — PASS. Cablear el theme en `app.dart` (`theme: AppTheme.light()`).

- [ ] **Step 5: Commit** — `git add -A && git commit -m "feat: design system theme tokens"`

### Task 4: `AppTextField` con todos los estados

**Files:**
- Create: `lib/core/design_system/app_text_field.dart`
- Test: `test/core/design_system/app_text_field_test.dart`

- [ ] **Step 1: Test que falla** (estado error muestra el mensaje; password oculta y el ojo alterna)

```dart
// test/core/design_system/app_text_field_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/design_system/app_text_field.dart';

void main() {
  testWidgets('muestra label y errorText', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: AppTextField(label: 'E-mail', errorText: 'Campo requerido'))));
    expect(find.text('E-mail'), findsOneWidget);
    expect(find.text('Campo requerido'), findsOneWidget);
  });

  testWidgets('password: el ojo alterna la visibilidad', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: AppTextField(label: 'Contraseña', isPassword: true))));
    expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    await tester.tap(find.byIcon(Icons.visibility_off));
    await tester.pump();
    expect(find.byIcon(Icons.visibility), findsOneWidget);
  });
}
```

- [ ] **Step 2: Correr y ver fallar** → FAIL.

- [ ] **Step 3: Implementar** (estado visual derivado de `errorText`/`isValid`; ícono check/X; modo password)

```dart
// lib/core/design_system/app_text_field.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_typography.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key, required this.label, this.hint, this.controller, this.errorText,
    this.helperText, this.isPassword = false, this.isValid = false,
    this.keyboardType, this.onChanged,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? errorText;
  final String? helperText;
  final bool isPassword;
  final bool isValid;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscure = widget.isPassword;

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;
    final borderColor = hasError ? AppColors.error : (widget.isValid ? AppColors.primario : Colors.transparent);
    Widget? suffix;
    if (widget.isPassword) {
      suffix = IconButton(
        icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: AppColors.link),
        onPressed: () => setState(() => _obscure = !_obscure),
      );
    } else if (hasError) {
      suffix = const Icon(Icons.cancel, color: AppColors.error);
    } else if (widget.isValid) {
      suffix = const Icon(Icons.check_circle, color: AppColors.primario);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: AppTypography.subtitulo),
        const SizedBox(height: 6),
        TextField(
          controller: widget.controller,
          obscureText: _obscure,
          keyboardType: widget.keyboardType,
          onChanged: widget.onChanged,
          style: AppTypography.campo,
          decoration: InputDecoration(
            hintText: widget.hint,
            filled: true, fillColor: AppColors.campo,
            suffixIcon: suffix,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.campo),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.campo),
              borderSide: const BorderSide(color: AppColors.primario, width: 1.5),
            ),
          ),
        ),
        if (hasError || widget.helperText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(widget.errorText ?? widget.helperText!,
              style: AppTypography.texto.copyWith(color: hasError ? AppColors.error : AppColors.texto)),
          ),
      ],
    );
  }
}
```

- [ ] **Step 4: Correr y ver pasar** → PASS.

- [ ] **Step 5: Commit** — `git add -A && git commit -m "feat: AppTextField with states"`

### Task 5: `AppButton` con estados (normal/cargando/validado/error)

**Files:**
- Create: `lib/core/design_system/app_button.dart`
- Test: `test/core/design_system/app_button_test.dart`

- [ ] **Step 1: Test que falla**

```dart
// test/core/design_system/app_button_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/design_system/app_button.dart';

void main() {
  testWidgets('cargando muestra spinner y deshabilita onPressed', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: AppButton(label: 'INICIAR SESIÓN', isLoading: true, onPressed: () => taps++))));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(AppButton));
    expect(taps, 0);
  });

  testWidgets('normal dispara onPressed', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: AppButton(label: 'OK', onPressed: () => taps++))));
    await tester.tap(find.byType(AppButton));
    expect(taps, 1);
  });
}
```

- [ ] **Step 2: Correr y ver fallar** → FAIL.

- [ ] **Step 3: Implementar**

```dart
// lib/core/design_system/app_button.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_typography.dart';

enum AppButtonState { normal, validado, error }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key, required this.label, this.onPressed,
    this.isLoading = false, this.state = AppButtonState.normal,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonState state;

  @override
  Widget build(BuildContext context) {
    final disabled = isLoading || onPressed == null;
    final gradient = state == AppButtonState.error
        ? const LinearGradient(colors: [Color(0xFF8E2D22), AppColors.error])
        : AppColors.gradienteFondo;

    return GestureDetector(
      onTap: disabled ? null : onPressed,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(AppRadii.boton)),
        child: isLoading
            ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.blanco))
            : state == AppButtonState.validado
                ? const Icon(Icons.check, color: AppColors.blanco)
                : state == AppButtonState.error
                    ? const Icon(Icons.close, color: AppColors.blanco)
                    : Text(label, style: AppTypography.boton),
      ),
    );
  }
}
```

- [ ] **Step 4: Correr y ver pasar** → PASS.

- [ ] **Step 5: Commit** — `git add -A && git commit -m "feat: AppButton with states"`

### Task 6: `AppSwitch`, `AppLink`, `AppGradientScaffold`, `AppCard`

**Files:**
- Create: `lib/core/design_system/app_switch.dart`, `app_link.dart`, `app_gradient_scaffold.dart`, `app_card.dart`
- Test: `test/core/design_system/components_test.dart`

- [ ] **Step 1: Test que falla** (el switch refleja value y dispara onChanged; el link dispara onTap)

```dart
// test/core/design_system/components_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/design_system/app_switch.dart';
import 'package:prosane_app/core/design_system/app_link.dart';

void main() {
  testWidgets('AppSwitch dispara onChanged', (tester) async {
    bool? changed;
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: AppSwitch(value: false, label: 'Recordarme', onChanged: (v) => changed = v))));
    await tester.tap(find.byType(AppSwitch));
    expect(changed, true);
  });

  testWidgets('AppLink dispara onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: AppLink(text: 'Regístrese aquí', onTap: () => tapped = true))));
    await tester.tap(find.text('Regístrese aquí'));
    expect(tapped, true);
  });
}
```

- [ ] **Step 2: Correr y ver fallar** → FAIL.

- [ ] **Step 3: Implementar los cuatro widgets**

```dart
// lib/core/design_system/app_switch.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class AppSwitch extends StatelessWidget {
  const AppSwitch({super.key, required this.value, required this.onChanged, this.label});
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? label;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Switch(value: value, activeColor: AppColors.primario, onChanged: onChanged),
        if (label != null) Text(label!, style: AppTypography.texto),
      ]);
}
```

```dart
// lib/core/design_system/app_link.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class AppLink extends StatelessWidget {
  const AppLink({super.key, required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Text(text, style: AppTypography.texto.copyWith(color: AppColors.link, fontWeight: FontWeight.w600)),
      );
}
```

```dart
// lib/core/design_system/app_gradient_scaffold.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppGradientScaffold extends StatelessWidget {
  const AppGradientScaffold({super.key, required this.child, this.title});
  final Widget child;
  final String? title;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.gradienteFondo),
          child: SafeArea(child: child),
        ),
      );
}
```

```dart
// lib/core/design_system/app_card.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.blanco.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        child: child,
      );
}
```

- [ ] **Step 4: Correr y ver pasar** → PASS.

- [ ] **Step 5: Commit** — `git add -A && git commit -m "feat: switch, link, gradient scaffold, card"`

### Task 7: Galería widgetbook

> **🚩 CHECKPOINT VISIBLE (fin de Fase 1):** no alcanza con tests verdes. Al terminar esta task
> el controlador corre `flutter run -t widgetbook/main.dart` y le muestra al usuario la galería con
> los componentes reales (AppTextField/AppButton/AppSwitch en todos sus estados) antes de seguir a la Fase 2.

**Files:**
- Create: `widgetbook/main.dart`
- Test: (verificación por build)

- [ ] **Step 1:** Crear `widgetbook/main.dart` con use-cases para `AppTextField` (normal/error/validado/password), `AppButton` (normal/cargando/validado/error) y `AppSwitch`. Cada use-case envuelve el widget en `MaterialApp(theme: AppTheme.light())`.
- [ ] **Step 2:** Run: `flutter run -t widgetbook/main.dart` (o `flutter build` del target). Expected: compila y lista los componentes.
- [ ] **Step 3: Commit** — `git add -A && git commit -m "feat: widgetbook component gallery"`

---

# FASE 2 — Core infrastructure

### Task 8: Capa de error (Failure + error_mapper) — taxonomía de login

**Files:**
- Create: `lib/core/error/failure.dart`, `lib/core/error/error_mapper.dart`
- Test: `test/core/error/error_mapper_test.dart`

- [ ] **Step 1: Test que falla** (cada categoría mapea a su Failure; nunca cae en credenciales por descarte)

```dart
// test/core/error/error_mapper_test.dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/error/failure.dart';
import 'package:prosane_app/core/error/error_mapper.dart';

DioException _dio(int? status, {DioExceptionType type = DioExceptionType.badResponse}) => DioException(
      requestOptions: RequestOptions(path: '/'),
      type: type,
      response: status == null ? null : Response(requestOptions: RequestOptions(path: '/'), statusCode: status),
    );

void main() {
  test('401 → InvalidCredentialsFailure', () {
    expect(mapDioError(_dio(401)), isA<InvalidCredentialsFailure>());
  });
  test('sin conexión → NoConnectionFailure', () {
    expect(mapDioError(_dio(null, type: DioExceptionType.connectionError)), isA<NoConnectionFailure>());
  });
  test('500 → ServerFailure (NO credenciales)', () {
    final f = mapDioError(_dio(500));
    expect(f, isA<ServerFailure>());
    expect(f, isNot(isA<InvalidCredentialsFailure>()));
  });
  test('timeout → ServerFailure', () {
    expect(mapDioError(_dio(null, type: DioExceptionType.receiveTimeout)), isA<ServerFailure>());
  });
}
```

- [ ] **Step 2: Correr y ver fallar** → FAIL.

- [ ] **Step 3: Implementar**

```dart
// lib/core/error/failure.dart
sealed class Failure {
  const Failure(this.mensaje);
  final String mensaje;
}
class NoConnectionFailure extends Failure {
  const NoConnectionFailure() : super('Necesitás conexión para iniciar sesión');
}
class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure() : super('Credenciales incorrectas');
}
class ServerFailure extends Failure {
  const ServerFailure() : super('Hubo un problema, probá de nuevo');
}
class UnknownFailure extends Failure {
  const UnknownFailure() : super('Hubo un problema, probá de nuevo');
}
```

```dart
// lib/core/error/error_mapper.dart
import 'package:dio/dio.dart';
import 'failure.dart';

Failure mapDioError(Object error) {
  if (error is! DioException) return const UnknownFailure();
  switch (error.type) {
    case DioExceptionType.connectionError:
      return const NoConnectionFailure();
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.sendTimeout:
      return const ServerFailure();
    case DioExceptionType.badResponse:
      final code = error.response?.statusCode ?? 0;
      if (code == 401) return const InvalidCredentialsFailure();
      if (code >= 500) return const ServerFailure();
      return const UnknownFailure();
    default:
      return const UnknownFailure();
  }
}
```

- [ ] **Step 4: Correr y ver pasar** → PASS.

- [ ] **Step 5: Commit** — `git add -A && git commit -m "feat: error taxonomy and dio mapper"`

### Task 9: Storage seguro (JWT)

**Files:**
- Create: `lib/core/storage/token_storage.dart`
- Test: `test/core/storage/token_storage_test.dart`

- [ ] **Step 1: Test que falla** (usa un backend en memoria inyectable para no depender del plugin nativo)

```dart
// test/core/storage/token_storage_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/storage/token_storage.dart';

void main() {
  test('guarda y lee access/refresh y limpia', () async {
    final store = TokenStorage(backend: InMemoryKeyValueStore());
    await store.guardar(access: 'a', refresh: 'r');
    expect(await store.access(), 'a');
    expect(await store.refresh(), 'r');
    await store.limpiar();
    expect(await store.access(), isNull);
  });
}
```

- [ ] **Step 2: Correr y ver fallar** → FAIL.

- [ ] **Step 3: Implementar** (abstracción `KeyValueStore` con impl segura y otra en memoria para tests)

```dart
// lib/core/storage/token_storage.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class KeyValueStore {
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
}

class SecureKeyValueStore implements KeyValueStore {
  final _s = const FlutterSecureStorage();
  @override Future<void> write(String k, String v) => _s.write(key: k, value: v);
  @override Future<String?> read(String k) => _s.read(key: k);
  @override Future<void> delete(String k) => _s.delete(key: k);
}

class InMemoryKeyValueStore implements KeyValueStore {
  final _m = <String, String>{};
  @override Future<void> write(String k, String v) async => _m[k] = v;
  @override Future<String?> read(String k) async => _m[k];
  @override Future<void> delete(String k) async => _m.remove(k);
}

class TokenStorage {
  TokenStorage({KeyValueStore? backend}) : _b = backend ?? SecureKeyValueStore();
  final KeyValueStore _b;
  static const _kAccess = 'jwt_access', _kRefresh = 'jwt_refresh';

  Future<void> guardar({required String access, required String refresh}) async {
    await _b.write(_kAccess, access);
    await _b.write(_kRefresh, refresh);
  }
  Future<String?> access() => _b.read(_kAccess);
  Future<String?> refresh() => _b.read(_kRefresh);
  Future<void> limpiar() async { await _b.delete(_kAccess); await _b.delete(_kRefresh); }
}
```

- [ ] **Step 4: Correr y ver pasar** → PASS.

- [ ] **Step 5: Commit** — `git add -A && git commit -m "feat: secure token storage"`

### Task 10: DioClient + interceptors (auth, refresh con lock, logging redactado)

**Files:**
- Create: `lib/core/network/api_exception.dart`, `lib/core/network/auth_interceptor.dart`, `lib/core/network/refresh_interceptor.dart`, `lib/core/network/logging_interceptor.dart`, `lib/core/network/dio_client.dart`
- Test: `test/core/network/interceptors_test.dart`

- [ ] **Step 1: Test que falla** (auth adjunta Bearer; logging redacta password/token)

```dart
// test/core/network/interceptors_test.dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/network/auth_interceptor.dart';
import 'package:prosane_app/core/network/logging_interceptor.dart';
import 'package:prosane_app/core/storage/token_storage.dart';

void main() {
  test('AuthInterceptor adjunta Authorization: Bearer', () async {
    final store = TokenStorage(backend: InMemoryKeyValueStore());
    await store.guardar(access: 'TOK', refresh: 'r');
    final i = AuthInterceptor(store);
    final opts = RequestOptions(path: '/x');
    final handler = _CapturingRequestHandler();
    await i.onRequest(opts, handler);
    expect(opts.headers['Authorization'], 'Bearer TOK');
  });

  test('redactarSensibles oculta password y token', () {
    final out = redactarSensibles({'email': 'a@b.com', 'password': 'secreto', 'access': 'xyz'});
    expect(out['password'], '***');
    expect(out['access'], '***');
    expect(out['email'], 'a@b.com'); // email no se loguea crudo: lo enmascara parcialmente
  });
}

class _CapturingRequestHandler extends RequestInterceptorHandler {
  @override void next(RequestOptions requestOptions) {}
}
```

- [ ] **Step 2: Correr y ver fallar** → FAIL.

- [ ] **Step 3: Implementar** (auth, refresh con lock anti-tormenta de 401, logging con redacción)

```dart
// lib/core/network/auth_interceptor.dart
import 'package:dio/dio.dart';
import '../storage/token_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokens);
  final TokenStorage _tokens;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _tokens.access();
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }
}
```

```dart
// lib/core/network/logging_interceptor.dart
import 'dart:developer' as dev;
import 'package:dio/dio.dart';

const _camposSensibles = {'password', 'confirmPassword', 'access', 'refresh', 'token'};

Map<String, dynamic> redactarSensibles(Map<String, dynamic> data) {
  return data.map((k, v) {
    if (_camposSensibles.contains(k)) return MapEntry(k, '***');
    if (k == 'email' && v is String && v.contains('@')) {
      final p = v.split('@');
      return MapEntry(k, '${p.first.substring(0, 1)}***@${p.last}');
    }
    return MapEntry(k, v);
  });
}

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final body = options.data is Map<String, dynamic>
        ? redactarSensibles(options.data as Map<String, dynamic>) : options.data;
    dev.log('→ ${options.method} ${options.path} $body', name: 'http');
    handler.next(options);
  }
}
```

```dart
// lib/core/network/refresh_interceptor.dart
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../storage/token_storage.dart';

/// Refresca el JWT ante 401, con un único refresh en vuelo (lock).
class RefreshInterceptor extends Interceptor {
  RefreshInterceptor(this._tokens, this._dio, {this.onLogout});
  final TokenStorage _tokens;
  final Dio _dio;
  final Future<void> Function()? onLogout;
  Future<String?>? _refreshEnVuelo;

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401 || err.requestOptions.extra['retry'] == true) {
      return handler.next(err);
    }
    final nuevo = await (_refreshEnVuelo ??= _refrescar());
    _refreshEnVuelo = null;
    if (nuevo == null) { await onLogout?.call(); return handler.next(err); }
    final req = err.requestOptions..extra['retry'] = true..headers['Authorization'] = 'Bearer $nuevo';
    try {
      final resp = await _dio.fetch(req);
      handler.resolve(resp);
    } catch (_) {
      handler.next(err);
    }
  }

  Future<String?> _refrescar() async {
    final refresh = await _tokens.refresh();
    if (refresh == null) return null;
    try {
      final r = await Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl))
          .post('/token/refresh', data: {'refresh': refresh});
      final access = r.data['access'] as String;
      await _tokens.guardar(access: access, refresh: refresh);
      return access;
    } catch (_) { return null; }
  }
}
```

```dart
// lib/core/network/dio_client.dart
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'auth_interceptor.dart';
import 'logging_interceptor.dart';
import 'refresh_interceptor.dart';

Dio buildDio(TokenStorage tokens, {Future<void> Function()? onLogout}) {
  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));
  dio.interceptors.addAll([
    AuthInterceptor(tokens),
    RefreshInterceptor(tokens, dio, onLogout: onLogout),
    LoggingInterceptor(),
  ]);
  return dio;
}
```

```dart
// lib/core/network/api_exception.dart
class ApiException implements Exception {
  ApiException(this.statusCode, [this.detalle]);
  final int? statusCode;
  final String? detalle;
}
```

- [ ] **Step 4: Correr y ver pasar** → PASS.

- [ ] **Step 5: Commit** — `git add -A && git commit -m "feat: dio client with auth/refresh/logging interceptors"`

---

# FASE 3 — Base de datos local + motor de sync

### Task 11: Drift database, mixin `sync_columns`, tabla `sync_state` y test de migración

**Files:**
- Create: `lib/core/database/sync_columns.dart`, `lib/core/database/tables/sync_state_table.dart`, `lib/core/database/app_database.dart`
- Test: `test/core/database/app_database_test.dart`, `test/core/database/migration_test.dart`

- [ ] **Step 1: Test que falla** (la DB abre en memoria; el mixin expone id/updatedAt/syncStatus)

```dart
// test/core/database/app_database_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/database/app_database.dart';

void main() {
  test('AppDatabase abre y persiste un sync_state', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.setWatermark('apto_fisico', DateTime.utc(2026, 1, 1));
    expect(await db.getWatermark('apto_fisico'), DateTime.utc(2026, 1, 1));
    await db.close();
  });
}
```

- [ ] **Step 2: Correr y ver fallar** → FAIL.

- [ ] **Step 3: Implementar** mixin, tabla, converter y database con `forTesting`

```dart
// lib/core/database/sync_columns.dart
import 'package:drift/drift.dart';

enum SyncStatus { pendiente, sincronizado, error } // Drift lo serializa por índice vía intEnum

mixin SyncColumns on Table {
  TextColumn get id => text()();                                   // UUID generado en cliente
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get syncStatus => intEnum<SyncStatus>().withDefault(const Constant(0))();
  DateTimeColumn get deletedAt => dateTime().nullable()();         // tombstone

  @override
  Set<Column> get primaryKey => {id};
}
```

```dart
// lib/core/database/tables/sync_state_table.dart
import 'package:drift/drift.dart';

class SyncStateRows extends Table {
  TextColumn get feature => text()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  @override Set<Column> get primaryKey => {feature};
}
```

```dart
// lib/core/database/app_database.dart
import 'package:drift/drift.dart';
import 'tables/sync_state_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [SyncStateRows])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);
  AppDatabase.forTesting(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;

  // IMPORTANTE (invariante de migraciones): al subir schemaVersion, escribir la migración
  // correspondiente acá y agregar su test en migration_test.dart. Nunca bumpear sin migración.
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // v2+: agregar steps versionados explícitos.
        },
      );

  Future<void> setWatermark(String feature, DateTime ts) =>
      into(syncStateRows).insertOnConflictUpdate(SyncStateRowsCompanion.insert(feature: feature, lastSyncedAt: Value(ts)));

  Future<DateTime?> getWatermark(String feature) async {
    final row = await (select(syncStateRows)..where((t) => t.feature.equals(feature))).getSingleOrNull();
    return row?.lastSyncedAt;
  }
}
```

- [ ] **Step 4: Generar y correr** — `dart run build_runner build --delete-conflicting-outputs` luego `flutter test test/core/database/` → PASS.

- [ ] **Step 5: Montar el HARNESS de verificación de migraciones (no solo el dump)**

> El objetivo de esta task NO es "el invariante ya está cumplido con el dump de v1". Es dejar el
> **andamiaje de verification configurado y corriendo**, listo para cuando haya un cambio de esquema
> real (v1→v2). Con una sola tabla todavía no hay migración que testear — está bien — pero el harness
> tiene que quedar funcionando, no pendiente.

Pasos concretos:

1. Exportar el esquema v1:
```bash
dart run drift_dev schema dump lib/core/database/app_database.dart drift_schemas/
```
2. Generar los helpers de verificación de Drift:
```bash
dart run drift_dev schema generate drift_schemas/ test/core/database/generated_migrations/
```
3. Crear `test/core/database/migration_test.dart` que use `SchemaVerifier` (de `drift_dev/api/migrations_native.dart`) con los helpers generados:
   - Test que **abre v1 y verifica el esquema** contra el snapshot (`verifier.startAt(1)` + `verifier.migrateAndValidate(db, 1)`). Esto prueba que el harness está vivo y cableado.
   - Un comentario `// Al subir a schemaVersion 2: dump v2, regenerar helpers y agregar un test v1→v2 con datos.` para que el próximo cambio sepa exactamente qué hacer.
4. Asegurar que `drift_schemas/` y `test/core/database/generated_migrations/` quedan commiteados (son parte del harness, no artefactos descartables).

Run: `flutter test test/core/database/migration_test.dart`
Expected: PASS (v1 abre y valida contra su snapshot).

- [ ] **Step 6: Commit** — `git add -A && git commit -m "feat: drift database, sync columns mixin and schema dump"`

### Task 12: ConnectivityService

**Files:**
- Create: `lib/core/sync/connectivity_service.dart`
- Test: `test/core/sync/connectivity_service_test.dart`

- [ ] **Step 1: Test que falla** (mapea resultados de connectivity_plus a un bool online, inyectando el stream)

```dart
// test/core/sync/connectivity_service_test.dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/sync/connectivity_service.dart';

void main() {
  test('none → offline; wifi → online', () async {
    final svc = ConnectivityService.fromStream(Stream.fromIterable([
      [ConnectivityResult.none], [ConnectivityResult.wifi],
    ]));
    expect(await svc.onlineStream.take(2).toList(), [false, true]);
  });
}
```

- [ ] **Step 2: Correr y ver fallar** → FAIL.

- [ ] **Step 3: Implementar**

```dart
// lib/core/sync/connectivity_service.dart
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  ConnectivityService.fromStream(Stream<List<ConnectivityResult>> raw)
      : onlineStream = raw.map((r) => !r.contains(ConnectivityResult.none) && r.isNotEmpty);
  factory ConnectivityService() =>
      ConnectivityService.fromStream(Connectivity().onConnectivityChanged);
  final Stream<bool> onlineStream;
}
```

- [ ] **Step 4: Correr y ver pasar** → PASS.

- [ ] **Step 5: Commit** — `git add -A && git commit -m "feat: connectivity service"`

### Task 13: `sync_engine` con FeatureSyncer (invariantes de push y watermark)

> **⚙️ Modelo:** el **implementer** usa el modelo **MÁS capaz** (no el estándar). Es la task más
> delicada del proyecto —los invariantes de sync— y la más cara de arreglar si sale mal.

**Files:**
- Create: `lib/core/sync/feature_syncer.dart`, `lib/core/sync/sync_engine.dart`
- Test: `test/core/sync/sync_engine_test.dart`

- [ ] **Step 1: Test que falla** — contra un `FeatureSyncer` FALSO, valida los dos invariantes:

```dart
// test/core/sync/sync_engine_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/sync/feature_syncer.dart';
import 'package:prosane_app/core/sync/sync_engine.dart';

class _FakeSyncer implements FeatureSyncer {
  _FakeSyncer(this._pendientes, this._resultados, {this.pullThrows = false});
  @override final String feature = 'fake';
  final List<String> _pendientes;
  final Map<String, PushOutcome> _resultados; // id → outcome
  final bool pullThrows;
  final List<String> marcadosSincronizados = [];
  DateTime? watermarkGuardado;
  DateTime? watermarkLeido;

  @override Future<List<String>> idsPendientes() async => _pendientes;
  @override Future<List<PushItemResult>> pushLote(List<String> ids) async =>
      ids.map((id) => PushItemResult(id, _resultados[id]!)).toList();
  @override Future<void> marcarSincronizado(String id) async => marcadosSincronizados.add(id);
  @override Future<DateTime?> getWatermark() async => watermarkLeido;
  @override Future<void> pullDesdeYMergear(DateTime? since) async {
    if (pullThrows) throw Exception('pull falló');
  }
  @override Future<void> setWatermark(DateTime ts) async => watermarkGuardado = ts;
}

void main() {
  test('push confirma fila-por-fila: solo los ok quedan sincronizados', () async {
    final s = _FakeSyncer(['a', 'b', 'c'], {
      'a': PushOutcome.ok, 'b': PushOutcome.transitorio, 'c': PushOutcome.ok,
    });
    await SyncEngine([s]).cicloPush();
    expect(s.marcadosSincronizados, ['a', 'c']); // b queda pendiente
  });

  test('watermark NO avanza si el pull falla', () async {
    final s = _FakeSyncer([], {}, pullThrows: true);
    await SyncEngine([s]).cicloPull(ahora: DateTime.utc(2026, 6, 1));
    expect(s.watermarkGuardado, isNull);
  });

  test('watermark avanza si el pull commitea', () async {
    final s = _FakeSyncer([], {});
    await SyncEngine([s]).cicloPull(ahora: DateTime.utc(2026, 6, 1));
    expect(s.watermarkGuardado, DateTime.utc(2026, 6, 1));
  });
}
```

- [ ] **Step 2: Correr y ver fallar** → FAIL.

- [ ] **Step 3: Implementar**

```dart
// lib/core/sync/feature_syncer.dart
enum PushOutcome { ok, transitorio, permanente }

class PushItemResult {
  PushItemResult(this.id, this.outcome);
  final String id;
  final PushOutcome outcome;
}

abstract class FeatureSyncer {
  String get feature;
  Future<List<String>> idsPendientes();
  Future<List<PushItemResult>> pushLote(List<String> ids);
  Future<void> marcarSincronizado(String id);   // marca ok
  Future<DateTime?> getWatermark();
  Future<void> setWatermark(DateTime ts);
  Future<void> pullDesdeYMergear(DateTime? since); // merge LWW dentro de una transacción
}
```

```dart
// lib/core/sync/sync_engine.dart
import 'feature_syncer.dart';

class SyncEngine {
  SyncEngine(this._syncers);
  final List<FeatureSyncer> _syncers;

  Future<void> ciclo({required DateTime ahora}) async {
    await cicloPush();
    await cicloPull(ahora: ahora);
  }

  Future<void> cicloPush() async {
    for (final s in _syncers) {
      final pendientes = await s.idsPendientes();
      if (pendientes.isEmpty) continue;
      final resultados = await s.pushLote(pendientes);
      for (final r in resultados) {
        // Confirmación fila-por-fila: solo OK se marca sincronizado.
        // transitorio → queda pendiente (reintenta); permanente → la feature lo marca 'error' al mergear.
        if (r.outcome == PushOutcome.ok) await s.marcarSincronizado(r.id);
      }
    }
  }

  Future<void> cicloPull({required DateTime ahora}) async {
    for (final s in _syncers) {
      try {
        final since = await s.getWatermark();
        await s.pullDesdeYMergear(since);   // si lanza, NO se llega a setWatermark
        await s.setWatermark(ahora);        // el watermark avanza SOLO si el merge commiteó entero
      } catch (_) {
        // El fallo de una feature no aborta las demás ni mueve su watermark; reintenta el próximo ciclo.
        continue;
      }
    }
  }
}
```

- [ ] **Step 4: Correr y ver pasar** → PASS (los 3 tests verifican los invariantes del spec).

- [ ] **Step 5: Commit** — `git add -A && git commit -m "feat: sync engine with per-row push and per-feature watermark"`

### Task 14: SyncScheduler (dispara ciclos)

**Files:**
- Create: `lib/core/sync/sync_scheduler.dart`
- Test: `test/core/sync/sync_scheduler_test.dart`

- [ ] **Step 1: Test que falla** (al pasar a online dispara un ciclo; debounce evita ráfagas)

```dart
// test/core/sync/sync_scheduler_test.dart
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/sync/sync_scheduler.dart';

void main() {
  test('dispara un ciclo al recuperar conexión', () async {
    var ciclos = 0;
    final online = StreamController<bool>();
    SyncScheduler(onlineStream: online.stream, ejecutarCiclo: () async => ciclos++,
        debounce: const Duration(milliseconds: 10))..iniciar();
    online.add(false); online.add(true);
    await Future.delayed(const Duration(milliseconds: 40));
    expect(ciclos, 1);
  });
}
```

- [ ] **Step 2: Correr y ver fallar** → FAIL.

- [ ] **Step 3: Implementar**

```dart
// lib/core/sync/sync_scheduler.dart
import 'dart:async';

class SyncScheduler {
  SyncScheduler({required this.onlineStream, required this.ejecutarCiclo,
      this.debounce = const Duration(seconds: 2)});
  final Stream<bool> onlineStream;
  final Future<void> Function() ejecutarCiclo;
  final Duration debounce;
  Timer? _timer;
  StreamSubscription<bool>? _sub;

  void iniciar() {
    _sub = onlineStream.where((online) => online).listen((_) => _agendar());
  }

  void dispararPorEscritura() => _agendar();

  void _agendar() {
    _timer?.cancel();
    _timer = Timer(debounce, ejecutarCiclo);
  }

  void dispose() { _timer?.cancel(); _sub?.cancel(); }
}
```

- [ ] **Step 4: Correr y ver pasar** → PASS.

- [ ] **Step 5: Commit** — `git add -A && git commit -m "feat: sync scheduler"`

---

# FASE 4 — Sesión, permisos y routing

### Task 15: Entidades de sesión, SessionController, can()/PermissionGate

**Files:**
- Create: `lib/core/session/entities.dart`, `lib/core/session/session_controller.dart`, `lib/core/session/permission_gate.dart`
- Test: `test/core/session/session_controller_test.dart`, `test/core/session/permission_gate_test.dart`

- [ ] **Step 1: Test que falla**

```dart
// test/core/session/session_controller_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/session/entities.dart';
import 'package:prosane_app/core/session/session_controller.dart';

void main() {
  test('estado inicial es noAutenticado y can() es false', () {
    final c = SessionController();
    expect(c.state, isA<SesionNoAutenticada>());
    expect(c.can('firmar_apto'), false);
  });

  test('tras setSesion, can() refleja los permisos', () {
    final c = SessionController();
    c.setSesion(Sesion(
      usuario: const Usuario(id: '1', nombre: 'Ana', rol: 'profesional'),
      permisos: const {'firmar_apto'},
    ));
    expect(c.can('firmar_apto'), true);
    expect(c.can('borrar_todo'), false);
  });
}
```

- [ ] **Step 2: Correr y ver fallar** → FAIL.

- [ ] **Step 3: Implementar** (Notifier con estado sealed; cache offline lo agrega Auth en Task 18)

```dart
// lib/core/session/entities.dart
class Usuario {
  const Usuario({required this.id, required this.nombre, required this.rol});
  final String id; final String nombre; final String rol;
}

class Sesion {
  const Sesion({required this.usuario, required this.permisos});
  final Usuario usuario; final Set<String> permisos;
}

sealed class SesionState {}
class SesionNoAutenticada extends SesionState {}
class SesionAutenticada extends SesionState { SesionAutenticada(this.sesion); final Sesion sesion; }
```

```dart
// lib/core/session/session_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'entities.dart';

class SessionController extends StateNotifier<SesionState> {
  SessionController() : super(SesionNoAutenticada());

  void setSesion(Sesion s) => state = SesionAutenticada(s);
  void cerrar() => state = SesionNoAutenticada();

  bool can(String permiso) {
    final st = state;
    return st is SesionAutenticada && st.sesion.permisos.contains(permiso);
  }
}

final sessionControllerProvider =
    StateNotifierProvider<SessionController, SesionState>((ref) => SessionController());
```

```dart
// lib/core/session/permission_gate.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'session_controller.dart';

class PermissionGate extends ConsumerWidget {
  const PermissionGate({super.key, required this.permiso, required this.child, this.fallback});
  final String permiso; final Widget child; final Widget? fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final puede = ref.watch(sessionControllerProvider.notifier).can(permiso);
    return puede ? child : (fallback ?? const SizedBox.shrink());
  }
}
```

- [ ] **Step 4: Test del gate** (muestra child solo con permiso) + correr todo → PASS.

- [ ] **Step 5: Commit** — `git add -A && git commit -m "feat: session controller and permission gate"`

### Task 16: Router (go_router + guard de auth)

**Files:**
- Create: `lib/core/router/app_router.dart`
- Modify: `lib/app.dart` (usar `MaterialApp.router`)
- Test: `test/core/router/app_router_test.dart`

- [ ] **Step 1: Test que falla** (sin sesión, cualquier ruta privada redirige a /login)

```dart
// test/core/router/app_router_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/router/app_router.dart';

void main() {
  test('no autenticado redirige a /login', () {
    final redirect = construirRedirect(false); // autenticado = false
    expect(redirect('/home'), '/login');
    expect(redirect('/login'), isNull);
  });

  test('autenticado en /login redirige a /home', () {
    final redirect = construirRedirect(true);
    expect(redirect('/login'), '/home');
    expect(redirect('/home'), isNull);
  });
}
```

- [ ] **Step 2: Correr y ver fallar** → FAIL.

- [ ] **Step 3: Implementar** la función pura de redirect + el router

```dart
// lib/core/router/app_router.dart
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../session/session_controller.dart';

typedef Redirect = String? Function(String location);

Redirect construirRedirect(bool autenticado) => (location) {
      final enLogin = location == '/login' || location == '/signup';
      if (!autenticado && !enLogin) return '/login';
      if (autenticado && enLogin) return '/home';
      return null;
    };

GoRouter buildRouter(Ref ref) {
  final autenticado = ref.read(sessionControllerProvider) is SesionAutenticada;
  final redirect = construirRedirect(autenticado);
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) => redirect(state.matchedLocation),
    routes: [
      // se completan en la Fase 5 (login/signup/home)
    ],
  );
}
```

> Nota: `construirRedirect(bool autenticado)` es **pura** y testeable sin Flutter; `buildRouter` solo la alimenta con el estado de sesión.

- [ ] **Step 4: Correr y ver pasar** → PASS.

- [ ] **Step 5: Commit** — `git add -A && git commit -m "feat: go_router with auth guard"`

---

# FASE 5 — Slice de Auth

### Task 17: Domain de Auth (entidades, repositorio, usecases)

**Files:**
- Create: `lib/features/auth/domain/repositories/auth_repository.dart`
- Create: `lib/features/auth/domain/usecases/login.dart`, `register.dart`
- Test: `test/features/auth/domain/login_test.dart`

- [ ] **Step 1: Test que falla** (el usecase Login delega en el repo y propaga el resultado)

```dart
// test/features/auth/domain/login_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:prosane_app/core/session/entities.dart';
import 'package:prosane_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:prosane_app/features/auth/domain/usecases/login.dart';

class _MockRepo extends Mock implements AuthRepository {}

void main() {
  test('Login devuelve la sesión del repo', () async {
    final repo = _MockRepo();
    final sesion = Sesion(usuario: const Usuario(id: '1', nombre: 'Ana', rol: 'profesional'), permisos: const {});
    when(() => repo.login('a@b.com', 'x')).thenAnswer((_) async => sesion);
    final r = await Login(repo)('a@b.com', 'x');
    expect(r, sesion);
  });
}
```

- [ ] **Step 2: Correr y ver fallar** → FAIL.

- [ ] **Step 3: Implementar**

```dart
// lib/features/auth/domain/repositories/auth_repository.dart
import '../../../../core/session/entities.dart';

abstract class AuthRepository {
  Future<Sesion> login(String email, String password);
  Future<void> register(Map<String, dynamic> datos);
  Future<Sesion?> sesionCacheada(); // para arranque offline
  Future<void> logout();
}
```

```dart
// lib/features/auth/domain/usecases/login.dart
import '../../../../core/session/entities.dart';
import '../repositories/auth_repository.dart';

class Login {
  Login(this._repo);
  final AuthRepository _repo;
  Future<Sesion> call(String email, String password) => _repo.login(email, password);
}
```

```dart
// lib/features/auth/domain/usecases/register.dart
import '../repositories/auth_repository.dart';

class Register {
  Register(this._repo);
  final AuthRepository _repo;
  Future<void> call(Map<String, dynamic> datos) => _repo.register(datos);
}
```

- [ ] **Step 4: Correr y ver pasar** → PASS.

- [ ] **Step 5: Commit** — `git add -A && git commit -m "feat: auth domain (repo + usecases)"`

### Task 18: Data de Auth (DTOs, remote datasource, repository impl con cache de /me)

**Files:**
- Create: `lib/features/auth/data/dtos/me_response.dart`
- Create: `lib/features/auth/data/datasources/auth_remote_datasource.dart`
- Create: `lib/features/auth/data/repositories/auth_repository_impl.dart`
- Test: `test/features/auth/data/auth_repository_impl_test.dart`

- [ ] **Step 1: Test que falla** (login guarda tokens, trae /me y arma la Sesión; permisos del backend)

```dart
// test/features/auth/data/auth_repository_impl_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:prosane_app/core/storage/token_storage.dart';
import 'package:prosane_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:prosane_app/features/auth/data/repositories/auth_repository_impl.dart';

class _MockRemote extends Mock implements AuthRemoteDataSource {}

void main() {
  test('login guarda tokens y arma sesión con permisos de /me', () async {
    final remote = _MockRemote();
    final tokens = TokenStorage(backend: InMemoryKeyValueStore());
    when(() => remote.login('a@b.com', 'x')).thenAnswer((_) async => (access: 'A', refresh: 'R'));
    when(() => remote.me()).thenAnswer((_) async =>
        MeResponse(id: '1', nombre: 'Ana', rol: 'profesional', permisos: {'firmar_apto'}));

    final repo = AuthRepositoryImpl(remote: remote, tokens: tokens);
    final sesion = await repo.login('a@b.com', 'x');

    expect(await tokens.access(), 'A');
    expect(sesion.usuario.nombre, 'Ana');
    expect(sesion.permisos, {'firmar_apto'});
  });
}
```

- [ ] **Step 2: Correr y ver fallar** → FAIL.

- [ ] **Step 3: Implementar** DTO (freezed/json), remote datasource y repo impl. El repo cachea la Sesión (usuario+permisos) para arranque offline (en Drift o en un KV; para esta iteración, KV seguro alcanza).

```dart
// lib/features/auth/data/dtos/me_response.dart
class MeResponse {
  MeResponse({required this.id, required this.nombre, required this.rol, required this.permisos});
  final String id; final String nombre; final String rol; final Set<String> permisos;

  factory MeResponse.fromJson(Map<String, dynamic> j) => MeResponse(
        id: j['id'] as String, nombre: j['nombre'] as String, rol: j['rol'] as String,
        permisos: (j['permisos'] as List).cast<String>().toSet(),
      );
}
```

```dart
// lib/features/auth/data/datasources/auth_remote_datasource.dart
import 'package:dio/dio.dart';
import '../dtos/me_response.dart';

typedef Tokens = ({String access, String refresh});

abstract class AuthRemoteDataSource {
  Future<Tokens> login(String email, String password);
  Future<void> register(Map<String, dynamic> datos);
  Future<MeResponse> me();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  @override
  Future<Tokens> login(String email, String password) async {
    final r = await _dio.post('/token', data: {'email': email, 'password': password});
    return (access: r.data['access'] as String, refresh: r.data['refresh'] as String);
  }

  @override
  Future<void> register(Map<String, dynamic> datos) => _dio.post('/register', data: datos);

  @override
  Future<MeResponse> me() async => MeResponse.fromJson((await _dio.get('/me')).data as Map<String, dynamic>);
}
```

```dart
// lib/features/auth/data/repositories/auth_repository_impl.dart
import '../../../../core/session/entities.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required this.remote, required this.tokens});
  final AuthRemoteDataSource remote;
  final TokenStorage tokens;

  @override
  Future<Sesion> login(String email, String password) async {
    final t = await remote.login(email, password);
    await tokens.guardar(access: t.access, refresh: t.refresh);
    final me = await remote.me();
    return Sesion(
      usuario: Usuario(id: me.id, nombre: me.nombre, rol: me.rol),
      permisos: me.permisos,
    );
  }

  @override
  Future<void> register(Map<String, dynamic> datos) => remote.register(datos);

  @override
  Future<Sesion?> sesionCacheada() async => null; // sin cache aún: Auth requiere red la 1ra vez (ver nota)

  @override
  Future<void> logout() => tokens.limpiar();
}
```

> Nota: `sesionCacheada()` devuelve `null` por ahora (Auth necesita red la primera vez). El cache real en Drift se cabléa cuando exista una pantalla post-login que lo use; queda fuera de esta iteración (consistente con el spec).

- [ ] **Step 4: Correr y ver pasar** → PASS.

- [ ] **Step 5: Commit** — `git add -A && git commit -m "feat: auth data layer with /me session"`

### Task 19: LoginController + LoginScreen (taxonomía de errores)

**Files:**
- Create: `lib/features/auth/presentation/controllers/login_controller.dart`
- Create: `lib/features/auth/presentation/screens/login_screen.dart`
- Test: `test/features/auth/presentation/login_controller_test.dart`

- [ ] **Step 1: Test que falla** (401 → mensaje credenciales; 500 → mensaje genérico, no credenciales)

```dart
// test/features/auth/presentation/login_controller_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:prosane_app/core/error/failure.dart';
import 'package:prosane_app/features/auth/domain/usecases/login.dart';
import 'package:prosane_app/features/auth/presentation/controllers/login_controller.dart';

class _MockLogin extends Mock implements Login {}

void main() {
  test('500 NO muestra "Credenciales incorrectas"', () async {
    final login = _MockLogin();
    when(() => login.call(any(), any())).thenThrow(const ServerFailure());
    final c = LoginController(login: login, onAutenticado: (_) {});
    await c.enviar('a@b.com', 'x');
    expect(c.state.error, 'Hubo un problema, probá de nuevo');
    expect(c.state.error, isNot('Credenciales incorrectas'));
  });
}
```

- [ ] **Step 2: Correr y ver fallar** → FAIL.

- [ ] **Step 3: Implementar** el controller (mapea Failure→mensaje vía el `mensaje` del sealed) y la pantalla con el design system.

```dart
// lib/features/auth/presentation/controllers/login_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/session/entities.dart';
import '../../domain/usecases/login.dart';

class LoginState {
  const LoginState({this.isLoading = false, this.error});
  final bool isLoading; final String? error;
  LoginState copyWith({bool? isLoading, String? error}) =>
      LoginState(isLoading: isLoading ?? this.isLoading, error: error);
}

class LoginController extends StateNotifier<LoginState> {
  LoginController({required Login login, required this.onAutenticado})
      : _login = login, super(const LoginState());
  final Login _login;
  final void Function(Sesion) onAutenticado;

  Future<void> enviar(String email, String password) async {
    state = const LoginState(isLoading: true);
    try {
      final sesion = await _login(email, password);
      onAutenticado(sesion);
      state = const LoginState();
    } on Failure catch (f) {
      state = LoginState(error: f.mensaje);
    } catch (_) {
      state = const LoginState(error: 'Hubo un problema, probá de nuevo');
    }
  }
}
```

`LoginScreen`: `AppGradientScaffold` + `AppCard` con "Bienvenido", dos `AppTextField` (el de password con `errorText` cuando `state.error != null`), `AppSwitch` Recordarme, `AppLink` olvido, `AppButton` (isLoading desde el state), `AppLink` "Regístrese aquí" → va a `/signup`.

- [ ] **Step 4: Correr y ver pasar** → PASS. Agregar un widget test que tipea credenciales y verifica que el botón pasa a loading.

- [ ] **Step 5: Commit** — `git add -A && git commit -m "feat: login controller and screen"`

### Task 20: SignupController + estado efímero del wizard

**Files:**
- Create: `lib/features/auth/presentation/controllers/signup_controller.dart`
- Test: `test/features/auth/presentation/signup_controller_test.dart`

- [ ] **Step 1: Test que falla** (gating por etapa; volver conserva datos; submit llama Register)

```dart
// test/features/auth/presentation/signup_controller_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:prosane_app/features/auth/domain/usecases/register.dart';
import 'package:prosane_app/features/auth/presentation/controllers/signup_controller.dart';

class _MockRegister extends Mock implements Register {}

void main() {
  test('no avanza de la etapa 1 sin aceptar política', () {
    final c = SignupController(register: _MockRegister(), onRegistrado: () {});
    c.setNumeroDocumento('123'); c.setTipoDocumento('DNI');
    expect(c.etapaValida(0), false); // falta aceptar política
    c.setAceptaPolitica(true);
    expect(c.etapaValida(0), true);
  });

  test('email != confirmEmail invalida la etapa 3', () {
    final c = SignupController(register: _MockRegister(), onRegistrado: () {});
    c.setEmail('a@b.com'); c.setConfirmEmail('x@b.com'); c.setPaisResidencia('AR');
    expect(c.etapaValida(2), false);
  });
}
```

- [ ] **Step 2: Correr y ver fallar** → FAIL.

- [ ] **Step 3: Implementar** `SignupFormData` (con freezed) + `SignupController` (`StateNotifier`) con `etapaValida(int)`, navegación `siguiente()/anterior()` y `enviar()` → `Register`. El estado vive solo en el controller (efímero).

- [ ] **Step 4: Correr y ver pasar** → PASS.

- [ ] **Step 5: Commit** — `git add -A && git commit -m "feat: signup wizard controller"`

### Task 21: Pantallas del wizard (4 etapas, autoDispose = efímero)

**Files:**
- Create: `lib/features/auth/presentation/screens/signup_wizard_screen.dart`
- Create: `lib/features/auth/presentation/widgets/` (step_documento, step_datos_personales, step_contacto, step_acceso, wizard_progress, wizard_nav_buttons)
- Test: `test/features/auth/presentation/signup_wizard_test.dart`

- [ ] **Step 1: Test que falla** (al cargar datos, ir a etapa 2 y volver, los datos siguen)

```dart
// test/features/auth/presentation/signup_wizard_test.dart
// widget test: escribe numeroDocumento en etapa 1, toca SIGUIENTE, toca ANTERIOR,
// verifica que el campo conserva '123' (estado en el controller, no en el widget).
```

- [ ] **Step 2: Correr y ver fallar** → FAIL.

- [ ] **Step 3: Implementar** el wizard con `PageView`/índice manejado por el controller. **El provider del controller es `autoDispose` scopeado a la ruta `/signup`** → salir del flujo borra el estado (efímero, a propósito). Moverse entre etapas NO dispone. Nada se escribe en disco.

- [ ] **Step 4: Correr y ver pasar** → PASS.

- [ ] **Step 5: Commit** — `git add -A && git commit -m "feat: signup wizard screens (ephemeral state)"`

### Task 22: Wiring final (providers + rutas + arranque)

> **🚩 CHECKPOINT VISIBLE (fin de Fase 5):** además de los tests, el controlador corre la app
> (`flutter run`) y le muestra al usuario el **login integrado end-to-end** funcionando (pantalla de
> login → INICIAR SESIÓN → home), no solo el verde de la suite.

**Files:**
- Create: `lib/core/providers.dart` (providers raíz: dio, tokenStorage, authRepository, sessionController)
- Modify: `lib/core/router/app_router.dart` (rutas /login, /signup, /home placeholder)
- Modify: `lib/app.dart` (`MaterialApp.router`)
- Test: `test/integration/login_flow_test.dart`

- [ ] **Step 1: Test de integración que falla** (login OK con datasource fake → router lleva a /home)

```dart
// test/integration/login_flow_test.dart
// Override del authRepositoryProvider con un fake que devuelve una Sesión;
// bombea LoginScreen, completa campos, toca INICIAR SESIÓN, espera, y verifica
// que se ve la pantalla /home (placeholder).
```

- [ ] **Step 2: Correr y ver fallar** → FAIL.

- [ ] **Step 3: Implementar** `providers.dart` cableando todo con Riverpod, completar rutas en el router y `MaterialApp.router` en `app.dart`. Home placeholder con un `PermissionGate` de ejemplo y botón de logout.

- [ ] **Step 4: Correr y ver pasar** — `flutter test` (toda la suite) → PASS. `flutter analyze` → sin issues.

- [ ] **Step 5: Commit** — `git add -A && git commit -m "feat: wire auth slice end-to-end"`

---

## Cierre

Al terminar las 22 tasks:
- `flutter test` en verde (unit + widget + integración + invariantes de sync).
- `flutter analyze` sin issues.
- App corriendo: login real contra la API, signup wizard, y la fundación offline-first (Drift + sync_engine) montada y testeada contra un FeatureSyncer falso.
- **Pendiente para la próxima iteración:** primera feature de dominio real (`apto_fisico`) que estrena el sync_engine end-to-end, y los endpoints de backend del contrato (`/me`, `/token/refresh`, batch con respuesta por-ítem).

Usar **superpowers:finishing-a-development-branch** para cerrar.
```
```
