enum PropiedadJugada {
  daJaque,
  esMate,
  esCaptura,
  esEnroque,
  esAlPaso,
  cualquierLegal,
  dejaPiezaDefendida,
}

sealed class Actividad {
  const Actividad({required this.id, required this.fen, this.nombre, this.numero});
  final String id;
  final String fen;

  /// Nombre a mostrar (ej. la partida de origen). Opcional.
  final String? nombre;

  /// Número del problema en su fuente (ej. el del libro). Si falta, se usa la posición en la lista.
  final int? numero;

  factory Actividad.fromJson(Map<String, dynamic> json) {
    final tipo = json['tipo'] as String?;
    switch (tipo) {
      case 'secuencia_exacta':
        return SecuenciaExacta.fromJson(json);
      case 'jugada_con_propiedad':
        return JugadaConPropiedad.fromJson(json);
      case 'trivia':
        return Trivia.fromJson(json);
      default:
        throw FormatException('Tipo de actividad desconocido: $tipo');
    }
  }
}

class SecuenciaExacta extends Actividad {
  const SecuenciaExacta({
    required super.id,
    required super.fen,
    super.nombre,
    super.numero,
    required this.solucionUci,
  });

  /// Jugadas alternadas en UCI; la primera es del usuario.
  final List<String> solucionUci;

  factory SecuenciaExacta.fromJson(Map<String, dynamic> j) => SecuenciaExacta(
        id: j['id'] as String,
        fen: j['fen'] as String,
        nombre: j['nombre'] as String?,
        numero: j['numero'] as int?,
        solucionUci: (j['solucionUci'] as List).cast<String>(),
      );
}

class JugadaConPropiedad extends Actividad {
  const JugadaConPropiedad({
    required super.id,
    required super.fen,
    super.nombre,
    super.numero,
    required this.propiedad,
  });
  final PropiedadJugada propiedad;

  factory JugadaConPropiedad.fromJson(Map<String, dynamic> j) =>
      JugadaConPropiedad(
        id: j['id'] as String,
        fen: j['fen'] as String,
        nombre: j['nombre'] as String?,
        numero: j['numero'] as int?,
        propiedad: PropiedadJugada.values.byName(j['propiedad'] as String),
      );
}

class Trivia extends Actividad {
  const Trivia({
    required super.id,
    required super.fen,
    super.nombre,
    super.numero,
    required this.opciones,
    required this.respuestaCorrecta,
  });
  final List<String> opciones;
  final int respuestaCorrecta;

  factory Trivia.fromJson(Map<String, dynamic> j) => Trivia(
        id: j['id'] as String,
        fen: j['fen'] as String,
        nombre: j['nombre'] as String?,
        numero: j['numero'] as int?,
        opciones: (j['opciones'] as List).cast<String>(),
        respuestaCorrecta: j['respuestaCorrecta'] as int,
      );
}
