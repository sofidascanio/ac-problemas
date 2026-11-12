import 'dart:convert';
import 'package:flutter/services.dart' show AssetManifest, rootBundle;
import '../models/actividad.dart';
import '../models/leccion.dart';
import '../models/menu_node.dart';

abstract class ContentRepository {
  Future<List<MenuNode>> cargarMenu();
  Future<List<Actividad>> cargarActividades(String asset);
  Future<Leccion?> cargarLeccion(String asset);
}

/// Carga lazy por categoría, con caché en memoria.
class AssetContentRepository implements ContentRepository {
  final Map<String, List<Actividad>> _cache = {};
  final Map<String, Leccion?> _cacheLecciones = {};

  static const _base = 'assets/data/';

  /// Carga menu.json y expande los nodos con `"carpeta"`: cada archivo .json
  /// de esa carpeta (assets/data/<carpeta>/) aparece como una subcategoría con
  /// listado. Las hojas escritas a mano en `hijos` tienen prioridad (conservan
  /// su id y su progreso) y se muestran primero.
  @override
  Future<List<MenuNode>> cargarMenu() async {
    final raw = await rootBundle.loadString('${_base}menu.json');
    final json = jsonDecode(raw) as List;
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = manifest.listAssets();
    return json
        .map((e) => MenuNode.fromJson(_expandir(e as Map<String, dynamic>, assets)))
        .toList();
  }

  Map<String, dynamic> _expandir(Map<String, dynamic> nodo, List<String> assets) {
    final hijos = [
      for (final h in (nodo['hijos'] as List? ?? const []))
        _expandir(h as Map<String, dynamic>, assets),
    ];

    final carpeta = nodo['carpeta'] as String?;
    if (carpeta != null) {
      final prefijo = '$_base${carpeta.replaceAll(RegExp(r'^/+|/+$'), '')}/';
      final yaDeclarados = {
        for (final h in hijos)
          if (h['asset'] != null) h['asset'] as String,
      };
      final archivos = assets
          .where((a) =>
              a.startsWith(prefijo) &&
              a.endsWith('.json') &&
              !a.substring(prefijo.length).contains('/'))
          .toList()
        ..sort((a, b) => _comparaNatural(a, b));

      for (final ruta in archivos) {
        final asset = ruta.substring(_base.length, ruta.length - '.json'.length);
        if (yaDeclarados.contains(asset)) continue;
        hijos.add({
          'id': asset.replaceAll('/', '_'), // clave del progreso: estable mientras no muevas el archivo
          'titulo': _tituloDesdeArchivo(asset.split('/').last),
          'icono': 'menu_book',
          'asset': asset,
          'lista': true,
        });
      }
    }
    return {...nodo, 'hijos': hijos};
  }

  /// "libro_2" -> "Libro 2"
  static String _tituloDesdeArchivo(String nombre) {
    final limpio = nombre.replaceAll(RegExp(r'[_\-]+'), ' ').trim();
    if (limpio.isEmpty) return nombre;
    return limpio[0].toUpperCase() + limpio.substring(1);
  }

  /// Orden "natural": libro_2 antes que libro_10.
  static int _comparaNatural(String a, String b) {
    final re = RegExp(r'(\d+)|(\D+)');
    final pa = re.allMatches(a.toLowerCase()).map((m) => m.group(0)!).toList();
    final pb = re.allMatches(b.toLowerCase()).map((m) => m.group(0)!).toList();
    for (var i = 0; i < pa.length && i < pb.length; i++) {
      final na = int.tryParse(pa[i]);
      final nb = int.tryParse(pb[i]);
      final c = (na != null && nb != null) ? na.compareTo(nb) : pa[i].compareTo(pb[i]);
      if (c != 0) return c;
    }
    return pa.length.compareTo(pb.length);
  }

  @override
  Future<List<Actividad>> cargarActividades(String asset) async {
    final cached = _cache[asset];
    if (cached != null) return cached;
    try {
      final raw = await rootBundle.loadString('$_base$asset.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final lista = (json['actividades'] as List)
          .map((e) => Actividad.fromJson(e as Map<String, dynamic>))
          .toList();
      return _cache[asset] = lista;
    } catch (_) {
      // Categoría sin contenido todavía => "Próximamente".
      // TODO: distinguir asset inexistente de JSON malformado (log en debug).
      return _cache[asset] = const [];
    }
  }

  @override
  Future<Leccion?> cargarLeccion(String asset) async {
    if (_cacheLecciones.containsKey(asset)) return _cacheLecciones[asset];
    try {
      final raw = await rootBundle.loadString('$_base$asset.json');
      return _cacheLecciones[asset] =
          Leccion.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Lección sin contenido todavía => "Próximamente".
      return _cacheLecciones[asset] = null;
    }
  }
}
