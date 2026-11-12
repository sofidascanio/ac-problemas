import 'dart:async';
import 'dart:math' as math;
import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/sound_service.dart';
import '../../data/models/actividad.dart';
import '../../logic/casillas.dart';
import '../../logic/validators.dart';
import '../../theme/app_theme.dart';
import '../leccion/marcas_tablero.dart';

/// Tamaño del tablero: cabe en el ancho y deja [reservado] px de alto para
/// título, feedback y botones (todo queda pegado al tablero, arriba y abajo).
double _tamanoTablero(BoxConstraints c, double reservado) =>
    math.min(c.maxWidth, math.max(200.0, c.maxHeight - reservado));

/// Renderiza la actividad según su variante (switch exhaustivo sobre el sealed).
class ActividadView extends StatelessWidget {
  const ActividadView({
    super.key,
    required this.actividad,
    required this.categoriaId,
    this.titulo,
    this.yaResuelto = false,
    this.comentario,
    this.exito,
    this.extraAlto = 0,
    this.tituloWidget,
    this.comentarioWidget,
    this.exitoWidget,
    this.marcas = const {},
    this.registrarIntentos = false,
    this.onAnterior,
    this.onProximo,
    this.onSiguiente,
    this.onTocarTablero,
  });
  final Actividad actividad;
  final String categoriaId;

  /// Registra cuántos intentos (jugadas) hicieron falta para resolver el problema.
  final bool registrarIntentos;

  /// Flechas de abajo para pasar al problema anterior / siguiente (null = sin flecha).
  final VoidCallback? onAnterior;
  final VoidCallback? onProximo;

  /// Versiones con formato (piezas junto a las coordenadas) de título, comentario y
  /// explicación al resolver. Si están, reemplazan a los textos planos.
  final Widget? tituloWidget;
  final Widget? comentarioWidget;
  final Widget? exitoWidget;

  /// Casillas a marcar con un punto de color sobre el tablero (las nombradas en el texto).
  final Map<String, Color> marcas;

  /// Texto explicativo siempre visible bajo el tablero (lecciones).
  final String? comentario;

  /// Texto que aparece al resolver la actividad (lecciones).
  final String? exito;

  /// Alto extra a reservar para esos textos (el tablero se achica en consecuencia).
  final double extraAlto;

  /// Texto sobre el tablero (nombre del problema). Si es null se usa la consigna.
  final String? titulo;

  /// El ejercicio ya estaba resuelto al abrirlo: habilita "Mostrar solución".
  final bool yaResuelto;
  final VoidCallback? onSiguiente;

  /// Avisa cuando el dedo toca / suelta el tablero (para desactivar el
  /// deslizamiento entre ejercicios mientras se arrastra una pieza).
  final ValueChanged<bool>? onTocarTablero;

  @override
  Widget build(BuildContext context) {
    // Un FEN que dartchess rechaza (posición imposible) no debe romper la pantalla.
    try {
      posicionDesdeFen(actividad.fen);
    } catch (_) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Este problema tiene una posición inválida.'),
            if (onSiguiente != null) ...[
              const SizedBox(height: 12),
              FilledButton(onPressed: onSiguiente, child: const Text('Siguiente')),
            ],
          ],
        ),
      );
    }
    return _vista();
  }

  Widget _vista() => switch (actividad) {
        Trivia t => _TriviaView(
            actividad: t,
            categoriaId: categoriaId,
            titulo: titulo,
            yaResuelto: yaResuelto,
            comentario: comentario,
            exito: exito,
            extraAlto: extraAlto,
            tituloWidget: tituloWidget,
            comentarioWidget: comentarioWidget,
            exitoWidget: exitoWidget,
            marcas: marcas,
            onAnterior: onAnterior,
            onProximo: onProximo,
            onSiguiente: onSiguiente),
        SecuenciaExacta s => _JugadaView(
            registrarIntentos: registrarIntentos,
            actividad: s,
            categoriaId: categoriaId,
            titulo: titulo,
            yaResuelto: yaResuelto,
            comentario: comentario,
            exito: exito,
            extraAlto: extraAlto,
            tituloWidget: tituloWidget,
            comentarioWidget: comentarioWidget,
            exitoWidget: exitoWidget,
            marcas: marcas,
            onAnterior: onAnterior,
            onProximo: onProximo,
            onSiguiente: onSiguiente,
            onTocarTablero: onTocarTablero),
        JugadaConPropiedad p => _JugadaView(
            registrarIntentos: registrarIntentos,
            actividad: p,
            categoriaId: categoriaId,
            titulo: titulo,
            yaResuelto: yaResuelto,
            comentario: comentario,
            exito: exito,
            extraAlto: extraAlto,
            tituloWidget: tituloWidget,
            comentarioWidget: comentarioWidget,
            exitoWidget: exitoWidget,
            marcas: marcas,
            onAnterior: onAnterior,
            onProximo: onProximo,
            onSiguiente: onSiguiente,
            onTocarTablero: onTocarTablero),
      };
}

