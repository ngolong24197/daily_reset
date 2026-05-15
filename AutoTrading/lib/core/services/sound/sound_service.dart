import 'package:audioplayers/audioplayers.dart';

enum ChimeLength { short, medium, long }

class SoundService {
  final AudioPlayer _player = AudioPlayer();

  Future<void> init() async {
    await _player.setReleaseMode(ReleaseMode.stop);
  }

  Future<void> playChime(ChimeLength length) async {
    final path = switch (length) {
      ChimeLength.short => 'sounds/chime_short.mp3',
      ChimeLength.medium => 'sounds/chime_medium.mp3',
      ChimeLength.long => 'sounds/chime_long.mp3',
    };
    try {
      await _player.play(AssetSource(path));
    } catch (_) {
      // Silently fail if sound can't play (e.g., silent mode)
    }
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}