import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:prosane_app/core/theme/app_theme.dart';
import 'package:prosane_app/core/design_system/app_text_field.dart';
import 'package:prosane_app/core/design_system/app_button.dart';
import 'package:prosane_app/core/design_system/app_switch.dart';
import 'package:prosane_app/core/design_system/app_link.dart';
import 'package:prosane_app/core/design_system/app_card.dart';
import 'package:prosane_app/core/design_system/app_gradient_scaffold.dart';

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
      ],
    );
  }
}
