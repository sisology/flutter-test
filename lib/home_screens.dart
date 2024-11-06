import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:wisely_diary/main.dart';
import 'create_diary_screens.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'custom_scaffold.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'date_select.dart';

class HomeScreens extends StatefulWidget {
  final String userId;

  HomeScreens({required this.userId})
      : assert(userId.isNotEmpty, 'userId cannot be empty');

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomeScreens> {
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  List<Map<String, dynamic>> _monthlyDiaryEntries = [];
  Map<DateTime, bool> _hasDiary = {}; // 날짜별 일기 여부를 저장하는 맵
  Map<String, dynamic>? _selectedDayEntry;
  late Future<void> _initializationFuture;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();

    initializeDateFormatting('ko_KR', null).then((_) {
      setState(() {});
    });

    // 페이지가 로드될 때 데이터를 초기화하는 Future 실행
    _initializationFuture = _fetchMonthlyDiaries(_focusedDay);
  }

  // 매달 일기 데이터를 가져오는 Future 함수
  Future<void> _fetchMonthlyDiaries(DateTime month) async {
    String date = DateFormat('yyyy-MM-01').format(month);

    try {
      final response = await http.post(
        Uri.parse('http://43.203.173.116:8080/api/diary/monthly'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'date': date,
          'memberId': widget.userId,
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _monthlyDiaryEntries = data
              .map((item) => {
                    'date': item['date'],
                    'content': item['diaryContents'],
                  })
              .toList();

          _hasDiary = {
            for (var entry in _monthlyDiaryEntries)
              DateTime.parse(entry['date']): true
          };

          _monthlyDiaryEntries.sort((a, b) =>
              DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));
        });
      } else {
        print('Error fetching diary content: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Exception occurred while fetching monthly diaries: $e');
    }
  }

  // 특정 날짜의 일기 내용을 가져오는 Future 함수
  Future<void> _fetchDiaryContent(DateTime selectedDay) async {
    final response = await http.post(
      Uri.parse('http://43.203.173.116:8080/api/diary/selectdetail'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'date': selectedDay.toIso8601String().split('T').first,
        'memberId': widget.userId,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        _selectedDayEntry = {
          'date': selectedDay.toIso8601String().split('T').first,
          'content': data['diaryContents'],
        };
      });
    } else {
      print('Error fetching diary content: ${response.reasonPhrase}');
      setState(() {
        _selectedDayEntry = {
          'date': selectedDay.toIso8601String().split('T').first,
          'content': '일기 내용을 가져오는 중 오류가 발생했습니다.',
        };
      });
    }
  }

  // 로그아웃
  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    final GoogleSignIn googleSignIn = GoogleSignIn();
    await googleSignIn.signOut();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => MyApp()),
    );
  }

  Future<bool> _checkTodayDiaryExists() async {
    final supabase = Supabase.instance.client;
    final today = DateTime.now()
        .toUtc()
        .toString()
        .split(' ')[0]; // Get today's date in UTC

    final response = await supabase
        .from('diary')
        .select()
        .eq('member_id', widget.userId)
        .eq('diary_status', 'EXIST')
        .gte('created_at', '$today 00:00:00')
        .lte('created_at', '$today 23:59:59');

    return response.length > 0;
  }

  void _navigateToAddDiaryEntryPage() async {
    bool todayDiaryExists = await _checkTodayDiaryExists();

    if (todayDiaryExists) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('알림'),
            content: Text('이미 오늘 일기를 작성하셨습니다.'),
            actions: <Widget>[
              TextButton(
                child: Text('확인'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } else {
      Navigator.of(context)
          .push(
        MaterialPageRoute(
          builder: (context) => CreateDiaryPage(),
        ),
      )
          .then((_) {
        _fetchMonthlyDiaries(_focusedDay);
      });
    }
  }

  // 날짜를 선택할 때마다 해당 날짜의 일기 데이터를 가져오는 함수
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _selectedDayEntry = null;
    });
    _fetchDiaryContent(selectedDay);
  }

  // 일기 상세 페이지로 이동하는 함수
  void _navigateToDiaryNoImgPage(DateTime selectedDate) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DiaryNoImgPage(selectedDate: selectedDate),
      ),
    );
  }

