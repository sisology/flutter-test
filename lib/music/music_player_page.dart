import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'music_service.dart';

class MusicPlayerPage extends StatefulWidget {
  final int musicCode;

  MusicPlayerPage({required this.musicCode});

  @override
  _MusicPlayerPageState createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends State<MusicPlayerPage> {
  final MusicService _musicService = MusicService();
  VideoPlayerController? _controller;
  bool _isVideoGenerating = false;
  static const Duration _initialDelay = Duration(seconds: 110);
  static const Duration _subsequentDelay = Duration(seconds: 30);
  int _retryCount = 0;
  static const int _maxRetries = 5;
  Map<String, dynamic>? _musicData;
  double _volume = 1.0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMusicData();
  }

  Future<void> _loadMusicData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      _musicData = await _musicService.getMusicPlayback(widget.musicCode);
      final videoUrl = _musicData!['clipResponse']?['clips']?[0]?['video_url'];
      if (videoUrl != null && videoUrl.isNotEmpty) {
        await _initializeVideoPlayer(videoUrl);
        _isVideoGenerating = false;
      } else {
        _isVideoGenerating = true;
        if (_retryCount < _maxRetries) {
          _scheduleNextAttempt();
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _scheduleNextAttempt() {
    _retryCount++;
    final delay = _retryCount == 1 ? _initialDelay : _subsequentDelay;
    print('Scheduling attempt $_retryCount in ${delay.inSeconds} seconds');
    Future.delayed(delay, () {
      if (mounted) {
        _loadMusicData();
      }
    });
  }

  Future<void> _initializeVideoPlayer(String videoUrl) async {
    print('Initializing video player with URL: $videoUrl');
    _controller = VideoPlayerController.network(videoUrl);
    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isVideoGenerating = false; // 비디오 생성 상태를 false로 변경
        });
      }
      print('Video initialized successfully');
    } catch (error) {
      print('Error initializing video player: $error');
      _controller = null;
      _error = 'Failed to initialize video player: $error';
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: GestureDetector(
          onTap: () {
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/home', (route) => false);
          },
          child: Image.asset(
            'assets/wisely-diary-logo.png',
            height: 30,
            fit: BoxFit.contain,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? _buildLoadingScreen()
          : _error != null
          ? _buildErrorScreen(_error!)
          : _buildMusicPlayer(_musicData!),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            '음악 작업이 거의 완료되었습니다! 잠시만 기다려 주세요.\n이 작업은 몇 분 동안 수행될 수 있습니다.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen(String? error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Error: $error'),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _retryCount = 0;
                _isLoading = true;
                _error = null;
              });
              _loadMusicData();
            },
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildMusicPlayer(Map<String, dynamic> musicData) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('제목: ${musicData['musicTitle'] ?? 'No Title'}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            if (_controller != null && _controller!.value.isInitialized) ...[
              AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
              VideoProgressIndicator(_controller!, allowScrubbing: true),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(_controller!.value.isPlaying ? Icons.pause : Icons.play_arrow),
                    onPressed: () {
                      setState(() {
                        _controller!.value.isPlaying
                            ? _controller!.pause()
                            : _controller!.play();
                      });
                    },
                  ),
                ],
              ),
            ] else if (_isVideoGenerating)
              Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      '음악을 생성 중입니다. 약 2분 정도 소요될 수 있습니다.\n기다리는 동안 가사를 통해 오늘 하루를 돌아보는건 어떨까요? :)\n(음악 요청 시도 $_retryCount/$_maxRetries)',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              Center(
                child: Text(
                  '음악을 로드할 수 없습니다.\n잠시 후 다시 시도해 주세요.',
                  textAlign: TextAlign.center,
                ),
              ),
            SizedBox(height: 16),
            Text('가사:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(musicData['musicLyrics'] ?? '가사 없음',
                style: TextStyle(fontSize: 14)),
            SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Color(0xFF8B69FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back, size: 18),
                    SizedBox(width: 8),
                    Text(
                      '다른 결과 확인하기',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayPauseButton() {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          if (_controller!.value.isPlaying) {
            _controller!.pause();
          } else {
            _controller!.play();
          }
        });
      },
      child: Icon(
        _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
      ),
    );
  }

  Widget _buildVolumeSlider() {
    return Row(
      children: [
        Icon(Icons.volume_down),
        Expanded(
          child: Slider(
            value: _volume,
            min: 0.0,
            max: 1.0,
            onChanged: (newVolume) {
              setState(() {
                _volume = newVolume;
                _controller?.setVolume(newVolume);
              });
            },
          ),
        ),
        Icon(Icons.volume_up),
      ],
    );
  }
}