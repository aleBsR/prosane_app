import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/sync/connectivity_service.dart';

void main() {
  test('none -> offline; wifi -> online; lista vacía -> offline', () async {
    final svc = ConnectivityService.fromStream(Stream.fromIterable([
      [ConnectivityResult.none],
      [ConnectivityResult.wifi],
      <ConnectivityResult>[],
    ]));
    expect(await svc.onlineStream.toList(), [false, true, false]);
  });

  test('mobile -> online', () async {
    final svc = ConnectivityService.fromStream(Stream.fromIterable([
      [ConnectivityResult.mobile],
    ]));
    expect(await svc.onlineStream.first, true);
  });
}
