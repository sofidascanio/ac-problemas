import 'dart:math' as math;
import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../data/models/leccion.dart';
import '../../data/models/menu_node.dart';
import '../../theme/app_theme.dart';
import '../activity/actividad_view.dart';
import 'colocar_tablero.dart';
import 'lista_pasos_screen.dart';
import 'marcas_tablero.dart';
import 'pieza_contorno.dart';
import 'tablero_pieza.dart';
import 'texto_leccion.dart';

/// Lección guiada: recorre los pasos de a uno (explicación, exploración, minijuegos),
/// con Atrás / Siguiente y un listado para saltar a un paso.
class LeccionScreen extends ConsumerStatefulWidget {
  const LeccionScreen({super.key, required this.categoria, this.hermanos = const []});
  final MenuNode categoria;

  /// Lecciones del mismo grupo del menú (para ofrecer "Siguiente lección" al terminar).
  final List<MenuNode> hermanos;

  @override
  ConsumerState<LeccionScreen> createState() => _LeccionScreenState();
}

class _LeccionScreenState extends ConsumerState<LeccionScreen> {
  int _i = 0;

  MenuNode? get _siguienteLeccion {
    final k = widget.hermanos.indexWhere((n) => n.id == widget.categoria.id);
    if (k < 0) return null;
    for (var j = k + 1; j < widget.hermanos.length; j++) {
      final n = widget.hermanos[j];
      if (n.leccion && n.asset != null) return n;
    }
    return null;
  }

