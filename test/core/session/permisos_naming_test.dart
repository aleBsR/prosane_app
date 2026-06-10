import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Invariante (spec §"Sesión y permisos"): todas las claves de permiso/acción
/// usadas en el front son camelCase, idénticas a las que emite el backend en
/// `/me` (listarPacientes, verFichaClinica, crearApto, firmarApto, …).
///
/// `can()` hace match EXACTO de strings: una clave en snake_case (firmar_apto)
/// nunca matchea y cae siempre al fallback "Sin permisos" — un bug silencioso
/// que no rompe en compilación. Este test le pone dientes al invariante:
/// escanea `lib/` y falla si alguna clave literal pasada a `can(...)` o a
/// `PermissionGate(permiso: ...)` no es camelCase.
void main() {
  // camelCase estricto: arranca en minúscula, solo letras/dígitos, sin `_`.
  // Rechaza snake_case (firmar_apto) y PascalCase (FirmarApto).
  final camelCase = RegExp(r'^[a-z][a-zA-Z0-9]*$');

  // Captura el literal string en `can('clave')` y `permiso: 'clave'`
  // (con comillas simples o dobles). Solo literales: `can(permiso)` con una
  // variable no matchea, así que la definición de `can(String permiso)` no
  // se cuenta como uso.
  final patrones = <RegExp>[
    RegExp(r'''\bcan\(\s*['"]([^'"]*)['"]'''),
    RegExp(r'''permiso:\s*['"]([^'"]*)['"]'''),
  ];

  test('todas las claves de permiso en lib/ son camelCase (idénticas al backend)', () {
    final libDir = Directory('lib');
    expect(libDir.existsSync(), isTrue, reason: 'no se encontró lib/ — corré el test desde la raíz del proyecto');

    final infractores = <String>[];

    for (final entidad in libDir.listSync(recursive: true)) {
      if (entidad is! File || !entidad.path.endsWith('.dart')) continue;
      final contenido = entidad.readAsStringSync();
      for (final patron in patrones) {
        for (final m in patron.allMatches(contenido)) {
          final clave = m.group(1)!;
          if (!camelCase.hasMatch(clave)) {
            infractores.add('${entidad.path}: "$clave"');
          }
        }
      }
    }

    expect(
      infractores,
      isEmpty,
      reason: 'Claves de permiso que NO son camelCase (deben matchear las del backend en /me):\n'
          '${infractores.join('\n')}',
    );
  });
}
