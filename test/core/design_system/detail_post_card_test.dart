import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/design_system/detail_post_card.dart';
import 'package:prosane_app/core/theme/app_colors.dart';
import 'package:prosane_app/core/theme/app_theme.dart';

Widget _buildScreen(Widget child) {
  return MaterialApp(
    theme: AppTheme.light().copyWith(splashFactory: NoSplash.splashFactory),
    home: Scaffold(
      body: SingleChildScrollView(child: child),
    ),
  );
}

void main() {
  testWidgets('cabecera, chips, acciones y menú', (tester) async {
    var elegido = '';
    await tester.pumpWidget(_buildScreen(DetailPostCard(
      avatarLetter: 'Escuela 1',
      title: 'Escuela 1',
      subtitle: 'CUE 1 • Salta',
      bannerIcon: Icons.school_outlined,
      bannerChips: const ['Estatal', 'Común'],
      menuEntries: const [
        PostMenuEntry(
            value: 'editar',
            label: 'Editar',
            icon: Icons.edit_outlined,
            color: AppColors.primario),
      ],
      onMenuSelected: (v) => elegido = v,
      actions: [
        PostActionButton(
          icono: Icons.menu_book_outlined,
          texto: 'Ver cursos',
          colorFondo: AppColors.primario,
          colorTexto: AppColors.blanco,
          onPressed: () {},
        ),
      ],
      body: const Text('Dato: X'),
    )));
    await tester.pumpAndSettle();

    expect(find.text('E'), findsOneWidget); // avatar con inicial
    expect(find.text('Escuela 1'), findsWidgets);
    expect(find.text('CUE 1 • Salta'), findsOneWidget);
    expect(find.text('Estatal'), findsOneWidget);
    expect(find.text('Común'), findsOneWidget);
    expect(find.text('Ver cursos'), findsOneWidget);
    expect(find.text('Dato: X'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    expect(elegido, 'editar');
  });

  testWidgets('sin menú no hay icono more_vert', (tester) async {
    await tester.pumpWidget(_buildScreen(const DetailPostCard(
      avatarLetter: '',
      title: 'T',
    )));
    await tester.pumpAndSettle();

    expect(find.text('?'), findsOneWidget); // avatar por defecto
    expect(find.byIcon(Icons.more_vert), findsNothing);
  });

  testWidgets('bannerTop y bannerBottom se renderizan dentro de la franja destacada', (tester) async {
    await tester.pumpWidget(_buildScreen(const DetailPostCard(
      title: 'Alumno',
      bannerTop: Text('Asistencia: Presente'),
      bannerChips: ['E ✓', 'A'],
      bannerBottom: Text('Botón Acción'),
    )));
    await tester.pumpAndSettle();

    expect(find.text('Asistencia: Presente'), findsOneWidget);
    expect(find.text('E ✓'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('Botón Acción'), findsOneWidget);
  });
}

