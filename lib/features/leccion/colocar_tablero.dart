import 'dart:math';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/sound_service.dart';
import '../../logic/geometria.dart';
import 'marcas_tablero.dart';

class _Orden {
  const _Orden(this.nombre, this.femenino, this.rol, this.columnas);
  final String nombre;
  final bool femenino;
  final String rol; // p n b r q k
  final List<int> columnas; // columnas válidas (0 = a)
}

// Orden de colocación: rey, dama, alfiles, caballos, torres y 8 peones.
const _ordenes = <_Orden>[
  _Orden('Rey', false, 'k', [4]),
  _Orden('Dama', true, 'q', [3]),
  _Orden('Alfil', false, 'b', [2, 5]),
  _Orden('Alfil', false, 'b', [2, 5]),
  _Orden('Caballo', false, 'n', [1, 6]),
  _Orden('Caballo', false, 'n', [1, 6]),
  _Orden('Torre', true, 'r', [0, 7]),
  _Orden('Torre', true, 'r', [0, 7]),
  _Orden('Peón', false, 'p', [0, 1, 2, 3, 4, 5, 6, 7]),
  _Orden('Peón', false, 'p', [0, 1, 2, 3, 4, 5, 6, 7]),
  _Orden('Peón', false, 'p', [0, 1, 2, 3, 4, 5, 6, 7]),
  _Orden('Peón', false, 'p', [0, 1, 2, 3, 4, 5, 6, 7]),
  _Orden('Peón', false, 'p', [0, 1, 2, 3, 4, 5, 6, 7]),
  _Orden('Peón', false, 'p', [0, 1, 2, 3, 4, 5, 6, 7]),
  _Orden('Peón', false, 'p', [0, 1, 2, 3, 4, 5, 6, 7]),
  _Orden('Peón', false, 'p', [0, 1, 2, 3, 4, 5, 6, 7]),
];

/// Simulación: tocar la casilla donde va cada pieza en la posición inicial.
class ColocarTablero extends ConsumerStatefulWidget {
  const ColocarTablero({
    super.key,
    required this.blancas,
    required this.size,
    required this.onCompleto,
    this.fenInicial,
  });
  final bool blancas;
  final double size;
  final String? fenInicial;
  final VoidCallback onCompleto;

  @override
  ConsumerState<ColocarTablero> createState() => _ColocarTableroState();
}

class _ColocarTableroState extends ConsumerState<ColocarTablero> {
  late Tablero _t;
  // Orden aleatorio en cada intento, para aprender las posiciones y no la secuencia.
  final List<_Orden> _orden = List.of(_ordenes)..shuffle(Random());
  int _i = 0;
  String? _error;
  Set<String> _pista = {};

  @override
  void initState() {
    super.initState();
    _t = widget.fenInicial == null ? <String, String>{} : parseTablero(widget.fenInicial!);
  }

  bool get _completo => _i >= _orden.length;
  int get _filaPiezas => widget.blancas ? 0 : 7;
  int get _filaPeones => widget.blancas ? 1 : 6;

  List<String> _validas(_Orden o) {
    final fila = o.rol == 'p' ? _filaPeones : _filaPiezas;
    return [
      for (final c in o.columnas)
        if (!_t.containsKey(nom(c, fila))) nom(c, fila),
    ];
  }

  String _prompt(_Orden o) {
    final color = widget.blancas
        ? (o.femenino ? 'blanca' : 'blanco')
        : (o.femenino ? 'negra' : 'negro');
    return '${o.nombre} $color';
  }

  void _tocar(Offset p) {
    if (_completo) return;
    final n = casillaEnPunto(p, widget.size);
    if (n == null) return;
    final o = _orden[_i];
    final validas = _validas(o);
    final sonido = ref.read(soundProvider);
    if (validas.contains(n)) {
      final ch = widget.blancas ? o.rol.toUpperCase() : o.rol;
      setState(() {
        _t[n] = ch;
        _i++;
        _error = null;
        _pista = {};
      });
      sonido.reproducir(Sonido.mover);
      if (_completo) {
        sonido.reproducir(Sonido.correcto, demora: const Duration(milliseconds: 160));
        widget.onCompleto();
      }
    } else {
      setState(() {
        _error = 'Esa no es la casilla. Mirá las marcadas.';
        _pista = validas.toSet();
      });
      sonido.reproducir(Sonido.incorrecto);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ap = ref.watch(appearanceProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _completo ? '¡Todas las piezas en su lugar!' : 'Tocá la casilla de: ${_prompt(_orden[_i])}',
          style: tt.titleMedium,
        ),
        const SizedBox(height: 8),
        Center(
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              children: [
                StaticChessboard(
                  size: widget.size,
                  fen: fenDe(_t),
                  orientation: Side.white,
                  settings: ap.staticSettings,
                ),
                IgnorePointer(
                  child: CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: PintorMarcas(capturas: _pista),
                  ),
                ),
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (d) => _tocar(d.localPosition),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: _i / _orden.length),
        const SizedBox(height: 6),
        Text('$_i de ${_orden.length} piezas',
            style: tt.bodySmall, textAlign: TextAlign.center),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(_error!,
                textAlign: TextAlign.center, style: TextStyle(color: cs.onErrorContainer)),
          ),
        ],
      ],
    );
  }
}
