import 'package:flutter/material.dart';
import 'package:wisely_diary/select_type_screens.dart';
import 'dart:async';
import 'AudioManager.dart';

class WaitPage extends StatefulWidget {
  final int emotionNumber;

  const WaitPage({Key? key, required this.emotionNumber}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _WaitPageState();
}

class _WaitPageState extends State<WaitPage> with TickerProviderStateMixin {
  int _counter = 5;
  Timer? _timer;
  final audioManager = AudioManager();
  late bool isPlaying;
  late double volume;
  bool _showButton = false;
  bool _showCounter = false;

  late AnimationController _backgroundController;
  late Animation<Color?> _colorAnimation1;
  late Animation<Color?> _colorAnimation2;

  late AnimationController _fadeController1;
  late AnimationController _fadeController2;
  late Animation<double> _fadeAnimation1;
  late Animation<double> _fadeAnimation2;
  String _currentText = '';

  final Map<int, Color> emotionColors = {
    1: Color(0xffAF89B1).withOpacity(0.7), // 걱정
    2: Color(0xffd8b6f1).withOpacity(0.7), // 뿌듯
    3: Color(0xffC4A989).withOpacity(0.7), // 감사
    4: Color(0xff80B9A3).withOpacity(0.7), // 억울
    5: Color(0xfff8bcbc).withOpacity(0.7), // 분노
    6: Color(0xffA0C9FF).withOpacity(0.7), // 슬픔
    7: Color(0xffffd2e7).withOpacity(0.7), // 설렘
    8: Color(0xffFFFF00).withOpacity(0.7), // 신나
    9: Color(0xff8FD997).withOpacity(0.7), // 편안
    10: Color(0xffBFAB9F).withOpacity(0.7), // 당황
  };

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

    _backgroundController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: true);


    Color emotionColor = emotionColors[widget.emotionNumber] ?? Colors.grey.withOpacity(0.7);

    _colorAnimation1 = ColorTween(
      begin: Color(0xfffdfbf0),
      end: emotionColor,
    ).animate(_backgroundController);

    _colorAnimation2 = ColorTween(
      begin: Color(0xffEAE2B7).withOpacity(0.9),
      end: emotionColor.withOpacity(0.5),
    ).animate(_backgroundController);

    _fadeController1 = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeController2 = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeAnimation1 = Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController1);
    _fadeAnimation2 = Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController2);

    _startAnimation();
  }

  void _startAnimation() async {
    // First text
    setState(() => _currentText = '오늘, 당신의 하루는 어땠나요?');
    _fadeController1.forward();
    await Future.delayed(Duration(seconds: 3));
    _fadeController1.reverse();
    await Future.delayed(Duration(seconds: 2));

    // Second text
    setState(() => _currentText = '잠시 심호흡하며 \n하루를 돌아봅시다.');
    _fadeController2.forward();
    await Future.delayed(Duration(seconds: 3));
    _fadeController2.reverse();
    await Future.delayed(Duration(seconds: 2));

    // Show counter and start countdown
    setState(() => _showCounter = true);
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_counter > 1) {
        setState(() {
          _counter--;
        });
      } else {
        setState(() {
          _counter--;
          _showCounter = false;
        });
        timer.cancel();
        Future.delayed(Duration(milliseconds: 500), () {
          setState(() {
            _showButton = true;
          });
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
  void dispose() {
    _timer?.cancel();
    _backgroundController.dispose();
    _fadeController1.dispose();
    _fadeController2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      body: AnimatedBuilder(
        animation: _backgroundController,
        builder: (context, child) {
          return Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_colorAnimation1.value!, _colorAnimation2.value!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_fadeAnimation1, _fadeAnimation2]),
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeAnimation1.value + _fadeAnimation2.value,
                        child: Text(
                          _currentText,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            color: const Color(0xff2c2c2c),
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_showCounter)
                  Center(
                    child: Text(
                      '$_counter',
                      style: TextStyle(
                        fontSize: 60,
                        color: const Color(0xff2c2c2c),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (_showButton)
                  Center(
                    child: Transform.translate(
                      offset: Offset(0, -20),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SelectTypePage(emotionNumber: widget.emotionNumber),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          backgroundColor: Color(0xE5FFFFFF),
                          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 5,
                        ),
                        child: Text(
                          '준비됐어요',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}