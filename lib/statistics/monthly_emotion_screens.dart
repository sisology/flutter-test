import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart' hide TextDirection;


// 감정 이름을 반환하는 함수 (예: '분노', '슬픔' 등)
String getEmotionNameByCode(String code) {
  final emotionNames = {
    '1': '걱정',
    '2': '뿌듯',
    '3': '감사',
    '4': '억울',
    '5': '분노',
    '6': '슬픔',
    '7': '설렘',
    '8': '신남',
    '9': '편안',
    '10': '당황'
  };
  return emotionNames[code] ?? '알 수 없음';
}
// 감정 코드와 색상을 매핑한 emotionColors
final emotionColors = {
  '1': Colors.deepPurpleAccent,
  '2': Colors.purple,
  '3': Colors.amber,
  '4': Colors.teal,
  '5': Colors.red,
  '6': Colors.cyan,
  '7': Colors.pink,
  '8': Colors.yellow,
  '9': Colors.green,
  '10': Colors.orange,
};

class MonthlyEmotionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Image.asset(
          'assets/wisely-diary-logo.png', // 이미지 경로
          height: 30, // 원하는 크기로 조정
          fit: BoxFit.contain,
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
            ),
            padding: const EdgeInsets.all(16.0),
            child: FutureBuilder<Map<String, dynamic>>(
              future: fetchEmotionData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data == null || snapshot.data!.isEmpty) {
                  // 데이터가 없을 경우 또는 비어있는 경우 처리
                  return _buildNoDataScreen(context);
                } else {
                  // 데이터가 있을 경우 통계 화면 처리
                  Map<String, dynamic> data = snapshot.data!;
                  Map<String, dynamic> thisMonthEmotions = data['thisMonthEmotions'];
                  Map<String, dynamic> yearlyEmotionsRaw = data['yearlyEmotions'];

                  if (thisMonthEmotions.isEmpty) {
                    return _buildNoDataScreen(context);
                  }

                  // 사용자 이름 가져오기
                  String memberName = data['memberName'] ?? '사용자'; // 기본값 설정

                  // 가장 높은 퍼센티지를 가진 emotion_code 찾기
                  String maxEmotionCode = thisMonthEmotions.keys.first;
                  double maxPercentage = thisMonthEmotions[maxEmotionCode];

                  thisMonthEmotions.forEach((emotionCode, percentage) {
                    if (percentage > maxPercentage) {
                      maxEmotionCode = emotionCode;
                      maxPercentage = percentage;
                    }
                  });

                  // 감정 코드와 이모티콘 이미지 파일을 매핑
                  final Map<String, String> emotionImageMap = {
                    '1': 'assets/emotions/worried.png',
                    '2': 'assets/emotions/proud.png',
                    '3': 'assets/emotions/greatful.png',
                    '4': 'assets/emotions/injustice.png',
                    '5': 'assets/emotions/anger.png',
                    '6': 'assets/emotions/sad.png',
                    '7': 'assets/emotions/lovely.png',
                    '8': 'assets/emotions/joy.png',
                    '9': 'assets/emotions/relax.png',
                    '10': 'assets/emotions/embarrassed.png'
                  };

                  String emotionName = getEmotionNameByCode(maxEmotionCode);

                  // 키와 값을 변환해서 Map<int, int>로 만듦
                  Map<int, int> yearlyEmotions = yearlyEmotionsRaw.map((key, value) {
                    return MapEntry(int.parse(key), value as int);
                  });

                  // 현재 월 구하기
                  String currentMonth = "${DateTime.now().month}월";

                  return Column(
                    children: [
                      // 감정 차트 제목
                      Stack(
                        children: [
                          Positioned(
                            top: 16,
                            left: 0,
                            child: Container(
                              width: 150,
                              height: 20,
                              color: Colors.yellow.withOpacity(0.5),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "이번 달 $memberName님 감정",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // 커스텀 반원 차트
                      SizedBox(
                        height: 200,
                        child: CustomSemiDonutChart(
                          emotions: thisMonthEmotions,
                        ),
                      ),
                      // 주된 감정 이미지와 텍스트
                      Column(
                        children: [
                          Image.asset(
                            // 해당 감정 코드에 맞는 이미지 경로 반환
                            emotionImageMap[maxEmotionCode] ?? 'assets/wisely-diary-logo.png',
                            height: 200,
                          ),
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: TextStyle(fontSize: 18, color: Colors.black),
                              children: [
                                TextSpan(text: '$currentMonth $memberName님의 메인 감정은\n'),
                                TextSpan(
                                  text: '$emotionName(${maxPercentage.toStringAsFixed(0)}%)',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: emotionColors[maxEmotionCode] ?? Colors.yellow,
                                  ),
                                ),
                                TextSpan(
                                    text: '입니다', style: TextStyle(fontSize: 18)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      // 감정 달력
                      _buildEmotionTable(yearlyEmotions),
                    ],
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  // 데이터를 처리할 수 없을 때 화면
  Widget _buildNoDataScreen(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 670,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center ,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Opacity(
            opacity: 0.5, // 0.0에서 1.0 사이의 값. 0.0은 완전 투명, 1.0은 완전 불투명
            child: Container(
              height: 100,
              child: Image.asset(
                'assets/wisely-diary-logo.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(height: 16),
          Text(
            '작성된 일기가 없습니다!\n일기를 작성해보세요!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }





  // HTTP 요청을 보내서 감정 데이터를 받아오는 함수
  Future<Map<String, dynamic>> fetchEmotionData() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User not logged in');
    }

    final memberId = user.id;
    String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final url = Uri.parse('http://43.203.173.116:8080/api/statistics/inquire');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "memberId": memberId,
        "date": todayDate
      }),
    );

    if (response.statusCode == 200) {
      print(response.body);
      final decodedResponse = utf8.decode(response.bodyBytes);
      return json.decode(decodedResponse);
    } else {
      throw Exception('Failed to load emotion data');
    }
  }

  // 감정 달력을 생성하는 함수
  Widget _buildEmotionTable(Map<int, int> yearlyEmotions) {
    // 감정 코드와 이모티콘 이미지 파일을 매핑
    final Map<int, String> emotionImageMap = {
      1: 'assets/emotions/worried.png',
      2: 'assets/emotions/proud.png',
      3: 'assets/emotions/greatful.png',
      4: 'assets/emotions/injustice.png',
      5: 'assets/emotions/anger.png',
      6: 'assets/emotions/sad.png',
      7: 'assets/emotions/lovely.png',
      8: 'assets/emotions/joy.png',
      9: 'assets/emotions/relax.png',
      10: 'assets/emotions/embarrassed.png'
    };

    return Table(
      border: TableBorder.all(color: Colors.grey, width: 1),
      children: [
        TableRow(
          children: [
            Center(child: Text('1월')),
            Center(child: Text('2월')),
            Center(child: Text('3월')),
            Center(child: Text('4월')),
            Center(child: Text('5월')),
            Center(child: Text('6월')),
          ],
        ),
        TableRow(
          children: [
            Center(child: _buildEmotionIcon(1, yearlyEmotions, emotionImageMap)),
            Center(child: _buildEmotionIcon(2, yearlyEmotions, emotionImageMap)),
            Center(child: _buildEmotionIcon(3, yearlyEmotions, emotionImageMap)),
            Center(child: _buildEmotionIcon(4, yearlyEmotions, emotionImageMap)),
            Center(child: _buildEmotionIcon(5, yearlyEmotions, emotionImageMap)),
            Center(child: _buildEmotionIcon(6, yearlyEmotions, emotionImageMap)),
          ],
        ),
        TableRow(
          children: [
            Center(child: Text('7월')),
            Center(child: Text('8월')),
            Center(child: Text('9월')),
            Center(child: Text('10월')),
            Center(child: Text('11월')),
            Center(child: Text('12월')),
          ],
        ),
        TableRow(
          children: [
            Center(child: _buildEmotionIcon(7, yearlyEmotions, emotionImageMap)),
            Center(child: _buildEmotionIcon(8, yearlyEmotions, emotionImageMap)),
            Center(child: _buildEmotionIcon(9, yearlyEmotions, emotionImageMap)),
            Center(child: _buildEmotionIcon(10, yearlyEmotions, emotionImageMap)),
            Center(child: _buildEmotionIcon(11, yearlyEmotions, emotionImageMap)),
            Center(child: _buildEmotionIcon(12, yearlyEmotions, emotionImageMap)),
          ],
        ),
      ],
    );
  }

  // emotion_code에 맞는 이모티콘 이미지를 반환하는 함수
  Widget _buildEmotionIcon(int month, Map<int, int> yearlyEmotions, Map<int, String> emotionImageMap) {
    int? emotionCode = yearlyEmotions[month]; // 해당 월의 감정 코드 가져오기

    if (emotionCode != null && emotionImageMap.containsKey(emotionCode)) {
      return Image.asset(
        emotionImageMap[emotionCode]!, // 감정 코드에 맞는 이미지 경로 반환
        height: 70,
        width: 70,
      );
    } else {
      return SizedBox(height: 70, width: 70); // 감정 코드가 없으면 빈 공간 반환
    }
  }
}

class CustomSemiDonutChart extends StatelessWidget {
  final Map<String, dynamic> emotions;

  CustomSemiDonutChart({required this.emotions});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(300, 150), // 차트의 크기 조정
      painter: SemiDonutPainter(emotions: emotions),
    );
  }
}

class SemiDonutPainter extends CustomPainter {
  final Map<String, dynamic> emotions;

  SemiDonutPainter({required this.emotions});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height;
    final radius = size.height - 100;

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 100.0;

    // 감정 데이터를 리스트로 변환하고, 퍼센티지에 따라 내림차순 정렬
    final sortedEmotions = emotions.entries.toList()
      ..sort((a, b) {
        final percentageComparison = (b.value as double).compareTo(a.value as double);
        if (percentageComparison != 0) {
          return percentageComparison;
        } else {
          // 퍼센티지가 같으면 emotion_code 순으로 정렬
          return int.parse(a.key).compareTo(int.parse(b.key));
        }
      });

    double startAngle = pi;
    for (var entry in sortedEmotions) {
      final emotionCode = entry.key;
      final percentage = entry.value as double;
      final sweepAngle = percentage * pi / 100;
      paint.color = emotionColors[emotionCode] ?? Colors.yellow;

      canvas.drawArc(
        Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      // 텍스트 위치 선정
      final textAngle = startAngle + sweepAngle / 2;
      final textX = centerX + (radius + 0) * cos(textAngle);
      final textY = centerY + (radius + 0) * sin(textAngle);

      // 감정 이름 매핑되어있는 전역함수 불러오기
      final emotionName = getEmotionNameByCode(emotionCode);
      final displayText = '$emotionName(${percentage.toStringAsFixed(0)}%)';

      // 차트 위에 텍스트 표시
      _drawText(canvas, displayText, textX, textY);

      startAngle += sweepAngle;
    }
  }

  // 텍스트 설정
  void _drawText(Canvas canvas, String text, double x, double y) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(color: Colors.white, fontSize: 14),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class EmotionData {
  final String name;
  final double percentage;
  final Color color;

  EmotionData(this.name, this.percentage, this.color);
}