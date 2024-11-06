import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'main.dart';
import 'member_deactivate.dart';

class MyPage extends StatefulWidget {
  @override
  _MyPageState createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  // 예시 회원 데이터
  String userName = '';
  String userEmail = '';

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final memberResponse = await Supabase.instance.client
          .from('member')
          .select('member_name,member_email')
          .eq('member_id', user.id)
          .single();

      setState(() {
        userName = memberResponse['member_name'];
        userEmail = memberResponse['member_email'];
      });

    }
  }


  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    final GoogleSignIn googleSignIn = GoogleSignIn();
    await googleSignIn.signOut();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => MyApp()),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          SizedBox(height: 70),
          Image.asset(
            'assets/wisely-diary-logo.png',
            width: 100,
            height: 80,
          ),
          SizedBox(height: 10),
          Text(
            userName,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 5),
          Text(
            userEmail,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 40),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 20),
                  _buildButton('알람 설정', () {
                    Navigator.pushNamed(context, '/notifications');
                  }),
                  SizedBox(height: 10),
                  _buildButton('감정 통계', () {
                    Navigator.pushNamed(context, '/statistics');
                  }),
                  SizedBox(height: 10),
                  _buildButton('로그아웃', _signOut),
                  SizedBox(height: 10),
                  _buildButton('회원 탈퇴', () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => MemberDeactivatePage(),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: 200,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xffeeede7),
          padding: EdgeInsets.symmetric(vertical: 15),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}