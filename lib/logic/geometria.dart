/// Movimiento de piezas "sueltas" para las lecciones (sin reyes obligatorios).
/// Es independiente de dartchess a propósito: una pieza sola en el tablero no es
/// una posición de ajedrez válida. Réplica en Python: herramientas/geometria.py.
typedef Tablero = Map<String, String>; // "e4" -> "N" (mayúscula = blancas)

const _caballo = [(1, 2), (2, 1), (2, -1), (1, -2), (-1, -2), (-2, -1), (-2, 1), (-1, 2)];
const _rey = [(1, 0), (1, 1), (0, 1), (-1, 1), (-1, 0), (-1, -1), (0, -1), (1, -1)];
const _diag = [(1, 1), (1, -1), (-1, 1), (-1, -1)];
const _recta = [(1, 0), (-1, 0), (0, 1), (0, -1)];

String nom(int f, int r) => '${String.fromCharCode(97 + f)}${r + 1}';
(int, int) coord(String n) => (n.codeUnitAt(0) - 97, int.parse(n[1]) - 1);
bool dentro(int f, int r) => f >= 0 && f < 8 && r >= 0 && r < 8;
bool esBlanca(String p) => p == p.toUpperCase();

/// Lee solo la parte de piezas del FEN.
Tablero parseTablero(String fen) {
  final t = <String, String>{};
  final filas = fen.split(' ').first.split('/');
  for (var i = 0; i < filas.length && i < 8; i++) {
    final r = 7 - i;
    var f = 0;
    for (final ch in filas[i].split('')) {
      final n = int.tryParse(ch);
      if (n != null) {
        f += n;
      } else if (f < 8) {
        t[nom(f, r)] = ch;
        f++;
      }
    }
  }
  return t;
}

String fenDe(Tablero t) {
  final filas = <String>[];
  for (var r = 7; r >= 0; r--) {
    final sb = StringBuffer();
    var vacias = 0;
    for (var f = 0; f < 8; f++) {
      final p = t[nom(f, r)];
      if (p == null) {
        vacias++;
      } else {
        if (vacias > 0) {
          sb.write(vacias);
          vacias = 0;
        }
        sb.write(p);
      }
    }
    if (vacias > 0) sb.write(vacias);
    filas.add(sb.toString());
  }
  return '${filas.join('/')} w - - 0 1';
}

Set<String> _ataques(Tablero t, String n, String p) {
  final (f, r) = coord(n);
  final res = <String>{};
  void salta(List<(int, int)> ds) {
    for (final (df, dr) in ds) {
      if (dentro(f + df, r + dr)) res.add(nom(f + df, r + dr));
    }
  }

  void desliza(List<(int, int)> ds) {
    for (final (df, dr) in ds) {
      var nf = f + df, nr = r + dr;
      while (dentro(nf, nr)) {
        final c = nom(nf, nr);
        res.add(c);
        if (t.containsKey(c)) break;
        nf += df;
        nr += dr;
      }
    }
  }

  switch (p.toLowerCase()) {
    case 'n':
      salta(_caballo);
    case 'k':
      salta(_rey);
    case 'b':
      desliza(_diag);
    case 'r':
      desliza(_recta);
    case 'q':
      desliza([..._diag, ..._recta]);
    case 'p':
      final d = esBlanca(p) ? 1 : -1;
      for (final df in [-1, 1]) {
        if (dentro(f + df, r + d)) res.add(nom(f + df, r + d));
      }
  }
  return res;
}

/// Casillas atacadas por las piezas de un bando. [sin] saca una pieza del
/// tablero antes de calcular (el rey no "tapa" la línea de una torre que lo ataca).
Set<String> atacadasPor(Tablero t, bool blancas, {String? sin}) {
  final o = Map<String, String>.of(t);
  if (sin != null) o.remove(sin);
  final res = <String>{};
  o.forEach((n, p) {
    if (esBlanca(p) == blancas) res.addAll(_ataques(o, n, p));
  });
  return res;
}

/// Casillas a las que puede ir la pieza de [casilla]. El rey evita casillas atacadas.
/// El peón puede llegar a la última fila: ahí se corona (lo resuelve el tablero).
Set<String> destinos(Tablero t, String casilla) {
  final p = t[casilla];
  if (p == null) return {};
  final blanca = esBlanca(p);
  final (f, r) = coord(casilla);
  final res = <String>{};

  if (p.toLowerCase() == 'p') {
    final d = blanca ? 1 : -1;
    final inicio = blanca ? 1 : 6;
    final r1 = r + d;
    if (r1 >= 0 && r1 < 8) {
      if (!t.containsKey(nom(f, r1))) {
        res.add(nom(f, r1));
        final r2 = r + 2 * d;
        if (r == inicio && !t.containsKey(nom(f, r2))) res.add(nom(f, r2));
      }
      for (final df in [-1, 1]) {
        if (dentro(f + df, r1)) {
          final c = nom(f + df, r1);
          final otra = t[c];
          if (otra != null && esBlanca(otra) != blanca) res.add(c);
        }
      }
    }
    return res;
  }

  for (final a in _ataques(t, casilla, p)) {
    final otra = t[a];
    if (otra == null || esBlanca(otra) != blanca) res.add(a);
  }
  if (p.toLowerCase() == 'k') {
    res.removeAll(atacadasPor(t, !blanca, sin: casilla));
  }
  return res;
}