DateTime _stripTime(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}


  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      // FutureBuilder로 페이지 초기화 및 데이터를 다시 로드
      body: FutureBuilder<void>(
        future: _initializationFuture,
        builder: (context, snapshot) {
          // 비동기 작업이 완료되기 전 로딩 표시
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // 오류 발생 시 메시지 표시
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            // 비동기 작업이 완료되면 UI 구성
            return Column(
              children: [
                SizedBox(height: 16),
                _buildCalendar(),
                SizedBox(height: 16),
                Expanded(
                  child: _monthlyDiaryEntries.isEmpty
                      ? _buildEmptyState()
                      : _buildDiaryEntriesList(),
                ),
              ],
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddDiaryEntryPage,
        child: Icon(Icons.edit),
        tooltip: '새 일기 추가',
        backgroundColor: Colors.yellow,
        foregroundColor: Colors.white,
      ),
    );
  }

Widget _buildCalendar() {
  return Container(
    margin: EdgeInsets.symmetric(horizontal: 16.0),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          spreadRadius: 2,
          blurRadius: 5,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: TableCalendar(
      locale: 'ko_KR',
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2100, 12, 31),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: _onDaySelected,
      onPageChanged: (focusedDay) {
        setState(() {
          _focusedDay = focusedDay;
          _selectedDayEntry = null;
        });
        _fetchMonthlyDiaries(focusedDay);
      },
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
      daysOfWeekHeight: 20,
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, date, _) {
          DateTime strippedDate = _stripTime(date);
          bool hasDiary = _hasDiary[strippedDate] == true;

          return Center(
            child: Container(
              decoration: hasDiary
                  ? BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.5),
                      shape: BoxShape.circle,
                    )
                  : null,
              padding: EdgeInsets.all(8),
              child: Text(
                date.day.toString(),
                style: TextStyle(
                  color: hasDiary ? Colors.white : Colors.black,
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

  Widget _buildDiaryEntriesList() {
    return SingleChildScrollView(
      child: _selectedDayEntry != null
          ? _buildDiaryEntry(
              _selectedDayEntry!['date'], _selectedDayEntry!['content'])
          : Column(
              children: _monthlyDiaryEntries
                  .map((entry) =>
                      _buildDiaryEntry(entry['date'], entry['content']))
                  .toList(),
            ),
    );
  }

  // 일기 항목을 생성하는 위젯
  Widget _buildDiaryEntry(String date, String content) {
    return GestureDetector(
      onTap: () {
        if (_hasDiary[DateTime.parse(date)] == true) {
          // 실제 일기가 존재하는 경우에만 상세 페이지로 이동
          _navigateToDiaryNoImgPage(DateTime.parse(date));
        } else {
          // 실제 일기가 없는 경우 (안내 메시지인 경우)
          print('이 날짜에는 일기가 없습니다.');
        }
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: 13,
                  left: 0,
                  child: Container(
                    width: 95,
                    height: 8,
                    color: Color(0x7FFFE76B),
                  ),
                ),
                Text(date, style: TextStyle(fontSize: 15, color: Colors.black)),
              ],
            ),
            SizedBox(height: 15),
            Text(
              content,
              style: TextStyle(fontSize: 14, color: Colors.black, fontFamily: 'ICHimchan'),
            ),
            Divider(height: 30),
          ],
        ),
      ),
    );
  }

  // 작성된 일기가 없을 때 보여줄 UI
  Widget _buildEmptyState() {

    DateTime now = DateTime.now();
    String message;

    if (_focusedDay.year == now.year && _focusedDay.month == now.month) {
      message = '작성한 일기가 없습니다.\n일기를 작성해보세요!';
    } else if (_focusedDay.isBefore(DateTime(now.year, now.month, 1))) {
      message = '작성할 수 있는 기간이 지났습니다';
    } else {
      message = '작성할 수 있는 기간이 아닙니다';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Opacity(
            opacity: 0.5,
            child: Image.asset(
              'assets/wisely-diary-logo.png',
              height: 80,
            ),
          ),
          SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}