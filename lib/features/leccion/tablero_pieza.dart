import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/sound_service.dart';
import '../../logic/casillas.dart';
import '../../logic/geometria.dart';
import 'marcas_tablero.dart';

/// Tablero para aprender cómo se mueve una pieza.
/// - [mostrarDestinos]: marca siempre a dónde puede ir (modo "explorar").
/// - [objetivos]: estrellas a alcanzar (o piezas a capturar); al juntarlas todas
///   llama a [onCompleto].
/// - [marcas]: casillas nombradas en el texto que no tienen pieza (punto de color).
/// - [onCaptura] / [onReinicio]: avisos para mostrar carteles en el paso.
class TableroPieza extends ConsumerStatefulWidget {
  const TableroPieza({
    super.key,
    required this.fen,
    required this.pieza,
    required this.size,
    this.objetivos = const [],
    this.mostrarDestinos = true,
    this.marcas = const {},
    this.onCompleto,
    this.onCaptura,
    this.onReinicio,
  });

  final String fen;
  final String pieza; // casilla inicial de la pieza protagonista
  final double size;
  final List<String> objetivos;
  final bool mostrarDestinos;
  final Map<String, Color> marcas;
  final VoidCallback? onCompleto;
  final VoidCallback? onCaptura;
  final VoidCallback? onReinicio;

  @override
  ConsumerState<TableroPieza> createState() => _TableroPiezaState();
}

class _TableroPiezaState extends ConsumerState<TableroPieza> {
  late Tablero _t;
  late String _casilla;
  late Set<String> _pendientes;
  late ChessboardController _controller;
  final List<ChessboardController> _descartados = [];
  bool _completo = false;
  bool _eligiendoCoronacion = false; // el tablero está mostrando las piezas para coronar
  int _reinicios = 0;

  @override
  void initState() {
    super.initState();
    _cargar();
    _controller = ChessboardController(game: _game());
  }

  @override
  void dispose() {
    _controller.dispose();
    for (final c in _descartados) {
      c.dispose();
    }
    super.dispose();
  }

  void _cargar() {
    _t = parseTablero(widget.fen);
    _casilla = widget.pieza;
    _pendientes = widget.objetivos.toSet();
    _completo = false;
  }

  bool get _blanca => esBlanca(_t[_casilla] ?? 'P');

  GameData _game() {
    final dest = destinos(_t, _casilla);
    return GameData(
      fen: fenDe(_t),
      playerSide: _completo
          ? PlayerSide.none
          : (_blanca ? PlayerSide.white : PlayerSide.black),
      sideToMove: _blanca ? Side.white : Side.black,
      validMoves: {
        casillaDe(_casilla): {for (final d in dest) casillaDe(d)},
      },
    );
  }

  void _onMove(Move move, {bool? viaDragAndDrop}) {
    if (move is! NormalMove) return;
    final uci = move.uci;
    final desde = uci.substring(0, 2);
    final hasta = uci.substring(2, 4);
    if (desde != _casilla || !destinos(_t, _casilla).contains(hasta)) return;

    final captura = _t.containsKey(hasta);
    var pieza = _t.remove(desde)!;
    if (uci.length > 4) {
      // coronación: el tablero ya preguntó en qué pieza se convierte
      pieza = esBlanca(pieza) ? uci[4].toUpperCase() : uci[4].toLowerCase();
    }
    _t[hasta] = pieza; // si había una pieza rival, queda capturada
    _casilla = hasta;
    _eligiendoCoronacion = false;
    final sonido = ref.read(soundProvider);
    sonido.reproducir(captura ? Sonido.capturar : Sonido.mover);

    var termino = false;
    if (_pendientes.remove(hasta) && _pendientes.isEmpty && widget.objetivos.isNotEmpty) {
      _completo = true;
      termino = true;
    }
    setState(() {});
    _controller.updatePosition(_game());
    if (captura) widget.onCaptura?.call();
    if (termino) {
      sonido.reproducir(Sonido.correcto, demora: const Duration(milliseconds: 160));
      widget.onCompleto?.call();
    }
  }

  void _reiniciar() {
    // Tablero y controlador nuevos: reutilizar el mismo controlador con un tablero
    // remontado dejaba la pantalla en gris al volver a mover.
    _descartados.add(_controller);
    setState(() {
      _eligiendoCoronacion = false;
      _cargar();
      _reinicios++;
      _controller = ChessboardController(game: _game());
    });
    widget.onReinicio?.call();
  }

  /// Cuando un peón llega a la última fila, el tablero abre su selector de piezas encima
  /// de esa casilla: se ocultan las estrellas y puntos para que no tapen las opciones.
  void _alSoltar(PointerUpEvent e) {
    final n = casillaEnPunto(e.localPosition, widget.size);
    if (n == null) return;
    final pieza = _t[_casilla];
    final corona = pieza != null &&
        pieza.toLowerCase() == 'p' &&
        (n.endsWith('8') || n.endsWith('1')) &&
        destinos(_t, _casilla).contains(n);
    if (corona != _eligiendoCoronacion) setState(() => _eligiendoCoronacion = corona);
  }

  @override
  Widget build(BuildContext context) {
    final ap = ref.watch(appearanceProvider);

    final ocultar = _eligiendoCoronacion;
    final dest = (widget.mostrarDestinos && !_completo && !ocultar)
        ? destinos(_t, _casilla)
        : <String>{};
    final puntos = {for (final d in dest) if (!_t.containsKey(d)) d};
    final capturas = {for (final d in dest) if (_t.containsKey(d)) d};
    final estrellas = ocultar ? <String>{} : {for (final o in _pendientes) if (!_t.containsKey(o)) o};
    final dorados = ocultar ? <String>{} : {for (final o in _pendientes) if (_t.containsKey(o)) o};
    // las marcas de color se borran cuando una pieza ocupa la casilla
    final marcas = {
      for (final e in widget.marcas.entries)
        if (!_t.containsKey(e.key)) e.key: e.value,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerUp: _alSoltar,
            child: Stack(
            children: [
              Chessboard(
                key: ValueKey(_reinicios),
                controller: _controller,
                size: widget.size,
                orientation: Side.white,
                settings: ap.boardSettings,
                onMove: _onMove,
              ),
              IgnorePointer(
                child: CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: PintorMarcas(
                    puntos: puntos,
                    capturas: capturas,
                    estrellas: estrellas,
                    dorados: dorados,
                    marcas: marcas,
                  ),
                ),
              ),
            ],
          ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _reiniciar,
            icon: const Icon(Icons.restart_alt, size: 18),
            label: const Text('Reiniciar'),
          ),
        ),
      ],
    );
  }
}
