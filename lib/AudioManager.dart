import 'package:just_audio/just_audio.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  final AudioPlayer player = AudioPlayer();

  void initAudio() {
    player.setLoopMode(LoopMode.all);
    player.setVolume(0.5);
  }

  void dispose() {
    player.dispose();
  }
}