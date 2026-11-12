import 'package:audioplayers/audioplayers.dart';

enum Sonido { mover, capturar, correcto, incorrecto }

/// Reproduce los efectos de sonido. Nunca lanza: si el audio falla (emulador
/// sin sonido, archivo ausente) simplemente no suena.
class SoundService {
  SoundService(this._activado);
  final bool Function() _activado;

  static const _archivos = {
    Sonido.mover: 'sounds/move.mp3',
    Sonido.capturar: 'sounds/capture.mp3',
    Sonido.correcto: 'sounds/correct.wav',
    Sonido.incorrecto: 'sounds/incorrect.wav',
  };

  final Map<Sonido, AudioPlayer> _players = {};

  Future<void> reproducir(Sonido s, {Duration demora = Duration.zero}) async {
    if (!_activado()) return;
    try {
      if (demora > Duration.zero) await Future<void>.delayed(demora);
      final p = _players.putIfAbsent(s, () {
        final nuevo = AudioPlayer();
        nuevo.setPlayerMode(PlayerMode.lowLatency);
        return nuevo;
      });
      await p.stop();
      await p.play(AssetSource(_archivos[s]!));
    } catch (_) {
      // sin audio: no pasa nada
    }
  }

  void dispose() {
    for (final p in _players.values) {
      p.dispose();
    }
    _players.clear();
  }
}
