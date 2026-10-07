import 'package:flutter/material.dart';

/// Leyenda de protección de datos (Leyes N° 25.326 y N° 26.529), espejo del
/// footer legal de la web.
Future<void> mostrarProteccionDatosDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      title: const Text('Protección de datos personales'),
      content: const SingleChildScrollView(
        child: Text(
          'La información aquí contenida constituye dato personal sensible de '
          'salud, amparado por la Ley N° 25.326 de Protección de los Datos '
          'Personales y por la Ley N° 26.529 de Derechos del Paciente, Historia '
          'Clínica y Consentimiento Informado (y sus modificatorias). Su '
          'tratamiento, comunicación y conservación deben ajustarse a dichas '
          'normas; el acceso y la impresión de documentos quedan registrados '
          'y auditados.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx),
          child: const Text('Cerrar'),
        ),
      ],
    ),
  );
}
