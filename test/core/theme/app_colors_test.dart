import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/design_system/action_group.dart';
import 'package:prosane_app/core/design_system/action_tile.dart';
import 'package:prosane_app/core/theme/app_colors.dart';

void main() {
  tearDown(() => AppColors.brillo = Brightness.light);

  test('paleta clara: valores históricos', () {
    AppColors.brillo = Brightness.light;
    expect(AppColors.texto, const Color(0xFF2D2D3A));
    expect(AppColors.blanco, const Color(0xFFFFFFFF));
    expect(AppColors.campo, const Color(0xFFF1F0F5));
    expect(AppColors.ok, const Color(0xFF2E7D32));
  });

  test('paleta oscura: superficies y textos adaptados', () {
    AppColors.brillo = Brightness.dark;
    expect(AppColors.texto, const Color(0xFFECEAF4));
    expect(AppColors.blanco, const Color(0xFF1E1E2A));
    expect(AppColors.campo, const Color(0xFF262633));
    expect(AppColors.ok, const Color(0xFF81C784));
    expect(AppColors.fondoApp, const Color(0xFF251C50));
  });

  testWidgets('ActionGroup del inicio refleja el brillo activo', (t) async {
    AppColors.brillo = Brightness.dark;
    await t.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: ActionGroup(titulo: 'GESTIÓN', children: [
          ActionTile(color: Colors.red, icon: Icons.add, label: 'Nuevo', onTap: _noop),
        ]),
      ),
    ));
    final cont = t.widget<Container>(find.byType(Container).first);
    final deco = cont.decoration as BoxDecoration;
    expect(deco.color, AppColors.blanco);
    expect(deco.color, const Color(0xFF1E1E2A));
  });
}

void _noop() {}
