import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'entities.dart';

class SessionController extends StateNotifier<SesionState> {
  SessionController() : super(SesionNoAutenticada());

  void setSesion(Sesion s) => state = SesionAutenticada(s);
  void cerrar() => state = SesionNoAutenticada();

  bool can(String permiso) => state.can(permiso);
}

final sessionControllerProvider =
    StateNotifierProvider<SessionController, SesionState>(
        (ref) => SessionController());
