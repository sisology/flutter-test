import 'package:flutter/material.dart';
import 'dart:async';
import 'music_player_page.dart';
import 'music_service.dart';

class MusicCreationStatusPage extends StatefulWidget {
  final int diaryCode;

  MusicCreationStatusPage({required this.diaryCode});

  @override
  _MusicCreationStatusPageState createState() => _MusicCreationStatusPageState();
}

class _MusicCreationStatusPageState extends State<MusicCreationStatusPage> {
  final MusicService _musicService = MusicService();
  bool _isLoading = true;
  final List<String> _statusMessages = [
    '음악을 가져오고 있어요...',
    '당신의 하루를 음악으로 만들고 있어요...',
    '멜로디를 고르고 있어요...',
    '가사를 작성하고 있어요...',
    '음악에 마음을 담고 있어요...',
  ];
  int _currentMessageIndex = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startVisualSimulation();
    _getOrCreateMusic();
  }

  void _startVisualSimulation() {
    _timer = Timer.periodic(Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _currentMessageIndex = (_currentMessageIndex + 1) % _statusMessages.length;
        });
      }
    });
  }

  Future<void> _getOrCreateMusic() async {
    try {
      final musicData = await _musicService.getOrCreateMusicPlayback(widget.diaryCode);

      // 시각적 효과를 위해 약간의 지연 추가
      await Future.delayed(Duration(seconds: 2));

      _navigateToMusicPlayer(musicData['musicCode']);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('음악 생성 또는 조회에 실패했습니다: $e')),
      );
      // 오류 발생 시 이전 페이지로 돌아가기
      Navigator.of(context).pop();
    }
  }

  void _navigateToMusicPlayer(int musicCode) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MusicPlayerPage(musicCode: musicCode),
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('음악 생성 중', style: TextStyle(fontSize: 16),)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading) CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(_statusMessages[_currentMessageIndex]),
          ],
        ),
      ),
    );
  }
}