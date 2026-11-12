import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Barrita compacta con todos los ejercicios de la categoría.
/// Con pocos ejercicios se reparte a lo ancho; con muchos, se desplaza
/// horizontalmente y se centra sola en el ejercicio actual.
class ExerciseStrip extends StatefulWidget {
  const ExerciseStrip({
    super.key,
    required this.completadas,
    required this.actual,
    required this.onTap,
  });

  final List<bool> completadas; // una entrada por ejercicio
  final int actual;
  final ValueChanged<int> onTap;

  @override
  State<ExerciseStrip> createState() => _ExerciseStripState();
}

class _ExerciseStripState extends State<ExerciseStrip> {
  static const double _celdaMin = 36;
  static const double _alto = 30;
  final _ctrl = ScrollController();
  int? _centrado;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _centrar(double celda, double viewport) {
    if (_centrado == widget.actual) return;
    _centrado = widget.actual;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_ctrl.hasClients) return;
      final objetivo = widget.actual * celda - (viewport - celda) / 2;
      _ctrl.animateTo(
        objetivo.clamp(0.0, _ctrl.position.maxScrollExtent),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final n = widget.completadas.length;

    return LayoutBuilder(builder: (context, c) {
      final cabe = n * _celdaMin <= c.maxWidth;
      final celda = cabe ? c.maxWidth / n : _celdaMin;
      if (!cabe) _centrar(celda, c.maxWidth);

      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: _alto,
          child: SingleChildScrollView(
            controller: _ctrl,
            scrollDirection: Axis.horizontal,
            physics: cabe ? const NeverScrollableScrollPhysics() : null,
            child: Row(
              children: [
                for (var i = 0; i < n; i++)
                  _Celda(
                    numero: i + 1,
                    ancho: celda,
                    alto: _alto,
                    actual: i == widget.actual,
                    hecha: widget.completadas[i],
                    ultima: i == n - 1,
                    onTap: () => widget.onTap(i),
                    cs: cs,
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _Celda extends StatelessWidget {
  const _Celda({
    required this.numero,
    required this.ancho,
    required this.alto,
    required this.actual,
    required this.hecha,
    required this.ultima,
    required this.onTap,
    required this.cs,
  });

  final int numero;
  final double ancho, alto;
  final bool actual, hecha, ultima;
  final VoidCallback onTap;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final Color fondo;
    final Color texto;
    if (actual) {
      fondo = cs.primary;
      texto = cs.onPrimary;
    } else if (hecha) {
      fondo = cs.primaryContainer;
      texto = cs.onPrimaryContainer;
    } else {
      fondo = cs.surfaceContainerHighest;
      texto = cs.onSurfaceVariant;
    }
    return Semantics(
      button: true,
      selected: actual,
      label: 'Ejercicio $numero${hecha ? ", resuelto" : ""}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: ancho,
          height: alto,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fondo,
            border: ultima
                ? null
                : Border(right: BorderSide(color: cs.surface, width: 1.5)),
          ),
          child: Text(
            '$numero',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: texto,
                  fontWeight: actual ? FontWeight.w700 : FontWeight.w500,
                ),
          ),
        ),
      ),
    );
  }
}
