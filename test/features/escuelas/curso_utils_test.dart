import 'package:flutter_test/flutter_test.dart';
import 'package:prosane_app/features/escuelas/data/curso_utils.dart';
import 'package:prosane_app/features/escuelas/data/escuelas_repository.dart';

Curso _curso(String grado, String division, int? ciclo, [String id = 'x']) {
  return Curso(
    id: id,
    escuela: 'e1',
    salaGradoAnio: grado,
    division: division,
    cicloLectivo: ciclo,
  );
}

void main() {
  group('normalizarGrado', () {
    test('número solo se completa con °', () {
      expect(normalizarGrado('1'), '1°');
      expect(normalizarGrado('12'), '12°');
      expect(normalizarGrado(' 2 '), '2°');
    });

    test('unifica º y ª a °', () {
      expect(normalizarGrado('1º'), '1°');
      expect(normalizarGrado('1ª'), '1°');
      expect(normalizarGrado('1°'), '1°');
    });

    test('no toca texto como Plurigrado', () {
      expect(normalizarGrado('Plurigrado'), 'Plurigrado');
    });
  });

  group('autocompletarGrado', () {
    test('sugiere ° para número solo', () {
      expect(autocompletarGrado('1'), '1°');
    });

    test('no sugiere si ya tiene símbolo o es texto', () {
      expect(autocompletarGrado('1°'), isNull);
      expect(autocompletarGrado('Plurigrado'), isNull);
      expect(autocompletarGrado(''), isNull);
    });
  });

  group('esCursoDuplicado', () {
    final existentes = [_curso('1°', 'A', 2026, 'c1')];

    test('detecta 1 como duplicado de 1°', () {
      expect(
        esCursoDuplicado(
          existentes: existentes,
          grado: '1',
          division: 'A',
          cicloLectivo: 2026,
        ),
        isTrue,
      );
    });

    test('detecta variante en minúscula y con º', () {
      expect(
        esCursoDuplicado(
          existentes: existentes,
          grado: '1º',
          division: 'a',
          cicloLectivo: 2026,
        ),
        isTrue,
      );
    });

    test('distinto ciclo o división no es duplicado', () {
      expect(
        esCursoDuplicado(
          existentes: existentes,
          grado: '1°',
          division: 'B',
          cicloLectivo: 2026,
        ),
        isFalse,
      );
      expect(
        esCursoDuplicado(
          existentes: existentes,
          grado: '1°',
          division: 'A',
          cicloLectivo: 2027,
        ),
        isFalse,
      );
    });

    test('excluirId ignora el propio curso al editar', () {
      expect(
        esCursoDuplicado(
          existentes: existentes,
          grado: '1°',
          division: 'A',
          cicloLectivo: 2026,
          excluirId: 'c1',
        ),
        isFalse,
      );
    });

    test('ciclo vacío es comodín en ambas direcciones', () {
      expect(
        esCursoDuplicado(
          existentes: existentes,
          grado: '1°',
          division: 'A',
          cicloLectivo: null,
        ),
        isTrue,
      );
      expect(
        esCursoDuplicado(
          existentes: [_curso('1°', 'A', null)],
          grado: '1°',
          division: 'A',
          cicloLectivo: 2026,
        ),
        isTrue,
      );
    });
  });

  group('mensajeAmigableCurso', () {
    test('traduce el error de duplicado del backend', () {
      expect(
        mensajeAmigableCurso(
          'Exception: Ya existe un curso con ese grado, división y ciclo lectivo.',
        ),
        mensajeCursoDuplicado,
      );
    });

    test('deja pasar otros errores', () {
      expect(
        mensajeAmigableCurso('Exception: Error de red'),
        contains('Error de red'),
      );
    });
  });
}
