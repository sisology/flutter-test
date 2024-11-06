import 'package:flutter/material.dart';
import 'AudioManager.dart';


class DiarySelectPage extends StatefulWidget {
  const DiarySelectPage({Key? key}) : super(key: key);

  @override
  _DiarySelectPageState createState() => _DiarySelectPageState();
}

class _DiarySelectPageState extends State<DiarySelectPage> {
  final audioManager = AudioManager();
  late bool isPlaying;
  late double volume;

  @override
  void initState() {
    super.initState();
    isPlaying = audioManager.player.playing;
    volume = audioManager.player.volume;

    audioManager.player.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          isPlaying = state.playing;
        });
      }
    });
  }

  void togglePlayPause() {
    if (isPlaying) {
      audioManager.player.pause();
    } else {
      audioManager.player.play();
    }
  }

  void changeVolume(double newVolume) {
    setState(() {
      volume = newVolume;
      audioManager.player.setVolume(newVolume);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('일기 선택 페이지'),
        actions: [
          IconButton(
            icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
            onPressed: togglePlayPause,
          ),
          Container(
            width: 150,
            child: Row(
              children: [
                Icon(Icons.volume_down, size: 20),
                Expanded(
                  child: Slider(
                    value: volume,
                    min: 0.0,
                    max: 1.0,
                    onChanged: changeVolume,
                  ),
                ),
                Icon(Icons.volume_up, size: 20),
              ],
            ),
          ),
        ],
      ),
      body: Center(
        child: Text(
          '일기 선택 페이지입니다.',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}