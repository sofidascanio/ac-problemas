import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Progreso por categoría: ejercicios resueltos, tiempo dedicado a cada uno y
/// último ejercicio visitado. Detrás de una interfaz para poder pasar a SQLite.
abstract class ProgressRepository {
  Set<String> completadas(String categoriaId);
  Future<void> marcarCompletada(String categoriaId, String actividadId);
  Future<void> reiniciar(String categoriaId);

  /// Borra TODO el progreso de todas las categorías (resueltos, tiempos, intentos, conteo por día).
  Future<void> reiniciarTodo();

  /// Segundos acumulados en un ejercicio (0 si nunca se abrió).
  int segundos(String categoriaId, String actividadId);

  /// Segundos de todos los ejercicios abiertos de la categoría (id -> segundos).
  Map<String, int> todosSegundos(String categoriaId);
  Future<void> guardarSegundos(String categoriaId, String actividadId, int segundos);

  String? ultimoVisitado(String categoriaId);
  Future<void> guardarUltimoVisitado(String categoriaId, String actividadId);

  /// Intentos (jugadas hechas) por paso hasta resolver el problema, ej. [2, 1].
  /// Null si no hay registro (problemas resueltos antes de existir esta estadística).
  List<int>? intentosDe(String categoriaId, String actividadId);
  Future<void> guardarIntentos(String categoriaId, String actividadId, List<int> intentos);

  /// Ejercicios resueltos por primera vez, por día ("2026-10-06" -> cantidad).
  Map<String, int> resueltosPorDia(String categoriaId);
  Future<void> sumarResueltoHoy(String categoriaId);
}

class SharedPrefsProgressRepository implements ProgressRepository {
  SharedPrefsProgressRepository(this._prefs);
  final SharedPreferences _prefs;

  // Los tiempos se guardan por categoría en un solo texto JSON {"id": segundos}
  // y solo contienen los ejercicios que se abrieron: pesan unos pocos KB.
  final Map<String, Map<String, int>> _tiempos = {};

  String _key(String c) => 'progreso.$c';
  String _keyTiempos(String c) => 'tiempos.$c';
  String _keyUltimo(String c) => 'ultimo.$c';
  String _keyDias(String c) => 'dias.$c';
  String _keyIntentos(String c) => 'intentos.$c';

  static String claveDia(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Set<String> completadas(String categoriaId) =>
      (_prefs.getStringList(_key(categoriaId)) ?? const []).toSet();

  @override
  Future<void> marcarCompletada(String categoriaId, String actividadId) async {
    final set = completadas(categoriaId)..add(actividadId);
    await _prefs.setStringList(_key(categoriaId), set.toList());
  }

  @override
  Future<void> reiniciar(String categoriaId) async {
    _tiempos.remove(categoriaId);
    await _prefs.remove(_key(categoriaId));
    await _prefs.remove(_keyTiempos(categoriaId));
    await _prefs.remove(_keyUltimo(categoriaId));
    await _prefs.remove(_keyDias(categoriaId));
    await _prefs.remove(_keyIntentos(categoriaId));
  }

  @override
  Future<void> reiniciarTodo() async {
    const prefijos = ['progreso.', 'tiempos.', 'ultimo.', 'dias.', 'intentos.'];
    for (final k in _prefs.getKeys().toList()) {
      if (prefijos.any(k.startsWith)) await _prefs.remove(k);
    }
    _tiempos.clear();
  }

  Map<String, int> _cargarTiempos(String categoriaId) =>
      _tiempos.putIfAbsent(categoriaId, () {
        try {
          final raw = _prefs.getString(_keyTiempos(categoriaId));
          if (raw == null) return <String, int>{};
          return (jsonDecode(raw) as Map<String, dynamic>)
              .map((k, v) => MapEntry(k, (v as num).toInt()));
        } catch (_) {
          return <String, int>{}; // dato corrupto: se empieza de cero
        }
      });

  @override
  int segundos(String categoriaId, String actividadId) =>
      _cargarTiempos(categoriaId)[actividadId] ?? 0;

  @override
  Map<String, int> todosSegundos(String categoriaId) =>
      Map.unmodifiable(_cargarTiempos(categoriaId));

  @override
  Future<void> guardarSegundos(String categoriaId, String actividadId, int segundos) async {
    final mapa = _cargarTiempos(categoriaId);
    if (mapa[actividadId] == segundos) return;
    mapa[actividadId] = segundos;
    await _prefs.setString(_keyTiempos(categoriaId), jsonEncode(mapa));
  }

  @override
  String? ultimoVisitado(String categoriaId) => _prefs.getString(_keyUltimo(categoriaId));

  @override
  Future<void> guardarUltimoVisitado(String categoriaId, String actividadId) async {
    await _prefs.setString(_keyUltimo(categoriaId), actividadId);
  }

  @override
  Map<String, int> resueltosPorDia(String categoriaId) {
    try {
      final raw = _prefs.getString(_keyDias(categoriaId));
      if (raw == null) return {};
      return (jsonDecode(raw) as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (_) {
      return {};
    }
  }

  @override
  Future<void> sumarResueltoHoy(String categoriaId) async {
    final mapa = resueltosPorDia(categoriaId);
    final hoy = claveDia(DateTime.now());
    mapa[hoy] = (mapa[hoy] ?? 0) + 1;
    // se guardan solo los últimos ~90 días: alcanza para "hoy" y "esta semana"
    final limite = claveDia(DateTime.now().subtract(const Duration(days: 90)));
    mapa.removeWhere((k, _) => k.compareTo(limite) < 0);
    await _prefs.setString(_keyDias(categoriaId), jsonEncode(mapa));
  }

  Map<String, dynamic> _cargarIntentos(String categoriaId) {
    try {
      final raw = _prefs.getString(_keyIntentos(categoriaId));
      return raw == null ? <String, dynamic>{} : jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  @override
  List<int>? intentosDe(String categoriaId, String actividadId) {
    final v = _cargarIntentos(categoriaId)[actividadId];
    return v is List ? v.map((e) => (e as num).toInt()).toList() : null;
  }

  @override
  Future<void> guardarIntentos(String categoriaId, String actividadId, List<int> intentos) async {
    final mapa = _cargarIntentos(categoriaId);
    mapa[actividadId] = intentos;
    await _prefs.setString(_keyIntentos(categoriaId), jsonEncode(mapa));
  }
}
