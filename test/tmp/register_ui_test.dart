import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:prosane_app/core/session/entities.dart';
import 'package:prosane_app/features/auth/domain/usecases/register.dart';
import 'package:prosane_app/features/auth/presentation/controllers/signup_controller.dart';
import 'package:prosane_app/features/auth/presentation/screens/signup_wizard_screen.dart';

class _MockRegister extends Mock implements Register {}

void main() {
  testWidgets('REGISTRARSE en etapa 4 llama al usecase', (tester) async {
    final reg = _MockRegister();
    when(() => reg.call(any())).thenAnswer((_) async => Sesion(
      usuario: const Usuario(id: '1', nombre: 'T', rolName: 'tutor', rolLabel: 'Tutor'),
      acciones: const [],
    ));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [registerUseCaseProvider.overrideWithValue(reg)],
        child: const MaterialApp(home: SignupWizardScreen()),
      ),
    );
    await tester.pump();

    // Etapa 0
    await tester.tap(find.byKey(const Key('signup_tipo_documento')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('DNI').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('signup_numero_documento')), '12345678');
    await tester.tap(find.text('Acepto la política de privacidad y términos'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('wizard_siguiente')));
    await tester.pumpAndSettle();

    // Etapa 1
    await tester.enterText(find.byKey(const Key('signup_nombre')), 'Juan');
    await tester.enterText(find.byKey(const Key('signup_apellido')), 'Pérez');
    await tester.tap(find.byKey(const Key('signup_sexo')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Masculino').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('signup_fecha_nacimiento')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('signup_lugar_nacimiento')), 'Salta');
    await tester.tap(find.byKey(const Key('wizard_siguiente')));
    await tester.pumpAndSettle();

    // Etapa 2
    await tester.tap(find.byKey(const Key('signup_pais_residencia')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Argentina').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('signup_email')), 'juan@test.com');
    await tester.enterText(find.byKey(const Key('signup_confirm_email')), 'juan@test.com');
    await tester.tap(find.byKey(const Key('wizard_siguiente')));
    await tester.pumpAndSettle();

    // Etapa 3
    await tester.enterText(find.byKey(const Key('signup_password')), 'Password123');
    await tester.enterText(find.byKey(const Key('signup_confirm_password')), 'Password123');
    await tester.pump();

    // Tocar REGISTRARSE
    await tester.tap(find.byKey(const Key('wizard_registrarse')));
    await tester.pump();

    verify(() => reg.call(any())).called(1);
  });
}