enum TipoMensaje { correcto, error, info }

class _Feedback extends StatelessWidget {
  const _Feedback({this.texto, required this.tipo});
  final String? texto;
  final TipoMensaje tipo;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final brillo = Theme.of(context).brightness;
    final (Color fondo, Color letra) = switch (tipo) {
      TipoMensaje.correcto => (AppTheme.verdeFondo(brillo), AppTheme.verdeTexto(brillo)),
      TipoMensaje.error => (cs.errorContainer, cs.onErrorContainer),
      TipoMensaje.info => (cs.surfaceContainerHighest, cs.onSurface),
    };
    return AnimatedSize(
      duration: const Duration(milliseconds: 150),
      child: texto == null
          ? const SizedBox(height: 0)
          : Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: fondo,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                texto!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: letra,
                  fontWeight: tipo == TipoMensaje.correcto ? FontWeight.w700 : null,
                ),
              ),
            ),
    );
  }
}

// ------------------------------------------------- Tablero jugable

class _JugadaView extends ConsumerStatefulWidget {
  const _JugadaView({
    required this.actividad,
    required this.categoriaId,
    this.titulo,
    this.yaResuelto = false,
    this.comentario,
    this.exito,
    this.extraAlto = 0,
    this.tituloWidget,
    this.comentarioWidget,
    this.exitoWidget,
    this.marcas = const {},
    this.registrarIntentos = false,
    this.onAnterior,
    this.onProximo,
    this.onSiguiente,
    this.onTocarTablero,
  });
  final bool registrarIntentos;
  final VoidCallback? onAnterior;
  final VoidCallback? onProximo;
  final Widget? tituloWidget;
  final Widget? comentarioWidget;
  final Widget? exitoWidget;
  final Map<String, Color> marcas;
  final Actividad actividad; // SecuenciaExacta | JugadaConPropiedad
  final String categoriaId;
  final String? titulo;
  final bool yaResuelto;
  final String? comentario;
  final String? exito;
  final double extraAlto;
  final VoidCallback? onSiguiente;
  final ValueChanged<bool>? onTocarTablero;

  @override
  ConsumerState<_JugadaView> createState() => _JugadaViewState();
}

