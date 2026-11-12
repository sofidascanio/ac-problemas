import 'package:dartchess/dartchess.dart';
import '../data/models/actividad.dart';

Position posicionDesdeFen(String fen) => Chess.fromSetup(Setup.parseFen(fen));

/// UCI "estándar" de una jugada del usuario. dartchess y el tablero representan el
/// enroque como "rey captura su torre" (e1h1); las soluciones lo escriben como rey
/// de dos casillas (e1g1). Esta función los unifica para poder compararlos.
String uciEstandar(Position pos, Move move) {
  final uci = move.uci;
  if (move is! NormalMove) return uci;
  final m = move;
  final pieza = pos.board.pieceAt(m.from);
  final destino = pos.board.pieceAt(m.to);
  if (pieza != null &&
      pieza.role == Role.king &&
      destino != null &&
      destino.role == Role.rook &&
      destino.color == pieza.color) {
    final desde = uci.substring(0, 2);
    final archivoDesde = uci.codeUnitAt(0);
    final archivoHasta = uci.codeUnitAt(2);
    final columna = archivoHasta > archivoDesde ? 'g' : 'c';
    return '$desde$columna${uci[1]}';
  }
  return uci;
}

// ---------------------------------------------------------------- Secuencia

enum ResultadoPaso { correcto, incorrecto, completada }

/// Valida paso a paso una [SecuenciaExacta]. Las jugadas pares (0,2,..) son
/// del usuario; las impares son respuestas automáticas del oponente.
class SecuenciaValidator {
  SecuenciaValidator(this.actividad);
  final SecuenciaExacta actividad;
  int _paso = 0;

  bool get terminada => _paso >= actividad.solucionUci.length;

  ResultadoPaso validar(String uciUsuario) {
    if (terminada) return ResultadoPaso.completada;
    if (uciUsuario != actividad.solucionUci[_paso]) return ResultadoPaso.incorrecto;
    _paso++;
    return terminada ? ResultadoPaso.completada : ResultadoPaso.correcto;
  }

  /// Devuelve la respuesta del oponente (UCI) y avanza, o null si no hay.
  String? respuestaOponente() {
    if (terminada) return null;
    return actividad.solucionUci[_paso++];
  }
}

// ---------------------------------------------------------------- Propiedad

class PropiedadValidator {
  PropiedadValidator(this.actividad) : _pos = posicionDesdeFen(actividad.fen);
  final JugadaConPropiedad actividad;
  final Position _pos;

  Position get posicion => _pos;

  /// Todas las jugadas legales que cumplen la propiedad.
  List<Move> jugadasValidas() {
    final res = <Move>[];
    for (final e in _pos.legalMoves.entries) {
      for (final to in e.value.squares) {
        final base = NormalMove(from: e.key, to: to);
        final m = _esPromocion(base)
            ? NormalMove(from: e.key, to: to, promotion: Role.queen)
            : base;
        if (cumple(m)) res.add(m);
      }
    }
    return res;
  }

  bool _esPromocion(NormalMove m) =>
      _pos.board.roleAt(m.from) == Role.pawn &&
      (m.to.rank == Rank.first || m.to.rank == Rank.eighth);

  /// ¿La jugada del usuario cumple la propiedad pedida?
  bool cumple(Move move) {
    if (move is! NormalMove) return false;
    final m = _pos.normalizeMove(move);
    if (m is! NormalMove) return false;
    if (!_pos.isLegal(m)) return false;
    final (nueva, san) = _pos.makeSan(m);
    switch (actividad.propiedad) {
      case PropiedadJugada.daJaque:
        return nueva.isCheck;
      case PropiedadJugada.esMate:
        return nueva.isCheckmate;
      case PropiedadJugada.esCaptura:
        return san.contains('x');
      case PropiedadJugada.esEnroque:
        return san.startsWith('O-O');
      case PropiedadJugada.esAlPaso:
        return san.contains('x') && _pos.board.pieceAt(m.to) == null;
      case PropiedadJugada.cualquierLegal:
        return true;
      case PropiedadJugada.dejaPiezaDefendida:
        // Interpretación: la pieza movida queda defendida por otra pieza propia.
        // TODO: ampliar a "ninguna pieza propia queda sin defender" si el diseño lo pide.
        return nueva.board.attacksTo(m.to, _pos.turn).isNotEmpty;
    }
  }
}

// ---------------------------------------------------------------- Trivia

class TriviaValidator {
  TriviaValidator(this.actividad);
  final Trivia actividad;
  bool validar(int opcion) => opcion == actividad.respuestaCorrecta;
}
