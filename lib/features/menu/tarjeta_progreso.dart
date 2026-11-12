import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/formato.dart';
import '../../core/providers.dart';
import '../../data/models/menu_node.dart';

/// Estadística personal de la pantalla principal:
/// - Resueltos / Hoy / Esta semana (todos los ejercicios).
/// - Una barra por sección que el usuario eligió mostrar (Ajustes > Perfil > Progreso).
///   Cada sección y cada subsección con contenido se puede plegar/desplegar. Todo sale
///   del menú: al agregar secciones o subsecciones aparecen solas.
/// - "Promedio por ejercicio" en la sección y en cada nivel (se puede ocultar en Perfil).
class TarjetaProgreso extends ConsumerWidget {
  const TarjetaProgreso({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menu = ref.watch(menuProvider).valueOrNull ?? const <MenuNode>[];
    final ocultas = ref.watch(perfilProvider.select((p) => p.ocultas));
    final visibles = [for (final n in menu) if (!ocultas.contains(n.id)) n];
    final resumen = ref.watch(resumenGeneralProvider).valueOrNull;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Tu progreso', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                _Dato(etiqueta: 'Resueltos', valor: resumen?.resueltos),
                _Dato(etiqueta: 'Hoy', valor: resumen?.hoy),
                _Dato(etiqueta: 'Esta semana', valor: resumen?.semana),
              ],
            ),
            if (visibles.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              for (final n in visibles) _NodoProgreso(key: ValueKey(n.id), nodo: n, nivel: 0),
            ] else
              const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.etiqueta, required this.valor});
  final String etiqueta;
  final int? valor;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        children: [
          Text(valor?.toString() ?? '–', style: tt.headlineSmall),
          const SizedBox(height: 2),
          Text(etiqueta, style: tt.bodySmall),
        ],
      ),
    );
  }
}

/// Las lecciones sueltas no se listan (ya se ven en el menú de Aprender a Jugar).
Iterable<MenuNode> _subsecciones(MenuNode n) =>
    n.hijos.where((h) => !(h.leccion && h.hijos.isEmpty));

/// Un nodo del menú con su barra de progreso. [nivel] 0 = sección, 1 = nivel, 2+ = más adentro.
/// Si tiene subsecciones con contenido, se pliega/despliega tocando su fila (empieza plegado).
class _NodoProgreso extends ConsumerStatefulWidget {
  const _NodoProgreso({super.key, required this.nodo, required this.nivel});
  final MenuNode nodo;
  final int nivel;

  @override
  ConsumerState<_NodoProgreso> createState() => _NodoProgresoState();
}

class _NodoProgresoState extends ConsumerState<_NodoProgreso> {
  bool _abierto = false;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final nivel = widget.nivel;
    final subs = _subsecciones(widget.nodo).toList();
    final est = ref.watch(estadisticaNodoProvider(widget.nodo.id));
    final mostrarPromedio = ref.watch(perfilProvider.select((p) => p.mostrarPromedio));

    return est.when(
      loading: () => nivel == 0
          ? Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.nodo.titulo, style: tt.bodyMedium),
                  const SizedBox(height: 6),
                  const LinearProgressIndicator(),
                ],
              ),
            )
          : const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (e) {
        if (e.total == 0) return const SizedBox.shrink(); // sin contenido todavía
        final estilo = nivel == 0 ? tt.bodyMedium : tt.bodySmall;
        // El promedio se muestra en la sección y en cada nivel.
        final conPromedio = mostrarPromedio && nivel <= 1 && e.segundosPromedio != null;

        return Padding(
          padding: EdgeInsets.only(left: nivel == 0 ? 0 : 14, top: nivel == 0 ? 0 : 10, bottom: nivel == 0 ? 12 : 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: subs.isEmpty ? null : () => setState(() => _abierto = !_abierto),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(widget.nodo.titulo, style: estilo)),
                        Text('${e.resueltos} de ${e.total}', style: tt.bodySmall),
                        if (subs.isNotEmpty)
                          Icon(_abierto ? Icons.expand_less : Icons.expand_more, size: 20),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: e.resueltos / e.total,
                      minHeight: nivel == 0 ? null : 6,
                    ),
                    if (conPromedio) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.timer_outlined, size: 14, color: tt.bodySmall?.color),
                          const SizedBox(width: 4),
                          Text('Promedio por ejercicio: ${formatoTiempo(e.segundosPromedio!)}',
                              style: tt.bodySmall),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (_abierto)
                for (final s in subs)
                  _NodoProgreso(key: ValueKey(s.id), nodo: s, nivel: nivel + 1),
            ],
          ),
        );
      },
    );
  }
}
