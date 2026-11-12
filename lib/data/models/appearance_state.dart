import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'tema_tablero.dart';

class AppearanceState {
  const AppearanceState({
    required this.boardTheme,
    required this.pieceSet,
    required this.themeMode,
    this.sonido = true,
  });

  final TemaTablero boardTheme;
  final PieceSet pieceSet;
  final ThemeMode themeMode;
  final bool sonido; // efectos de sonido activados

  static const defaults = AppearanceState(
    boardTheme: TemaTablero.brown,
    pieceSet: PieceSet.cburnett,
    themeMode: ThemeMode.system,
  );

  AppearanceState copyWith({
    TemaTablero? boardTheme,
    PieceSet? pieceSet,
    ThemeMode? themeMode,
    bool? sonido,
  }) =>
      AppearanceState(
        boardTheme: boardTheme ?? this.boardTheme,
        pieceSet: pieceSet ?? this.pieceSet,
        themeMode: themeMode ?? this.themeMode,
        sonido: sonido ?? this.sonido,
      );

  /// Settings para el tablero interactivo.
  ChessboardSettings get boardSettings => ChessboardSettings(
        colorScheme: boardTheme.colores,
        pieceAssets: pieceSet.assets,
      );

  /// Settings para tableros de solo lectura (StaticChessboard).
  StaticChessboardSettings get staticSettings =>
      StaticChessboardSettings.fromBoardSettings(boardSettings);
}
