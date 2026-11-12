import 'package:chessground/chessground.dart';

/// Temas de tablero disponibles en la app.
/// (chessground 10 expone `ChessboardColorScheme` como constantes, no como enum;
/// este enum propio da lista, etiqueta y clave estable para guardar en preferencias.)
enum TemaTablero {
  brown('Marrón', ChessboardColorScheme.brown),
  blue('Azul', ChessboardColorScheme.blue),
  blue2('Azul 2', ChessboardColorScheme.blue2),
  green('Verde', ChessboardColorScheme.green),
  purple('Violeta', ChessboardColorScheme.purple),
  grey('Gris', ChessboardColorScheme.grey),
  olive('Oliva', ChessboardColorScheme.olive),
  wood('Madera', ChessboardColorScheme.wood),
  wood2('Madera 2', ChessboardColorScheme.wood2),
  marble('Mármol', ChessboardColorScheme.marble),
  metal('Metal', ChessboardColorScheme.metal),
  newspaper('Diario', ChessboardColorScheme.newspaper);

  const TemaTablero(this.label, this.colores);
  final String label;
  final ChessboardColorScheme colores;
}
