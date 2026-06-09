import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/sync/sync_scheduler.dart';

void main() {
  test('dispara un ciclo al recuperar conexión', () async {
    var ciclos = 0;
    final online = StreamController<bool>();
    final sch = SyncScheduler(
      onlineStream: online.stream,
      ejecutarCiclo: () async => ciclos++,
      debounce: const Duration(milliseconds: 20),
    )..iniciar();
    online.add(false);
    online.add(true);
    await Future.delayed(const Duration(milliseconds: 80));
    expect(ciclos, 1);
    sch.dispose();
    await online.close();
  });

  test('debounce: dos triggers rápidos generan un solo ciclo', () async {
    var ciclos = 0;
    final online = StreamController<bool>();
    final sch = SyncScheduler(
      onlineStream: online.stream,
      ejecutarCiclo: () async => ciclos++,
      debounce: const Duration(milliseconds: 30),
    )..iniciar();
    online.add(true);
    sch.dispararPorEscritura(); // segundo trigger antes del debounce
    await Future.delayed(const Duration(milliseconds: 80));
    expect(ciclos, 1);
    sch.dispose();
    await online.close();
  });

  test('un evento offline no dispara ciclo', () async {
    var ciclos = 0;
    final online = StreamController<bool>();
    final sch = SyncScheduler(
      onlineStream: online.stream,
      ejecutarCiclo: () async => ciclos++,
      debounce: const Duration(milliseconds: 20),
    )..iniciar();
    online.add(false);
    await Future.delayed(const Duration(milliseconds: 60));
    expect(ciclos, 0);
    sch.dispose();
    await online.close();
  });
}
