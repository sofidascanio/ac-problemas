import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../data/models/tema_tablero.dart';
import 'opcion_visual.dart';

class AparienciaScreen extends ConsumerWidget {
  const AparienciaScreen({super.key});

  // Posición de ejemplo para la vista previa grande.
  static const _fenPreview =
      'r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4';
  static const _fenVacio = '8/8/8/8/8/8/8/8';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = ref.watch(appearanceProvider);
    final notif = ref.read(appearanceProvider.notifier);
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Apariencia')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Tema', style: tt.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.system, label: Text('Sistema')),
              ButtonSegment(value: ThemeMode.light, label: Text('Claro')),
              ButtonSegment(value: ThemeMode.dark, label: Text('Oscuro')),
            ],
            selected: {a.themeMode},
            onSelectionChanged: (s) => notif.actualizar(a.copyWith(themeMode: s.first)),
          ),
          const SizedBox(height: 16),
          Center(
            child: StaticChessboard(
              size: MediaQuery.sizeOf(context).width - 32,
              fen: _fenPreview,
              orientation: Side.white,
              settings: a.staticSettings,
            ),
          ),
          const SizedBox(height: 24),
          Text('Tablero', style: tt.titleMedium),
          const SizedBox(height: 8),
          Wrap(spacing: 10, runSpacing: 10, children: [
            for (final t in TemaTablero.values)
              OpcionVisual(
                etiqueta: t.label,
                seleccionada: a.boardTheme == t,
                onTap: () => notif.actualizar(a.copyWith(boardTheme: t)),
                child: StaticChessboard(
                  size: OpcionVisual.lado,
                  fen: _fenVacio,
                  orientation: Side.white,
                  settings: StaticChessboardSettings.fromBoardSettings(
                    ChessboardSettings(
                      colorScheme: t.colores,
                      pieceAssets: a.pieceSet.assets,
                    ),
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 24),
          Text('Piezas', style: tt.titleMedium),
          const SizedBox(height: 8),
          Wrap(spacing: 10, runSpacing: 10, children: [
            for (final p in PieceSet.values)
              OpcionVisual(
                etiqueta: p.label,
                seleccionada: a.pieceSet == p,
                onTap: () => notif.actualizar(a.copyWith(pieceSet: p)),
                child: ColoredBox(
                  color: cs.surfaceContainerHighest,
                  child: Center(child: PiezaPreview(set: p)),
                ),
              ),
          ]),
        ],
      ),
    );
  }
}

