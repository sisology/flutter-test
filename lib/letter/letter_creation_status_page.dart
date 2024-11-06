import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'letter_view_page.dart';
import 'letter_service.dart';

class LetterCreationStatusPage extends StatefulWidget {
  final int diaryCode;
  LetterCreationStatusPage({required this.diaryCode});

  @override
  _LetterCreationStatusPageState createState() => _LetterCreationStatusPageState();
}

class _LetterCreationStatusPageState extends State<LetterCreationStatusPage> {
  final LetterService _letterService = LetterService();
  bool _isLoading = true;
  String? _cartoonUrl;
  final List<String> _statusMessages = [
    '편지를 가져오고 있어요...',
    '친구가 당신의 하루를 생각하고 있어요...',
    '따뜻한 말을 고르고 있어요...',
    '정성스럽게 편지를 쓰고 있어요...',
    '편지에 마음을 담고 있어요...',
  ];
  int _currentMessageIndex = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startVisualSimulation();
    _getOrCreateLetterAndCartoon();
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

  Future<void> _getOrCreateLetterAndCartoon() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // First, try to get an existing cartoon
      final existingCartoon = await _getExistingCartoon(user.id);
      if (existingCartoon != null) {
        setState(() {
          _cartoonUrl = existingCartoon;
        });
      } else {
        // If no existing cartoon, create a new one
        await _createLetterCartoon(user.id);
      }

      // Get or create the letter
      final letter = await _letterService.getOrCreateLetter(widget.diaryCode);

      // Add a slight delay for visual effect
      await Future.delayed(Duration(seconds: 2));

      _navigateToLetterView(letter.letterCode);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('편지 또는 만화 생성/조회에 실패했습니다: $e')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  Future<String?> _getExistingCartoon(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('http://43.203.173.116:8080/api/cartoon/inquiry?date=${DateTime.now().toIso8601String().split('T')[0]}&memberId=$userId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> cartoons = json.decode(response.body);
        final letterCartoon = cartoons.firstWhere(
              (cartoon) => cartoon['type'] == 'Letter',
          orElse: () => null,
        );
        return letterCartoon != null ? letterCartoon['cartoonPath'] : null;
      } else if (response.statusCode == 204) {
        return null;
      } else {
        throw Exception('Failed to get existing cartoons');
      }
    } catch (e) {
      print('Error getting existing cartoon: $e');
      return null;
    }
  }

  Future<void> _createLetterCartoon(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('http://43.203.173.116:8080/api/cartoon/letterCartoon/create'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'diaryCode': widget.diaryCode,
          'memberId': userId,
          // Add other necessary parameters here
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _cartoonUrl = response.body;
        });
      } else {
        throw Exception('Failed to create cartoon');
      }
    } catch (e) {
      print('Error creating cartoon: $e');
    }
  }

  void _navigateToLetterView(int letterCode) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LetterViewPage(
          letterCode: letterCode,
          cartoonUrl: _cartoonUrl,
        ),
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
      appBar: AppBar(title: Text('편지 생성 중', style: TextStyle(fontSize: 16),)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading) CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(_statusMessages[_currentMessageIndex]),
            SizedBox(height: 20),
            if (_cartoonUrl != null)
              Column(
                children: [
                  Image.network(_cartoonUrl!),
                  SizedBox(height: 10),
                  Text('당신의 오늘 감정을 그리고 있어요...'),
                ],
              ),
          ],
        ),
      ),
    );
  }
}