  Future<void> _abrirLista(Leccion l) async {
    final elegido = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => ListaPasosScreen(
          categoriaId: widget.categoria.id,
          titulo: widget.categoria.titulo,
          pasos: l.pasos,
          actual: _i,
        ),
      ),
    );
    if (elegido != null && mounted) setState(() => _i = elegido);
  }

  @override
  Widget build(BuildContext context) {
    final cat = widget.categoria;
    final lec = ref.watch(leccionProvider(cat.asset!));
    final hechas = ref.watch(completedProvider(cat.id));
    final l = lec.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(cat.titulo),
        actions: [
          if (l != null && l.pasos.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.format_list_numbered),
              tooltip: 'Pasos de la lección',
              onPressed: () => _abrirLista(l),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: lec.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('No se pudo cargar la lección.')),
          data: (l) {
            if (l == null || l.pasos.isEmpty) {
              return const Center(child: Text('Próximamente'));
            }
            if (_i >= l.pasos.length) {
              return _Final(
                siguiente: _siguienteLeccion,
                onRepetir: () => setState(() => _i = 0),
                onSiguiente: () {
                  final s = _siguienteLeccion!;
                  Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (_) => LeccionScreen(categoria: s, hermanos: widget.hermanos),
                  ));
                },
              );
            }
            final paso = l.pasos[_i];
            final teorico = paso is PasoTexto || paso is PasoExplorar;
            final puedeSeguir = teorico || hechas.contains(paso.idProgreso);

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LinearProgressIndicator(value: (_i + 1) / l.pasos.length),
                  const SizedBox(height: 6),
                  Text('Paso ${_i + 1} de ${l.pasos.length}',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 12),
                  Expanded(
                    child: LayoutBuilder(builder: (context, c) => _vistaPaso(paso, c)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _i > 0 ? () => setState(() => _i--) : null,
                          child: const Text('Atrás'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: puedeSeguir
                              ? () {
                                  if (teorico && !hechas.contains(paso.idProgreso)) {
                                    ref
                                        .read(completedProvider(cat.id).notifier)
                                        .marcar(paso.idProgreso);
                                  }
                                  setState(() => _i++);
                                }
                              : null,
                          child: const Text('Siguiente'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  double _lado(BoxConstraints c, double reservado) =>
      math.min(c.maxWidth, math.max(220.0, c.maxHeight - reservado));

  Widget _vistaPaso(Paso paso, BoxConstraints c) {
    final cat = widget.categoria;
    return switch (paso) {
      PasoTexto p => _VistaTexto(key: ValueKey(p.id), paso: p, size: _lado(c, 200)),
      PasoExplorar p => _VistaMovimiento(
          key: ValueKey(p.id),
          paso: p,
          fen: p.fen,
          pieza: p.pieza,
          objetivos: const [],
          mostrarDestinos: true,
          textoCaptura: p.alCapturar,
          categoriaId: cat.id,
          size: _lado(c, 250)),
      PasoAlcanzar p => _VistaMovimiento(
          key: ValueKey(p.id),
          paso: p,
          fen: p.fen,
          pieza: p.pieza,
          objetivos: p.objetivos,
          mostrarDestinos: p.ayuda,
          categoriaId: cat.id,
          size: _lado(c, 290)),
      PasoActividad p => _vistaActividad(p, cat.id),
      PasoColocar p => _VistaColocar(
          key: ValueKey(p.id), categoriaId: cat.id, paso: p, size: _lado(c, 290)),
    };
  }

  Widget _vistaActividad(PasoActividad p, String categoriaId) {
    final tt = Theme.of(context).textTheme;
    final fen = p.actividad.fen;
    final conCoord = p.coordenadas;
    final marcas = conCoord
        ? marcasDeTextos([p.texto, p.comentario], fen, sinMarca: p.sinMarca)
        : <String, Color>{};
    return ActividadView(
      key: ValueKey(p.id),
      actividad: p.actividad,
      categoriaId: categoriaId,
      titulo: p.texto,
      comentario: p.comentario,
      exito: p.exito,
      extraAlto: 90,
      tituloWidget: p.texto == null
          ? null
          : TextoLeccion(p.texto!,
              fen: fen, estilo: tt.titleMedium, marcas: marcas, conCoordenadas: conCoord),
      comentarioWidget: p.comentario == null
          ? null
          : TextoLeccion(p.comentario!,
              fen: fen, estilo: tt.bodyMedium, marcas: marcas, conCoordenadas: conCoord),
      exitoWidget: p.exito == null
          ? null
          : TextoLeccion(p.exito!,
              fen: fen, estilo: tt.bodyMedium, marcas: marcas, conCoordenadas: conCoord),
      marcas: marcas,
      // la navegación (Atrás / Siguiente) está en la barra de abajo de la lección
    );
  }
}

// ------------------------------------------------- Piezas reutilizables

class _CartelVerde extends StatelessWidget {
  const _CartelVerde(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.verdeFondo(b),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(texto,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.verdeTexto(b), fontWeight: FontWeight.w700)),
    );
  }
}

// ------------------------------------------------- Pasos

class _VistaTexto extends ConsumerWidget {
  const _VistaTexto({super.key, required this.paso, required this.size});
  final PasoTexto paso;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ap = ref.watch(appearanceProvider);
    final tt = Theme.of(context).textTheme;
    final set = ap.pieceSet;
    final marcas = paso.coordenadas
        ? marcasDeTextos([paso.texto, paso.textoDespues], paso.fen, sinMarca: paso.sinMarca)
        : <String, Color>{};

    Widget texto(String t) =>
        TextoLeccion(t, fen: paso.fen, marcas: marcas, conCoordenadas: paso.coordenadas);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (paso.fen != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Center(
                child: SizedBox(
                  width: size,
                  height: size,
                  child: Stack(
                    children: [
                      StaticChessboard(
                        size: size,
                        fen: paso.fen!,
                        orientation: Side.white,
                        settings: ap.staticSettings,
                      ),
                      IgnorePointer(
                        child: CustomPaint(
                          size: Size(size, size),
                          painter: PintorMarcas(dorados: paso.resaltar.toSet(), marcas: marcas),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (paso.texto != null) texto(paso.texto!),
          if (paso.tabla.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final f in paso.tabla)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: () {
                        final pz = piezaDeFen(f.pieza);
                        final img = pz == null ? null : set.assets[pz.kind];
                        return img == null
                            ? const SizedBox.shrink()
                            : PiezaContorno(imagen: img, size: 40, negra: f.pieza == f.pieza.toLowerCase());
                      }(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(f.nombre, style: tt.bodyLarge)),
                    Text(f.valor, style: tt.titleMedium),
                  ],
                ),
              ),
            const SizedBox(height: 8),
          ],
          if (paso.textoDespues != null) ...[
            const SizedBox(height: 4),
            texto(paso.textoDespues!),
          ],
        ],
      ),
    );
  }
}

