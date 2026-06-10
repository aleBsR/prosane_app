import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/core/design_system/accion_presentacion.dart';

void main() {
  test('accionIcon mapea los nombres conocidos del backend', () {
    expect(accionIcon('people'), Icons.people_outline);
    expect(accionIcon('clinical_notes'), Icons.medical_information_outlined);
    expect(accionIcon('assignment_add'), Icons.note_add_outlined);
    expect(accionIcon('draw'), Icons.draw_outlined);
    expect(accionIcon('dentistry'), Icons.medical_services_outlined);
    expect(accionIcon('straighten'), Icons.straighten_outlined);
    expect(accionIcon('description'), Icons.description_outlined);
    expect(accionIcon('how_to_reg'), Icons.how_to_reg_outlined);
  });

  test('accionIcon: un icon DESCONOCIDO cae al fallback (no rompe)', () {
    expect(accionIcon('icono_que_no_existe_aun'), kIconFallback);
    expect(accionIcon(''), kIconFallback);
  });

  test('colorDesdeHex parsea #RRGGBB', () {
    expect(colorDesdeHex('#1565C0'), const Color(0xFF1565C0));
  });

  test('colorDesdeHex parsea #AARRGGBB', () {
    expect(colorDesdeHex('#801565C0'), const Color(0x801565C0));
  });

  test('colorDesdeHex: hex inválido cae al fallback', () {
    expect(colorDesdeHex('no-es-hex'), kColorFallback);
    expect(colorDesdeHex(''), kColorFallback);
  });
}
