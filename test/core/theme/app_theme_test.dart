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
