// cartoon_creation_status_page.dart

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

import 'package:wisely_diary/today_cartoon.dart';

class CartoonCreationStatusPage extends StatefulWidget {
  final int diaryCode;
  CartoonCreationStatusPage({required this.diaryCode});

  @override
  _CartoonCreationStatusPageState createState() => _CartoonCreationStatusPageState();
}

class _CartoonCreationStatusPageState extends State<CartoonCreationStatusPage> {
  bool _isLoading = true;
  List<String> _cartoonUrls = [];
  final List<String> _statusMessages = [
    '당신에게 그림을 전달하고 있어요...',
    '당신의 하루를 공감하고 있어요...',
    '당신의 하루를 드로잉하고 있어요...',
    '당신의 하루를 색칠하고 있어요...',
  ];
  int _currentMessageIndex = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startVisualSimulation();
    _getOrCreateCartoon();
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

  Future<void> _getOrCreateCartoon() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final today = DateTime.now().toIso8601String().substring(0, 10);
      final existingCartoons = await _getExistingCartoons(user.id, today);

      if (existingCartoons.isNotEmpty) {
        setState(() {
          _cartoonUrls = existingCartoons;
        });
      } else {
        await _createCartoon(user.id);
      }

      await Future.delayed(Duration(seconds: 2));
      _navigateToCartoonView();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('만화 생성/조회에 실패했습니다: $e')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  Future<List<String>> _getExistingCartoons(String userId, String date) async {
    final response = await http.get(
      Uri.parse('http://43.203.173.116:8080/api/cartoon/inquiry?date=$date&memberId=$userId'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> cartoons = json.decode(response.body);
      return cartoons
          .where((cartoon) => cartoon['type'] == 'Cartoon')
          .map<String>((cartoon) => cartoon['cartoonPath'] ?? '')
          .toList();
    }
    return [];
  }

  Future<void> _createCartoon(String userId) async {
    final response = await http.post(
      Uri.parse('http://43.203.173.116:8080/api/cartoon/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'diaryCode': widget.diaryCode,
        'memberId': userId,
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        _cartoonUrls = [response.body];
      });
    } else {
      throw Exception('Failed to create cartoon');
    }
  }

  void _navigateToCartoonView() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TodayCartoonPage(
          diaryCode: widget.diaryCode,
          cartoonUrls: _cartoonUrls,
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
      appBar: AppBar(title: Text('만화 생성 중')),
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
