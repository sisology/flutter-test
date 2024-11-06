import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'music_service.dart';

class MusicInquiryPage extends StatefulWidget {
  final String date;

  MusicInquiryPage({Key? key, required this.date}) : super(key: key);

  @override
  _MusicInquiryPageState createState() => _MusicInquiryPageState();
}

class _MusicInquiryPageState extends State<MusicInquiryPage> {
  List<Map<String, dynamic>> musics = [];
  bool isLoading = true;
  String? error;
  final MusicService _musicService = MusicService();
  Map<int, VideoPlayerController> videoControllers = {};

  @override
  void initState() {
    super.initState();
    fetchMusicData();
  }

  @override
  void dispose() {
    for (var controller in videoControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> fetchMusicData() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() {
        error = '사용자 인증에 실패했습니다.';
        isLoading = false;
      });
      return;
    }

    try {
      final fetchedMusics = await _musicService.inquiryMusic(widget.date, user.id);
      setState(() {
        musics = fetchedMusics;
        isLoading = false;
      });
      for (var music in musics) {
        initializeVideoPlayer(music);
      }
    } catch (e) {
      setState(() {
        error = '음악을 불러오는 데 실패했습니다: $e';
        isLoading = false;
      });
    }
  }

  Future<void> initializeVideoPlayer(Map<String, dynamic> music) async {
    final musicPath = music['musicPath'];
    if (musicPath != null && musicPath.isNotEmpty) {
      final controller = VideoPlayerController.network(musicPath);
      await controller.initialize();
      setState(() {
        videoControllers[music['musicCode']] = controller;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xfffdfbf0),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Image.asset(
          'assets/wisely-diary-logo.png',
          height: 30,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : error != null
          ? Center(child: Text(error!))
          : musics.isEmpty
          ? Center(child: Text('해당 날짜의 음악이 없습니다.'))
          : ListView.builder(
        itemCount: musics.length,
        itemBuilder: (context, index) {
          final music = musics[index];
          final formattedDate = DateFormat('yyyy년 M월 d일').format(DateTime.parse(music['createdAt']));
          final controller = videoControllers[music['musicCode']];
          return Card(
            margin: EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    '${formattedDate}\n당신에게 도착한 음악',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: [
                        TextSpan(
                          text: '제목: ',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.normal,
                            color: Colors.black,
                          ),
                        ),
                        TextSpan(
                          text: music['musicTitle'] ?? '제목 없음',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.normal,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                if (controller != null) ...[
                  AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    child: VideoPlayer(controller),
                  ),
                  VideoProgressIndicator(controller, allowScrubbing: true),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
                        onPressed: () {
                          setState(() {
                            controller.value.isPlaying
                                ? controller.pause()
                                : controller.play();
                          });
                        },
                      ),
                    ],
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    music['musicLyrics'] ?? '가사 없음',
                    style: TextStyle(fontSize: 12),
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