/// Explorar y alcanzar: el mismo tablero; alcanzar suma estrellas y marca progreso.
class _VistaMovimiento extends ConsumerStatefulWidget {
  const _VistaMovimiento({
    super.key,
    required this.paso,
    required this.fen,
    required this.pieza,
    required this.objetivos,
    required this.mostrarDestinos,
    required this.categoriaId,
    required this.size,
    this.textoCaptura,
  });
  final Paso paso;
  final String fen, pieza;
  final List<String> objetivos;
  final bool mostrarDestinos;
  final String categoriaId;
  final double size;
  final String? textoCaptura;

  @override
  ConsumerState<_VistaMovimiento> createState() => _VistaMovimientoState();
}

class _VistaMovimientoState extends ConsumerState<_VistaMovimiento> {
  bool _completo = false;
  bool _capturo = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.paso;
    final estrellas = widget.objetivos.toSet();
    final marcas = p.coordenadas
        ? marcasDeTextos([p.texto], widget.fen, estrellas: estrellas, sinMarca: p.sinMarca)
        : <String, Color>{};

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: TableroPieza(
              fen: widget.fen,
              pieza: widget.pieza,
              size: widget.size,
              objetivos: widget.objetivos,
              mostrarDestinos: widget.mostrarDestinos,
              marcas: marcas,
              onCaptura: () => setState(() => _capturo = true),
              onReinicio: () => setState(() {
                _completo = false;
                _capturo = false;
              }),
              onCompleto: () {
                ref.read(completedProvider(widget.categoriaId).notifier).marcar(p.idProgreso);
                setState(() => _completo = true);
              },
            ),
          ),
          if (_completo) ...[
            const SizedBox(height: 8),
            const _CartelVerde('¡Muy bien!'),
          ] else if (_capturo && widget.objetivos.isEmpty) ...[
            const SizedBox(height: 8),
            _CartelVerde(widget.textoCaptura ??
                '¡Capturaste una pieza! Tocá Reiniciar para volver a probar o seguí con el siguiente paso.'),
          ],
          if (p.texto != null) ...[
            const SizedBox(height: 10),
            TextoLeccion(p.texto!,
                fen: widget.fen,
                estrellas: estrellas,
                marcas: marcas,
                conCoordenadas: p.coordenadas),
          ],
        ],
      ),
    );
  }
}

class _VistaColocar extends ConsumerStatefulWidget {
  const _VistaColocar({
    super.key,
    required this.categoriaId,
    required this.paso,
    required this.size,
  });
  final String categoriaId;
  final PasoColocar paso;
  final double size;

  @override
  ConsumerState<_VistaColocar> createState() => _VistaColocarState();
}

class _VistaColocarState extends ConsumerState<_VistaColocar> {
  bool _completo = false;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.paso.texto != null) ...[
            Text(widget.paso.texto!, style: tt.bodyLarge),
            const SizedBox(height: 10),
          ],
          ColocarTablero(
            blancas: widget.paso.blancas,
            fenInicial: widget.paso.fen,
            size: widget.size,
            onCompleto: () {
              ref
                  .read(completedProvider(widget.categoriaId).notifier)
                  .marcar(widget.paso.idProgreso);
              setState(() => _completo = true);
            },
          ),
          if (_completo) ...[
            const SizedBox(height: 12),
            const _CartelVerde('¡Correcto!'),
          ],
        ],
      ),
    );
  }
}

class _Final extends StatelessWidget {
  const _Final({required this.siguiente, required this.onRepetir, required this.onSiguiente});
  final MenuNode? siguiente;
  final VoidCallback onRepetir;
  final VoidCallback onSiguiente;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.check_circle_outline, size: 72, color: cs.primary),
            const SizedBox(height: 12),
            Text('¡Lección completada!',
                textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            if (siguiente != null) ...[
              FilledButton(
                onPressed: onSiguiente,
                child: Text('Siguiente lección: ${siguiente!.titulo}'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Volver al menú'),
              ),
            ] else
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Volver al menú'),
              ),
            const SizedBox(height: 4),
            TextButton(onPressed: onRepetir, child: const Text('Repetir lección')),
          ],
        ),
      ),
    );
  }
}
