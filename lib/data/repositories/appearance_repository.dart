import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/appearance_state.dart';
import '../models/tema_tablero.dart';

abstract class AppearanceRepository {
  AppearanceState cargar();
  Future<void> guardar(AppearanceState estado);
}

class SharedPrefsAppearanceRepository implements AppearanceRepository {
  SharedPrefsAppearanceRepository(this._prefs);
  final SharedPreferences _prefs;

  static const _kBoard = 'apariencia.boardTheme';
  static const _kPieces = 'apariencia.pieceSet';
  static const _kMode = 'apariencia.themeMode';
  static const _kSonido = 'apariencia.sonido';

  @override
  AppearanceState cargar() {
    const d = AppearanceState.defaults;
    return AppearanceState(
      boardTheme: TemaTablero.values.firstWhere(
          (e) => e.name == _prefs.getString(_kBoard),
          orElse: () => d.boardTheme),
      pieceSet: PieceSet.values.firstWhere(
          (e) => e.name == _prefs.getString(_kPieces),
          orElse: () => d.pieceSet),
      themeMode: ThemeMode.values.firstWhere(
          (e) => e.name == _prefs.getString(_kMode),
          orElse: () => d.themeMode),
      sonido: _prefs.getBool(_kSonido) ?? d.sonido,
    );
  }

  @override
  Future<void> guardar(AppearanceState e) async {
    await _prefs.setString(_kBoard, e.boardTheme.name);
    await _prefs.setString(_kPieces, e.pieceSet.name);
    await _prefs.setString(_kMode, e.themeMode.name);
    await _prefs.setBool(_kSonido, e.sonido);
  }
}
