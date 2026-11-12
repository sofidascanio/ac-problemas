import 'actividad.dart';

/// Una lección es una secuencia de pasos (explicación, exploración, minijuegos).
/// Formato aparte del de las actividades de "Mate en N":
///   { "leccion": { "pasos": [ { "tipo": "...", "id": "...", ... } ] } }
/// Todos los pasos cuentan para el progreso (también los teóricos).
sealed class Paso {
  const Paso({required this.id, this.texto, this.coordenadas = true, this.sinMarca = const []});
  final String id; // único dentro de la lección
  final String? texto; // explicación que se muestra con el paso

  /// false => no dibujar piezas/cuadraditos junto a las coordenadas del texto
  /// ni marcarlas en el tablero (ej. cuando se habla de filas y columnas en general).
  final bool coordenadas;

  /// Casillas nombradas en el texto que NO se marcan (ni cuadradito ni punto en el tablero).
  final List<String> sinMarca;

  /// id con el que el paso cuenta para el progreso.
  String get idProgreso => id;

  /// FEN del tablero que muestra el paso (si tiene), para ilustrar las coordenadas del texto.
  String? get fenTablero => null;

  /// Nombre corto para el listado de pasos.
  String get etiqueta;

  factory Paso.fromJson(Map<String, dynamic> j) {
    final tipo = j['tipo'] as String?;
    switch (tipo) {
      case 'texto':
        return PasoTexto.fromJson(j);
      case 'explorar':
        return PasoExplorar.fromJson(j);
      case 'alcanzar':
        return PasoAlcanzar.fromJson(j);
      case 'actividad':
        return PasoActividad.fromJson(j);
      case 'colocar':
        return PasoColocar.fromJson(j);
      default:
        throw FormatException('Tipo de paso desconocido: $tipo');
    }
  }
}

/// Fila de una tabla ilustrada: una pieza (carácter FEN) y su valor.
class FilaValor {
  const FilaValor({required this.pieza, required this.nombre, required this.valor});
  final String pieza; // P N B R Q K (mayúscula = blancas)
  final String nombre;
  final String valor;

  factory FilaValor.fromJson(Map<String, dynamic> j) => FilaValor(
        pieza: j['pieza'] as String,
        nombre: (j['nombre'] as String?) ?? '',
        valor: (j['valor'] as String?) ?? '',
      );
}

/// Explicación con tablero opcional (solo lectura), casillas resaltadas y,
/// si hace falta, una tabla de piezas entre dos textos.
class PasoTexto extends Paso {
  const PasoTexto({
    required super.id,
    super.texto,
    super.coordenadas,
    super.sinMarca,
    this.fen,
    this.resaltar = const [],
    this.tabla = const [],
    this.textoDespues,
  });
  final String? fen;
  final List<String> resaltar;
  final List<FilaValor> tabla;
  final String? textoDespues; // se muestra debajo de la tabla

  @override
  String? get fenTablero => fen;

  @override
  String get etiqueta => 'Explicación';

  factory PasoTexto.fromJson(Map<String, dynamic> j) => PasoTexto(
        id: j['id'] as String,
        texto: j['texto'] as String?,
        coordenadas: (j['coordenadas'] as bool?) ?? true,
        sinMarca: ((j['sinMarca'] as List?) ?? const []).cast<String>(),
        fen: j['fen'] as String?,
        resaltar: ((j['resaltar'] as List?) ?? const []).cast<String>(),
        tabla: ((j['tabla'] as List?) ?? const [])
            .map((e) => FilaValor.fromJson(e as Map<String, dynamic>))
            .toList(),
        textoDespues: j['textoDespues'] as String?,
      );
}

/// Tablero libre: se mueve la pieza y se ven a dónde puede ir.
class PasoExplorar extends Paso {
  const PasoExplorar({
    required super.id,
    super.texto,
    super.coordenadas,
    super.sinMarca,
    required this.fen,
    required this.pieza,
    this.alCapturar,
  });
  final String fen;
  final String pieza; // casilla de la pieza protagonista, ej. "d4"

  /// Texto del cartel que aparece al capturar una pieza en este paso.
  final String? alCapturar;

  @override
  String? get fenTablero => fen;

  @override
  String get etiqueta => 'Exploración';