class _JugadaViewState extends ConsumerState<_JugadaView> {
  late Position _pos;
  late final Side _lado;
  late ChessboardController _controller;
  // Controladores reemplazados: se liberan al cerrar la pantalla (el tablero viejo
  // todavía los usa mientras se desmonta).
  final List<ChessboardController> _descartados = [];
  late final bool _yaResuelto; // se fija al abrir: no cambia al resolverlo ahora
  // Intentos = jugadas hechas por el usuario en cada paso hasta acertar. Se guardan la
  // primera vez que se resuelve (o la primera vez que se vuelve a resolver si no había registro).
  List<int> _intentos = [0];
  List<int>? _intentosGuardados;
  SecuenciaValidator? _seq;
  PropiedadValidator? _prop;
  Move? _ultima;
  String? _mensaje;
  String? _solucionTexto;
  TipoMensaje _tipo = TipoMensaje.info;
  bool _completa = false;
  bool _esperando = false;
  bool _soloLectura = false; // tras "Mostrar solución"
  int _reinicios = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final a = widget.actividad;
    _yaResuelto = widget.yaResuelto;
    if (widget.registrarIntentos) {
      _intentosGuardados =
          ref.read(progressRepositoryProvider).intentosDe(widget.categoriaId, a.id);
    }
    _pos = posicionDesdeFen(a.fen);
    _lado = _pos.turn;
    if (a is SecuenciaExacta) _seq = SecuenciaValidator(a);
    if (a is JugadaConPropiedad) _prop = PropiedadValidator(a);
    _controller = ChessboardController(game: _buildGame());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose(); // el controller es nuestro: hay que liberarlo
    for (final c in _descartados) {
      c.dispose();
    }
    super.dispose();
  }

  GameData _buildGame() {
    final bloqueado = _completa || _esperando || _soloLectura;
    return GameData(
      fen: _pos.fen,
      lastMove: _ultima,
      playerSide: bloqueado
          ? PlayerSide.none
          : (_lado == Side.white ? PlayerSide.white : PlayerSide.black),
      sideToMove: _pos.turn == Side.white ? Side.white : Side.black,
      kingSquareInCheck:
          _pos.isCheck ? _pos.board.kingOf(_pos.turn) : null,
      validMoves: makeLegalMoves(_pos),
    );
  }

  /// Aplica cambios de estado y sincroniza el tablero con el controller.
  void _actualizar(VoidCallback cambios, {bool animar = true}) {
    setState(cambios);
    _controller.updatePosition(_buildGame(), animate: animar);
  }

  // La promoción la resuelve el tablero: onMove llega con `promotion` ya elegida.
  void _onMove(Move move, {bool? viaDragAndDrop}) {
    if (move is NormalMove) _resolver(move);
  }

  /// Aplica la jugada a la posición (sin setState) y devuelve su SAN.
  String _aplicar(Move m) {
    if (m is! NormalMove) return '';
    final (nueva, san) = _pos.makeSan(m);
    _pos = nueva;
    _ultima = m;
    return san;
  }

  void _sonar(String san) => ref
      .read(soundProvider)
      .reproducir(san.contains('x') ? Sonido.capturar : Sonido.mover);

  /// Vuelve el tablero a la posición actual con un tablero y un controlador NUEVOS.
  /// Reutilizar el mismo controlador (updatePosition sin animación o con el tablero
  /// remontado) dejaba la pantalla en gris desde el tablero hacia abajo.
  void _nuevoTablero(VoidCallback cambios) {
    _descartados.add(_controller);
    setState(() {
      cambios();
      _reinicios++;
      _controller = ChessboardController(game: _buildGame());
    });
  }

  void _error(String texto) {
    _nuevoTablero(() {
      _mensaje = texto;
      _tipo = TipoMensaje.error;
    });
    ref.read(soundProvider).reproducir(Sonido.incorrecto);
  }

  void _resolver(NormalMove move) {
    final normal = _pos.normalizeMove(move);
    _intentos[_intentos.length - 1]++; // cada jugada del usuario es un intento
    if (_seq != null) {
      final res = _seq!.validar(uciEstandar(_pos, normal));
      if (res == ResultadoPaso.incorrecto) {
        _error('Incorrecto');
        return;
      }
      if (res == ResultadoPaso.correcto) _intentos.add(0); // empieza el paso siguiente
      var san = '';
      _actualizar(() {
        san = _aplicar(normal);
        _mensaje = null;
      });
      _sonar(san);
      if (res == ResultadoPaso.completada) {
        _completar();
      } else {
        _actualizar(() {
          _esperando = true;
          _mensaje = '¡Bien! Mueve el rival…';
          _tipo = TipoMensaje.info;
        });
        _timer = Timer(const Duration(milliseconds: 600), _jugarOponente);
      }
    } else if (_prop != null) {
      if (_prop!.cumple(move)) {
        var san = '';
        _actualizar(() => san = _aplicar(normal));
        _sonar(san);
        _completar();
      } else {
        _error('Incorrecto');
      }
    }
  }

  void _jugarOponente() {
    if (!mounted) return;
    final uci = _seq!.respuestaOponente();
    final m = uci == null ? null : Move.parse(uci);
    if (m is! NormalMove) return;
    final normal = _pos.normalizeMove(m);
    var san = '';
    _actualizar(() {
      san = _aplicar(normal);
      _esperando = false;
      _mensaje = null;
    });
    _sonar(san);
    if (_seq!.terminada) _completar();
  }

  void _completar() {
    ref.read(completedProvider(widget.categoriaId).notifier).marcar(widget.actividad.id);
    if (widget.registrarIntentos && _intentosGuardados == null) {
      final registro = List<int>.of(_intentos);
      while (registro.length > 1 && registro.last == 0) {
        registro.removeLast(); // paso vacío si la solución termina con jugada del rival
      }
      ref
          .read(progressRepositoryProvider)
          .guardarIntentos(widget.categoriaId, widget.actividad.id, registro);
      _intentosGuardados = registro;
    }
    _actualizar(() {
      _completa = true;
      _tipo = TipoMensaje.correcto;
      _mensaje = '¡Correcto!';
    });
    ref.read(soundProvider).reproducir(Sonido.correcto,
        demora: const Duration(milliseconds: 160));
  }

  // ------------------------------------------------- Mostrar solución

  List<NormalMove> _lineaSolucion() {
    final a = widget.actividad;
    if (a is SecuenciaExacta) {
      final res = <NormalMove>[];
      for (final u in a.solucionUci) {
        final m = Move.parse(u);
        if (m is NormalMove) res.add(m);
      }
      return res;
    }
    return _prop!.jugadasValidas().whereType<NormalMove>().take(1).toList();
  }

  /// "1. Rb7 Kg8 2. Ra8#" (con número de jugada del FEN).
  String _sanDe(Position inicial, List<NormalMove> linea) {
    var p = inicial;
    var numero = p.fullmoves;
    final partes = <String>[];
    for (var i = 0; i < linea.length; i++) {
      final n = p.normalizeMove(linea[i]);
      if (n is! NormalMove) break;
      final turno = p.turn;
      final (siguiente, san) = p.makeSan(n);
      if (turno == Side.white) {
        partes.add('$numero. $san');
      } else {
        partes.add(i == 0 ? '$numero… $san' : san);
        numero++;
      }
      p = siguiente;
    }
    return partes.join(' ');
  }

  void _mostrarSolucion() {
    _timer?.cancel();
    final a = widget.actividad;
    final inicial = posicionDesdeFen(a.fen);
    final linea = _lineaSolucion();
    final prefijo = a is SecuenciaExacta ? 'Solución' : 'Una jugada válida';
    _nuevoTablero(() {
      _pos = inicial;
      _ultima = null;
      _completa = false;
      _esperando = true; // bloquea el tablero durante la reproducción
      _soloLectura = false;
      _mensaje = null;
      _solucionTexto = '$prefijo: ${_sanDe(inicial, linea)}';
    });
    _timer = Timer(const Duration(milliseconds: 700), () => _reproducir(linea, 0));
  }

  void _reproducir(List<NormalMove> linea, int i) {
    if (!mounted) return;
    if (i >= linea.length) {
      _actualizar(() {
        _esperando = false;
        _soloLectura = true;
      });
      return;
    }
    final n = _pos.normalizeMove(linea[i]);
    var san = '';
    _actualizar(() => san = _aplicar(n));
    _sonar(san);
    _timer = Timer(const Duration(milliseconds: 900), () => _reproducir(linea, i + 1));
  }

  void _reiniciar() {
    _timer?.cancel();
    final a = widget.actividad;
    _nuevoTablero(() {
      _pos = posicionDesdeFen(a.fen);
      _ultima = null;
      if (a is SecuenciaExacta) _seq = SecuenciaValidator(a);
      _completa = false;
      _esperando = false;
      _soloLectura = false;
      _mensaje = null;
      _solucionTexto = null;
      _intentos = [0];
    });
  }

  /// Las marcas se borran cuando una pieza ocupa la casilla (ej. el rey y la torre
  /// del enroque al llegar a g1 y f1).
  Map<String, Color> get _marcasVisibles => {
        for (final e in widget.marcas.entries)
          if (_pos.board.pieceAt(casillaDe(e.key)) == null) e.key: e.value,
      };

  String get _consigna {
    final a = widget.actividad;
    if (a is JugadaConPropiedad) {
      return switch (a.propiedad) {
        PropiedadJugada.daJaque => 'Da jaque al rey rival.',
        PropiedadJugada.esMate => 'Da jaque mate.',
        PropiedadJugada.esCaptura => 'Captura una pieza.',
        PropiedadJugada.esEnroque => 'Haz un enroque.',
        PropiedadJugada.esAlPaso => 'Captura al paso.',
        PropiedadJugada.cualquierLegal => 'Haz una jugada legal.',
        PropiedadJugada.dejaPiezaDefendida =>
          'Mueve una pieza a una casilla donde quede protegida.',
      };
    }
    return 'Encuentra la mejor jugada para ${_lado == Side.white ? "blancas" : "negras"}.';
  }

  @override
  Widget build(BuildContext context) {
    final apariencia = ref.watch(appearanceProvider);
    final tt = Theme.of(context).textTheme;
    final titulo = widget.titulo ?? _consigna;
    final puedeSiguiente = (_completa || _soloLectura) && widget.onSiguiente != null;

    return LayoutBuilder(builder: (context, c) {
      final size = _tamanoTablero(c, 330 + widget.extraAlto);
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            widget.tituloWidget ??
                Text(titulo,
                    style: tt.titleMedium, maxLines: 4, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            // TODO(accesibilidad): envolver en Semantics con descripción de la posición.
            Center(
              child: Listener(
                onPointerDown: (_) => widget.onTocarTablero?.call(true),
                onPointerUp: (_) => widget.onTocarTablero?.call(false),
                onPointerCancel: (_) => widget.onTocarTablero?.call(false),
                child: Stack(
                  children: [
                    Chessboard(
                      key: ValueKey(_reinicios),
                      controller: _controller,
                      size: size,
                      orientation: _lado,
                      settings: apariencia.boardSettings,
                      onMove: _onMove,
                    ),
                    if (_marcasVisibles.isNotEmpty)
                      IgnorePointer(
                        child: CustomPaint(
                          size: Size(size, size),
                          painter: PintorMarcas(marcas: _marcasVisibles),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Orden: solución -> intentos -> comentario -> carteles -> botones -> flechas
            if (_solucionTexto != null) ...[
              Text(_solucionTexto!, textAlign: TextAlign.center, style: tt.bodyMedium),
              const SizedBox(height: 8),
            ],
            if (_intentosGuardados != null) ...[
              _LineaIntentos(intentos: _intentosGuardados!),
              const SizedBox(height: 8),
            ],
            if (widget.comentarioWidget != null || widget.comentario != null) ...[
              widget.comentarioWidget ?? Text(widget.comentario!, style: tt.bodyMedium),
              const SizedBox(height: 10),
            ],
            _Feedback(texto: _mensaje, tipo: _tipo),
            if (_completa && (widget.exitoWidget != null || widget.exito != null)) ...[
              const SizedBox(height: 8),
              widget.exitoWidget ?? Text(widget.exito!, style: tt.bodyMedium),
            ],
            if (puedeSiguiente) ...[
              const SizedBox(height: 12),
              FilledButton(onPressed: widget.onSiguiente, child: const Text('Siguiente')),
            ],
            if (_yaResuelto) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _esperando
                    ? null
                    : (_soloLectura ? _reiniciar : _mostrarSolucion),
                child: Text(_soloLectura ? 'Reintentar' : 'Mostrar solución'),
              ),
            ],
            _FlechasProblema(onAnterior: widget.onAnterior, onProximo: widget.onProximo),
          ],
        ),
      );
    });
  }
}

/// "Intentos: 5 (Paso 1: 3 · Paso 2: 2)": jugadas hechas hasta llegar a la solución.
class _LineaIntentos extends StatelessWidget {
  const _LineaIntentos({required this.intentos});
  final List<int> intentos;

  @override
  Widget build(BuildContext context) {
    final total = intentos.fold<int>(0, (a, b) => a + b);
    final detalle = intentos.length > 1
        ? ' (${[for (var i = 0; i < intentos.length; i++) 'Paso ${i + 1}: ${intentos[i]}'].join(' · ')})'
        : '';
    return Text('Intentos: $total$detalle',
        textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium);
  }
}

/// Dos flechas abajo de todo para pasar al problema anterior o siguiente
/// (también se puede deslizar la pantalla).
class _FlechasProblema extends StatelessWidget {
  const _FlechasProblema({this.onAnterior, this.onProximo});
  final VoidCallback? onAnterior;
  final VoidCallback? onProximo;

  @override
  Widget build(BuildContext context) {
    if (onAnterior == null && onProximo == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            tooltip: 'Problema anterior',
            onPressed: onAnterior,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            tooltip: 'Problema siguiente',
            onPressed: onProximo,
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------- Trivia

class _TriviaView extends ConsumerStatefulWidget {
  const _TriviaView({
    required this.actividad,
    required this.categoriaId,
    this.titulo,
    this.yaResuelto = false,
    this.comentario,
    this.exito,
    this.extraAlto = 0,
    this.tituloWidget,
    this.comentarioWidget,
    this.exitoWidget,
    this.marcas = const {},
    this.registrarIntentos = false,
    this.onAnterior,
    this.onProximo,
    this.onSiguiente,
  });
  final bool registrarIntentos;
  final VoidCallback? onAnterior;
  final VoidCallback? onProximo;
  final Widget? tituloWidget;
  final Widget? comentarioWidget;
  final Widget? exitoWidget;
  final Map<String, Color> marcas;
  final Trivia actividad;
  final String categoriaId;
  final String? titulo;
  final bool yaResuelto;
  final String? comentario;
  final String? exito;
  final double extraAlto;
  final VoidCallback? onSiguiente;

  @override
  ConsumerState<_TriviaView> createState() => _TriviaViewState();
}

class _TriviaViewState extends ConsumerState<_TriviaView> {
  late final TriviaValidator _validador = TriviaValidator(widget.actividad);
  late final bool _yaResuelto = widget.yaResuelto;
  String? _mensaje;
  TipoMensaje _tipo = TipoMensaje.info;
  bool _completa = false;
  bool _solucionVista = false;

  void _elegir(int i) {
    if (_completa) return;
    if (_validador.validar(i)) {
      ref.read(completedProvider(widget.categoriaId).notifier).marcar(widget.actividad.id);
      setState(() {
        _completa = true;
        _tipo = TipoMensaje.correcto;
        _mensaje = '¡Correcto!';
      });
      ref.read(soundProvider).reproducir(Sonido.correcto);
    } else {
      setState(() {
        _tipo = TipoMensaje.error;
        _mensaje = 'Incorrecto';
      });
      ref.read(soundProvider).reproducir(Sonido.incorrecto);
    }
  }

  void _mostrarSolucion() {
    final a = widget.actividad;
    setState(() {
      _solucionVista = true;
      _tipo = TipoMensaje.info;
      _mensaje = 'Respuesta: ${a.opciones[a.respuestaCorrecta]}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.actividad;
    final apariencia = ref.watch(appearanceProvider);
    final turno = posicionDesdeFen(a.fen).turn;
    return LayoutBuilder(builder: (context, c) {
      final size = _tamanoTablero(c, 200.0 + a.opciones.length * 56 + widget.extraAlto);
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            widget.tituloWidget ??
                Text(widget.titulo ?? '¿Qué situación es esta?',
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            // TODO(accesibilidad): Semantics con descripción de la posición.
            Center(
              child: Stack(
                children: [
                  StaticChessboard(
                    size: size,
                    fen: a.fen,
                    orientation: turno,
                    settings: apariencia.staticSettings,
                  ),
                  if (widget.marcas.isNotEmpty)
                    IgnorePointer(
                      child: CustomPaint(
                        size: Size(size, size),
                        painter: PintorMarcas(marcas: widget.marcas),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (widget.comentarioWidget != null || widget.comentario != null) ...[
              widget.comentarioWidget ??
                  Text(widget.comentario!, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 10),
            ],
            for (var i = 0; i < a.opciones.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton(
                  onPressed: () => _elegir(i),
                  child: Text(a.opciones[i]),
                ),
              ),
            _Feedback(texto: _mensaje, tipo: _tipo),
            if (_completa && (widget.exitoWidget != null || widget.exito != null)) ...[
              const SizedBox(height: 8),
              widget.exitoWidget ?? Text(widget.exito!, style: Theme.of(context).textTheme.bodyMedium),
            ],
            if (_completa && widget.onSiguiente != null) ...[
              const SizedBox(height: 12),
              FilledButton(onPressed: widget.onSiguiente, child: const Text('Siguiente')),
            ],
            if (_yaResuelto && !_solucionVista) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _mostrarSolucion,
                child: const Text('Mostrar solución'),
              ),
            ],
            _FlechasProblema(onAnterior: widget.onAnterior, onProximo: widget.onProximo),
          ],
        ),
      );
    });
  }
}
