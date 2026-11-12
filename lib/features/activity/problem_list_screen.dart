import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/dialogos.dart';
import '../../core/providers.dart';
import '../../data/models/menu_node.dart';

/// Resultado de ProblemListScreen cuando se reinició la sección (en vez de un índice).
const int kIndiceReiniciado = -1;

/// Listado de problemas de una subcategoría: número + nombre, con los
/// resueltos resaltados. Al tocar uno se vuelve a los problemas en ese ejercicio
/// (devuelve su índice con Navigator.pop).
class ProblemListScreen extends ConsumerStatefulWidget {
  const ProblemListScreen({
    super.key,
    required this.categoria,
    this.tituloPadre,
    this.indiceActual,
  });
  final MenuNode categoria;
  final String? tituloPadre; // ej. "Mate en 2"

  /// Problema abierto al entrar al listado: el listado se posiciona cerca de él.
  final int? indiceActual;

  @override
  ConsumerState<ProblemListScreen> createState() => _ProblemListScreenState();
}

class _ProblemListScreenState extends ConsumerState<ProblemListScreen> {
  static const double _alto = 60; // alto fijo por fila: permite saltar a una posición
  ScrollController? _scroll;

  @override
  void dispose() {
    _scroll?.dispose();
    super.dispose();
  }

  Future<void> _reiniciarSeccion(int resueltos, int total) async {
    final cat = widget.categoria;
    final nombre = widget.tituloPadre == null ? cat.titulo : '${widget.tituloPadre} - ${cat.titulo}';
    final ok = await confirmarAccion(
      context,
      titulo: 'Reiniciar esta sección',
      mensaje: 'Se va a reiniciar el progreso de «$nombre» ($resueltos de $total resueltos): '
          'se pierden los ejercicios resueltos, los tiempos y los intentos de ESTA sección. '
          'Las demás secciones no se tocan. No se puede deshacer.',
    );
    if (!ok || !mounted) return;
    await reiniciarProgresoCategoria(ref, cat.id);
    if (!mounted) return;
    Navigator.pop(context, kIndiceReiniciado); // la pantalla de problemas vuelve al inicio
  }

  @override
  Widget build(BuildContext context) {
    final cat = widget.categoria;
    final lista = ref.watch(actividadesProvider(cat.asset!));
    final hechas = ref.watch(completedProvider(cat.id));
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(widget.tituloPadre ?? cat.titulo)),
      body: SafeArea(
        top: false,
        child: lista.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => const Center(child: Text('No se pudo cargar el contenido.')),
          data: (acts) {
            if (acts.isEmpty) return const Center(child: Text('Próximamente'));
            final resueltos = acts.where((a) => hechas.contains(a.id)).length;
            // La primera vez, abre el listado cerca del primer problema pendiente.
            final primera = acts.indexWhere((a) => !hechas.contains(a.id));
            _scroll ??= ScrollController(
              initialScrollOffset:
                  math.max(0, (widget.indiceActual ?? (primera < 0 ? 0 : primera)) - 1) * _alto,
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(0, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(Icons.restart_alt, size: 18),
                        label: const Text('Reiniciar esta sección'),
                        onPressed: () => _reiniciarSeccion(resueltos, acts.length),
                      ),
                      const SizedBox(height: 4),
                      if (widget.tituloPadre != null) ...[
                        Text(cat.titulo, style: tt.titleMedium),
                        const SizedBox(height: 8),
                      ],
                      LinearProgressIndicator(value: resueltos / acts.length),
                      const SizedBox(height: 6),
                      Text('$resueltos de ${acts.length} resueltos'),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: _scroll,
                    itemExtent: _alto,
                    itemCount: acts.length,
                    itemBuilder: (context, i) {
                      final a = acts[i];
                      return _Fila(
                        numero: a.numero ?? i + 1,
                        nombre: a.nombre ?? 'Problema ${i + 1}',
                        resuelto: hechas.contains(a.id),
                        actual: i == widget.indiceActual,
                        onTap: () => Navigator.pop(context, i),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({
    required this.numero,
    required this.nombre,
    required this.resuelto,
    required this.onTap,
    this.actual = false,
  });
  final int numero;
  final String nombre;
  final bool resuelto;
  final bool actual; // el problema que estaba abierto
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final fondo = resuelto ? cs.primaryContainer : cs.surfaceContainerHighest.withValues(alpha: 0.5);
    final texto = resuelto ? cs.onPrimaryContainer : cs.onSurface;
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: actual ? BorderSide(color: cs.primary, width: 2) : BorderSide.none,
    );

    return Semantics(
      button: true,
      label: 'Problema $numero, $nombre${resuelto ? ", resuelto" : ""}',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch, // misma altura en número y nombre
          children: [
            SizedBox(
              width: 48,
              child: Material(
                color: fondo,
                shape: forma,
                child: InkWell(
                  customBorder: forma,
                  onTap: onTap,
                  child: Center(
                    child: Text('$numero',
                        style: tt.titleMedium?.copyWith(color: texto, fontSize: 15)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Material(
                color: fondo,
                shape: forma,
                child: InkWell(
                  customBorder: forma,
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(nombre,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: tt.bodyLarge?.copyWith(color: texto, fontSize: 17)),
                        ),
                        if (resuelto) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.check_circle_outline, size: 20, color: texto),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
