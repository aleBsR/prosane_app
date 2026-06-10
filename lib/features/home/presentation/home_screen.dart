import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/session/entities.dart';
import '../../../core/session/permission_gate.dart';
import '../../../core/session/session_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesionState = ref.watch(sessionControllerProvider);
    final nombre = sesionState is SesionAutenticada
        ? sesionState.sesion.usuario.nombre
        : '';

    return Scaffold(
      key: const Key('home_screen'),
      appBar: AppBar(
        title: const Text('PROSANE'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () =>
                ref.read(sessionControllerProvider.notifier).cerrar(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bienvenido/a, $nombre',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            PermissionGate(
              // Clave de permiso en camelCase, idéntica a la que emite el backend
              // en /me (listarPacientes, verFichaClinica, crearApto, firmarApto).
              permiso: 'firmarApto',
              fallback: const Text('Sin permisos para firmar aptos.'),
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Firmar apto'),
              ),
            ),
            // El logout vive en el IconButton del AppBar (punto único).
          ],
        ),
      ),
    );
  }
}