  factory PasoExplorar.fromJson(Map<String, dynamic> j) => PasoExplorar(
        id: j['id'] as String,
        texto: j['texto'] as String?,
        coordenadas: (j['coordenadas'] as bool?) ?? true,
        sinMarca: ((j['sinMarca'] as List?) ?? const []).cast<String>(),
        fen: j['fen'] as String,
        pieza: j['pieza'] as String,
        alCapturar: j['alCapturar'] as String?,
      );
}

/// Minijuego: llevar la pieza a todas las estrellas (o capturar las piezas marcadas).
class PasoAlcanzar extends Paso {
  const PasoAlcanzar({
    required super.id,
    super.texto,
    super.coordenadas,
    super.sinMarca,
    required this.fen,
    required this.pieza,
    required this.objetivos,
    this.ayuda = false,
  });
  final String fen;
  final String pieza;
  final List<String> objetivos;

  /// true => se muestran siempre las casillas a las que puede ir.
  final bool ayuda;

  @override
  String? get fenTablero => fen;

  @override
  String get etiqueta => 'Desafío';

  factory PasoAlcanzar.fromJson(Map<String, dynamic> j) => PasoAlcanzar(
        id: j['id'] as String,
        texto: j['texto'] as String?,
        coordenadas: (j['coordenadas'] as bool?) ?? true,
        sinMarca: ((j['sinMarca'] as List?) ?? const []).cast<String>(),
        fen: j['fen'] as String,
        pieza: j['pieza'] as String,
        objetivos: (j['objetivos'] as List).cast<String>(),
        ayuda: (j['ayuda'] as bool?) ?? false,
      );
}

/// Una actividad con reglas reales de ajedrez (las mismas de Mate en N / Fundamentos),
/// con comentario bajo el tablero y explicación al resolverla.
class PasoActividad extends Paso {
  const PasoActividad({
    required super.id,
    super.texto,
    super.coordenadas,
    super.sinMarca,
    required this.actividad,
    this.comentario,
    this.exito,
  });
  final Actividad actividad;
  final String? comentario; // siempre visible bajo el tablero
  final String? exito; // se muestra al resolverla

  @override
  String get idProgreso => actividad.id;

  @override
  String? get fenTablero => actividad.fen;

  @override
  String get etiqueta => 'Actividad';

  factory PasoActividad.fromJson(Map<String, dynamic> j) => PasoActividad(
        id: (j['id'] as String?) ?? (j['actividad'] as Map)['id'] as String,
        texto: j['texto'] as String?,
        coordenadas: (j['coordenadas'] as bool?) ?? true,
        sinMarca: ((j['sinMarca'] as List?) ?? const []).cast<String>(),
        actividad: Actividad.fromJson(j['actividad'] as Map<String, dynamic>),
        comentario: j['comentario'] as String?,
        exito: j['exito'] as String?,
      );
}

/// Simulación: colocar cada pieza en su casilla inicial (en orden aleatorio).
class PasoColocar extends Paso {
  const PasoColocar({
    required super.id,
    super.texto,
    super.coordenadas,
    super.sinMarca,
    required this.blancas,
    this.fen,
  });
  final bool blancas; // true: se colocan las blancas
  final String? fen; // piezas ya puestas al empezar (ej. las blancas, para colocar las negras)

  @override
  String get etiqueta => blancas ? 'Colocar las blancas' : 'Colocar las negras';

  factory PasoColocar.fromJson(Map<String, dynamic> j) => PasoColocar(
        id: j['id'] as String,
        texto: j['texto'] as String?,
        coordenadas: (j['coordenadas'] as bool?) ?? true,
        sinMarca: ((j['sinMarca'] as List?) ?? const []).cast<String>(),
        blancas: (j['color'] as String? ?? 'w') == 'w',
        fen: j['fen'] as String?,
      );
}

class Leccion {
  const Leccion({required this.pasos});
  final List<Paso> pasos;

  /// ids de todos los pasos: el progreso cuenta la teoría y las actividades.
  Set<String> get idsProgreso => {for (final p in pasos) p.idProgreso};

  factory Leccion.fromJson(Map<String, dynamic> j) {
    final raiz = (j['leccion'] as Map<String, dynamic>?) ?? j;
    return Leccion(
      pasos: (raiz['pasos'] as List)
          .map((e) => Paso.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
