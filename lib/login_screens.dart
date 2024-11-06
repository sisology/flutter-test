import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'home_screens.dart';
import 'member_information.dart';
import 'alarm/fcm_helper.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    // 상태 바 스타일 설정
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
  }

  Future<void> _googleSignIn() async {
    try {
      const webClientId = '250529177786-ufcdttr2mssq4tleorq6d6r44eh24k71.apps.googleusercontent.com';
      const iosClientId = '250529177786-j7sdpq73vmd9cqtlcc6fq02rl1oscqe7.apps.googleusercontent.com';

      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: iosClientId,
        serverClientId: webClientId,
      );
      final googleUser = await googleSignIn.signIn();
      final googleAuth = await googleUser!.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        throw 'No Access Token or ID Token found.';
      }

      final response = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      final user = response.user;
      if (user != null) {

        // 로그인 성공 후 FCM 토큰 저장
        await FCMHelper.getFCMTokenAndSave(user.id);
        await _handleUserAfterLogin(user, context, googleUser.displayName);
      }
    } catch (e) {
      print('Error during Google login: $e');
    }
  }

  Future<void> _kakaoSignIn() async {
    try {
      kakao.OAuthToken kakaoToken = await kakao.UserApi.instance.loginWithKakaoAccount();
      final accessToken = kakaoToken.accessToken;
      final idToken = kakaoToken.idToken;

      if (accessToken == null || idToken == null) {
        throw 'No Access Token or ID Token found.';
      }

      final kakaoUser = await kakao.UserApi.instance.me();
      final memberName = kakaoUser.kakaoAccount?.profile?.nickname ?? 'Unknown';

      final response = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.kakao,
        idToken: idToken,
        accessToken: accessToken,
      );

      final user = response.user;
      if (user != null) {
        // 로그인 성공 후 FCM 토큰 저장 로직 추가
        await FCMHelper.getFCMTokenAndSave(user.id);
        await _handleUserAfterLogin(user, context, memberName);
      }
    } catch (e) {
      print('Error during Kakao login: $e');
    }
  }

  Future<bool> _isNewUser(String userId) async {
    try {
      final response = await supabase
          .from('member')
          .select()
          .eq('member_id', userId)
          .single();
      return false; // User already exists
    } catch (e) {
      print('Error checking user existence: $e');
      return true; // User does not exist (new user)
    }
  }

  Future<void> _saveUserToDatabase(User user, String? memberName) async {
    final userData = {
      'member_email': user.email,
      'join_at': DateTime.now().toIso8601String(),
      'member_name': memberName ?? user.userMetadata?['full_name'],
      'member_status': 'active',
      'member_id': user.id
    };

    try {
      await supabase.from('member').upsert(userData);
      print('User data saved to database');
    } catch (e) {
      print('Error saving user data to database: $e');
    }
  }

  Future<void> _handleUserAfterLogin(User user, BuildContext context, String? memberName) async {
    try {
      bool isNewUser = await _isNewUser(user.id);

      if (isNewUser) {
        // New user: Save to database and navigate to MemberInformationPage
        await _saveUserToDatabase(user, memberName);
        print('New user detected. Redirecting to MemberInformationPage.');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MemberInformationPage(),
          ),
        );
      } else {
        // Existing user: Navigate to HomePage
        print('Existing user detected. Redirecting to HomePage.');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreens(userId: user.id),
          ),
        );
      }

    } catch (e) {
      print('Error in _handleUserAfterLogin: $e');
      // Error handling (e.g., show alert to user)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Image.asset(
                  'assets/wisely-diary-logo.png',
                  height: 200,
                  width: 300,
                ),
                SizedBox(height: 20),
                Text(
                  '일기로운 슬기생활',
                  style: TextStyle(
                    fontFamily: 'HSSaemaul',
                    color: Colors.black,
                    fontWeight: FontWeight.normal,
                    fontSize: 50,
                  ),
                ),
                SizedBox(height: 50),
                ElevatedButton.icon(
                  icon: Image.asset(
                    'assets/google_logo.png',
                    height: 24,
                    width: 24,
                  ),
                  label: Text('Google로 시작하기'),
                  onPressed: _googleSignIn,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: Colors.white,
                    minimumSize: Size(300, 50),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: Image.asset(
                    'assets/kakao_logo.png',
                    height: 24,
                    width: 24,
                  ),
                  label: Text('카카오로 시작하기'),
                  onPressed: _kakaoSignIn,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: Color(0xFFFFE812),
                    minimumSize: Size(300, 50),
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