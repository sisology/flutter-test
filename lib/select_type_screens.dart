import 'package:flutter/material.dart';
import 'package:wisely_diary/record_screens.dart';
import 'package:wisely_diary/text_screens.dart';
import 'AudioManager.dart';

class SelectTypePage extends StatefulWidget {
  final int emotionNumber; // Add this line

  SelectTypePage({Key? key, required this.emotionNumber}) : super(key: key); // Update constructor

  @override
  State<StatefulWidget> createState() => _SelectTypePageState();
}

class _SelectTypePageState extends State<SelectTypePage> {
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

  void _navigateToNextPage(String type) {
    if (type == 'voice') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecordScreen(emotionNumber: widget.emotionNumber),
        ),
      );
    } else if (type == 'text') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TextPage(emotionNumber: widget.emotionNumber),
        ),
      );
    }
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
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double buttonWidth = screenWidth * 0.8;
    final double buttonHeight = 60.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xfffdfbf0),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Image.asset(
          'assets/wisely-diary-logo.png',
          height: 30,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
            onPressed: togglePlayPause,
          ),
          Container(
            width: 100,
            child: Slider(
              value: volume,
              min: 0.0,
              max: 1.0,
              onChanged: changeVolume,
            ),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xfffdfbf0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: screenHeight * 0.30),
            ElevatedButton(
              onPressed: () => _navigateToNextPage('voice'),
              child: Text('음성 일기'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(buttonWidth, buttonHeight),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _navigateToNextPage('text'),
              child: Text('텍스트 일기'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(buttonWidth, buttonHeight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}