import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'entities.dart';

class SessionController extends StateNotifier<SesionState> {
  SessionController() : super(SesionNoAutenticada());

  void setSesion(Sesion s) => state = SesionAutenticada(s);
  void cerrar() => state = SesionNoAutenticada();

  bool can(String permiso) => state.can(permiso);

  Future<void> hidratar(Future<Sesion?> Function() leer) async {
    final s = await leer();
    if (s != null) state = SesionAutenticada(s);
  }
}

final sessionControllerProvider =
    StateNotifierProvider<SessionController, SesionState>(
        (ref) => SessionController());
