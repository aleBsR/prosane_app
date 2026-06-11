import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:prosane_app/core/theme/app_theme.dart';
import 'package:prosane_app/core/design_system/app_text_field.dart';
import 'package:prosane_app/core/design_system/app_button.dart';
import 'package:prosane_app/core/design_system/app_switch.dart';
import 'package:prosane_app/core/design_system/app_link.dart';
import 'package:prosane_app/core/design_system/app_card.dart';
import 'package:prosane_app/core/design_system/app_gradient_scaffold.dart';
import 'package:prosane_app/core/design_system/floating_nav_bar.dart';
import 'package:prosane_app/core/design_system/nav_bar_badge.dart';
import 'package:prosane_app/core/design_system/action_group.dart';
import 'package:prosane_app/core/design_system/action_tile.dart';
import 'package:prosane_app/core/design_system/empty_state.dart';

void main() => runApp(const ProsaneWidgetbook());

/// Centra y aplica el theme a cada preview.
Widget _frame(Widget child) => Theme(
      data: AppTheme.light(),
      child: Scaffold(
        backgroundColor: const Color(0xFFEDEAF6),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: child,
          ),
        ),
      ),
    );

class ProsaneWidgetbook extends StatelessWidget {
  const ProsaneWidgetbook({super.key});

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      directories: [
        WidgetbookComponent(
          name: 'AppButton',
          useCases: [
            WidgetbookUseCase(
              name: 'Normal',
              builder: (c) => _frame(
                AppButton(label: 'INICIAR SESIÓN', onPressed: () {}),
              ),
            ),
            WidgetbookUseCase(
              name: 'Cargando',
              builder: (c) => _frame(
                const AppButton(label: 'INICIAR SESIÓN', isLoading: true),
              ),
            ),
            WidgetbookUseCase(
              name: 'Validado',
              builder: (c) => _frame(
                const AppButton(label: 'OK', state: AppButtonState.validado),
              ),
            ),
            WidgetbookUseCase(
              name: 'Error',
              builder: (c) => _frame(
                const AppButton(label: 'OK', state: AppButtonState.error),
              ),
            ),
          ],
        ),
        WidgetbookComponent(
          name: 'AppTextField',
          useCases: [
            WidgetbookUseCase(
              name: 'Normal',
              builder: (c) => _frame(
                const AppTextField(
                  label: 'E-mail',
                  hint: 'Ingrese su e-mail',
                ),
              ),
            ),
            WidgetbookUseCase(
              name: 'Error',
              builder: (c) => _frame(
                const AppTextField(
                  label: 'Contraseña',
                  errorText: 'Credenciales incorrectas',
                ),
              ),
            ),
            WidgetbookUseCase(
              name: 'Validado',
              builder: (c) => _frame(
                const AppTextField(label: 'Cuil', isValid: true),
              ),
            ),
            WidgetbookUseCase(
              name: 'Password',
              builder: (c) => _frame(
                const AppTextField(label: 'Contraseña', isPassword: true),
              ),
            ),
          ],
        ),
        WidgetbookComponent(
          name: 'AppSwitch',
          useCases: [
            WidgetbookUseCase(
              name: 'Off',
              builder: (c) => _frame(
                AppSwitch(
                  value: false,
                  label: 'Recordarme',
                  onChanged: (_) {},
                ),
              ),
            ),
            WidgetbookUseCase(
              name: 'On',
              builder: (c) => _frame(
                AppSwitch(
                  value: true,
                  label: 'Recordarme',
                  onChanged: (_) {},
                ),
              ),
            ),
          ],
        ),
        WidgetbookComponent(
          name: 'AppLink',
          useCases: [
            WidgetbookUseCase(
              name: 'Default',
              builder: (c) => _frame(
                AppLink(text: 'Regístrese aquí', onTap: () {}),
              ),
            ),
          ],
        ),
        WidgetbookComponent(
          name: 'AppCard',
          useCases: [
            WidgetbookUseCase(
              name: 'Sobre fondo',
              builder: (c) => Theme(
                data: AppTheme.light(),
                child: AppGradientScaffold(
                  child: Center(
                    child: AppCard(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text('Bienvenido'),
                          SizedBox(height: 8),
                          Text('contenido de ejemplo'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        WidgetbookComponent(
          name: 'FloatingNavBar',
          useCases: [
            WidgetbookUseCase(name: 'Expandida — Inicio activo', builder: (c) => _frame(
              const _NavBarDemo(selected: 0, compacta: false, badge: 0))),
            WidgetbookUseCase(name: 'Expandida — Pendientes activo (badge 3)', builder: (c) => _frame(
              const _NavBarDemo(selected: 1, compacta: false, badge: 3))),
            WidgetbookUseCase(name: 'Compacta — solo íconos', builder: (c) => _frame(
              const _NavBarDemo(selected: 0, compacta: true, badge: 3))),
            WidgetbookUseCase(name: 'Sin badge (todo sincronizado)', builder: (c) => _frame(
              const _NavBarDemo(selected: 1, compacta: false, badge: 0))),
          ],
        ),
        WidgetbookComponent(
          name: 'ActionGroup',
          useCases: [
            WidgetbookUseCase(name: 'Expandido (Salud, 4 acciones)', builder: (c) => _frame(
              ActionGroup(titulo: 'SALUD', children: [
                for (final l in ['Listar pacientes', 'Ver ficha clínica', 'Crear apto físico', 'Firmar apto físico'])
                  ActionTile(color: const Color(0xFF2E7D32), icon: Icons.draw_outlined, label: l, onTap: () {}),
              ]))),
            WidgetbookUseCase(name: 'Colapsado', builder: (c) => _frame(
              const ActionGroup(titulo: 'CONSENTIMIENTO', initiallyExpanded: false, children: [Text('—')]))),
          ],
        ),
        WidgetbookComponent(
          name: 'ActionTile',
          useCases: [
            WidgetbookUseCase(name: 'Salud (verde)', builder: (c) => _frame(
              ActionTile(color: const Color(0xFF2E7D32), icon: Icons.draw_outlined, label: 'Firmar apto físico', onTap: () {}))),
            WidgetbookUseCase(name: 'Consentimiento (gris)', builder: (c) => _frame(
              ActionTile(color: const Color(0xFF455A64), icon: Icons.description_outlined, label: 'Ver constancias', onTap: () {}))),
          ],
        ),
        WidgetbookComponent(
          name: 'NavBarBadge',
          useCases: [
            for (final n in [1, 9, 150])
              WidgetbookUseCase(name: '$n', builder: (c) => _frame(NavBarBadge(count: n))),
          ],
        ),
        WidgetbookComponent(
          name: 'EmptyState',
          useCases: [
            WidgetbookUseCase(name: 'Sin acciones', builder: (c) => Theme(data: AppTheme.light(),
              child: const AppGradientScaffold(child: EmptyState(icon: Icons.inbox_outlined,
                titulo: 'No tenés acciones disponibles todavía',
                subtitulo: 'Cuando te asignen un rol, vas a ver acá lo que podés hacer.')))),
            WidgetbookUseCase(name: 'Todo sincronizado', builder: (c) => Theme(data: AppTheme.light(),
              child: const AppGradientScaffold(child: EmptyState(icon: Icons.check_circle_outline, titulo: 'Todo sincronizado')))),
          ],
        ),
      ],
    );
  }
}

class _NavBarDemo extends StatelessWidget {
  const _NavBarDemo({required this.selected, required this.compacta, required this.badge});
  final int selected;
  final bool compacta;
  final int badge;
  @override
  Widget build(BuildContext context) => FloatingNavBar(
        compacta: compacta,
        selectedIndex: selected,
        onTap: (_) {},
        items: [
          const NavItemData(outlinedIcon: Icons.home_outlined, filledIcon: Icons.home, label: 'Inicio'),
          NavItemData(outlinedIcon: Icons.sync_outlined, filledIcon: Icons.sync, label: 'Pendientes', badgeCount: badge),
          const NavItemData(outlinedIcon: Icons.person_outline, filledIcon: Icons.person, label: 'Usuario'),
        ],
      );
}
