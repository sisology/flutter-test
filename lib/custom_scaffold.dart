import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart'; // GoogleSignIn import 추가
import 'package:wisely_diary/main.dart'; // MyApp이 정의된 파일 import 추가


class CustomScaffold extends StatelessWidget {
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final String? title;
  final bool showAppBar;

  const CustomScaffold({
    Key? key,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.title,
    this.showAppBar = true,
  }) : super(key: key);

  Future<void> _signOut(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    final GoogleSignIn googleSignIn = GoogleSignIn();
    await googleSignIn.signOut();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => MyApp()),
          (Route<dynamic> route) => false,
    );
  }

  void _navigateToHome(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false, arguments: userId);
  }

  void _navigateToPage(BuildContext context, String routeName) {
    Navigator.of(context).pushNamed(routeName);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar
          ? AppBar(
        backgroundColor: const Color(0xfffffdf9),
        elevation: 0,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: Icon(Icons.menu, color: Colors.black),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        title: title != null
            ? Text(title!,
            style: TextStyle(color: Colors.black, fontSize: 15))
            : GestureDetector(
          onTap: () => _navigateToHome(context),
          child: Image.asset(
            'assets/wisely-diary-logo.png',
            height: 30,
            fit: BoxFit.contain,
          ),
        ),
        centerTitle: true,
        actions: [
          ...?actions,
        ],
      )
          : null,
      drawer: Drawer(
        backgroundColor: const Color(0xfffffdf9), // 원래 배경색으로 복원
        child: Stack(
          children: [
            Column(
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(
                    color: Color(0xfffffdf9),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/wisely-diary-logo.png',
                        height: 60,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(height: 10),
                      Text(
                        '일기로운 슬기생활',
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      ListTile(
                        leading: Icon(Icons.home),
                        title: Text('홈', style: TextStyle(fontSize: 15.0)),
                        onTap: () {
                          _navigateToHome(context);
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.person),
                        title: Text('마이페이지', style: TextStyle(fontSize: 15.0)),
                        onTap: () {
                          Navigator.pop(context);
                          _navigateToPage(context, '/mypage');
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.analytics),
                        title: Text('감정 통계', style: TextStyle(fontSize: 15.0)),
                        onTap: () {
                          Navigator.pop(context);
                          _navigateToPage(context, '/statistics');
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.notifications),
                        title: Text('알림 설정', style: TextStyle(fontSize: 15.0)),
                        onTap: () {
                          Navigator.pop(context);
                          _navigateToPage(context, '/notifications');
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // 로그아웃 버튼을 이모티콘으로 하단에 배치
            Positioned(
              bottom: 16,
              right: 16,
              child: IconButton(
                icon: Icon(Icons.logout, color: Colors.black),
                onPressed: () async {
                  Navigator.pop(context);
                  await _signOut(context);
                },
                tooltip: '로그아웃',
              ),
            ),
          ],
        ),
      ),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}