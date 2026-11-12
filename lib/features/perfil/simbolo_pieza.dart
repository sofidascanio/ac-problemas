import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../leccion/pieza_contorno.dart';

/// Códigos de símbolo: color (w/b) + pieza (P N B R Q K).
const List<String> kSimbolos = [
  'wP', 'wN', 'wB', 'wR', 'wQ', 'wK',
  'bP', 'bN', 'bB', 'bR', 'bQ', 'bK',
];

/// PieceSet por nombre (null si está vacío o no existe).
PieceSet? setDelPerfil(String nombre) {
  for (final s in PieceSet.values) {
    if (s.name == nombre) return s;
  }
  return null;
}

Piece? _pieza(String codigo) => switch (codigo) {
      'wP' => Piece.whitePawn,
      'wN' => Piece.whiteKnight,
      'wB' => Piece.whiteBishop,
      'wR' => Piece.whiteRook,
      'wQ' => Piece.whiteQueen,
      'wK' => Piece.whiteKing,
      'bP' => Piece.blackPawn,
      'bN' => Piece.blackKnight,
      'bB' => Piece.blackBishop,
      'bR' => Piece.blackRook,
      'bQ' => Piece.blackQueen,
      'bK' => Piece.blackKing,
      _ => null,
    };

/// Una pieza del tablero. Se dibuja con [set] o, si no se indica, con el set de
/// piezas elegido en Apariencia.
class SimboloPieza extends ConsumerWidget {
  const SimboloPieza({super.key, required this.codigo, this.set, this.size = 28});
  final String codigo;
  final PieceSet? set;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final global = ref.watch(appearanceProvider.select((a) => a.pieceSet));
    final pieza = _pieza(codigo) ?? Piece.whiteKnight;
    final imagen = (set ?? global).assets[pieza.kind];
    if (imagen == null) return SizedBox(width: size, height: size);
    return PiezaContorno(imagen: imagen, size: size, negra: codigo.startsWith('b'));
  }
}
