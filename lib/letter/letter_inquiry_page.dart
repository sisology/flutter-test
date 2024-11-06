import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'letter_model.dart';  // 기존의 모델들
import 'letter_service.dart'; // 기존의 서비스들

class LetterInquiryPage extends StatefulWidget {
  final String date;
  final int? diaryCode;
  LetterInquiryPage({Key? key, required this.date, required this.diaryCode}) : super(key: key);

  @override
  _LetterInquiryPageState createState() => _LetterInquiryPageState();
}

class _LetterInquiryPageState extends State<LetterInquiryPage> {
  List<Letter> letters = [];
  List<String> cartoonPaths = [];
  bool isLoading = true;
  String? error;
  final LetterService _letterService = LetterService();
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchLetterData();
  }

  Future<void> fetchLetterData() async {
    print("일기코드 ${widget.diaryCode}");
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
      final fetchedLetters = await _letterService.inquiryLetter(widget.date, user.id);

      // Fetch cartoon paths
      final cartoonResponse = await Supabase.instance.client
          .from('cartoon')
          .select('cartoon_path')
          .eq('diary_code', widget.diaryCode as Object)
          .eq('type', 'Letter')
          .maybeSingle();

      print("카툰 리스펀스 $cartoonResponse");

      if (cartoonResponse != null) {
        // cartoonResponse is already a Map, no need to cast to List<dynamic>
        final cartoonPath = cartoonResponse['cartoon_path'] as String?;
        cartoonPaths = cartoonPath != null ? [cartoonPath] : [];
      } else {
        cartoonPaths = [];
      }

      setState(() {
        letters = fetchedLetters;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = '데이터를 불러오는 데 실패했습니다: $e';
        isLoading = false;
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
          : letters.isEmpty
          ? Center(child: Text('해당 날짜의 편지가 없습니다.'))
          : PageView.builder(
        itemCount: letters.length,
        onPageChanged: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final letter = letters[index];
          final formattedDate = DateFormat('yyyy년 M월 d일').format(letter.createdAt);
          final cartoonPath = index < cartoonPaths.length ? cartoonPaths[index] : null;

          return SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${formattedDate}\n당신에게 도착한 편지',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 24),
                Text(
                  letter.letterContents ?? '내용 없음',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 24),
                if (cartoonPath != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Divider(thickness: 1.5, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        '당신의 감정을 그려보았어요.',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 16),
                      Image.network(
                        cartoonPath,
                        fit: BoxFit.cover,
                        height: 200,
                        width: double.infinity,
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: letters.length > 1
          ? BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        items: [
          for (int i = 0; i < letters.length; i++)
            BottomNavigationBarItem(
              icon: Icon(Icons.mail),
              label: '편지 ${i + 1}',
            ),
        ],
      )
          : null,
    );
  }
}
