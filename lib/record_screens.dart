import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:mime/mime.dart';
import 'dart:convert';
import 'add_photo_screens.dart';
import 'AudioManager.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart'; // 추가된 패키지

class RecordScreen extends StatefulWidget {
  final int emotionNumber;

  RecordScreen({Key? key, required this.emotionNumber}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen>
    with SingleTickerProviderStateMixin {
  final audioManager = AudioManager();
  final AudioRecorder audioRecorder = AudioRecorder();
  String? recordingPath;
  bool isRecording = false;

  String? memberId;
  String? memberName;

  late AnimationController _controller;

  // 추가된 변수들
  late bool isPlaying;
  late double volume;

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    isPlaying = audioManager.player.playing;
    volume = audioManager.player.volume;

    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    audioManager.player.playerStateStream.listen((state) {
      setState(() {
        isPlaying = state.playing;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchUserName() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final memberResponse = await Supabase.instance.client
          .from('member')
          .select('member_id, member_name')
          .eq('member_id', user.id)
          .single();

      setState(() {
        memberId = memberResponse['member_id'];
        memberName = memberResponse['member_name'];
      });

      print('Fetched memberId: $memberId, memberName: $memberName');
    }
  }

  Future<void> _requestMicrophonePermission() async {
    PermissionStatus status = await Permission.microphone.request();

    if (!status.isGranted) {
      throw Exception('Microphone permission not granted');
    }
  }

  Future<void> startRecording() async {
    await _requestMicrophonePermission(); // 권한 요청

    final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
    final String filePath = p.join(appDocumentsDir.path, "recording.wav");

    await audioRecorder.start(RecordConfig(), path: filePath);
    setState(() {
      isRecording = true;
      recordingPath = filePath;
      _controller.repeat(); // 애니메이션 시작
    });
    print('Recording started, file will be saved to: $filePath');
  }

  Future<String?> stopRecording() async {
    String? filePath = await audioRecorder.stop();
    setState(() {
      isRecording = false;
      recordingPath = filePath;
      _controller.stop(); // 애니메이션 중지
    });
    print('Recording stopped, file saved to: $recordingPath');
    return filePath;
  }

  void togglePlayPause() {
    setState(() {
      if (isPlaying) {
        audioManager.player.pause();
      } else {
        audioManager.player.play();
      }
    });
  }

  void changeVolume(double newVolume) {
    setState(() {
      volume = newVolume;
      audioManager.player.setVolume(newVolume);
    });
  }

  Future<Map<String, dynamic>> sendFileToBackend(String filePath) async {
    if (memberId == null || memberName == null) {
      throw Exception('Member ID or Name is missing.');
    }

    final Uri uri = Uri.parse('http://43.203.173.116:8080/api/transcription');
    final mimeType = lookupMimeType(filePath);

    var request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath(
        'file',
        filePath,
        contentType: mimeType != null ? MediaType.parse(mimeType) : null,
      ));

    var response = await request.send();
    if (response.statusCode == 200) {
      var responseData = await http.Response.fromStream(response);

      var jsonData = jsonDecode(responseData.body);

      String? prompt = jsonData['transcription'] ?? jsonData['text'];
      if (prompt == null) {
        throw Exception('Transcription or text is missing in the response.');
      }

      print('Received transcription: $prompt');
      return await generateDiaryEntry(prompt);
    } else {
      throw Exception('Failed to send file to backend');
    }
  }

  Future<Map<String, dynamic>> generateDiaryEntry(String prompt) async {
    String sanitizedPrompt = prompt.replaceAll(RegExp(r'[\n\r\t]'), ' ');

    String finalPrompt = "위 내용을 포함한 편지 형식이 아닌 일기를 작성해주세요: $sanitizedPrompt";

    final response = await http.post(
      Uri.parse('http://43.203.173.116:8080/api/generate'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'prompt': finalPrompt,
        'memberId': memberId,
        'memberName': memberName,
        'emotionCode': widget.emotionNumber.toString(),
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      print('Generated diary entry: ${responseData['diaryEntry']}');
      print('Generated diary code: ${responseData['diaryCode']}');

      return {
        'diaryEntry': responseData['diaryEntry'],
        'diaryCode': responseData['diaryCode'],
      };
    } else {
      throw Exception('Failed to generate diary entry');
    }
  }

  Future<void> handleStopRecordingAndNavigate() async {
    // 로딩 다이얼로그 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("당신의 일기를 분석 중이에요.."),
              ],
            ),
          ),
        );
      },
    );

    try {
      String? filePath = await stopRecording();
      if (filePath != null) {
        Map<String, dynamic> diaryData = await sendFileToBackend(filePath);
        String transcription = diaryData['diaryEntry'];
        int diaryCode = diaryData['diaryCode'];

        print('Navigating to AddPhotoScreen with diaryCode: $diaryCode');

        // 로딩 다이얼로그 닫기
        Navigator.of(context).pop();

        // 다음 페이지로 이동
        navigateToAddPhotoScreen(transcription, diaryCode);
      }
    } catch (e) {
      Navigator.of(context).pop(); // 에러 발생 시 로딩 다이얼로그 닫기
      print('Error occurred: $e');
      // 에러 처리 (예: 사용자에게 알림)
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
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '가장 기억에 남는 상황이 있었나요?\n언제, 어떤 상황이었나요?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, color: Colors.black),
              ),
              SizedBox(height: 50),
              GestureDetector(
                onTap: () async {
                  if (isRecording) {
                    await handleStopRecordingAndNavigate(); // 수정된 부분
                  } else {
                    await startRecording();
                  }
                },
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: isRecording ? 1 + _controller.value * 0.2 : 1.0, // 크기 변화
                      child: child,
                    );
                  },
                  child: Image.asset(
                    'assets/mic_img.png',
                    width: 100,
                    height: 100,
                  ),
                ),
              ),
              SizedBox(height: 10),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Opacity(
                    opacity: isRecording ? _controller.value : 1.0,
                    child: Text(
                      isRecording ? '녹음 중입니다...\n녹음을 종료하고 싶으시면 다시한번 버튼을 눌러주세요.' : '버튼을 눌러 녹음을 시작하세요',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      backgroundColor: const Color(0xfffdfbf0),
    );
  }

  void navigateToAddPhotoScreen(String transcription, int diaryCode) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => AddPhotoBloc(
            audioManager: AudioManager(),
            transcription: transcription,
            diaryCode: diaryCode,
          ),
          child: AddPhotoScreen(
            transcription: transcription,
            diaryCode: diaryCode,
          ),
        ),
      ),
    );
  }
}
