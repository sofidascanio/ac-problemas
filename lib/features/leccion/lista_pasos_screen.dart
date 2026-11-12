import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../data/models/leccion.dart';

/// Listado de pasos de una lección (como el listado de problemas): al tocar uno
/// se vuelve a la lección en ese paso (devuelve su índice con Navigator.pop).
class ListaPasosScreen extends ConsumerWidget {
  const ListaPasosScreen({
    super.key,
    required this.categoriaId,
    required this.titulo,
    required this.pasos,
    required this.actual,
  });
  final String categoriaId;
  final String titulo;
  final List<Paso> pasos;
  final int actual;

  static const double _alto = 64;

  String _resumen(Paso p) {
    final t = (p.texto ?? '').replaceAll('\n', ' ').trim();
    return t.length > 70 ? '${t.substring(0, 70)}…' : t;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hechas = ref.watch(completedProvider(categoriaId));
    final resueltos = pasos.where((p) => hechas.contains(p.idProgreso)).length;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(value: resueltos / pasos.length),
                  const SizedBox(height: 6),
                  Text('$resueltos de ${pasos.length} pasos'),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: ScrollController(
                  initialScrollOffset: (actual > 0 ? actual - 1 : 0) * _alto,
                ),
                itemExtent: _alto,
                itemCount: pasos.length,
                itemBuilder: (context, i) {
                  final p = pasos[i];
                  final hecho = hechas.contains(p.idProgreso);
                  final fondo = hecho
                      ? cs.primaryContainer
                      : cs.surfaceContainerHighest.withValues(alpha: 0.5);
                  final texto = hecho ? cs.onPrimaryContainer : cs.onSurface;
                  final forma = RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: i == actual ? BorderSide(color: cs.primary, width: 2) : BorderSide.none,
                  );
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: 48,
                          child: Material(
                            color: fondo,
                            shape: forma,
                            child: InkWell(
                              customBorder: forma,
                              onTap: () => Navigator.pop(context, i),
                              child: Center(
                                child: Text('${i + 1}',
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
                              onTap: () => Navigator.pop(context, i),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(p.etiqueta,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: tt.bodyLarge?.copyWith(
                                                  color: texto, fontWeight: FontWeight.w700)),
                                          if (_resumen(p).isNotEmpty)
                                            Text(_resumen(p),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: tt.bodySmall?.copyWith(color: texto)),
                                        ],
                                      ),
                                    ),
                                    if (hecho) ...[
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
