import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../logic/geometria.dart';
import 'marcas_tablero.dart';
import 'pieza_contorno.dart';

final RegExp _coordenada = RegExp(r'\b([a-h][1-8])\b');

Piece? piezaDeFen(String c) => switch (c) {
      'P' => Piece.whitePawn,
      'N' => Piece.whiteKnight,
      'B' => Piece.whiteBishop,
      'R' => Piece.whiteRook,
      'Q' => Piece.whiteQueen,
      'K' => Piece.whiteKing,
      'p' => Piece.blackPawn,
      'n' => Piece.blackKnight,
      'b' => Piece.blackBishop,
      'r' => Piece.blackRook,
      'q' => Piece.blackQueen,
      'k' => Piece.blackKing,
      _ => null,
    };

/// Casillas nombradas en los textos (ej. "f6") que están vacías en el tablero del paso:
/// cada una recibe un color distinto (en orden de aparición) para el cuadradito del texto
/// y el puntito del tablero. [sinMarca] las excluye; [estrellas] son objetivos (★).
Map<String, Color> marcasDeTextos(
  List<String?> textos,
  String? fen, {
  Set<String> estrellas = const {},
  Iterable<String> sinMarca = const [],
}) {
  if (fen == null) return {};
  final tablero = parseTablero(fen);
  final excluidas = sinMarca.toSet();
  final res = <String, Color>{};
  for (final t in textos) {
    if (t == null) continue;
    for (final m in _coordenada.allMatches(t)) {
      final c = m.group(1)!;
      if (tablero.containsKey(c) || estrellas.contains(c) || excluidas.contains(c)) continue;
      res.putIfAbsent(c, () => kPaletaMarcas[res.length % kPaletaMarcas.length]);
    }
  }
  return res;
}

/// Texto de una lección: cada coordenada (ej. "f6") va seguida de la pieza que hay en
/// esa casilla o, si está vacía, de un cuadradito rojo (que también se marca en el tablero).
class TextoLeccion extends ConsumerWidget {
  const TextoLeccion(
    this.texto, {
    super.key,
    this.fen,
    this.estilo,
    this.estrellas = const {},
    this.marcas = const {},
    this.conCoordenadas = true,
    this.maxLines,
  });

  final String texto;
  final String? fen; // posición del tablero que ilustra el texto
  final TextStyle? estilo;
  final Set<String> estrellas; // casillas-objetivo (se indican con ★)
  final Map<String, Color> marcas; // casillas vacías nombradas, con su color
  final bool conCoordenadas;
  final int? maxLines;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final base = estilo ?? Theme.of(context).textTheme.bodyLarge;
    if (!conCoordenadas || fen == null || !_coordenada.hasMatch(texto)) {
      return Text(texto, style: base, maxLines: maxLines, overflow: maxLines == null ? null : TextOverflow.ellipsis);
    }
    final set = ref.watch(appearanceProvider.select((a) => a.pieceSet));
    final tablero = parseTablero(fen!);
    final lado = (base?.fontSize ?? 16) * 1.45;

    final spans = <InlineSpan>[];
    var desde = 0;
    for (final m in _coordenada.allMatches(texto)) {
      spans.add(TextSpan(text: texto.substring(desde, m.start)));
      final c = m.group(1)!;
      spans.add(TextSpan(text: c, style: const TextStyle(fontWeight: FontWeight.w700)));
      final ch = tablero[c];
      final Widget marca;
      if (ch != null && piezaDeFen(ch) != null) {
        final img = set.assets[piezaDeFen(ch)!.kind];
        marca = img == null
            ? const SizedBox.shrink()
            : PiezaContorno(imagen: img, size: lado, negra: ch == ch.toLowerCase());
      } else if (estrellas.contains(c)) {
        marca = Text('★', style: TextStyle(color: kDorado, fontSize: lado * 0.8, height: 1));
      } else if (marcas.containsKey(c)) {
        marca = Container(
          width: lado * 0.5,
          height: lado * 0.5,
          decoration: BoxDecoration(
            color: marcas[c],
            borderRadius: BorderRadius.circular(3),
          ),
        );
      } else {
        marca = const SizedBox.shrink(); // casilla sin pieza ni marca: solo el texto
      }
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: marca),
      ));
      desde = m.end;
    }
    spans.add(TextSpan(text: texto.substring(desde)));
    return Text.rich(TextSpan(style: base, children: spans),
        maxLines: maxLines, overflow: maxLines == null ? TextOverflow.clip : TextOverflow.ellipsis);
  }
}
