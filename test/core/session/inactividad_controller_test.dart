import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/session/inactividad_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('default 30 minutos y opciones válidas', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(timeoutMinProvider), 30);
    expect(TimeoutController.opciones, [5, 15, 30, 60]);
  });

  test('fijar persiste un valor válido', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(timeoutMinProvider.notifier).fijar(15);
    expect(container.read(timeoutMinProvider), 15);
    expect(
      (await SharedPreferences.getInstance()).getInt('prosane_timeout_min'),
      15,
    );
  });

  test('fijar ignora valores fuera de opciones', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(timeoutMinProvider.notifier).fijar(999);
    expect(container.read(timeoutMinProvider), 30);
  });
}
