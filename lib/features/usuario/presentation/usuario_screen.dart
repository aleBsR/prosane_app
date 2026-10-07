import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system/app_gradient_scaffold.dart';
import '../../../core/providers.dart';
import '../../../core/session/entities.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_controller.dart';
import 'widgets/proteccion_datos_dialog.dart';

class UsuarioScreen extends ConsumerWidget {
  const UsuarioScreen({super.key});

  void _confirmarLogout(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro que querés cerrar sesión?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('No')),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await ref.read(logoutProvider)();
            },
            child: const Text('Sí'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(sessionControllerProvider);
    final usuario = estado is SesionAutenticada
        ? estado.sesion.usuario
        : const Usuario(id: '', nombre: '', rolName: '', rolLabel: '');
    final modoOscuro = ref.watch(themeModeProvider) == ThemeMode.dark;

    return AppGradientScaffold(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 120), // 120 abajo: espacio para la FloatingNavBar
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 18),
            child: Text('Usuario', style: AppTypography.titulo.copyWith(fontSize: 24, color: Colors.white)),
          ),
          // Material (no Container+BoxDecoration) para que el ListTile de adentro
          // pinte su fondo/ink sobre un Material propio y no quede oculto por la
          // tarjeta blanca. Mismo look: blanco, redondeado y con clip.
          Material(
            color: AppColors.blanco,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 26, 18, 8),
                child: Column(children: [
                   CircleAvatar(radius: 38, backgroundColor: AppColors.primario,
                      child: Icon(Icons.person_outline, color: Colors.white, size: 40)),
                  const SizedBox(height: 14),
                  Text(usuario.nombre, style: AppTypography.titulo.copyWith(fontSize: 18, color: AppColors.texto)),
                  const SizedBox(height: 2),
                  Text(usuario.rolLabel, style:  TextStyle(fontFamily: 'Rubik', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primario)),
                ]),
              ),
              ListTile(
                leading: Icon(
                  modoOscuro ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  color: AppColors.primario,
                ),
                title: Text('Modo oscuro',
                    style: TextStyle(fontFamily: 'Rubik', fontWeight: FontWeight.w600, color: AppColors.texto)),
                trailing: Switch(
                  value: modoOscuro,
                  onChanged: (_) =>
                      ref.read(themeModeProvider.notifier).alternar(),
                ),
                onTap: () =>
                    ref.read(themeModeProvider.notifier).alternar(),
              ),
              ListTile(
                leading:  Icon(Icons.settings_outlined, color: AppColors.primario),
                title:  Text('Configuración', style: TextStyle(fontFamily: 'Rubik', fontWeight: FontWeight.w600, color: AppColors.texto)),
                trailing: const Icon(Icons.keyboard_arrow_right, color: Color(0xFFC4BBE8)),
                onTap: () => context.push('/usuario/configuracion'),
              ),
            ]),
          ),
          const SizedBox(height: 18),
          TextButton.icon(
            onPressed: () => _confirmarLogout(context, ref),
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text('Cerrar sesión', style: TextStyle(fontFamily: 'Rubik', color: Colors.white, fontWeight: FontWeight.w600)),
          ),
          // Aviso legal discreto: abre la leyenda de protección de datos.
          TextButton.icon(
            onPressed: () => mostrarProteccionDatosDialog(context),
            icon: const Icon(Icons.privacy_tip_outlined, color: Colors.white70, size: 14),
            label: const Text('Protección de datos',
                style: TextStyle(fontFamily: 'Rubik', fontSize: 11, color: Colors.white70)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}
