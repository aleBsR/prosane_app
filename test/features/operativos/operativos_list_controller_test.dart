import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:prosane_app/core/providers.dart';
import 'package:prosane_app/core/session/entities.dart';
import 'package:prosane_app/core/session/session_controller.dart';
import 'package:prosane_app/features/operativos/data/operativos_repository.dart';
import 'package:prosane_app/features/operativos/presentation/controllers/operativos_list_controller.dart';

class _MockRepo extends Mock implements OperativosRepository {}

SesionAutenticada _sesion(String rol) => SesionAutenticada(
      Sesion(
        usuario: Usuario(
            id: 'u-$rol', nombre: rol, rolName: rol, rolLabel: rol),
        acciones: const [],
      ),
    );

void main() {
  test('cambiar de usuario refetchea la lista (no queda caché ajena)', () async {
    final repo = _MockRepo();
    final session = SessionController()..state = _sesion('superadmin');
    var llamadas = 0;
    when(() => repo.listar()).thenAnswer((_) async {
      llamadas++;
      // 1° llamada (superadmin): 5; siguientes (escuela): 1.
      return List.generate(llamadas == 1 ? 5 : 1, (i) => {'id': 'op$i'});
    });

    final container = ProviderContainer(
      overrides: [
        operativosRepositoryProvider.overrideWithValue(repo),
        sessionControllerProvider.overrideWith((ref) => session),
      ],
    );
    addTearDown(container.dispose);

    final primera = await container.read(operativosListControllerProvider.future);
    expect(primera.length, 5);

    // Cambio de usuario: superadmin -> escuela.
    session.state = _sesion('escuela');
    final segunda = await container.read(operativosListControllerProvider.future);
    expect(segunda.length, 1);
    verify(() => repo.listar()).called(2);
  });
}
