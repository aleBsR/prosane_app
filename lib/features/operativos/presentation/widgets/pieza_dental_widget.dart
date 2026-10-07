import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../controllers/evaluacion_odontologica_controller.dart';

class PiezaDentalWidget extends StatelessWidget {
  const PiezaDentalWidget({
    super.key,
    required this.numero,
    required this.pieza,
    required this.onTap,
  });

  final String numero;
  final PiezaOdontograma pieza;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 48,
              height: 58,
              child: CustomPaint(
                painter: _DientePainter(pieza),
              ),
            ),
            Text(numero, style:  TextStyle(fontSize: 11, color: AppColors.texto)),
          ],
        ),
      ),
    );
  }
}

class _DientePainter extends CustomPainter {
  const _DientePainter(this.pieza);

  final PiezaOdontograma pieza;

  @override
  void paint(Canvas canvas, Size size) {
    final border = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final crownRect = Rect.fromLTWH(5, 3, size.width - 10, size.height * .62);
    final crown = RRect.fromRectAndRadius(
      crownRect,
      const Radius.circular(12),
    );
    // Con estado general normal, el fondo es neutro: cada cara define su color.
    final colorBase = pieza.estadoGeneral.isEmpty
        ? Colors.green.shade300
        : _colorPieza();
    canvas.drawRRect(crown, Paint()..color = colorBase);
    if (pieza.estadoGeneral.isEmpty) {
      canvas.save();
      canvas.clipRRect(crown);
      final left = crownRect.left;
      final right = crownRect.right;
      final top = crownRect.top;
      final bottom = crownRect.bottom;
      // Se prioriza el área de oclusal y de las caras laterales.
      const anchoLateral = 10.0;
      const altoFranja = 7.0;
      final centroIzquierdo = left + anchoLateral;
      final centroDerecho = right - anchoLateral;
      final centroSuperior = top + altoFranja;
      final centroInferior = bottom - altoFranja;
      // Cada superficie se pinta de forma independiente.
      canvas.drawRect(Rect.fromLTRB(left, top, right, centroSuperior),
          Paint()..color = _colorCara('vestibular'));
      canvas.drawRect(Rect.fromLTRB(left, centroInferior, right, bottom),
          Paint()..color = _colorCara('lingual'));
      canvas.drawRect(Rect.fromLTRB(left, centroSuperior, centroIzquierdo, centroInferior),
          Paint()..color = _colorCara('mesial'));
      canvas.drawRect(Rect.fromLTRB(centroDerecho, centroSuperior, right, centroInferior),
          Paint()..color = _colorCara('distal'));
      canvas.drawRect(Rect.fromLTRB(centroIzquierdo, centroSuperior,
          centroDerecho, centroInferior),
          Paint()..color = _colorCara('oclusal'));
      canvas.restore();
    }
    canvas.drawRRect(crown, border);

    final centerX = size.width / 2;
    final rootTop = crownRect.bottom + 2;
    final root = Path()
      ..moveTo(centerX - 7, rootTop)
      ..lineTo(centerX - 3, size.height - 3)
      ..lineTo(centerX, size.height * .75)
      ..lineTo(centerX + 3, size.height - 3)
      ..lineTo(centerX + 7, rootTop)
      ..close();
    canvas.drawPath(root, Paint()..color = _colorRaiz());
    canvas.drawPath(root, border);

    final line = Paint()
      ..color = Colors.black26
      ..strokeWidth = 1;
    canvas.drawLine(
        Offset(crownRect.left, crownRect.top + 7),
        Offset(crownRect.right, crownRect.top + 7),
        line);
    canvas.drawLine(
        Offset(crownRect.left, crownRect.bottom - 7),
        Offset(crownRect.right, crownRect.bottom - 7),
        line);
    canvas.drawLine(
        Offset(crownRect.left + 10, crownRect.top + 7),
        Offset(crownRect.left + 10, crownRect.bottom - 7),
        line);
    canvas.drawLine(
        Offset(crownRect.right - 10, crownRect.top + 7),
        Offset(crownRect.right - 10, crownRect.bottom - 7),
        line);
  }

  Color _colorPieza() {
    if ({'ausente', 'perdido', 'extraido'}.contains(pieza.estadoGeneral)) {
      return Colors.grey.shade400;
    }
    if ({'a_extraer', 'fractura_total'}.contains(pieza.estadoGeneral) ||
        pieza.caras.values.any((e) => {'caries', 'fractura', 'a_tratar'}.contains(e)) ||
        pieza.raiz == 'conducto_pendiente') {
      return Colors.red.shade300;
    }
    if (pieza.estadoGeneral.isNotEmpty ||
        pieza.caras.values.any((e) => {'restauracion', 'sellador', 'tratada'}.contains(e)) ||
        pieza.raiz == 'conducto_realizado') {
      return Colors.blue.shade300;
    }
    return Colors.green.shade300;
  }

  Color _colorCara(String cara) {
    final estado = pieza.caras[cara] ?? '';
    if ({'caries', 'fractura', 'a_tratar'}.contains(estado)) {
      return Colors.red.shade300;
    }
    if ({'restauracion', 'sellador', 'tratada'}.contains(estado)) {
      return Colors.blue.shade300;
    }
    return Colors.green.shade300;
  }

  Color _colorRaiz() {
    if (pieza.raiz == 'conducto_pendiente') return Colors.red.shade300;
    if (pieza.raiz == 'conducto_realizado') return Colors.blue.shade300;
    return Colors.white.withValues(alpha: .7);
  }

  @override
  bool shouldRepaint(_DientePainter oldDelegate) => oldDelegate.pieza != pieza;
}
