import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'custom_scaffold.dart';

class TodayCartoonPage extends StatefulWidget {
  final int diaryCode;
  final List<String> cartoonUrls;

  TodayCartoonPage({required this.diaryCode, required this.cartoonUrls});

  @override
  _TodayCartoonPageState createState() => _TodayCartoonPageState();
}

class _TodayCartoonPageState extends State<TodayCartoonPage> {
  String userName = '';

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
          .select('member_name')
          .eq('member_id', user.id)
          .single();
      setState(() {
        userName = memberResponse['member_name'];
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
        title: GestureDetector(
          child: Image.asset(
            'assets/wisely-diary-logo.png',
            height: 30,
            fit: BoxFit.contain,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "${userName}님께 도착한\n오늘 하루 만화",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              ...widget.cartoonUrls.map((url) => ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: url.isNotEmpty ? Image.network(
                  url,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ) : Text("만화 URL을 불러오지 못했습니다."),
              )).toList(),
              SizedBox(height: 24),
              ElevatedButton(
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
                    Text(
                      '다른 결과 확인하기',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}