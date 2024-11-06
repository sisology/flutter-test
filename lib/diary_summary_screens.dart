import 'package:flutter/material.dart';
import 'package:wisely_diary/music/music_creation_page.dart';
import 'package:wisely_diary/today_cartoon.dart';
import 'dart:io';
import 'cartoon_creation_status.dart';
import 'custom_scaffold.dart';
import 'package:wisely_diary/letter/letter_creation_status_page.dart';
import 'package:wisely_diary/main.dart';

import 'home_screens.dart';  // Added for MyApp navigation

class DiarySummaryScreen extends StatelessWidget {
  final String transcription;
  final List<File> imageFiles;
  final int diaryCode;
  final String userId;

  DiarySummaryScreen({
    required this.transcription,
    required this.imageFiles,
    required this.diaryCode,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

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
      body: Container(
        color: const Color(0xfffdfbf0),
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            Text(
              "오늘의 일기에요",
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            SizedBox(height: 20),
            Container(
              width: screenWidth * 0.8,
              height: screenHeight * 0.4,
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black12),
              ),
              child: Stack(
                children: [
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 10),
                        Text(
                          transcription,
                          style: TextStyle(fontSize: 14, color: Colors.black, fontFamily: 'ICHimchan',),
                        ),
                        SizedBox(height: 10),
                        if (imageFiles.isNotEmpty)
                          Column(
                            children: imageFiles.map((file) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Image.file(file, width: screenWidth * 0.7),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Image.asset(
                      'assets/wisely-diary-logo.png',
                      width: 40,
                      height: 40,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildButton(
                  context,
                  iconPath: 'assets/music_icon.png',
                  label: "노래 선물 받기",
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MusicCreationStatusPage(diaryCode: diaryCode),
                    ),
                  ),
                ),
                _buildButton(
                  context,
                  iconPath: 'assets/cuttoon_icon.png',
                  label: "오늘의 만화",
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CartoonCreationStatusPage(diaryCode: diaryCode),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildButton(
                  context,
                  iconPath: 'assets/letter_icon.png',
                  label: "친구에게 편지 받기",
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LetterCreationStatusPage(diaryCode: diaryCode),
                    ),
                  ),
                ),
                _buildButton(
                  context,
                  iconPath: 'assets/diary_icon.png',
                  label: "메인으로",
                  onPressed: () => _showConfirmationDialog(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

 void _showConfirmationDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("잠깐! 확인해주세요."),
        content: Text("음악, 만화, 편지를 생성하지 않았을 경우\n현재 페이지의 일기만 저장됩니다.\n메인화면으로 이동할까요?"),
        actions: <Widget>[
          TextButton(
            child: Text("취소"),
            onPressed: () {
              Navigator.of(context).pop(); // 다이얼로그 닫기
            },
          ),
          TextButton(
            child: Text("확인"),
            onPressed: () {
              Navigator.of(context).pop(); // 다이얼로그 닫기
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => HomeScreens(userId: userId),
                ),
              );
            },
          ),
        ],
      );
    },
  );
}


  Widget _buildButton(BuildContext context, {required String iconPath, required String label, required VoidCallback onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFFE5E1FF),
        foregroundColor: Colors.black,
        minimumSize: Size(MediaQuery.of(context).size.width * 0.35, 50),
        padding: EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(iconPath, width: 30, height: 30),
          SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // Method to build the logo button
  Widget _buildLogoButton(BuildContext context, {required VoidCallback onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFFE5E1FF), // Match background color with other buttons
        foregroundColor: Colors.black, // Match text color with other buttons
        minimumSize: Size(MediaQuery.of(context).size.width * 0.35, 50),
        padding: EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/wisely-diary-logo.png', width: 35, height: 35), // Increased logo size
          SizedBox(width: 5), // Reduced the space between the logo and text
          Text(
            '홈으로', // Text for the logo button
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
