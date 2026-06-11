import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/router/app_router.dart';

void main() {
  test('no autenticado: rutas privadas redirigen a /login; login/signup no', () {
    final r = construirRedirect(false);
    expect(r('/inicio'), '/login');
    expect(r('/cualquier-cosa'), '/login');
    expect(r('/login'), isNull);
    expect(r('/signup'), isNull);
  });

  test('autenticado: login/signup redirigen a /inicio; privadas no', () {
    final r = construirRedirect(true);
    expect(r('/login'), '/inicio');
    expect(r('/signup'), '/inicio');
    expect(r('/inicio'), isNull);
    expect(r('/pendientes'), isNull);
    expect(r('/usuario'), isNull);
  });
}
