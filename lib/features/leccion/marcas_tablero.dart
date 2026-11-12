import 'package:flutter/material.dart';
import '../../logic/geometria.dart';

const Color kDorado = Color(0xFFF2B01E);

/// Rojo de las casillas nombradas en los textos (se ve bien en tema claro y oscuro).
const Color kRojoMarca = Color(0xFFE5484D);

/// Colores para distinguir las casillas nombradas en un texto (en orden de aparición).
const List<Color> kPaletaMarcas = [
  kRojoMarca,
  Color(0xFF2F80ED), // azul
  Color(0xFF2EB67D), // verde
  Color(0xFFF2994A), // naranja
];

/// Capa transparente sobre el tablero (blancas abajo) con las ayudas visuales:
/// puntos (casillas libres), anillos (capturas), estrellas (objetivos) y anillos dorados.
class PintorMarcas extends CustomPainter {
  PintorMarcas({
    this.puntos = const {},
    this.capturas = const {},
    this.estrellas = const {},
    this.dorados = const {},
    this.marcas = const {},
  });

  final Set<String> puntos;
  final Set<String> capturas;
  final Set<String> estrellas;
  final Set<String> dorados;
  final Map<String, Color> marcas; // casillas nombradas en el texto: puntito de su color

  Offset _centro(String n, double c) {
    final (f, r) = coord(n);
    return Offset((f + 0.5) * c, (7 - r + 0.5) * c);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.width / 8;
    final sombra = Paint()..color = Colors.black.withValues(alpha: 0.30);
    final anillo = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = c * 0.09
      ..color = Colors.black.withValues(alpha: 0.30);
    final anilloDorado = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = c * 0.10
      ..color = kDorado;

    marcas.forEach((n, color) {
      canvas.drawCircle(_centro(n, c), c * 0.17, Paint()..color = color);
    });
    for (final n in puntos) {
      canvas.drawCircle(_centro(n, c), c * 0.16, sombra);
    }
    for (final n in capturas) {
      canvas.drawCircle(_centro(n, c), c * 0.44, anillo);
    }
    for (final n in dorados) {
      canvas.drawCircle(_centro(n, c), c * 0.44, anilloDorado);
    }
    for (final n in estrellas) {
      final tp = TextPainter(
        text: TextSpan(text: '★', style: TextStyle(fontSize: c * 0.7, color: kDorado, height: 1)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, _centro(n, c) - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(PintorMarcas old) => true;
}

/// Nombre de la casilla tocada en un tablero cuadrado de [lado] px (blancas abajo).
String? casillaEnPunto(Offset p, double lado) {
  if (p.dx < 0 || p.dy < 0 || p.dx >= lado || p.dy >= lado) return null;
  final f = (p.dx / (lado / 8)).floor();
  final r = 7 - (p.dy / (lado / 8)).floor();
  return nom(f, r);
}
