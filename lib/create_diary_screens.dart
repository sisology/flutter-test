import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'wait_screens.dart';
import 'AudioManager.dart';

class CreateDiaryPage extends StatefulWidget {
  @override
  _CreateDiaryPageState createState() => _CreateDiaryPageState();
}

class _CreateDiaryPageState extends State<CreateDiaryPage> with WidgetsBindingObserver {
  final audioManager = AudioManager();
  late bool isPlaying;
  late double volume;
  late String userName = 'Loading...'; // Initialize with a placeholder

  final Map<String, String> emotionToAudio = {
    '분노': 'assets/audio/anger_bgm.mp3',
    '설렘': 'assets/audio/lovely_bgm.mp3',
    '편안': 'assets/audio/relax_bgm.mp3',
    '신나': 'assets/audio/joy_bgm.mp3',
    '감사': 'assets/audio/greatful_bgm.mp3',
    '슬픔': 'assets/audio/sad_bgm.mp3',
    '당황': 'assets/audio/embarrassed_bgm.mp3',
    '억울': 'assets/audio/injustice_bgm.mp3',
    '뿌듯': 'assets/audio/proud_bgm.mp3',
    '걱정': 'assets/audio/worried_bgm.mp3',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    audioManager.initAudio();
    isPlaying = audioManager.player.playing;
    volume = audioManager.player.volume;

    _fetchUserName();
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
    WidgetsBinding.instance.removeObserver(this);
    // 페이지가 dispose될 때 음악을 멈춤
    audioManager.player.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      audioManager.player.stop();
    }
  }

  Future<void> _fetchUserName() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final memberResponse = await Supabase.instance.client
          .from('member')
          .select('member_name')
          .eq('member_id', user.id)
          .single();

      setState(() {
        userName = memberResponse['member_name'];
      });

    }
  }

  void togglePlayPause() {
    if (isPlaying) {
      audioManager.player.pause();
    } else {
      audioManager.player.play();
    }
    setState(() {
      isPlaying = !isPlaying;
    });
  }

  void changeVolume(double newVolume) {
    setState(() {
      volume = newVolume;
      audioManager.player.setVolume(newVolume);
    });
  }

  Future<void> playEmotionMusic(String emotion) async {
    if (emotionToAudio.containsKey(emotion)) {
      await audioManager.player.setAsset(emotionToAudio[emotion]!);
      await audioManager.player.play();
      setState(() {
        isPlaying = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double imageSize = screenWidth * 0.2;
    final double textSpacing = 5.0;
    final double itemSpacing = 20.0;

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
        // actions: [
        //   IconButton(
        //     icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
        //     onPressed: togglePlayPause,
        //   ),
        //   Container(
        //     width: 100,
        //     child: Slider(
        //       value: volume,
        //       min: 0.0,
        //       max: 1.0,
        //       onChanged: changeVolume,
        //     ),
        //   ),
        // ],
      ),
      body: Container(
        child: Stack(
          children: [
            Positioned(
              left: 0,
              width: screenWidth,
              height: screenHeight * 0.9,
              child: Container(
                color: const Color(0xfffdfbf0),
              ),
            ),
            Positioned(
              left: 20,
              width: screenWidth - 40,
              child: Text(
                '$userName님\n오늘은 어떤 하루였나요?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  decoration: TextDecoration.none,
                  fontSize: 20,
                  color: const Color(0xff2c2c2c),
                  fontWeight: FontWeight.normal,
                ),
                maxLines: 9999,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _buildEmotionWidget(context, '분노', 'assets/emotions/anger.png', 0.25, 0.10, imageSize, textSpacing, itemSpacing),
            _buildEmotionWidget(context, '설렘', 'assets/emotions/lovely.png', 0.25, 0.25, imageSize, textSpacing, itemSpacing),
            _buildEmotionWidget(context, '편안', 'assets/emotions/relax.png', 0.25, 0.40, imageSize, textSpacing, itemSpacing),
            _buildEmotionWidget(context, '신나', 'assets/emotions/joy.png', 0.25, 0.55, imageSize, textSpacing, itemSpacing),
            _buildEmotionWidget(context, '감사', 'assets/emotions/greatful.png', 0.25, 0.70, imageSize, textSpacing, itemSpacing),
            _buildEmotionWidget(context, '슬픔', 'assets/emotions/sad.png', 0.55, 0.10, imageSize, textSpacing, itemSpacing),
            _buildEmotionWidget(context, '당황', 'assets/emotions/embarrassed.png', 0.55, 0.25, imageSize, textSpacing, itemSpacing),
            _buildEmotionWidget(context, '억울', 'assets/emotions/injustice.png', 0.55, 0.40, imageSize, textSpacing, itemSpacing),
            _buildEmotionWidget(context, '뿌듯', 'assets/emotions/proud.png', 0.55, 0.55, imageSize, textSpacing, itemSpacing),
            _buildEmotionWidget(context, '걱정', 'assets/emotions/worried.png', 0.55, 0.70, imageSize, textSpacing, itemSpacing),
          ],
        ),
      ),
    );
  }

  Widget _buildEmotionWidget(BuildContext context, String label, String imagePath, double left, double top, double imageSize, double textSpacing, double itemSpacing) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    final emotionNumberMap = {
      '걱정': 1,
      '뿌듯': 2,
      '감사': 3,
      '억울': 4,
      '분노': 5,
      '슬픔': 6,
      '설렘': 7,
      '신나': 8,
      '편안': 9,
      '당황': 10,
    };

    return Positioned(
      left: screenWidth * left,
      top: screenHeight * top,
      child: GestureDetector(
        onTap: () async {
          final int emotionNumber = emotionNumberMap[label]!;

          // Start playing the emotion music
          playEmotionMusic(label);

          await playEmotionMusic(label);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WaitPage(emotionNumber: emotionNumber),
            ),
          );
        },
        child: Column(
          children: [
            Image.asset(
              imagePath,
              width: imageSize,
              height: imageSize,
              fit: BoxFit.contain,
            ),
            SizedBox(height: textSpacing),
            Text(
              label,
              style: TextStyle(
                decoration: TextDecoration.none,
                fontSize: 14,
                color: const Color(0xff282034),
                fontWeight: FontWeight.normal,
              ),
            ),
            SizedBox(height: itemSpacing),
          ],
        ),
      ),
    );
  }
}