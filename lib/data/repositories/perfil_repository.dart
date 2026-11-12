import 'package:shared_preferences/shared_preferences.dart';
import '../models/perfil_state.dart';

abstract class PerfilRepository {
  PerfilState cargar();
  Future<void> guardar(PerfilState perfil);
}

class SharedPrefsPerfilRepository implements PerfilRepository {
  SharedPrefsPerfilRepository(this._prefs);
  final SharedPreferences _prefs;

  static const _kNombre = 'perfil.nombre';
  static const _kSimbolo = 'perfil.simbolo';
  static const _kIconoSet = 'perfil.iconoSet';
  static const _kOcultas = 'perfil.ocultas';
  static const _kPromedio = 'perfil.mostrarPromedio';

  @override
  PerfilState cargar() {
    final nombre = _prefs.getString(_kNombre) ?? '';
    return PerfilState(
      nombre: nombre.length > PerfilState.maxNombre
          ? nombre.substring(0, PerfilState.maxNombre)
          : nombre,
      simbolo: _prefs.getString(_kSimbolo) ?? const PerfilState().simbolo,
      iconoSet: _prefs.getString(_kIconoSet) ?? '',
      ocultas: (_prefs.getStringList(_kOcultas) ?? const []).toSet(),
      mostrarPromedio: _prefs.getBool(_kPromedio) ?? true,
    );
  }

  @override
  Future<void> guardar(PerfilState p) async {
    await _prefs.setString(_kNombre, p.nombre);
    await _prefs.setString(_kSimbolo, p.simbolo);
    await _prefs.setString(_kIconoSet, p.iconoSet);
    await _prefs.setStringList(_kOcultas, p.ocultas.toList());
    await _prefs.setBool(_kPromedio, p.mostrarPromedio);
  }
}
