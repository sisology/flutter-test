import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'letter_model.dart';
import 'letter_service.dart';

class LetterViewPage extends StatefulWidget {
  final int letterCode;
  final String? cartoonUrl;

  LetterViewPage({required this.letterCode, this.cartoonUrl});

  @override
  _LetterViewPageState createState() => _LetterViewPageState();
}

class _LetterViewPageState extends State<LetterViewPage> {
  Future<Letter>? _letterDataFuture;
  final LetterService _letterService = LetterService();

  @override
  void initState() {
    super.initState();
    _letterDataFuture = _fetchLetterData();
  }

  Future<Letter> _fetchLetterData() async {
    try {
      return await _letterService.viewLetter(widget.letterCode);
    } catch (e) {
      print('Error fetching letter data: $e');
      rethrow;
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
      body: FutureBuilder<Letter>(
        future: _letterDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${snapshot.error}'),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _letterDataFuture = _fetchLetterData();
                      });
                    },
                    child: Text('다시 시도'),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasData) {
            final letter = snapshot.data!;
            return SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '오늘의 편지',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '작성일: ${DateFormat('yyyy.MM.dd').format(letter.createdAt) ??
                        '알 수 없음'}',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  SizedBox(height: 24),
                  Text(
                    letter.letterContents ?? '내용 없음',
                    style: TextStyle(fontSize: 16, fontFamily: 'ICHimchan'),
                  ),
                  SizedBox(height: 24),
                  Divider(thickness: 2),
                  SizedBox(height: 24),
                  if (widget.cartoonUrl != null) ...[
                    Text(
                      '당신의 감정을 그려보았어요.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    SizedBox(height: 10),
                    FadeInImage(
                      placeholder: AssetImage('assets/loading_spinner.gif'),
                      image: NetworkImage(widget.cartoonUrl!),
                      fit: BoxFit.contain,
                      imageErrorBuilder: (context, error, stackTrace) {
                        return Text('이미지를 불러오지 못했습니다.',
                            style: TextStyle(color: Colors.red));
                      },
                    ),
                  ],
                  SizedBox(height: 24),
                  Center( // 버튼을 감싸는 Center 위젯 추가
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Color(0xFF8B69FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 24,
                            vertical: 12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back, size: 18),
                          SizedBox(width: 8),
                          Text(
                            '다른 결과 확인하기',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else {
            return Center(child: Text('편지를 찾을 수 없습니다.'));
          }
        },
      ),
    );
  }
}
