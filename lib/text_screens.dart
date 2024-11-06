import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'AudioManager.dart';
import 'add_photo_screens.dart';
import 'package:http/http.dart' as http; // HTTP 요청을 위해 추가
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';

class TextPage extends StatefulWidget {
  final int emotionNumber;

  TextPage({Key? key, required this.emotionNumber}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _TextPageState();
}
class _TextPageState extends State<TextPage> {
  final TextEditingController _textEditingController = TextEditingController();
  final FocusNode _focusNode = FocusNode(); // 텍스트 상자 포커스 관리
  final audioManager = AudioManager();
  late bool isPlaying;
  late double volume;

  String? memberId;
  String? memberName;

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

    _fetchUserName(); // 사용자 이름 및 ID를 가져오는 메소드 호출
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
    }
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevents closing the dialog by tapping outside
      builder: (BuildContext context) {
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
  }

  Future<Map<String, dynamic>> generateDiaryEntry(String prompt) async {
    String sanitizedPrompt = prompt.replaceAll(RegExp(r'[\n\r\t]'), ' ');

    final response = await http.post(
      Uri.parse('http://43.203.173.116:8080/api/generate'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'prompt': sanitizedPrompt,
        'memberId': memberId,
        'memberName': memberName,
        'emotionCode': widget.emotionNumber.toString(),
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      String diaryEntry =  responseData['diaryEntry'];
      int diaryCode = responseData['diaryCode'];

      return {
        'diaryEntry': diaryEntry,
        'diaryCode': diaryCode,
      };

    } else {
      throw Exception('Failed to generate diary entry');
    }
  }

  void _navigateToAddPhotoScreen() async {
    if (memberId == null || memberName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('사용자 정보를 불러오는 중입니다. 잠시 후 다시 시도해주세요.')),
      );
      return;
    }

    final prompt = '이 내용으로 정성스러운 하루 일기를 작성해주세요: ${_textEditingController.text}';

    try {
      // Show loading dialog
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

      // Generate diary entry
      final diaryData = await generateDiaryEntry(prompt);

      // Close the loading dialog
      Navigator.of(context, rootNavigator: true).pop();

      // Navigate to the next screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BlocProvider(
              create: (context) => AddPhotoBloc(
                audioManager: AudioManager(),
                transcription: diaryData['diaryEntry'],
                diaryCode: diaryData['diaryCode'],
              ),
              child: AddPhotoScreen(
                transcription: diaryData['diaryEntry'],
                diaryCode: diaryData['diaryCode'],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      // Close the loading dialog in case of an error
      Navigator.of(context, rootNavigator: true).pop();

      print('Failed to generate diary entry: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('일기 생성에 실패했습니다. 나중에 다시 시도해주세요.')),
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
        child: SingleChildScrollView(
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            color: const Color(0xfffdfbf0),
            child: Column(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                Text(
                  '가장 기억에 남는 상황이 있었나요?\n언제, 어떤 상황이었나요?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    decoration: TextDecoration.none,
                    fontSize: 20,
                    color: const Color(0xff2c2c2c),
                    fontWeight: FontWeight.normal,
                  ),
                ),
                SizedBox(height: 20),
                Image.asset(
                  'assets/text_img.png',
                  width: 120,
                  height: 120,
                ),
                SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xffffffff),
                      border: Border.all(color: const Color(0xff000000), width: 1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: _textEditingController,
                      focusNode: _focusNode,
                      maxLines: 5,
                      decoration: InputDecoration.collapsed(
                        hintText: '이곳에 상황을 입력해주세요',
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                GestureDetector(
                  onTap: _navigateToAddPhotoScreen,
                  child: Container(
                    width: 221,
                    height: 54,
                    decoration: BoxDecoration(
                      color: const Color(0xff8d83ff),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '생성하기',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          decoration: TextDecoration.none,
                          fontSize: 20,
                          color: const Color(0xffffffff),
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
