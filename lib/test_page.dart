import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart'; // MainApp을 import합니다.

class TestPage extends StatefulWidget {
  @override
  _TestPageState createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        // 사용자가 로그인하지 않은 경우, 메인 페이지로 리다이렉트
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => MyApp()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('테스트 페이지'),
      ),
      body: Center(
        child: Text('로그인한 사용자만 볼 수 있는 페이지입니다.'),
      ),
    );
  }
}