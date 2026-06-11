import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design_system/app_gradient_scaffold.dart';
import '../../../core/providers.dart';
import '../../../core/session/entities.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class UsuarioScreen extends ConsumerWidget {
  const UsuarioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(sessionControllerProvider);
    final usuario = estado is SesionAutenticada
        ? estado.sesion.usuario
        : const Usuario(id: '', nombre: '', rolName: '', rolLabel: '');

    return AppGradientScaffold(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 120), // 120 abajo: espacio para la FloatingNavBar
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 18),
            child: Text('Usuario', style: AppTypography.titulo.copyWith(fontSize: 24, color: Colors.white)),
          ),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            clipBehavior: Clip.antiAlias,
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 26, 18, 8),
                child: Column(children: [
                  const CircleAvatar(radius: 38, backgroundColor: AppColors.primario,
                      child: Icon(Icons.person_outline, color: Colors.white, size: 40)),
                  const SizedBox(height: 14),
                  Text(usuario.nombre, style: AppTypography.titulo.copyWith(fontSize: 18, color: AppColors.texto)),
                  const SizedBox(height: 2),
                  Text(usuario.rolLabel, style: const TextStyle(fontFamily: 'Rubik', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primario)),
                ]),
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined, color: AppColors.primario),
                title: const Text('Configuración', style: TextStyle(fontFamily: 'Rubik', fontWeight: FontWeight.w600, color: AppColors.texto)),
                trailing: const Icon(Icons.keyboard_arrow_right, color: Color(0xFFC4BBE8)), // lavanda claro (sin token aún)
                onTap: () => showDialog<void>(context: context, builder: (_) => AlertDialog(
                  content: const Text('Editar perfil — próximamente'),
                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))])),
              ),
            ]),
          ),
          const SizedBox(height: 18),
          TextButton.icon(
            onPressed: () => ref.read(logoutProvider)(),
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text('Cerrar sesión', style: TextStyle(fontFamily: 'Rubik', color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
