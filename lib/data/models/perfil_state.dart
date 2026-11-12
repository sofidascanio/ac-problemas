/// Perfil local del usuario (sin cuenta ni servidor).
class PerfilState {
  const PerfilState({
    this.nombre = '',
    this.simbolo = 'wN',
    this.iconoSet = '',
    this.ocultas = const {},
    this.mostrarPromedio = true,
  });

  static const maxNombre = 40;

  final String nombre; // vacío => se muestra "Ajedrez"
  final String simbolo; // color + pieza: wP wN wB wR wQ wK / bP bN bB bR bQ bK

  /// Set de piezas con el que se dibuja el ícono (nombre del PieceSet). Vacío => el
  /// set elegido en Apariencia.
  final String iconoSet;
  final Set<String> ocultas; // ids de secciones cuyo progreso NO se muestra
  final bool mostrarPromedio; // "Promedio por ejercicio" en la tarjeta de progreso

  String get nombreVisible => nombre.trim().isEmpty ? 'Ajedrez' : nombre.trim();

  PerfilState copyWith({
    String? nombre,
    String? simbolo,
    String? iconoSet,
    Set<String>? ocultas,
    bool? mostrarPromedio,
  }) =>
      PerfilState(
        nombre: nombre ?? this.nombre,
        simbolo: simbolo ?? this.simbolo,
        iconoSet: iconoSet ?? this.iconoSet,
        ocultas: ocultas ?? this.ocultas,
        mostrarPromedio: mostrarPromedio ?? this.mostrarPromedio,
      );
}
