import 'package:dartchess/dartchess.dart';

/// Conversión nombre <-> Square usando solo la API de jugadas (Move.parse / uci),
/// que es estable entre versiones de dartchess.
Square casillaDe(String nombre) {
  final m = Move.parse(nombre == 'a1' ? 'b1a1' : 'a1$nombre');
  return (m as NormalMove).to;
}

String nombreDe(Square s) => NormalMove(from: s, to: s).uci.substring(0, 2);
