import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/session/entities.dart';
import 'package:prosane_app/core/session/agrupar_acciones.dart';

Accion _a(String name, String cat, int sort) => Accion(
    name: name, label: name, icon: 'x', color: '#000000', type: 'form',
    category: cat, isSensitive: false, sortOrder: sort);

void main() {
  test('agrupa por category preservando el orden del server y el de aparición de categorías', () {
    final grupos = agruparPorCategoria([
      _a('listarPacientes', 'salud', 10),
      _a('firmarApto', 'salud', 40),
      _a('verConstancias', 'consentimiento', 10),
    ]);
    expect(grupos.map((g) => g.categoria).toList(), ['salud', 'consentimiento']);
    expect(grupos.first.acciones.map((a) => a.name).toList(), ['listarPacientes', 'firmarApto']);
    expect(grupos.last.acciones.map((a) => a.name).toList(), ['verConstancias']);
  });

  test('lista vacía → sin grupos', () {
    expect(agruparPorCategoria(const []), isEmpty);
  });

  test('una categoría que reaparece NO crea un grupo nuevo', () {
    final grupos = agruparPorCategoria([
      _a('a', 'salud', 1), _a('b', 'consentimiento', 1), _a('c', 'salud', 2),
    ]);
    expect(grupos.map((g) => g.categoria).toList(), ['salud', 'consentimiento']);
    expect(grupos.first.acciones.map((a) => a.name).toList(), ['a', 'c']);
  });
}
