import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import '../leccion/pieza_contorno.dart';

/// Miniatura de un set de piezas: caballo blanco y negro.
class PiezaPreview extends StatelessWidget {
  const PiezaPreview({super.key, required this.set});
  final PieceSet set;

  @override
  Widget build(BuildContext context) {
    final blanca = set.assets[Piece.whiteKnight.kind];
    final negra = set.assets[Piece.blackKnight.kind];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (blanca != null) Image(image: blanca, width: 28, height: 28),
        if (negra != null) PiezaContorno(imagen: negra, size: 28, negra: true),
      ],
    );
  }
}

/// Casilla seleccionable con borde de acento cuando está activa.
class OpcionVisual extends StatelessWidget {
  const OpcionVisual({
    required this.etiqueta,
    required this.seleccionada,
    required this.onTap,
    required this.child,
  });

  static const double lado = 64;

  final String etiqueta; // solo para accesibilidad y tooltip
  final bool seleccionada;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Semantics(
      button: true,
      selected: seleccionada,
      label: etiqueta,
      child: Tooltip(
        message: etiqueta,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: seleccionada ? color : Colors.transparent,
                width: 3,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: SizedBox(width: lado, height: lado, child: child),
            ),
          ),
        ),
      ),
    );
  }
}
