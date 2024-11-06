import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import 'AudioManager.dart';
import 'diary_select.dart';

class BgmPlay extends StatefulWidget {
  @override
  _BgmPlayState createState() => _BgmPlayState();
}

class _BgmPlayState extends State<BgmPlay> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final audioManager = AudioManager();
  String currentEmotion = '';
  bool isSecondPage = false;
  bool isPlaying = false;
  double volume = 1.0;



  final Map<String, Map<String, String>> emotionData = {
    '걱정': {'image': 'assets/emotions/worried.png', 'audio': 'assets/audio/worried_bgm.mp3'},
    '뿌듯': {'image': 'assets/emotions/proud.png', 'audio': 'assets/audio/proud_bgm.mp3'},
    '감사': {'image': 'assets/emotions/greatful.png', 'audio': 'assets/audio/greatful_bgm.mp3'},
    '억울': {'image': 'assets/emotions/injustice.png', 'audio': 'assets/audio/injustice_bgm.mp3'},
    '분노': {'image': 'assets/emotions/anger.png', 'audio': 'assets/audio/anger_bgm.mp3'},
    '슬픔': {'image': 'assets/emotions/sad.png', 'audio': 'assets/audio/sad_bgm.mp3'},
    '설렘': {'image': 'assets/emotions/lovely.png', 'audio': 'assets/audio/lovely_bgm.mp3'},
    '신남': {'image': 'assets/emotions/joy.png', 'audio': 'assets/audio/joy_bgm.mp3'},
    '편안': {'image': 'assets/emotions/relax.png', 'audio': 'assets/audio/relax_bgm.mp3'},
    '당황': {'image': 'assets/emotions/embarrassed.png', 'audio': 'assets/audio/embarrassed_bgm.mp3'},
  };

  @override
  void initState() {
    super.initState();
    audioManager.initAudio();
    audioManager.player.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          isPlaying = state.playing;
        });
      }
    });
  }

  @override
  void dispose() {
    // _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> playEmotionMusic(String emotion) async {
    if (emotionData.containsKey(emotion)) {
      await audioManager.player.setAsset(emotionData[emotion]!['audio']!);
      await audioManager.player.play();
      setState(() {
        currentEmotion = emotion;
        isSecondPage = true;
      });
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

  void goToFirstPage() {
    if (mounted) {
      setState(() {
        isSecondPage = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (isSecondPage) {
          goToFirstPage();
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('감정 음악 플레이어'),
          leading: isSecondPage
              ? IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: goToFirstPage,
          )
              : null,
        ),
        body: isSecondPage ? _buildSecondPage() : _buildFirstPage(),
      ),
    );
  }

  Widget _buildFirstPage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            '오늘은 어떤 하루였나요?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          _buildEmotionGrid(),
        ],
      ),
    );
  }

  Widget _buildEmotionGrid() {
    return GridView.count(
      crossAxisCount: 5,
      shrinkWrap: true,
      childAspectRatio: 0.8,
      children: emotionData.keys.map((emotion) {
        return GestureDetector(
          onTap: () => playEmotionMusic(emotion),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                emotionData[emotion]!['image']!,
                width: 80,
                height: 80,
              ),
              SizedBox(height: 5),
              Text(emotion, style: TextStyle(fontSize: 12)),
            ],
          ),
        );
      }).toList(),
    );
  }



  Widget _buildSecondPage() {
    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '눈을 감고',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                '오늘 하루를 돌아봅시다.',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 40),
              CountdownTimer(
                onFinished: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DiarySelectPage(key: null),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 20,
          right: 20,
          child: Row(
            children: [
              IconButton(
                icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: togglePlayPause,
              ),
              _buildVolumeSlider(),
              ElevatedButton(
                child: Text('처음으로'),
                onPressed: goToFirstPage,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  minimumSize: Size(60, 30),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVolumeSlider() {
    return Container(
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
    );
  }
}

class CountdownTimer extends StatefulWidget {
  final VoidCallback onFinished;

  CountdownTimer({required this.onFinished});

  @override
  _CountdownTimerState createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  int _secondsRemaining = 10;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    Future.delayed(Duration(seconds: 1), () {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
        _startTimer();
      } else {
        widget.onFinished();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      '$_secondsRemaining',
      style: TextStyle(fontSize: 72, fontWeight: FontWeight.bold),
    );
  }
}