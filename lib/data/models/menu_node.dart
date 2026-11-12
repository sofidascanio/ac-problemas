/// Nodo del menú, cargado desde assets/data/menu.json.
/// Hoja con [asset] => categoría de actividades (assets/data/<asset>.json).
/// Hoja sin [asset] => pantalla especial / placeholder (ej. disposición del tablero).
class MenuNode {
  const MenuNode({
    required this.id,
    required this.titulo,
    required this.icono,
    this.asset,
    this.pantalla,
    this.lista = false,
    this.leccion = false,
    this.hijos = const [],
  });

  final String id; // también es la clave de progreso
  final String titulo;
  final String icono;
  final String? asset;
  final String? pantalla;

  /// true => al tocar la hoja se abre primero el listado de problemas
  /// (número + nombre) en vez de ir directo al primer ejercicio.
  final bool lista;

  /// true => la hoja es una lección guiada (formato de lección, no de actividades).
  final bool leccion;
  final List<MenuNode> hijos;

  bool get esHoja => hijos.isEmpty;

  factory MenuNode.fromJson(Map<String, dynamic> j) => MenuNode(
        id: j['id'] as String,
        titulo: j['titulo'] as String,
        icono: (j['icono'] as String?) ?? 'circle',
        asset: j['asset'] as String?,
        pantalla: j['pantalla'] as String?,
        lista: (j['lista'] as bool?) ?? false,
        leccion: (j['leccion'] as bool?) ?? false,
        hijos: ((j['hijos'] as List?) ?? const [])
            .map((e) => MenuNode.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
