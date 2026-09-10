import 'escuelas_repository.dart';

/// Normaliza el grado igual que el backend (`normalizar_grado`):
/// quita espacios, unifica º/ª a ° y un número solo ('1') equivale a '1°'.
String normalizarGrado(String valor) {
  final v = valor.trim().replaceAll('º', '°').replaceAll('ª', '°');
  if (RegExp(r'^\d{1,2}$').hasMatch(v)) return '$v°';
  return v;
}

/// Normaliza la división igual que el backend: sin espacios y en mayúsculas.
String normalizarDivision(String valor) => valor.trim().toUpperCase();

/// Autocompletado del campo grado: si el usuario escribió solo el número
/// ('1'), devuelve '1°'. Si ya tiene símbolo o es texto (ej. 'Plurigrado'),
/// lo deja igual. Retorna null si no hay nada que completar.
String? autocompletarGrado(String actual) {
  final v = actual.trim();
  if (RegExp(r'^\d{1,2}$').hasMatch(v)) return '$v°';
  return null;
}

/// El Ciclo vacío es comodín: coincide con cualquier año.
bool _mismoCiclo(int? a, int? b) {
  if (a == null || b == null) return true;
  return a == b;
}

/// Dice si [grado]/[division]/[ciclo] duplica a alguno de [existentes`
/// (comparación normalizada; [excluirId] se ignora, útil al editar).
bool esCursoDuplicado({
  required List<Curso> existentes,
  required String grado,
  required String division,
  required int? cicloLectivo,
  String? excluirId,
}) {
  final g = normalizarGrado(grado).toUpperCase();
  final d = normalizarDivision(division);
  for (final c in existentes) {
    if (excluirId != null && c.id == excluirId) continue;
    if (normalizarGrado(c.salaGradoAnio).toUpperCase() == g &&
        normalizarDivision(c.division) == d &&
        _mismoCiclo(c.cicloLectivo, cicloLectivo)) {
      return true;
    }
  }
  return false;
}

const mensajeCursoDuplicado =
    'Ese curso ya existe en esta escuela (mismo grado, división y ciclo lectivo).';

/// Convierte un error técnico (ej. 'Exception: ...' o mensaje del servidor)
/// en un texto amigable para mostrar en el cartelito del diálogo.
String mensajeAmigableCurso(Object e) {
  final crudo = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
  if (crudo.contains('Ya existe un curso')) return mensajeCursoDuplicado;
  if (RegExp(r'400').hasMatch(crudo) && crudo.toLowerCase().contains('curso')) {
    return mensajeCursoDuplicado;
  }
  return crudo;
}
